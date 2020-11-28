ALTER PROCEDURE [dbo].[PcImportaNfeServicosGinfes] @CodEmpresa Int, @DataInicialP Datetime, @DataFinalP datetime, 
@PkUsuario Int, @Caminho Varchar(8000), @Sobrepor char(3), @TipoImportacao tinyint, @BtDataEmissao Char(3), @BtDataCompetencia Char(3) 
as
------------------------------------------------------------------------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
----------------------------------------------------------------------------------------------------------------------------------------
--Esta Pc atende vários municípios:
--Pará de Minas
--Belo Horizonte
--Nova Lima
--Cajuru
--Santa Luzia
--Itapecerica
--Contagem
--Itaúna
--São Luís do Maranhão
--Joinville 
--Dentre Outros
--

--Ao realizar alterações, cuidado para não arrumar um município e prejudicar outros

------------------------------------------------------------------------------------------------------------------------------------------
Declare @Query varchar(1000), @FileName varchar(200), @Extensao varchar(100), @CaminhoC Varchar(8000),
@Emissao Varchar(30), @PkXml Int, @Conteudo NVarchar(MAX), @PkNota int, @item varchar(255), 
@Inicio varchar(100), @Inicio2 varchar(100), @Alteracao Varchar(30), @Texto Varchar(900), 
@CnpjTomador Varchar(14), @CnpjPrestador Varchar(14), @CnpjEmpresaCorrente Varchar(14), @ImpServicosTomadosCN Char(1), 
@ImpServicosPrestadosCN Char(1), @ImpServicosTomadosVP Char(1), @ImpServicosPrestadosVP Char(1), @Numero BigInt, @CodigoVerificacao Varchar(100),
@Cnpj Varchar(14), @Count Int, @DataBalancoAbertura Datetime, @Cpf Varchar(14), @CodigoProdutoPadrao Varchar(60), @PkCodigoProdutoPadrao Int,
@Pg405 Char(3), @TipoDeclaranteDmed Int, @TipoNfse Int, @PkEscritorio Int = dbo.FPkEscritorioUsuarios(@PkUsuario),
@FkListaServicos Int, @CodigoMunicipio Varchar(10), @DataHoraInicial DateTime = GetDate(), @MunicipioXml int
------------------------------------------------------------------------------------------------------------------------------------------
Begin Try
------------------------------------------------------------------------------------------------------------------------------------------
Set @Emissao = dbo.FEmissao(@PkUsuario)
Set @Alteracao = @Emissao
------------------------------------------------------------------------------------------------------------------------------------------
Set @ImpServicosTomadosCN = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 283)), 1)
Set @ImpServicosPrestadosCN = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 284)), 1)
Set @ImpServicosTomadosVP = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 281)), 1)
Set @ImpServicosPrestadosVP = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 282)), 1)
Set @CodigoProdutoPadrao = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 390)), 60)
Set @Pg405 = dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 405)

Set @PkCodigoProdutoPadrao = 0

Select Top 1 @PkCodigoProdutoPadrao = Coalesce(Pk, 0)
From CadProdutos 
Where (CodEmpresa = @CodEmpresa) and
(CodigoProduto = LTrim(RTrim(@CodigoProdutoPadrao)))

Select @CnpjEmpresaCorrente = Cnpj, 
@DataBalancoAbertura = DataBalancoAbertura
From CadEmpresa
Where (CodEmpresa = @CodEmpresa) and
(FkEscritorio = @PkEscritorio)

Select Top 1 @TipoDeclaranteDmed = TipoDeclaranteDmed
From TributacaoFederal
Where (CodEmpresa = @CodEmpresa) and 
(DataInicial <= @DataFinalP) and
(FkCadEmpresaScp is null)
Order By DataInicial desc

Select Top 1 @FkListaServicos = FkListaServicos
From TributacaoMunicipal
Where (CodEmpresa = @CodEmpresa) and 
(DataInicial <= @DataFinalP)
order by DataInicial Desc

Set @FkListaServicos = Case When @FkListaServicos is null Then 0 Else @FkListaServicos End

-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
--Início da Validação
-----------------------------------------------------------------------------------------------------------------------------------------
Delete MSistema
Where (FkUsuario = @PkUsuario)

-----------------------------------------------------------------------------------------------------------------------------------------
Exec PcVerificaModuloSistema 6, @PkUsuario
Exec PcValidaCodEmpresa @CodEmpresa, @PkUsuario
Exec PcValidaDataPeriodo @DataInicialP, @DataFinalP, @PkUsuario
Exec PcValidaCaminhoImportacao @Caminho, @PkUsuario
Exec PcVerificaDataLimiteUsoSistema @DataInicialP, @PkUsuario
Exec PcVerificaEncerramento @CodEmpresa, 'Fiscal', @DataInicialP, 'Sim', 'Sim', @PkUsuario, 'Sim'
Exec PcValidaSmallDateTime @PkUsuario, @DataInicialP, 'Data Inicial do Período de Trabalho'
Exec PcValidaSmallDateTime @PkUsuario, @DataFinalP, 'Data Final do Período de Trabalho'

-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
--Valida o parametro global 390, se existe o produto cadastrado.
-----------------------------------------------------------------------------------------------------------------------------------------
If (Coalesce(LTrim(RTrim(@CodigoProdutoPadrao)), '') <> '')    
  Begin
    If Not Exists(
        Select Pk
        From CadProdutos
        Where (CodEmpresa = @CodEmpresa) and
        (CodigoProduto = LTrim(RTrim(@CodigoProdutoPadrao))))
      Begin
        Insert MSistema(FkUsuario, Abort, Descricao, Texto)
        Select @PkUsuario,
        'Sim',
        Left('O código do produto: ' + RTrim(LTrim(@CodigoProdutoPadrao)) + 
        ' não existe no cadastro de produtos. Cadastre-o primeiro e tente importar novamente.', 255),
        'Este código de produto está configurado no parâmetro global 390. Verifique esta situação!'
      End
  End

-----------------------------------------------------------------------------------------------------------------------------------------    
If dbo.FAbort(@PkUsuario) = 'Sim' --Caso não exista o arquivo
  Begin
    Return
  End
  
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
--Declare @NomeArquivo table (nome varchar(300))

Begin Try Drop Table #NomeArquivo End Try Begin Catch End Catch
Create table #NomeArquivo(nome varchar(300))


If @TipoImportacao = 1 --Todas as NF-e do diretório escolhido
  Begin

    Set @Caminho = dbo.FNomeArquivoDiretorio(@Caminho)
    
    Set @Extensao = '*.xml'
    Set @query = 'master.dbo.xp_cmdshell "dir ""' + @Caminho + @Extensao + '"" /b"'
  End
Else
  Begin
    Set @query = 'master.dbo.xp_cmdshell "dir ""' + @Caminho + '"" /b"'
  End

------------------------------------------------------------------------------------------------------------------------------------------------------
--Esta validação foi feita porque o Windows não aceita caminhos com mais de 128 caracteres... 15/12/2010 Adriana
------------------------------------------------------------------------------------------------------------------------------------------------------
If (LEN(@Query) > 128)
  Begin
    Insert MSistema
    (FkUsuario, Descricao, Texto, Abort)
    Select @PkUsuario, --FkUsuario 
    Left('O caminho do diretório escolhido é muito longo. Por favor escolha outro caminho!', 255), --Descricao
    'Retire as notas fiscais do diretorio escolhido: ' + @Caminho + ', e coloque em um diretório mais curto!', --Texto
    'Sim' --Abort
    
    return
  End
------------------------------------------------------------------------------------------------------------------------------------------
--Inclui na tabela temporária todos os nomes dos arquivo da extensão do diretório informado
-----------------------------------
--Insert @NomeArquivo
--exec(@query)
Insert #NomeArquivo exec(@query)

--Delete @NomeArquivo 
--Where (Coalesce(Nome, '') = '')
Delete #NomeArquivo 
Where (Coalesce(Nome, '') = '')

--Início da validação
If @CodEmpresa = 0
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select Distinct @PkUsuario, --FkUsuario 
    'Sim', --Abort
    Left('Escolha a empresa que será importada a NFSe primeiro.', 255), --Descricao
    'A empresa corrente ainda deverá ser escolhida, é possível que você tenha feito um filtro em EMPRESAS.' --Texto
  End
  
---------------------------------------------------------------------------------------------------------------------------------------------------- 
If @Sobrepor = ''
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select @PkUsuario, --FkUsuario
    'Sim', --Abort 
    'Informe se o sistema irá sobrepor as Notas de Serviços já existentes do período.',
    'Operação cancelada.'
  End
  
If Coalesce(@TipoImportacao, 0) = 0
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select @PkUsuario, --FkUsuario
    'Sim', --Abort 
    'Informe que tipo de importação será aplicado sobre o diretório escolhido.',
    'Operação cancelada.'
  End

----------------------------------------------------------------------------------------------------------------------------------------------------  
If @DataFinalP < @DataInicialP
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select Distinct @PkUsuario, --FkUsuario 
    'Sim', --Abort
    Left('A data final tem que ser maior ou igual a data inicial.', 255), --Descricao
    'Verifique no período de trabalho escolhido.' --Texto
  end

If DatePart(mm, @DataInicialP) <> DatePart(mm, @DataFinalP)
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select Distinct @PkUsuario, --FkUsuario 
    'Não', --Abort
    Left('O sistema só permite importar NFe em até um mês calendário.', 255), --Descricao
    'Você pode escolher apenas um período.' --Texto
  End
  
If DatePart(yy, @DataInicialP) <> DatePart(yy, @DataFinalP)
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select Distinct @PkUsuario, --FkUsuario
    'Não', --Abort
    Left('O sistema só permite importar NFe em até um ano calendário.', 255), --Descricao
    'Você pode escolher apenas um período.' --Texto
  End

If not exists(Select Top 1 Nome From #NomeArquivo Where (Nome like '%.Xml'))
  Begin
    If @TipoImportacao = 1 --Todas as NF-e do diretório escolhido
      Begin
        Insert MSistema 
        (FkUsuario, Abort, Descricao, Texto)
        Select @PkUsuario, --FkUsuario
        'Sim', --Abort
        Left(@Caminho, 255), --Descricao
        'Não foi encontrado nenhum arquivo XML no diretório escolhido' --Texto
      End
    Else
      Begin
        Insert MSistema 
        (FkUsuario, Abort, Descricao, Texto)
        Select @PkUsuario, --FkUsuario 
        'Sim', --Abort
        Left('Arquivo escolhido: ' + @Caminho, 255), --Descricao
        'Este arquivo ainda terá que ser importado, pois sua extensão é diferente da extensão .XML' --Texto
        From #NomeArquivo
         
      End
  End
-----------------------------------------------------------------------------------------------------------------------------------------
If exists(Select Top 1 FkUsuario From MSistema Where (FkUsuario = @PkUsuario) and (Abort = 'Sim'))
  Begin
    Insert MSistema 
    (FkUsuario, Abort, Descricao, Texto)
    Select @PkUsuario, --FkUsuario 
    'Sim', --Abort
    Left('Na validação inicial da importação foi encontrado erros. Verifique acima.', 255), --Descricao
    'Nenhuma NFe. foi importada' --Texto 

    Return
  End
  
------------------------------------------------------------------------------------------------------------------------------------------------------
Declare @impostosFederais table
(dtEmissao varchar(100), numeroNota varchar(100), codigoVerificacao varchar(100), codigoImposto varchar(10), 
descricaoImposto varchar(100), tipo varchar(10), aliquota numeric(18, 2), valorImposto numeric(18, 2))

Declare @PrestadorServico table
(Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), Cidade Varchar(30), Uf Varchar(2), CodigoMunicipio Varchar(7), Estado Varchar(2), 
Cep Varchar(8), RazaoSocial Varchar(115), Cnpj Varchar(14), CodigoVerificacao Varchar(255), CodigoControle Varchar(255), Cpf Varchar(14))
------------------------------------------------------------------------------------------------------------------------------------------------------

Begin Try Close CrNomeArquivo  Deallocate CrNomeArquivo End try Begin Catch End Catch

Declare CrNomeArquivo cursor local static for
Select Nome
From #NomeArquivo
Where (Nome like '%.Xml')
Order By Nome
Open CrNomeArquivo
Fetch next from CrNomeArquivo Into @FileName
While @@Fetch_Status = 0
  begin
    -------------------------------------------------------------------------------------------------------------------------------------------------
    Begin Try Drop Table #Conteudo End Try Begin Catch End Catch
    Create Table #Conteudo (Conteudo nVarchar(max))

    
    If @TipoImportacao = 1 --Todas as NF-e do diretório escolhido
      Begin
        Set @CaminhoC = @Caminho+@FileName
      End
    Else
      Begin
        Set @CaminhoC = @Caminho
      End

    Set @CaminhoC = '''' + @CaminhoC + ''''
    
    Set @Query = ('BULK INSERT #Conteudo FROM ' + @CaminhoC + 'with (CODEPAGE = ''ACP'', ROWTERMINATOR=''NVTMSEMFIMDELINHA'')')
    
    Execute (@Query)    

    --Adicionado por Everton no dia 09/01/2019 para tratamento da exportação do municipio de Matozinhos. ---------------------------------------------------
     Update #Conteudo
     Set Conteudo = Replace(Replace(Replace(Replace(Conteudo,'<![CDATA[',''),']]>',''),'R$',''),'&','E')    
    --------------------------------------------------------------------------------------------------------------------------------------------------------
            
    Insert MSistema
    (FkUsuario, Abort, Descricao, Texto)
    Select distinct @PkUsuario, --FkUsuario 
    'Sim', --Abort
    Left('Este arquivo não possui as características de uma nota fiscal eletrônica Ginfes! Leia Abaixo:', 255), --Descricao 
    '- Você pode estar escolhendo o nó GINFES e tentando importar uma nota fiscal eletrônica de serviço com outro layout, se for este o caso escolha o nó NFE.' + CHAR(13) + 
    '- Você pode estar tentando importar uma nota fiscal corrompida, abra o arquivo e verifique se o navegador está interpretando a nota fiscal.' + Char(13) +
    '- O MakroContábil pode não estar preparado para importar este layout de nota fiscal.'
    From #Conteudo
    Where 
    (
      (Conteudo not like '%GINFES%') and 
      (Conteudo not like '%abrasf%') and 
      (Conteudo not like '%IssIntel%') and 
      (Conteudo not like '%CompNfse%') and 
      (Conteudo not like 'DeclaracaoPrestacaoServico') and
      (Conteudo not like '%ComplNfse%') and 
      (Conteudo not like '%nfem.joinville%') and --Prefeitura de Joinville
      (Conteudo not like '%<notas>%') and --Prefeitura de Várzea da Palma 
      (Conteudo not like '%<codigo_municipio>3141108</codigo_municipio>%') and  --Prefeitura de Matozinho
      (Conteudo not like '%<NewDataSet>%') and --Prefeitura de Cubatão
      (Conteudo not like '%<inscricaoMunicipal>14009</inscricaoMunicipal>%') and --Prefeitura de Várzea da Palma
      (Conteudo not like '%<inscricaoMunicipal>1744</inscricaoMunicipal>%') and --Prefeitura de Várzea da Palma
      (Conteudo not like '%<codigoMunicipio>921</codigoMunicipio>%') and --Prefeitura de São Luís do Maranhão
      (Conteudo not like '%<InscricaoMunicipal>19383</InscricaoMunicipal>%') and --Prefeitura de Belford Roxo
      (Conteudo not like '%<codigo_municipio>3114006</codigo_municipio>%') and --Prefeitura de Carmo da Mata
      (Conteudo not like '%<codigo_municipio>3118403</codigo_municipio>%') and --Prefeitura de Conselheiro Pena
      (Conteudo not like '%<codigo_municipio>3126000</codigo_municipio>%') and --Prefeitura de Florestal
      (Upper(Conteudo) not like '%<CODIGO_CIDADE>7145</CODIGO_CIDADE>%') and --Prefeitura de Sorocaba - Everton - 14/02/2019
      (Conteudo not like '%<tcListaNFse%') --Prefeitura de Guanhães
    ) 
    
    
    If exists(Select Top 1 FkUsuario From MSistema Where (FkUsuario = @PkUsuario) and (Abort = 'Sim'))
      Begin
        Insert MSistema 
        (FkUsuario, Abort, Descricao, Texto)
        Select @PkUsuario, --FkUsuario 
        'Sim', --Abort
        Left('Na validação inicial da importação foram encontrados alguns erros. Verifique acima.', 255), --Descricao
        'Nenhuma NFe. foi importada' --Texto 

        Return
      End

    
     
    If exists (select 1 from #Conteudo where (Conteudo like '%nfem.joinville%')) --Joinville
      Begin
        Set @MunicipioXml = 4209102
      End

    If exists (select 1 from #Conteudo where (Upper(Conteudo) like '%<CODIGO_CIDADE>7145</CODIGO_CIDADE>%')) --Sorocaba - Everton - 14/02/2019
      Begin
        Set @MunicipioXml = 3552205
      End

    IF Exists (Select * From #Conteudo Where  (Upper(Conteudo) not like '%<CODIGO_CIDADE>7145</CODIGO_CIDADE>%'))
      Begin
        Select @Conteudo = Conteudo
        From #Conteudo
      End 
    Else
      Begin
        Select @Conteudo = Conteudo
        From #Conteudo  
      End
      
    exec PcRetornaXmlPadrao @Conteudo output
        
    Set @Inicio = null
  
    If exists(Select Conteudo From #Conteudo Where Conteudo like '%GINFES%') 
      Begin
        set @Inicio = '/NFSE/Nfse'
        Set @TipoNfse = 1

        If exists(Select Conteudo From #Conteudo Where Conteudo like ('%<CodigoMunicipio>3147105</CodigoMunicipio>%'))
          Begin
            --Referente ao Município de Pará de Minas. Esta variável está sendo utilizada para saber qual a cidade da importação, quando for necessário atender alguma particularidade do município. Élio 15.01.2018
            Set @MunicipioXml = 3147105
          End

        If exists(Select Conteudo From #Conteudo Where Conteudo like ('%<MunicipioPrestacaoServico>3133808</MunicipioPrestacaoServico>%'))
          Begin   
            --Recebe o código do município de Itaúna para tratamento diferenciado. 
            Set @MunicipioXml = 3133808
          End 
        
      End

    Else If exists (Select Conteudo From #Conteudo Where Conteudo like ('%ComplNfse%')) --Prefeitura de Cajuru
      Begin
        Set @Inicio = 'ListaNfse/ComplNfse/Nfse/InfNfse'
        Set @TipoNfse = 1
      End

    Else If exists (Select Conteudo From #Conteudo Where (Conteudo like '%ListaNfse%') and (Conteudo not like '%DeclaracaoPrestacaoServico%') and (Conteudo not like '%<InscricaoMunicipal>0951456</InscricaoMunicipal>%') and (Conteudo Not Like '%<tcListaNFse%'))
      Begin
        Set @Inicio = 'ListaNfse/Nfse/InfNfse'
        Set @TipoNfse = 1
      End
    --Para notas fiscais emitidas pelo programa facilitiss (Município Cláudio), dentro desse arquivo possui mais tags do que dentro dos outros arquivos.
    Else If exists (Select Conteudo From #Conteudo Where Conteudo like '%DeclaracaoPrestacaoServico%')
      Begin
        If Exists(Select Conteudo From #Conteudo Where Conteudo like '%%')
          Begin
            --Print('TRUE')
      
            If exists (Select Conteudo From #Conteudo Where Conteudo like '%ListaNfse%')
              Begin
                Set @Inicio = 'ListaNfse/Nfse/InfNfse'
                Set @TipoNfse = 2
              End
            Else
              Begin
                Set @Inicio = 'Nfse/InfNfse'
                Set @TipoNfse = 2
              End
                
            If not exists(Select Conteudo From #Conteudo Where Conteudo like '%InfNfse Id="%')
              Begin          
    
                --Set @Conteudo = Replace(@Conteudo, '<ListaNfse>', '')
                --Set @Conteudo = Replace(@Conteudo, '</ListaNfse>', '')
                --Set @Conteudo = Replace(@Conteudo, '<Nfse >', '') --Situação de Pernambuco com espaço antes do fechamento
                --Set @Conteudo = Replace(@Conteudo, '<Nfse>', '')
                --Set @Conteudo = Replace(@Conteudo, '</Nfse>', '')

                Set @Inicio = 'ListaNfse/Nfse/InfNfse'
                Set @TipoNfse = 2
      
              End
          End
      End
    Else If exists (Select Conteudo From #Conteudo Where Conteudo like '%<codigoMunicipio>921</codigoMunicipio>%')
      Begin
        --Prefeitura de São Luís do Maranhão
        Set @Inicio = '/nfse' 
        Set @TipoNfse = 3
      End
    
    Else If exists (Select Conteudo From #Conteudo Where Upper(Conteudo) like '%<CODIGO_CIDADE>7145</CODIGO_CIDADE>%') 
      Begin
        --Prefeitura de Sorocaba
        Set @Inicio = 'NOTAS_FISCAIS/NOTA_FISCAL' 
        Set @TipoNfse = 9
        print Concat('Tipo  ',@TipoNfse)
      End

    Else If (exists (Select Conteudo From #Conteudo Where Conteudo like '%<codigo_municipio>3114006</codigo_municipio>%') Or --Carmo da Mata
      exists (Select Conteudo From #Conteudo Where Conteudo like '%<codigo_municipio>3118403</codigo_municipio>%') Or--Conselheiro Pena
      exists (Select Conteudo From #Conteudo Where Conteudo like '%<codigo_municipio>3126000</codigo_municipio>%') Or --Florestal
      exists (Select Conteudo From #Conteudo Where Conteudo like '%<codigo_municipio>3141108</codigo_municipio>%') --Matozinho --Everton - 09/01/2019
    )
      Begin --Prefeitura de Carmo da Mata, Conselheiro Pena, Florestal e Matozinho
        Set @Inicio = 'notas/item'   
        Set @TipoNfse = 4
        
      End

    Else If exists (Select Conteudo From #Conteudo Where Conteudo like '%<tcListaNFse%')
      Begin --Prefeitura de Guanhães
        Set @Inicio = '/Nfse'   
        Set @TipoNfse = 5
      End

    Else If (@MunicipioXml = 4209102 )
      Begin --Prefeitura de Joinville
        Set @Inicio = '/lote'
        Set @TipoNfse = 6
      End

    Else If exists (Select Conteudo From #Conteudo Where Conteudo like '%<notas>%')
      Begin
        Set @Inicio = '/notas/nfse'
        Set @TipoNfse = 7
      End
    
    Else If exists (Select Conteudo From #Conteudo Where Conteudo like '%nfdok numeronfd="%')
      Begin --Prefeitura de Cubatão
        Set @Inicio = '/tbnfd/nfdok/NewDataSet/NOTA_FISCAL'
        Set @TipoNfse = 8
      End

    Else If exists (Select Conteudo From #Conteudo Where Conteudo like '%RZEA DA PALMA</nome>%')
      Begin --Prefeitura de VÁRZEA DA PALMA
        Set @Inicio = '/nfse'
        Set @TipoNfse = 7
      End

    Else 
      Begin
        Set @Inicio = '/Nfse/InfNfse'
        Set @TipoNfse = 1
      End
       

   -- Select @Inicio, @TipoNfse, @Conteudo
    Begin Try      
      Exec SP_XML_PREPAREDOCUMENT @PkXml Output, @Conteudo
    End Try
    Begin Catch
      Insert MSistema 
      (FkUsuario, Abort, Descricao, Texto)
      Select @PkUsuario, --FkUsuario 
      'Sim', --Abort
      Left('O arquivo: ' + @FileName + ', está fora do padrão XML e não será importado.', 255), --Descricao
      'Erro: ' + ERROR_MESSAGE() + CHAR(13) + CHAR(10) + 'Verifique a situação no caminho: ' + @Caminho --Texto 
      
      Fetch next from CrNomeArquivo Into @FileName
      Continue
      
    End Catch
    -----------------------------------------------------------------------------------------------------------------------------------------------
    --Identifica o Cnpj do Emitente para Identificar o Código da Empresa
    ---------------------------------------------------------------------
    Delete @PrestadorServico

    If (@TipoNfse = 3) 
      Begin
        --Prefeitura de São Luís do Maranhão
        Select @Inicio2 = @Inicio + '/prestador/endereco'

        Insert @PrestadorServico(Endereco, Numero, Bairro, Cidade, Uf, CodigoMunicipio, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle)
        Select logradouro, 0, Bairro, descricaoMunicipio, codigoEstado, codigoMunicipio, codigoEstado, cep,
        razaoSocial, cnpj, CodigoVerificacao, ''
        From OpenXml(@PkXml, @Inicio2, 2)
        With (logradouro varchar(125), bairro Varchar(60), codigoEstado Varchar(2), codigoMunicipio Varchar(7), descricaoMunicipio Varchar(7), cep Varchar(8),
        razaoSocial Varchar(115) '../razaoSocial', cnpj Varchar(14) '../cnpj', codigoVerificacao Varchar(100) '../../codigoVerificacao')
      End
    Else If (@TipoNfse = 4)
      Begin
        --Prefeitura de Carmo da Mata, Florestal, Matozinhos
        Select @Inicio2 = @Inicio +  '/prestacao_servico/identificacao_prestador'

        Insert @PrestadorServico(Endereco, Numero, Bairro, Uf, CodigoMunicipio, Cep, RazaoSocial, Cnpj, CodigoVerificacao)
        Select logradouro, numero, bairro, uf, codigo_municipio, cep, razao_social, cnpj, codigo_verificacao
        From OpenXml(@PkXml, @Inicio2, 2) 
        With (logradouro Varchar(125) '../endereco/logradouro', numero Varchar(10) '../endereco/numero', bairro Varchar(60) '../endereco/bairro', uf Varchar(2) '../endereco/uf', 
        codigo_municipio Varchar(7) '../endereco/codigo_municipio', cep Varchar(8) '../endereco/cep', razao_social Varchar(115) '../razao_social', cnpj Varchar(14),
        codigo_verificacao Varchar(100) '../../codigo_verificacao')
                     
        ------------------------------
      End
    Else If (@TipoNfse = 5)
      Begin
        --Prefeitura de Guanhães
        Select @Inicio2 = @Inicio +  '/DadosPrestador/Endereco'

        Insert @PrestadorServico(Endereco, Numero, Bairro, Cidade, Uf, CodigoMunicipio, Cep, RazaoSocial, Cnpj, CodigoVerificacao)
        Select Logradouro, LogradouroNumero, Bairro, Municipio, Uf, CodigoMunicipio, Cep, RazaoSocial, CpfCnpj, Id
        From OpenXml(@PkXml, @Inicio2, 2) 
        With (Logradouro Varchar(125), LogradouroNumero Varchar(10), Bairro Varchar(60), Municipio Varchar(20), Uf Varchar(2), CodigoMunicipio Varchar(10), Cep Varchar(8), RazaoSocial Varchar(115) '../RazaoSocial', 
        CpfCnpj Varchar(14) '../../DadosPrestador', Id Varchar(255) '../../Id')
    
        ------------------------------
      End
    Else If (@TipoNfse = 6)
      Begin
        --Prefeitura de Joinville
        Select @Inicio2 = @Inicio + '/prestador'

        Insert @PrestadorServico(Cnpj, RazaoSocial)
        Select documento, razao_social
        From OpenXml(@PkXml, @Inicio2, 2)
        With (documento Varchar(14), razao_social Varchar(115))

        ------------------------------
      End
    Else If (@TipoNfse = 7)
      Begin      
        --Prefeitura de Várzea da Palma
        Select @Inicio2 = @Inicio + '/prestadorServico'

        Insert @PrestadorServico(Endereco, Bairro, Cep, RazaoSocial, Cnpj, CodigoVerificacao, Cidade, Uf)
        Select endereco, bairro, cep, nomeRazao, cnpj, codigoVerificacao, nome, uf
        From OpenXml(@PkXml, @Inicio2, 2)
        With (endereco Varchar(125), bairro Varchar(60), cep Varchar(8), nomeRazao Varchar(115), cnpj Varchar(14), codigoVerificacao Varchar(255), 
        nome Varchar (30) '../municipioPrestacao/nome', uf Varchar(2) '../municipioPrestacao/uf')
              
        ------------------------------        
      End
      Else If (@TipoNfse = 9)
      Begin
        --Prefeitura de Sorocaba
        Select @Inicio2 = @Inicio +  ''

       Insert @PrestadorServico(Endereco, Numero, Complemento, Bairro, Cidade,  CodigoMunicipio, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao)
        Select PRESTADOR_LOGRADOURO, PRESTADOR_PREST_NUMERO, PRESTADOR_TIPO_BAIRRO, PRESTADOR_BAIRRO , PRESTADOR_CIDADE,  PRESTADOR_CIDADE_CODIGO, PRESTADOR_UF, PRESTADOR_CEP, PRESTADOR_RAZAO_SOCIAL, 
        PRESTADOR_CPF_CNPJ, CODIGO_VERIFICACAO
        From OpenXml(@PkXml, @Inicio2, 2)
        With (PRESTADOR_LOGRADOURO varchar(125), PRESTADOR_PREST_NUMERO Varchar(10), PRESTADOR_TIPO_BAIRRO Varchar(60), PRESTADOR_BAIRRO Varchar(60), PRESTADOR_CIDADE Varchar(30),  PRESTADOR_CIDADE_CODIGO Varchar(7), 
        PRESTADOR_UF Varchar(2), PRESTADOR_CEP Varchar(8), PRESTADOR_RAZAO_SOCIAL Varchar(115) , PRESTADOR_CPF_CNPJ Varchar(14), CODIGO_VERIFICACAO Varchar )

        Update @PrestadorServico 
        set CodigoMunicipio =
        Concat(@MunicipioXml,''),
         Uf = Estado
        Where CodigoMunicipio = '7145'

        Set @CodigoMunicipio = @MunicipioXml
        ------------------------------
      End
    Else If (@TipoNfse = 8)
      Begin
        --Prefeitura de Cubatão
        Select @Inicio2 = @Inicio

        Declare @TempPrestador Table (Endereco varchar(125), RazaoSocial Varchar(115), Cnpj Varchar(100), CodigoVerificacao Varchar(100))

        Insert @TempPrestador(Endereco, RazaoSocial, Cnpj, CodigoVerificacao)
        Select TimbreContribuinteLinha2, TimbreContribuinteLinha1, TimbreContribuinteLinha4, ChaveValidacao
        From OpenXml(@PkXml, @Inicio2, 2)
        With (TimbreContribuinteLinha2 Varchar(125), TimbreContribuinteLinha1 Varchar(50), TimbreContribuinteLinha4 Varchar(100), 
        ChaveValidacao Varchar(255))

        Update @TempPrestador
        Set Cnpj = dbo.FSomenteNumeros(Substring(Cnpj, PATINDEX('%CPF/CNPJ:%', Cnpj) + 9, Len(Cnpj)))


        Insert @PrestadorServico(Endereco, RazaoSocial, Cnpj, CodigoVerificacao)
        Select Endereco, RazaoSocial, Cnpj, CodigoVerificacao
        From @TempPrestador

        ------------------------------
      End
  
    Else
      Begin

        Set @Inicio2 = @Inicio + '/PrestadorServico/Endereco'

        Insert @PrestadorServico
        (Endereco, Numero, Complemento, Bairro, Cidade, Uf, CodigoMunicipio, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf)
        Select Endereco, Numero, Complemento, Bairro, Cidade, Uf, CodigoMunicipio, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf 
        From OpenXml(@PkXml, @Inicio2, 2)
        With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), Cidade Varchar(30), Uf Varchar(2), CodigoMunicipio Varchar(7), 
        Estado Varchar(2), Cep Varchar(8), RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../Cnpj', CodigoVerificacao Varchar(100) '../../CodigoVerificacao', 
        CodigoControle Varchar(255) '../../CodigoControle', Cpf Varchar(14) '../Cpf')
                        
        If not exists (Select Endereco From @PrestadorServico)
          Begin
            Set @Inicio = '/Nfse/InfNfse'

            Set @Inicio2 = @Inicio + '/PrestadorServico/Endereco'

            Insert @PrestadorServico
            (Endereco, Numero, Complemento, Bairro, Cidade, Uf, CodigoMunicipio, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle)
            Select Endereco, Numero, Complemento, Bairro, Cidade, Uf, CodigoMunicipio, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle
            From OpenXml(@PkXml, @Inicio2, 2)
            With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), Cidade Varchar(30), Uf Varchar(2), CodigoMunicipio Varchar(7), 
            Estado Varchar(2), Cep Varchar(8), RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../Cnpj', CodigoVerificacao Varchar(100) '../../CodigoVerificacao', 
            CodigoControle Varchar(255) '../../CodigoControle')
          End

      End
      

    -----------------------------------------------------------------------------------------------------------------------------------------------
    --Identifica o Cnpj do destinatário para Identificar o Pk
    -------------------------------------------------------
    
    Begin Try Drop Table #TomadorServico End Try Begin Catch End Catch
    Begin Try Drop Table #TomadorServicoTemp End Try Begin Catch End Catch
    Begin Try Drop Table #TomadorServicoTemp2 End Try Begin Catch End Catch
    Begin Try Drop Table #TomadorServicoTemp3 End Try Begin Catch End Catch
    Begin Try Drop Table #TomadorServicoTemp6 End Try Begin Catch End Catch --Prefeitura de Carmo da Mata, Matozinhos
    Begin Try Drop Table #TomadorServicoTemp7 End Try Begin Catch End Catch --Prefeitura de Guanhães
    Begin Try Drop Table #TomadorServicoTemp8 End Try Begin Catch End Catch --Prefeitura de Joinville
    Begin Try Drop Table #TomadorServicoTemp9 End Try Begin Catch End Catch --Prefeitura de Várzea da Palma
    Begin Try Drop Table #TomadorServicoTemp10 End Try Begin Catch End Catch --Prefeitura de Cubatão
    Begin Try Drop Table #TomadorServicoTemp11 End Try Begin Catch End Catch --Prefeitura de Sorocaba
    Begin Try Drop Table #TomadorServicoTempMpm End Try Begin Catch End Catch --Prefeitura de Pará de Minas
    Begin Try Drop Table #TomadorServicoTempItauna End Try Begin Catch End Catch --Prefeitura de Itaúna


    If (@TipoNfse = 1)
      Begin
        Select @Inicio2 = @Inicio + '/TomadorServico/Endereco'
      End
    Else if (@TipoNfse = 3)
      Begin
        Select @Inicio2 = @Inicio + '/tomador/endereco'  --Prefeitura de São Luís do Maranhão
      End
    Else
      Begin 
        If Exists (Select Conteudo From #Conteudo Where Conteudo Like '%TomadorServico%')
          Begin
            Select @Inicio2 = @Inicio + '/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/TomadorServico/Endereco'
          End
        Else if not exists (Select Conteudo From #Conteudo Where Conteudo Like '%InfDeclaracaoPrestacaoServico%')
          Begin
            Select @Inicio2 = @Inicio + '/DeclaracaoPrestacaoServico/Tomador/Endereco' --Prefeitura de Nova Lima
          End
        Else
          Begin
            Select @Inicio2 = @Inicio + '/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Tomador/Endereco'
          End
      End

    
    Select * Into #TomadorServico
    From OpenXml(@PkXml, @Inicio2, 2)
    With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), Cidade Varchar(30), Estado Varchar(2), Cep Varchar(8),
    RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../Cnpj', CodigoVerificacao Varchar(100) '../../CodigoVerificacao',  
    CodigoControle Varchar(255) '../../CodigoControle', Cpf Varchar(11) '../Cpf', CodigoMunicipio varchar(15))

    --Atender especificação de Itaúna. Élio 16.02.2018 
    If(@MunicipioXml = 3133808)
      Begin

        Delete From #TomadorServico
        Select * Into #TomadorServicoTempItauna
        From OpenXml(@PkXml, @Inicio2, 2)
        With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), Cidade Varchar(30), Estado Varchar(2), Cep Varchar(8),
        RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../CpfCnpj/Cnpj', CodigoVerificacao Varchar(100) '../../CodigoVerificacao',  
        CodigoControle Varchar(255) '../../CodigoControle', Cpf Varchar(14) '../CpfCnpj/Cpf')

        -----------------------------------
        Insert Into #TomadorServico (Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf)
        Select Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf
        From #TomadorServicoTempItauna
        -----------------------------------

      End
    
    --Tratamento de acordo com o Código do município, para atender especificação de Pará de Minas. Ps: Vou tentar encontrar uma solução melhor, até o momento não encontrei. Élio  
    If (@MunicipioXml = 3147105)
      Begin
 
        Delete From #TomadorServico
        
        Select * Into #TomadorServicoTempMpm
        From OpenXml(@PkXml, @Inicio2, 2)
        With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), Cidade Varchar(30), Estado Varchar(2), Cep Varchar(8),
        RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../CpfCnpj/Cnpj', CodigoVerificacao Varchar(100) '../../CodigoVerificacao',  
        CodigoControle Varchar(255) '../../CodigoControle', Cpf Varchar(14) '../CpfCnpj/Cpf')

        -----------------------------------
        Insert Into #TomadorServico (Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf)
        Select Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf
        From #TomadorServicoTempMpm
        -----------------------------------

      End

    If (@TipoNfse = 2)
      Begin

        Select * Into #TomadorServicoTemp
        From OpenXml(@PkXml, @Inicio2, 2)
        With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), CodigoMunicipio Varchar(7), Uf Varchar(2), Cep Varchar(8),
        RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../Cnpj', CodigoVerificacao Varchar(100) '../../../../CodigoVerificacao', 
        CodigoControle Varchar(255) '../../../../CodigoControle', Cpf Varchar(14) '../Cpf')

        If exists (Select CodigoVerificacao From #TomadorServicoTemp Where Coalesce(CodigoVerificacao, '') = '') --Prefeitura de Nova Lima os códigos ficam localizados em outros nós
          Begin
            Select * Into #TomadorServicoTemp2
            From OpenXml(@PkXml, @Inicio2, 2)
            With (CodigoVerificacao Varchar(100) '../../../CodigoVerificacao', CodigoControle Varchar(255) '../../../CodigoControle')

            Update #TomadorServicoTemp
            Set CodigoVerificacao = T.CodigoVerificacao,
            CodigoControle = T.CodigoControle
            From #TomadorServicoTemp2 T
          End 

        Delete From #TomadorServico

        Insert #TomadorServico(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf)
        Select Endereco, Numero, Complemento, Bairro, CodigoMunicipio, Uf, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf
        From #TomadorServicoTemp

      End
  
    If(@TipoNfse = 4)
      Begin
        --Prefeitura de Carmo da Mata, Matozinhos
        Select @Inicio2 = @Inicio +  '/tomador_servico/identificacao_tomador'

        Select * Into #TomadorServicoTemp6
        From OpenXml(@PkXml, @Inicio2, 2)
        With(logradouro Varchar(125) '../endereco/logradouro', numero Varchar(10) '../endereco/numero', complemento Varchar(125) '../endereco/complemento', 
        bairro Varchar(60) '../endereco/bairro', codigo_municipio Varchar(15) '../endereco/codigo_municipio', uf Varchar(2) '../endereco/uf', cep Varchar(8) '../endereco/cep', 
        razao_social Varchar(115) '../razao_social', cnpj Varchar(14) 'cpf_cnpj', codigo_verificacao Varchar(100) '../../codigo_verificacao')

        Insert #TomadorServico(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao)
        Select Upper(logradouro), numero, Upper(complemento), Upper(bairro), codigo_municipio, uf, cep, Upper(razao_social), cnpj, codigo_verificacao
        From #TomadorServicoTemp6
        
        ------------------------------
      End

    If(@TipoNfse = 5)
      Begin
        --Prefeitura de Guanhães
        Select @Inicio2 = @Inicio +  '/DadosTomador/Endereco'

        Select * Into #TomadorServicoTemp7
        From OpenXml(@PkXml, @Inicio2, 2)
        With(Logradouro Varchar(125), LogradouroNumero Varchar(10), LogradouroComplemento Varchar(125), Bairro Varchar(60),
        CodigoMunicipio Varchar(15), Uf Varchar(2), Cep Varchar(8), RazaoSocial Varchar(115) '../RazaoSocial', CpfCnpj Varchar(14) '../../DadosTomador',
        Id Varchar(100) '../../Id')

        Insert #TomadorServico(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao)
        Select Logradouro, LogradouroNumero, LogradouroComplemento, Bairro, CodigoMunicipio, Uf, Cep, RazaoSocial, CpfCnpj, Id
        From #TomadorServicoTemp7

        Select * From #TomadorServicoTemp7 --teste
    
        ------------------------------
      End

    If(@TipoNfse = 6)
      Begin
        --Prefeitura de Joinville
        Select @Inicio2 = @Inicio + '/nota/tomador'

        Select * Into #TomadorServicoTemp8
        From OpenXml(@PkXml, @Inicio2, 2)
        With(endereco varchar(125), numero varchar(3), complemento varchar (20), bairro varchar (20), cidade varchar (15), estado varchar(2), 
        cep varchar(8), nome Varchar(50), codigo_verificacao Varchar(100) '../codigo_verificacao', documento Varchar(11))

        Insert #TomadorServico (Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, CodigoVerificacao, Cpf)
        Select T.endereco, T.numero, T.complemento, T.bairro, T.cidade, T.estado, T.cep, T.nome, T.codigo_verificacao, T.documento
        From #TomadorServicoTemp8 T
        --cross join cidades C
        --inner join Estados E on (FkEstado = E.Pk)
        --where concat(C.Cidade, ' - ', E.Uf) = concat(T.Cidade, ' - ', T.Estado)
        
        ------------------------------
      End

    If (@TipoNfse = 7)
      Begin
        --Prefeitura de Várzea da Palma
        Select @Inicio2 = @Inicio + '/tomadorServico'

        Select * Into #TomadorServicoTemp9
        From OpenXml(@PkXml, @Inicio2, 2)
        With (endereco Varchar(125), bairro Varchar(60), cep Varchar(8), CnpjTomador Varchar(14), codigoVerificacao Varchar(255), nomeRazao Varchar(50), 
        nome Varchar(30) '../municipioTributacao/nome', uf Varchar(2) '../municipioTributacao/uf')
        
        Insert #TomadorServico (Endereco, Bairro, Cep, Cnpj, CodigoVerificacao, RazaoSocial, Cidade, Estado)
        Select endereco, bairro, cep, 
               Case When CnpjTomador is Null 
                Then
                  (Select text
                    From OpenXml(@PkXml, @Inicio2, 1) 
                    where len(convert(Varchar(14),text)) = 14 and 
                    ISNUMERIC(convert(Varchar(14),text))=1
                  )
                Else CnpjTomador End , 
              codigoVerificacao, nomeRazao, nome, uf
        From #TomadorServicoTemp9       

        ------------------------------
      End

    If (@TipoNfse = 8)
      Begin
        --Prefeitura de Cubatão
        Select @Inicio2 = @Inicio            

        Select * Into #TomadorServicoTemp10
        From OpenXml(@PkXml, @Inicio2, 2)
        With (ClienteEndereco Varchar(125), ClienteCEP Varchar(10), ClienteCNPJCPF Varchar(18), 
        ChaveValidacao Varchar(255), ClienteNomeRazaoSocial Varchar(50), ClienteCidade Varchar(20), ClienteUF Varchar(2), ClienteBairro VarChar(60))

        Insert #TomadorServico (Endereco, Cep, Cnpj, CodigoVerificacao, RazaoSocial, Cidade, Estado, Bairro)
        Select ClienteEndereco, Dbo.Ftrim(Replace(ClienteCEP, '-','')),  Replace(Replace(Replace(ClienteCNPJCPF,'/', ''), '.', ''), '-', ''), ChaveValidacao, ClienteNomeRazaoSocial, ClienteCidade, ClienteUF,
        ClienteBairro
        From #TomadorServicoTemp10      

      --  Select * From #TomadorServicoTemp10 -- teste

        ------------------------------
      End

    If (@TipoNfse = 9) --Prefeitura de Sorocaba - Everton 14/02/2019
      Begin
        print @Inicio
        
        Select *  Into #TomadorServicoTemp11 
        From OpenXml(@PkXml, @Inicio, 2)
        With (TOMADOR_LOGRADOURO varchar(125), TOMADOR_NUMERO Varchar(10), TOMADOR_TIPO_LOGRADOURO Varchar(60), TOMADOR_BAIRRO Varchar(60), TOMADOR_CIDADE Varchar(50), TOMADOR_UF Varchar(2), TOMADOR_CEP Varchar(8),
        TOMADOR_RAZAO_SOCIAL Varchar(115), TOMADOR_CPF_CNPJ Varchar(14), CODIGO_VERIFICACAO Varchar(100))
           
       --Select * From #TomadorServicoTemp11       
               
        Delete From #TomadorServico

        Insert #TomadorServico(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, CodigoMunicipio)
        Select UPPER(TOMADOR_LOGRADOURO), TOMADOR_NUMERO, UPPER(TOMADOR_TIPO_LOGRADOURO), UPPER(TOMADOR_BAIRRO), UPPER(TOMADOR_CIDADE), TOMADOR_UF, TOMADOR_CEP, UPPER(TOMADOR_RAZAO_SOCIAL), TOMADOR_CPF_CNPJ, CODIGO_VERIFICACAO, 0, C.Codigo
        From #TomadorServicoTemp11 T
        Left Join Cidades C on (Replace(Replace(Replace(Replace(Replace(UPPER(C.Cidade),'Í','I'),'Á','A'),'É','E'),'Ó','O'),'Ú','U') = (Replace(Replace(Replace(Replace(Replace(UPPER(T.TOMADOR_CIDADE),'Í','I'),'Á','A'),'É','E'),'Ó','O'),'Ú','U')))
        Left Join Estados E on (C.FkEstado = E.Pk)
        Where E.UF = TOMADOR_UF
       
      End

    If Exists (Select Endereco From #TomadorServico Where (Estado is null) and (Cidade is null)) and (@TipoNfse = 1) and (@MunicipioXml <> 3147105)
      Begin
     
        Begin Try Drop Table #TomadorServicoTemp5 End Try Begin Catch End Catch
     
        Select * Into #TomadorServicoTemp5
        From OpenXml(@PkXml, @Inicio2, 2)
        With (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), Bairro Varchar(60), CodigoMunicipio Varchar(7), Uf Varchar(2), Cep Varchar(8),
        RazaoSocial Varchar(115) '../RazaoSocial', Cnpj Varchar(14) '../Cnpj', CodigoVerificacao Varchar(100) '../../CodigoVerificacao',  
        CodigoControle Varchar(255) '../../CodigoControle', Cpf Varchar(14) '../Cpf')

        Delete From #TomadorServico

        Insert #TomadorServico(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf)
        Select Endereco, Numero, Complemento, Bairro, CodigoMunicipio, Uf, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf
        From #TomadorServicoTemp5
        
        
      End

    --Prefeitura de São Luís do Maranhão
    If (@TipoNfse = 3) 
      Begin

        
        Select * Into #TomadorServicoTemp3
        From OpenXml(@PkXml, @Inicio2, 2)
        With (logradouro varchar(125), bairro Varchar(60), CodigoMunicipio Varchar(7), codigoEstado Varchar(2), cep Varchar(8),
        razaoSocial Varchar(115) '../razaoSocial', Cnpj Varchar(14) '../cnpj', Cpf Varchar(14) '../cpf', codigoVerificacao Varchar(100) '../../codigoVerificacao')

        Delete From #TomadorServico

        Insert #TomadorServico(Endereco, Numero, bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf)
        Select logradouro, 0, bairro, CodigoMunicipio, codigoEstado, cep, razaoSocial, cnpj, CodigoVerificacao, '', cpf
        From #TomadorServicoTemp3

      End

    Select @CodigoMunicipio = CodigoMunicipio
    From @PrestadorServico

    --Caso o CodigoMunicipio vier vazio para esse fornecedor. Élio 29.09.2017
    If (@CodigoMunicipio = '') and (@TipoNfse = 2) and (Exists(Select * From @PrestadorServico Where Cep = '34007754'))
      Begin
        Set @CodigoMunicipio = '3144805'
      End

    ---------------------------------------------------------------------------------------------------------------------

    Begin Try Drop Table #NotaFiscal End Try Begin Catch End Catch 
    Begin Try Drop Table #NotaFiscalAuxiliar End Try Begin Catch End Catch 
    Begin Try Drop Table #NotaFiscalAuxiliar2 End Try Begin Catch End Catch 
    Begin Try Drop Table #NotaFiscalAuxiliar3 End Try Begin Catch End Catch --Outra versão de Nova Lima
    Begin Try Drop Table #NotaFiscalAuxiliar4 End Try Begin Catch End Catch --Prefeitura de Carmo da Mata
    Begin Try Drop Table #NotaFiscalAuxiliar5 End Try Begin Catch End Catch --Prefeitura de Guanhães
    Begin try Drop Table #NotaFiscalAuxiliar8 End Try Begin Catch End Catch --Prefeitura de Joinville
    Begin try Drop Table #NotaFiscalAuxiliar9 End Try Begin Catch End Catch --Prefeitura de Várzea da Palma
    Begin try Drop Table #NotaFiscalAuxiliar10 End Try Begin Catch End Catch --Prefeitura de Cubatão
    Begin try Drop Table #NotaFiscalAuxiliar11 End Try Begin Catch End Catch --Prefeitura de Sorocaba
    Begin Try Drop Table #NotaFiscalTemp End Try Begin Catch End Catch 
    Begin Try Drop Table #NotaFiscalBaseCalculo End Try Begin Catch End Catch
    Begin Try Drop Table #atividadeExecutada End Try Begin Catch End Catch  --Prefeitura de São Luís do Maranhão
    Begin Try Drop Table #totais End Try Begin Catch End Catch  --Prefeitura de São Luís do Maranhão


    If (@TipoNfse = 1)
      Begin
        Select @Inicio2 = @Inicio + '/Servico/Valores'
      End
    Else if not exists (Select Conteudo From #Conteudo Where Conteudo Like '%InfDeclaracaoPrestacaoServico%')
      Begin
        Select @Inicio2 = @Inicio + '/DeclaracaoPrestacaoServico/Valores' --Prefeitura de Nova Lima
      End
    Else 
      Begin
        Select @Inicio2 = @Inicio + '/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Servico/Valores'
      End
   
    --Prefeitura de São Luís do Maranhão
    If (@TipoNfse = 3)  
      Begin
        Delete @impostosFederais

        Select @Inicio2 = @Inicio + '/detalhamentoNota/impostosFederais/imposto'
        Select @Query = @Inicio + '/detalhamentoNota/impostosFederais/imposto'

        Insert @impostosFederais
        (dtEmissao, numeroNota, codigoVerificacao, codigoImposto, descricaoImposto, tipo, aliquota, valorImposto)
        Select dtEmissao, numeroNota, codigoVerificacao, codigoImposto, descricaoImposto, tipo, aliquota, valorImposto
        From OpenXml(@PkXml, @Query, 2)
        With (dtEmissao varchar(100) '../../../dtEmissao', numeroNota varchar(100) '../../../numeroNota', codigoVerificacao varchar(100) '../../../codigoVerificacao', 
        codigoImposto varchar(10), descricaoImposto varchar(100), tipo varchar(10), aliquota varchar(10), valorImposto varchar(1000))
        
        ------------------------------------------------------------------------------------------------------------------------------------
      
       Select @Inicio2 = @Inicio + '/atividadeExecutada'

        Select * Into #atividadeExecutada 
        From OpenXml(@PkXml, @Inicio2, 2)
        With (dtEmissao varchar(100) '../dtEmissao', numeroNota varchar(100) '../numeroNota', codigoVerificacao varchar(100) '../codigoVerificacao', 
        codigoServico varchar(10), aliquota numeric(18, 2))

        Select @Inicio2 = @Inicio + '/detalhamentoNota/totais'

        Select * Into #totais 
        From OpenXml(@PkXml, @Inicio2, 2)
        With (dtEmissao varchar(100) '../../dtEmissao', numeroNota varchar(100) '../../numeroNota', codigoVerificacao varchar(100) '../../codigoVerificacao', 
        valotTotalNota numeric(18, 2), valorTotalServico numeric(18, 2), valorTotalDeducao numeric(18, 2), valorTotalIss numeric(18, 2), valorReducaoBC numeric(18, 2))
        
      End  

    Select * Into #NotaFiscal
    From OpenXml(@PkXml, @Inicio2, 2)
    With (ValorServicos Numeric(18, 2), IssRetido Int, ValorIss Numeric(18, 2), BaseCalculo Numeric(18, 2), Aliquota Numeric(18, 2),
    ValorLiquidoNfse Numeric(18, 2), ItemListaServico Varchar(5) '../ItemListaServico', DataEmissao Varchar(30) '../../DataEmissao', 
    Competencia Varchar(30) '../../Competencia', Numero BigInt '../../Numero', CodigoVerificacao Varchar(100) '../../CodigoVerificacao',
    CodigoControle  Varchar(100) '../../CodigoControle', ValorDeducoes Numeric(18, 2), DescontoIncondicionado Numeric(18, 2), ValorPIS Numeric(18, 2), ValorCOFINS Numeric(18, 2), 
    ValorINSS Numeric(18, 2), ValorIR Numeric(18, 2), ValorCSLL Numeric(18, 2), ValorISSRetido Numeric(18, 2), CnpjTomador Varchar(14), CnpjPrestador Varchar(14), 
    ValorTotal numeric(18,2), ValorIRRF numeric(18,2), DataRPS Varchar(30), CpfTomador Varchar(11), Observacao Varchar(50), TipoServico Numeric(18, 2))



    If ((@TipoNfse = 1) and (@MunicipioXml = 3147105))
      Begin
       
        Delete #NotaFiscal

        Select * Into #NotaFiscalAuxiliar6
        From OpenXml(@PkXml, @Inicio2, 2)
        With (ValorServicos Numeric(18, 2), IssRetido Int, ValorIss Numeric(18, 2), BaseCalculo Numeric(18, 2), Aliquota Numeric(18, 2),
        ValorLiquidoNfse Numeric(18, 2), ItemListaServico Varchar(5) '../ItemListaServico', DataEmissao Varchar(30) '../../DataEmissao', 
        Competencia Varchar(30) '../../Competencia', Numero BigInt '../../Numero', CodigoVerificacao Varchar(100) '../../CodigoVerificacao',
        CodigoControle  Varchar(100) '../../CodigoControle', ValorDeducoes Numeric(18, 2), DescontoIncondicionado Numeric(18, 2), ValorPIS Numeric(18, 2), ValorCOFINS Numeric(18, 2), 
        ValorINSS Numeric(18, 2), ValorIR Numeric(18, 2), ValorCSLL Numeric(18, 2), ValorISSRetido Numeric(18, 2), CnpjTomador Varchar(14) '../../TomadorServico/CpfCnpj/Cnpj', 
        CnpjPrestador Varchar(14) '../../PrestadorServico/Cnpj')

        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
        CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador)
        Select ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao,
        CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPis, ValorCofins, ValorInss, ValorIr, ValorCsll, ValorISSRetido, CnpjTomador, CnpjPrestador
        From #NotaFiscalAuxiliar6

      End
    
    

    --Select *
    --From #NotaFiscal
    --Return

    --Outra versão do xml de nova lima
    If (@TipoNfse = 2) and (@CodigoMunicipio = '3144805') and (Exists(Select Conteudo From #Conteudo Where Conteudo Like '%DeclaracaoPrestacaoServico%'))
      Begin
        Select * Into #NotaFiscalAuxiliar3
        From OpenXml(@PkXml, 'Nfse/InfNfse/DeclaracaoPrestacaoServico/Servico/Valores', 2)
        With (ValorServicos Numeric(18, 2), IssRetido Int '../IssRetido', ValorIss Numeric(18, 2), BaseCalculo Numeric(18, 2) '../../../ValoresNfse/BaseCalculo', Aliquota Numeric(18, 2),
        ValorLiquidoNfse Numeric(18, 2) '../../../ValoresNfse/ValorLiquidoNfse', ItemListaServico Varchar(5) '../ItemListaServico', DataEmissao Varchar(30) '../../../DataEmissao', 
        Competencia Varchar(30) '../../Competencia', Numero BigInt '../../../Numero', CodigoVerificacao Varchar(100) '../../../CodigoVerificacao',
        CodigoControle  Varchar(100) '../../../CodigoControle', ValorDeducoes Numeric(18, 2), DescontoIncondicionado Numeric(18, 2), ValorPis Numeric(18, 2), ValorCofins Numeric(18, 2), 
        ValorInss Numeric(18, 2), ValorIr Numeric(18, 2), ValorCsll Numeric(18, 2), ValorISSRetido Numeric(18, 2), CnpjTomador Varchar(14) '../../Tomador/Cnpj', 
        CnpjPrestador Varchar(14) '../../Prestador/Cnpj')

        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
        CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador)
        Select ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao,
        CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPis, ValorCofins, ValorInss, ValorIr, ValorCsll, ValorISSRetido, CnpjTomador, CnpjPrestador
        From #NotaFiscalAuxiliar3 

        --Select * From #NotaFiscal
        --return

      End

          
    --Prefeitura de Carmo da Mata, Matozinhos
    If(@TipoNfse = 4)
      Begin
       
        Select @Inicio2 = @Inicio + '/servico/valores'
            
        Select * Into #NotaFiscalAuxiliar4 
        From OpenXml(@PkXml, @Inicio2, 2)
        With (valor_servico Varchar(18), iss_retido Varchar(18), valor_iss Varchar(18), base_calculo Varchar(18), aliquota_servico Varchar(18), valor_liquido_nfse Varchar(18),
        item_lista_servico Varchar(10), data_emissao varchar(50) '../../data_emissao', competencia Varchar(10) '../../competencia', numero Varchar(10) '../../numero', codigo_verificacao Varchar(10) '../../codigo_verificacao',
        valor_deducao Varchar(18), valor_pis Varchar(18), valor_confins Varchar(18), valor_inss Varchar(18), valor_ir Varchar(18), valor_csll Varchar(18), valor_iss_retido Varchar(18), 
        cnpj_tomador Varchar(14) '../../tomador_servico/identificacao_tomador/cpf_cnpj', cnpj_prestador Varchar(14) '../../prestacao_servico/identificacao_prestador/cnpj', codigo_tributacao_municipio VarChar(5) '../codigo_tributacao_municipio')
        --Everton - 09/01/2019 -- Adicionado a função dbo.FDecimalSql para os campos do tipo Decimal -- Adaptação para importação de Matozinhos --------------------------------------------------------------------------
        Begin Try    --Everton - 31/01/2019 - Adicionado o metodo Try, pois em alguns XML não é necessária a conversão, em outros sim.          
          Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
          ValorDeducoes, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador )
          Select valor_servico,
                 iss_retido, 
                 valor_iss,
                 base_calculo, 
                  Replace(aliquota_servico,',','.'),
                 valor_liquido_nfse,
                 codigo_tributacao_municipio, --item_lista_servico
                 data_emissao, competencia, numero, codigo_verificacao, 
                 valor_deducao, 
                 valor_pis, 
                 valor_confins, 
                 valor_inss, 
                 valor_ir, 
                 valor_csll, 
                 valor_iss_retido, 
                 cnpj_tomador, cnpj_prestador
          From #NotaFiscalAuxiliar4     
        End Try
        Begin Catch      
         Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
          ValorDeducoes, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador )
         Select dbo.FDecimalSql(valor_servico),
                  dbo.FDecimalSql(iss_retido), 
                  dbo.FDecimalSql(valor_iss),
                  dbo.FDecimalSql(base_calculo), 
                  Replace(aliquota_servico,',','.'), 
                  dbo.FDecimalSql(valor_liquido_nfse),
                  codigo_tributacao_municipio, --item_lista_servico
                  data_emissao, competencia, numero, codigo_verificacao, 
                  dbo.FDecimalSql(valor_deducao), 
                  dbo.FDecimalSql(valor_pis), 
                  dbo.FDecimalSql(valor_confins), 
                  dbo.FDecimalSql(valor_inss), 
                  dbo.FDecimalSql(valor_ir), 
                  dbo.FDecimalSql(valor_csll), 
                  dbo.FDecimalSql(valor_iss_retido), 
                  cnpj_tomador, cnpj_prestador
              From #NotaFiscalAuxiliar4
        End Catch
        Select * From #NotaFiscal
        


        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      End 

      --Prefeitura de Guanhães
    If(@TipoNfse = 5)
      Begin
       
        Select @Inicio2 = @Inicio + '/Valores'
            
        Select * Into #NotaFiscalAuxiliar5
        From OpenXml(@PkXml, @Inicio2, 2)
        With (ValorServicos Decimal(18,2), IssRetido Decimal(18,2) '../IssRetido', ValorIss Decimal(18,2), BaseCalculo Decimal(18,2) 'ValorServicos', 
        Aliquota Decimal(18,2) '../Servicos/Aliquota', DataEmissao varchar(50) '../DataEmissao', Numero Varchar(10) '../Numero', Id Varchar(255) '../Id', 
        ValorDeducoes Decimal(18,2), ValorPis Decimal(18,2), ValorCofins Decimal(18,2), ValorInss Decimal(18,2), ValorIr Decimal(18,2), ValorCsll Decimal(18,2),
        CnpjTomador Varchar(14) '../DadosTomador', CnpjPrestador Varchar(14) '../DadosPrestador', CodigoServicoMunicipal VarChar(5) '../Servicos/CodigoServicoMunicipal')
        
        
        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, DataEmissao, Numero, CodigoVerificacao, ValorDeducoes, 
        ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, CnpjTomador, CnpjPrestador, itemListaServico)
        Select ValorServicos, Left(IssRetido, 1), ValorIss, BaseCalculo, Aliquota, Substring(DataEmissao, 1, 10), Numero, Id, ValorDeducoes, ValorPis, 
        ValorCofins, ValorInss, ValorIr, ValorCsll, CnpjTomador, CnpjPrestador, CodigoServicoMunicipal
        From #NotaFiscalAuxiliar5 
        
      End 

      --Prefeitura de Joinville
    If(@TipoNfse = 6)
      Begin

        Select @Inicio2 = @Inicio + '/nota'

        Select * Into #NotaFiscalAuxiliar8
        From OpenXml(@PkXml, @Inicio2, 2)
        With (valor_total Decimal(18,2), iss_retido Decimal(18,2), valor_iss Decimal(18,2), valor_base_calculo Decimal(18,2), aliquota_iss Decimal(18,2), data_emissao varchar(100), 
        numero Varchar(100), codigo_verificacao Varchar(100), valor_pis Decimal(18,2), valor_cofins Decimal(18,2), valor_inss Decimal(18,2), valor_csll Decimal(18,2), 
        documento Varchar(14) '../prestador', valor_irrf Decimal(18,2), data_rps Varchar(30), observacao Varchar(50), servico Decimal(18,2))

        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, DataEmissao, Numero, CodigoVerificacao, ValorPIS, ValorCOFINS, ValorINSS, ValorCSLL, 
        CnpjPrestador, ValorIRRF, DataRPS, Observacao, ItemListaServico)
        Select valor_total, iss_retido, valor_iss, valor_base_calculo, aliquota_iss, data_emissao, numero, codigo_verificacao, valor_pis, valor_cofins, valor_inss, valor_csll, 
        documento, valor_irrf, data_rps, observacao, servico
        From #NotaFiscalAuxiliar8

      End

      --Prefeitura de Várzea da Palma
    If(@TipoNfse = 7)
      Begin

        Select @Inicio2 = @Inicio

        Select * Into #NotaFiscalAuxiliar9
        From OpenXml(@PkXml, @Inicio2, 2)
        With (valorServico Decimal(18,2), reterIss varchar(5) 'servicos/item/reterIss', valorIss Decimal(18,2), valorBase Decimal(18,2), 
        aliquotaIss Decimal(18,2) 'servicos/item/aliquotaIss', valorLiquido Decimal(18,2), dataEmissao varchar(30), numero Varchar(100), codigoVerificacao Varchar(100), 
        valorPis Decimal(18,2), valorCofins Decimal(18,2), valorInss Decimal(18,2), valorCsll Decimal(18,2), cnpj Varchar(14) 'prestadorServico/cnpj', 
        CnpjTomador Varchar(14) 'tomadorServico/CnpjTomador', valorIr Decimal(18,2), competencia Varchar(30), descricaoCnae Varchar(5) 'servicos/item/descricaoCnae', 
        valorDeducao Decimal(18,2), valorDescontoIncondicionado Decimal (18,2), valorIssRetido Decimal(18,2))
        SElect * from #NotaFiscalAuxiliar9
        
        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, DataEmissao, Numero, CodigoVerificacao, ValorPIS, ValorCOFINS, ValorINSS, 
        ValorCSLL, CnpjPrestador, CnpjTomador, ValorIR, Competencia, ItemListaServico, ValorDeducoes, DescontoIncondicionado, ValorISSRetido)
        Select valorServico, valorIssRetido, valorIss, valorBase, aliquotaIss, valorLiquido, dataEmissao, numero, codigoVerificacao, valorPis, valorCofins, valorInss, valorCsll, 
        cnpj, 
        Case When CnpjTomador Is Null
          Then
           (Select Cnpj From #TomadorServico)
          Else CnpjTomador End, valorIr, competencia, descricaoCnae, valorDeducao, valorDescontoIncondicionado, valorIssRetido
        From #NotaFiscalAuxiliar9
        
      End

      --Prefeitura de Cubatão
    If(@TipoNfse = 8)
      Begin

        Select @Inicio2 = @Inicio

        Select * Into #NotaFiscalAuxiliar10
        From OpenXml(@PkXml, @Inicio2, 2)
        With (ValorTotalNota Decimal(18,2), ImpostoRetido VarChar(5) 'ITENS/ImpostoRetido', IssQNTotal Decimal(18,2), BaseCalculo Decimal(18,2), 
        Aliquota Decimal(18,2) 'ITENS/Aliquota', DataEmissao varchar(30), NumeroNota Varchar(100), ChaveValidacao Varchar(100), Pis Decimal(18,2), Cofins Decimal(18,2), 
        Inss Decimal(18,2), Csll Decimal(18,2), ClienteCNPJCPF Varchar(14), TimbreContribuinteLinha4 Varchar(14), Irrf Decimal(18,2), Cae Varchar(5))

        Insert #NotaFiscal(ValorServicos, IssRetido, ValorISSRetido, ValorIss, BaseCalculo, Aliquota, DataEmissao, Numero, CodigoVerificacao, 
        ValorPIS, ValorCOFINS, ValorINSS, ValorCSLL, CnpjPrestador, CnpjTomador, ValorIR, ItemListaServico)
        Select ValorTotalNota, Case ImpostoRetido When 'false' Then 0 Else 1 End, IssQNTotal, IssQNTotal, BaseCalculo, Aliquota, DataEmissao, NumeroNota,
        ChaveValidacao, Pis, Cofins, Inss, Csll, Replace(Replace(Replace(ClienteCNPJCPF,'/', ''), '.', ''), '-', ''), TimbreContribuinteLinha4, Irrf, Cae
        From #NotaFiscalAuxiliar10        

      End
     If(@TipoNfse = 9)
      Begin
        Select @Inicio2 = @Inicio
        print @Inicio2

        --Select *
        --From OpenXml(@PkXml, @Inicio2)

        Select VALOR_SERVICO, VALOR_ISS, VALOR_NOTA, ALIQUOTA, DATA_HORA_EMISSAO, NUM_NOTA, CODIGO_VERIFICACAO, VALOR_DEDUCAO, VALOR_PIS, 
        VALOR_COFINS, VALOR_INSS, VALOR_IR, VALOR_CSLL, TOMADOR_CPF_CNPJ, PRESTADOR_CPF_CNPJ, COS_SERVICO, VALOR_ISS_RET Into #NotaFiscalAuxiliar11
        From OpenXml(@PkXml, @Inicio2, 2)
        With (VALOR_SERVICO VarChar (100), VALOR_Iss VarChar (10),VALOR_NOTA VarChar (100), 
        ALIQUOTA VarChar (100), DATA_HORA_EMIssAO VarChar (100),NUM_NOTA VarChar (100), CODIGO_VERIFICACAO VarChar (100), 
        VALOR_DEDUCAO VarChar (100), VALOR_PIS VarChar (100), VALOR_COFINS VarChar (100), VALOR_INss VarChar (100), VALOR_IR VarChar (100), VALOR_CSLL VarChar (100),
        TOMADOR_CPF_CNPJ VarChar (100), PRESTADOR_CPF_CNPJ VarChar (100), COS_SERVICO VarChar (100),VALOR_Iss_RET VarChar (100))

        --Select * From #NotaFiscalAuxiliar11
     
        Insert #NotaFiscal(ValorServicos, ValorIss, BaseCalculo, Aliquota, DataEmissao, Numero, CodigoVerificacao, ValorDeducoes, 
        ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, CnpjTomador, CnpjPrestador, itemListaServico, ValorIssRetido)
        Select dbo.FStrVigulaPonto(VALOR_SERVICO), dbo.FStrVigulaPonto(VALOR_ISS), dbo.FStrVigulaPonto(VALOR_NOTA), dbo.FStrVigulaPonto(ALIQUOTA),
        Concat(Right(Left(Substring(DATA_HORA_EMISSAO, 1, 10),5),2),'/',Left(Substring(DATA_HORA_EMISSAO, 1, 10),2),Right(Substring(DATA_HORA_EMISSAO, 1, 10),5)), --DataEmissão 
        NUM_NOTA, CODIGO_VERIFICACAO, dbo.FStrVigulaPonto(VALOR_DEDUCAO), dbo.FStrVigulaPonto(VALOR_PIS), dbo.FStrVigulaPonto(VALOR_COFINS), dbo.FStrVigulaPonto(VALOR_INSS), 
        dbo.FStrVigulaPonto(VALOR_IR), dbo.FStrVigulaPonto(VALOR_CSLL), TOMADOR_CPF_CNPJ, PRESTADOR_CPF_CNPJ, COS_SERVICO, dbo.FStrVigulaPonto(VALOR_ISS_RET)
        From #NotaFiscalAuxiliar11         
        
        
        Update #NotaFiscal
        Set IssRetido = Case When (ValorIssRetido > 0) Then 1 Else 0 End        

        --Select * From #NotaFiscalAuxiliar11
        --Select * From #NotaFiscal
        --print 'return'
        --Return
      End 

    If (@TipoNfse = 2) and (@CodigoMunicipio not in (3144805, 3157807)) --Nova Lima, Santa Luzia
      Begin

        Select * Into #NotaFiscalTemp
        From OpenXml(@PkXml, @Inicio2, 2)
        With (ValorServicos Numeric(18, 2), IssRetido Int '../IssRetido', ValorIss Numeric(18, 2), BaseCalculo Numeric(18, 2) '../../../../ValoresNfse/BaseCalculo', 
        Aliquota Numeric(18, 2), ValorLiquidoNfse Numeric(18, 2) '../../../../ValoresNfse/ValorLiquidoNfse', ItemListaServico Varchar(5) '../ItemListaServico', 
        DataEmissao Varchar(30) '../../../../DataEmissao', Competencia Varchar(30) '../../Competencia', Numero BigInt '../../../../Numero', 
        CodigoVerificacao Varchar(100) '../../../../CodigoVerificacao', CodigoControle  Varchar(100) '../../../../CodigoControle', ValorDeducoes Numeric(18, 2), 
        DescontoIncondicionado Numeric(18, 2), ValorPis Numeric(18, 2), ValorCofins Numeric(18, 2), ValorInss Numeric(18, 2), ValorIr Numeric(18, 2), ValorCsll Numeric(18, 2), 
        ValorIssRetido Numeric(18, 2), CnpjTomador Varchar(14) '../../Tomador/Cnpj', CnpjPrestador Varchar(14) '../../../../PrestadorServico/Cnpj')
        
        --Select('AQUI')
        --Select *
        --From #NotaFiscalTemp
        --Return

        Delete From #NotaFiscal

        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
        CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador)
        Select ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
        CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador
        From #NotaFiscalTemp 

        --06/06/2017
        --TRATAMENTO REALIZADO PARA ATENDER O XML DE SERVIÇO DE RORAIMA. POIS A NOTA É RETIDA E O VALOR DO ISS RETIDO ESTAVA COMO NULL
        If Exists(Select Top 1 ValorISSRetido From #NotaFiscal Where(IssRetido = 1) and (ValorISSRetido is null) and (ValorIss is not null))
          Begin
            --Print('Aqui')
            Update #NotaFiscal
            Set ValorISSRetido = ValorIss
            Where(IssRetido = 1)
          End
      End

    If (@TipoNfse = 3) --Prefeitura de São Luís do Maranhão
      Begin
        Delete From #NotaFiscal

        Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, CodigoVerificacao, 
        CodigoControle, ValorDeducoes, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador)
        Select t.valorTotalServico, --ValorServicos
        0, --IssRetido
        t.valorTotalISS, --ValorIss
        t.valorTotalServico, --BaseCalculo
        A.aliquota, --Aliquota 
        t.valotTotalNota, --ValorLiquidoNfse
        A.codigoServico, --ItemListaServico
        t.dtEmissao, --DataEmissao
        t.dtEmissao, --Competencia
        t.numeroNota, --Numero
        t.CodigoVerificacao, --CodigoVerificacao
        '', --CodigoControle
        valorTotalDeducao, --ValorDeducoes
        0, --ValorPIS
        0, --ValorCOFINS
        0, --ValorINSS
        0, --ValorIR
        0, --ValorCSLL
        0, --ValorISSRetido
        '', --CnpjTomador
        '' --CnpjPrestador
        From #totais t
        inner join #atividadeExecutada A on (t.CodigoVerificacao = A.CodigoVerificacao)  

      End
    

    Update #NotaFiscal
    Set ItemListaServico = Replace(ItemListaServico, '.', ''),
    DataEmissao = Convert(Datetime, Left(DataEmissao, 10))

    Begin Try
      Update #NotaFiscal
      Set Competencia = Convert(Datetime, Left(Competencia, 10))
    End Try Begin Catch 
      Update #NotaFiscal
      Set Competencia = @DataInicialP
    End Catch

    ---------------------------------------------------------------------------------------------------------------------
    
    Select * Into #NotaFiscalAuxiliar
    From OpenXml(@PkXml, @Inicio2, 2)
    With (ValorPis Varchar(30), ValorCofins Varchar(30), ValorIssRetido Varchar(30), ValorInss Varchar(30), ValorCsll Varchar(30), ValorIr Varchar(30), 
    CodigoVerificacao Varchar(100) '../../CodigoVerificacao', CodigoControle Varchar(255) '../../CodigoControle')
    
    --Select *
    --From #NotaFiscalAuxiliar
    --Return

    If exists(Select CodigoVerificacao From #NotaFiscalAuxiliar Where CodigoVerificacao is null)
      Begin
        Select * Into #NotaFiscalAuxiliar2
        From OpenXml(@PkXml, @Inicio2, 2)
        With (ValorPis Varchar(30), ValorCofins Varchar(30), ValorIssRetido Varchar(30), ValorInss Varchar(30), ValorCsll Varchar(30), ValorIr Varchar(30), 
        CodigoVerificacao Varchar(100) '../../../../CodigoVerificacao', CodigoControle Varchar(255) '../../../../CodigoControle')
        
        Update #NotaFiscalAuxiliar
        Set CodigoVerificacao = A.CodigoVerificacao
        From #NotaFiscalAuxiliar2 A

        --Select *
        --From #NotaFiscalAuxiliar

        --Select *
        --From #NotaFiscalAuxiliar2
        
        --Return
      End

    If (@TipoNfse = 3) --Prefeitura de São Luís do Maranhão
      Begin
        Update #NotaFiscalAuxiliar
        Set CodigoVerificacao = I.codigoVerificacao 
        From @impostosFederais I

        Update #NotaFiscalAuxiliar 
        Set ValorPis = valorImposto
        From @impostosFederais
        Where codigoImposto = '1'

        Update #NotaFiscalAuxiliar 
        Set ValorCofins = valorImposto
        From @impostosFederais
        Where codigoImposto = '2'

        Update #NotaFiscalAuxiliar 
        Set ValorInss = valorImposto
        From @impostosFederais
        Where codigoImposto = '3'

        Update #NotaFiscalAuxiliar 
        Set ValorIr = valorImposto
        From @impostosFederais
        Where codigoImposto = '4'

        Update #NotaFiscalAuxiliar 
        Set ValorCsll = valorImposto
        From @impostosFederais
        Where codigoImposto = '5'

      End
        
    Update #NotaFiscalAuxiliar
    Set ValorPIS = Case When Coalesce(ValorPis, '') = '' Then '0' Else ValorPis End,
    ValorCOFINS = Case When Coalesce(ValorCofins, '') = '' Then '0' Else ValorCofins End,
    ValorIssRetido = Case When Coalesce(ValorIssRetido, '') = '' Then '0' Else ValorIssRetido End,
    ValorCsll = Case When Coalesce(ValorCsll, '') = '' Then '0' Else ValorCsll End,
    ValorIr = Case When Coalesce(ValorIr, '') = '' Then '0' Else ValorIr End,
    ValorInss = Case When Coalesce(ValorInss, '') = '' Then '0' Else ValorInss End


    Update #NotaFiscal
    Set CodigoVerificacao = Case When Coalesce(CodigoVerificacao, '') = '' Then CodigoControle Else CodigoVerificacao End


    Update #NotaFiscalAuxiliar
    Set CodigoVerificacao = Case When Coalesce(CodigoVerificacao, '') = '' Then CodigoControle Else CodigoVerificacao End    

     
    Update #NotaFiscal
    Set ValorPIS = Convert(Numeric(18, 2), N.ValorPis)
    From #NotaFiscalAuxiliar N Inner Join #NotaFiscal F on (N.CodigoVerificacao = F.CodigoVerificacao)
    Where (Convert(Numeric(18, 2), N.ValorPis) > 0)
    
    Update #NotaFiscal
    Set ValorCOFINS = Convert(Numeric(18, 2), N.ValorCofins)
    From #NotaFiscalAuxiliar N Inner Join #NotaFiscal F on (N.CodigoVerificacao = F.CodigoVerificacao)
    Where (Convert(Numeric(18, 2), N.ValorCofins) > 0)

    Update #NotaFiscal
    Set ValorIssRetido = Convert(Numeric(18, 2), N.ValorIssRetido)
    From #NotaFiscalAuxiliar N Inner Join #NotaFiscal F on (N.CodigoVerificacao = F.CodigoVerificacao)
    Where (Convert(Numeric(18, 2), N.ValorIssRetido) > 0)

    Update #NotaFiscal
    Set ValorInss = Convert(Numeric(18, 2), N.ValorInss)
    From #NotaFiscalAuxiliar N 
    Inner Join #NotaFiscal F on (N.CodigoVerificacao = F.CodigoVerificacao)
    Where (Convert(Numeric(18, 2), N.ValorInss) > 0)

    Update #NotaFiscal
    Set ValorCsll = Convert(Numeric(18, 2), N.ValorCsll)
    From #NotaFiscalAuxiliar N 
    Inner Join #NotaFiscal F on (N.CodigoVerificacao = F.CodigoVerificacao)
    Where (Convert(Numeric(18, 2), N.ValorCsll) > 0)

    Update #NotaFiscal
    Set ValorIr = Convert(Numeric(18, 2), N.ValorIr)
    From #NotaFiscalAuxiliar N 
    Inner Join #NotaFiscal F on (N.CodigoVerificacao = F.CodigoVerificacao)
    Where (Convert(Numeric(18, 2), N.ValorIr) > 0)

    --Entra se @TipoNfse = 2 e se o código do município for diferente de Oliveira-MG. Élio 02.02.2018
    --Everton - 01/02/2019 - Adicionada a linha marcada com --01022019* para sanar um problema que ocorria quando haviam mais NFSes
    If ((@TipoNfse = 2) and (@CodigoMunicipio <> '3145604'))
      Begin
        ---------------------------------------------------------------------------------------------------------------------
        Select @Inicio2 = @Inicio + '/ValoresNfse'

        Select * Into #NotaFiscalBaseCalculo
        From OpenXml(@PkXml, @Inicio2, 2)
        With (BaseCalculo Varchar(30))  
        
        Update #NotaFiscal 
        Set BaseCalculo = Convert(Numeric(18, 2), N.BaseCalculo)
        From #NotaFiscalBaseCalculo N
        Where (Convert(Numeric(18, 2), N.BaseCalculo) > 0) And 
        #NotaFiscal.BaseCalculo = N.BaseCalculo --01022019*
        
      End

    ---------------------------------------------------------------------------------------------------------------------
    --Altera o cnpj e a razão social caso seja do exterior
    ---------------------------------------------------------------------------------------------------------------------

    Update #TomadorServico
    Set Cnpj = Case When (Select Top 1 Estado From #TomadorServico) = 'EX' Then '00000000000000' Else Cnpj End,
    RazaoSocial = Case When (Select Top 1 Estado From #TomadorServico) = 'EX' Then 'EXTERIOR' Else RazaoSocial End
        
    Update @PrestadorServico
    Set Cnpj = Case When (Select Top 1 Estado From #TomadorServico) = 'EX' Then '00000000000000' Else Cnpj End,
    RazaoSocial = Case When (Select Top 1 Estado From #TomadorServico) = 'EX' Then 'EXTERIOR' Else RazaoSocial End
        
    ---------------------------------------------------------------------------------------------------------------------
    --Alterando a data de emissão pela data de competência, de acordo com o que o usuário escolher
    ---------------------------------------------------------------------------------------------------------------------
    --A Nf @TipoNfse = 5 não fornece informação da DataCompetencia
    If ((@BtDataCompetencia = 'Sim') and (@TipoNfse <> 5))
      Begin
        Update #NotaFiscal    
        Set DataEmissao = Competencia
      End
    ----------------------------------------------------------------------------------------------------------------------
    

    --Cria uma tabela para juntar os prestadores e tomadores
    Begin Try Drop Table #PrestadorTomador End Try Begin Catch End Catch
    
    Create Table #PrestadorTomador (Endereco varchar(125), Numero Varchar(10), Complemento Varchar(60), 
    Bairro Varchar(60), Cidade Varchar(30), Estado Varchar(2), Cep Varchar(8), RazaoSocial Varchar(115), 
    Cnpj Varchar(14), CodigoVerificacao Varchar(100), CodigoControle Varchar(255), Cpf Varchar(14), TipoServico Int, CodigoMunicipio varchar(15))

    ---------------------------------------------------------------------------------------------------------------------
    --Incluir tomadores e prestadores em uma única tabela        
    ---------------------------------------------------------------------------------------------------------------------
    Insert #PrestadorTomador(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, Cpf, TipoServico)
    Select Endereco, Numero, Complemento, Bairro, Case When Cidade is null Then CodigoMunicipio Else Cidade End, --Cidade 
    Case When Estado is null Then Uf Else Estado End, --Estado 
    Cep, RazaoSocial, Cnpj, CodigoVerificacao, CodigoControle, null, 2
    From @PrestadorServico

    Insert #PrestadorTomador(Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, Cpf, CodigoControle, TipoServico, CodigoMunicipio)
    Select Endereco, Numero, Complemento, Bairro, Cidade, Estado, Cep, RazaoSocial, Cnpj, CodigoVerificacao, Right('00000000000000' + Cpf, 14), CodigoControle, 1, CodigoMunicipio
    From #TomadorServico
        
    ---------------------------------------------------------------------------------------------------------------------
    --Localiza o Cnpj do Tomador e do prestador e altera a tabela #NotaFiscal
    ---------------------------------------------------------------------------------------------------------------------
    Update #PrestadorTomador 
    Set CodigoVerificacao = Case When Coalesce(CodigoVerificacao, '') = '' Then CodigoControle Else CodigoVerificacao End

    Update #NotaFiscal
    Set CnpjTomador = Case When Coalesce(Cnpj, '') = '' Then Cpf Else Cnpj End
    From #PrestadorTomador P
    Inner Join #NotaFiscal N on (N.CodigoVerificacao = P.CodigoVerificacao)
    Where P.TipoServico = 1

    Update #NotaFiscal
    Set CnpjPrestador = Case When Coalesce(Cnpj, '') = '' Then Cpf Else Cnpj End
    From #PrestadorTomador P
    Inner Join #NotaFiscal N on (N.CodigoVerificacao = P.CodigoVerificacao)
    Where P.TipoServico = 2
        
    Select @CnpjPrestador = CnpjPrestador, @CnpjTomador = CnpjTomador
    From #NotaFiscal
    
    --select * from #NotaFiscal

    --Select @CnpjEmpresaCorrente CnpjEmpresaCorrente
    --Select @CnpjPrestador CnpjPrestador
    --Select @CnpjEmpresaCorrente CnpjEmpresaCorrente
    --Select @CnpjTomador CnpjTomador
    --return

    If (@CnpjEmpresaCorrente <> @CnpjPrestador) and (@CnpjEmpresaCorrente <> @CnpjTomador)
      Begin
        Insert MSistema
        (FkUsuario, Abort, Descricao, Texto)
        Select distinct @PkUsuario, --FkUsuario 
        'Sim', --Abort
        Left('O Cnpj da empresa: ' + dbo.FMascaraDocumentos(@CnpjEmpresaCorrente) + ' corrente está diferente do 
        Cnpj do Prestador: ' + dbo.FMascaraDocumentos(@CnpjPrestador) + ' e também do 
        Cnpj do tomador: ' + dbo.FMascaraDocumentos(@CnpjTomador) + ', por isso a nota fiscal não será importada.', 255), --Descricao 
        'Operação cancelada.'
      End

     
    ---------------------------------------------------------------------------------------------------------------------
    --Verificando se existe algum item da lista de serviço não existente no cadastro
    ---------------------------------------------------------------------------------------------------------------------
    Insert MSistema(Abort, FkUsuario, Descricao, Texto)
    Select 'Não',
    @PkUsuario,
    'A nota Fiscal nº: ' + Coalesce(Convert(Varchar, Numero), '') + ', não possui o CNPJ do Tomador do Serviço!',
    'Favor verificar pois estamos colocando o CNPJ do prestador na nota fiscal.'
    From #NotaFiscal
    Where Coalesce(CnpjTomador, '') = ''
    
    Update #NotaFiscal
    Set CnpjTomador = CnpjPrestador
    From #NotaFiscal N
    Where Coalesce(CnpjTomador, '') = ''
    
    ---------------------------------------------------------------------------------------------------------------------
    --Verificando se existe algum item da lista de serviço não existente no cadastro
    ---------------------------------------------------------------------------------------------------------------------
    Insert MSistema(Abort, FkUsuario, Descricao, Texto)
    Select 'Não',
    @PkUsuario,
    'A nota Fiscal nº: ' + Coalesce(Convert(Varchar, Numero), '') + ', possui um item da lista de serviço('+Right('0000' + ItemListaServico, 4)+') que não consta em nosso cadastro!',
    'Favor verificar o item de serviço desta nota, pois não corresponde ao encontrado no arquivo XML.'
    From #NotaFiscal
    Where Right('0000' + ItemListaServico, 4) not in (Select Replace(Item, '.', '') From ListaServicos Where (FkEscritorio = @PkEscritorio))

    If exists(Select Pk From MSistema Where FkUsuario = @PkUsuario and Descricao like '%possui um item da lista de serviço que não consta em nosso cadastro!%')
      Begin
        If not Exists(
        Select Pk 
        From ListaServicos 
        Where Pk = @FkListaServicos and (FkEscritorio = @PkEscritorio)) and (@FkListaServicos is not null)
          Begin
            Insert MSistema 
            (FkUsuario, Abort, Descricao, Texto)
            Select Distinct @PkUsuario, --FkUsuario 
            'Sim', --Abort
            Left('O código da atividade: ' + Convert(Varchar, @FkListaServicos) + ' localizado na Tributação Municipal não existe na lista de serviços.', 255), --Descricao
            'Vá no nó <Empresas/Tributacao/Municipal> e informe um código de atividade válido.' --Texto
          End
      End    

    If exists(Select Top 1 FkUsuario From MSistema Where (FkUsuario = @PkUsuario) and (Abort = 'Sim'))
      Begin
        Return
      End

    ---------------------------------------------------------------------------------------------------------------------
    --Verificando se existem notas fora do período
    ---------------------------------------------------------------------------------------------------------------------
    Select * From #NotaFiscal
    Insert MSistema(Abort, FkUsuario, Descricao, Texto)
    Select 'Não',
    @PkUsuario,
    Concat('Existem Notas fiscais com data de ' , Case When @BtDataEmissao = 'Sim' Then 'emissão' Else 'competência' End , 
    ' fora do período de trabalho escolhido. Verifique se está correto! Data da ', Case When @BtDataEmissao = 'Sim' Then 'emissão:  ' Else 'competência: ' End,
    dbo.FStrDataddmmaaaa(Convert(Date, DataEmissao))),
    'Não serão importadas notas fiscais fora do período de trabalho ' + Convert(Varchar, Numero)
    From #NotaFiscal
    Where (Convert(Datetime, DataEmissao, 103) not between @DataInicialP and @DataFinalP)
    Order By Numero
  
    ---------------------------------------------------------------------------------------------------------------------
    --Elimina fornecedores ou clientes duplicados dentro da tabela
    ---------------------------------------------------------------------------------------------------------------------
    
    Declare C Cursor local static for
    Select Cnpj, Count(Cnpj)
    From #PrestadorTomador
    Where Coalesce(Cnpj, '') <> ''
    Group by Cnpj
    Having Count(Cnpj) > 1 
    Open C
    Fetch next from C into @Cnpj, @Count
    While @@FETCH_STATUS = 0
      Begin 
        Delete top (@Count -1) 
        From #PrestadorTomador
        Where Cnpj = @Cnpj

        Fetch next from C into @Cnpj, @Count
      End

    Close C
    Deallocate C
    ---------------------------------------------------------------------------------------------------------------------    

    Declare C Cursor local static for
    Select Cpf, Count(Cpf)
    From #PrestadorTomador
    Group by Cpf
    Having Count(Cpf) > 1 
    Open C
    Fetch next from C into @Cpf, @Count
    While @@FETCH_STATUS = 0
      Begin 
        Delete top (@Count -1) 
        From #PrestadorTomador
        Where (Cpf = @Cpf)

        Fetch next from C into @Cpf, @Count
      End

    Close C
    Deallocate C
    ------------------------------------------------------------------------------------------------------------------------
      Declare @tblPrestadorTomador Table (Pk int IDENTITY(1,1), CNPJ Varchar(14), CodigoMunicipio int, Cidade Varchar(50))
      Insert @tblPrestadorTomador (CNPJ, CodigoMunicipio, Cidade)
      Select P.Cnpj, P.CodigoMunicipio, P.Cidade From #PrestadorTomador P

      Declare @Cont int = (Select Count(Pk) From @tblPrestadorTomador)
      While @Cont>0
        Begin
            Begin Try
              Update CadFornecedores
              set FkCidades = Coalesce((Select Top 1 Pk From Cidades Where Codigo = P.CodigoMunicipio),(Select Top 1 Pk From Cidades Where Codigo = P.Cidade))
              From CadFornecedores Cf inner join @tblPrestadorTomador p on (Cf.CNPJ = p.Cnpj)
              Where Cf.FkCidades is null and p.Pk = @Cont
            End Try 
            Begin Catch
            End Catch
          Set @Cont-=1
        End      

      Delete From @tblPrestadorTomador Where Pk > 0
    ------------------------------------------------------------------------------------------------------------------------      

    -----------------------------------------------------------------------------------------------------------------------------------------------
    --Insere o fornecedor/cliente no cadastro...
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Insert CadFornecedores 
    (CNPJ, TipoInscricao, Nome, Endereco, Numero, Complemento, Bairro, Cidade, UF, Cep, ProdutorRural, InscrEstadual, InscrMunicipal, Telefone, Fax, Email, TipoPrincipal, Emissao, 
    InscrSuframa, FkCidades, ContribuinteICMS)
    Select (Case When Coalesce(P.CNPJ, '') = '' Then P.Cpf Else P.Cnpj End), --CNPJ
    --TipoInscricao
    Case When Coalesce(P.CNPJ, '') = '' Then 2 Else 1 End, 
    Coalesce(Substring(P.RazaoSocial, 1, 80), 'A CADASTRAR'), --Nome
    Coalesce(Substring(P.Endereco, 1, 50), 'A Cadastrar'), --Endereco
    Substring(P.Numero, 1, 10), --Numero
    Substring(P.Complemento, 1, 30), --Complemento
    Coalesce(Substring(P.Bairro, 1, 25), 'A Cadastrar'), --Bairro 
    --Cidade 
    Left(Coalesce((Select Top 1 Cidade 
       From Cidades 
       Where Codigo = Convert(Varchar, Coalesce(P.Cidade, P.CodigoMunicipio))), 
      (Select Top 1 Ci.Cidade 
       From Cep C 
       inner join Cidades Ci on (C.FkCidades = Ci.Pk) 
       Where Replace(Cep, '-', '') = Replace(P.Cep, '-', '')), 'A Cadastrar'),25),
    Coalesce(Substring(P.Estado, 1, 2), ''), --UF
    Left(P.Cep, 5) + '-' + Right(P.Cep, 3), --Cep
    'Não', --ProdutorRural
    (Case When Coalesce(P.CNPJ, '') = '' Then 'ISENTO' Else '0' End), --InscrEstadual
    '', --InscrMunicipal 
    '', --Telefone
    '', --Fax
    '', --Email 
    'Não', --TipoPrincipal
    @Emissao, --Emissao 
    '', --InscrSuframa
    --FkCidades
    Case 
      When @TipoNfse = 8
        Then
          (Select Top 1 Ci.Pk 
         From Cep C 
         inner join Cidades Ci on (C.FkCidades = Ci.Pk) 
         Where Replace(Cep, '-', '') = Replace(P.Cep, '-', ''))
       When @TipoNfse = 9
        Then
          (Select Top 1 Pk From Cidades Where Codigo = P.CodigoMunicipio)
    Else
      Coalesce(
      (Select Top 1 Pk 
       From Cidades 
       Where Codigo = Convert(Varchar, Coalesce(P.Cidade, P.CodigoMunicipio))), 
      (Select Top 1 Ci.Pk 
       From Cep C 
       inner join Cidades Ci on (C.FkCidades = Ci.Pk) 
       Where Replace(Cep, '-', '') = Replace(P.Cep, '-', ''))) 
    End, 
    'Não'
    From #PrestadorTomador P
    Left Outer Join CadFornecedores C on (C.Cnpj = Case When (Coalesce(P.Cnpj, '') = '') Then P.Cpf Else P.Cnpj End)
    Where C.Pk is null and (Case When Coalesce(P.CNPJ, '') = '' Then P.Cpf Else P.Cnpj End) is not null

    ---------------------------------------------------------------------------------------------------------------------
    If (@Sobrepor = 'Sim') 
      Begin
        Delete RegPrestServicos
        From RegPrestServicos R
        Inner Join #NotaFiscal N on (R.ChaveNfe = N.CodigoVerificacao)
        Where (R.CodEmpresa = @CodEmpresa) and 
        (R.Data Between @DataInicialP and @DataFinalP)
      End
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --Everton 01/02/2019 - O trecho abaixo foi retirado de dentro do cursor, pois se houvesse mais de um ciclo, a aliquota era modificada incorretamente

     If exists (Select Conteudo From #Conteudo Where Conteudo like '%ComplNfse%') or (@TipoNfse in(2, 3, 6)) or (@CodigoMunicipio = '3133808')
          Begin            
            Update #NotaFiscal
            Set Aliquota = Aliquota / 100
          End      
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    Declare CrNota cursor local static for
    Select distinct Numero, CodigoVerificacao
    From #NotaFiscal
    Where (Cast(DataEmissao as Date) between @DataInicialP and @DataFinalP)
    Order By Numero
    Open CrNota
    Fetch next from CrNota Into @Numero, @CodigoVerificacao
    While @@Fetch_Status = 0
      Begin
        Insert RegPrestServicos
        (PkC, FkClientes, CodEmpresa, Data, DocN, ADocN, Tipo, Serie, ValorContabil, Issqn, Inss, Irrf, VP, PisRetido, 
        CofinsRetido, CssllRetido, Exportado, TipoNota, TipoServico, Emissao, Alteracao, Observacao, StatusNf, SubSerie, FkIntegra, ChaveNfe, 
        DataConclusaoServicos, Descontos, TotalServicos, FkTomador, Modelo, FkInfComplementares, InfComplementares, TipoDeclaranteDmed, 
        Retencao, FkCidades)
        Select Top 1      
        --PkC, 
        4,
        --FkClientes, 
        Case When Right('00000000000000' + N.CnpjPrestador, 14) = Right('00000000000000' + @CnpjEmpresaCorrente, 14) Then 
          Coalesce((Select Top 1 Pk From CadFornecedores C Where Right('00000000000000' + C.CNPJ, 14) = Right('00000000000000' + N.CnpjTomador, 14)), (Select Top 1 Pk From CadFornecedores))
        Else
          Coalesce((Select Top 1 Pk From CadFornecedores C Where Right('00000000000000' + C.CNPJ, 14) = Right('00000000000000' + N.CnpjPrestador, 14)), (Select Top 1 Pk From CadFornecedores))
        End,
        --CodEmpresa, 
        @CodEmpresa,
        --Data, 
        Cast(DataEmissao as Date),
        --DocN, 
        Right(N.Numero, 10),
        --ADocN, 
        Right(N.Numero, 10),
        --Tipo, 
        'NF',
        --Serie, 
        '0',
        --ValorContabil, 
        Coalesce(ValorServicos, 0), 
        --Issqn, 
        Case When IssRetido = 1 And @TipoNfse <> 5 Then Coalesce(ValorIssRetido, 0) Else Coalesce(ValorIss, 0) End,
        --Inss, 
        Coalesce(ValorINSS, 0),
        --Irrf, 
        Coalesce(ValorIR, 0),
        --VP,
        Case When N.CnpjPrestador = @CnpjEmpresaCorrente Then 
          Case When @ImpServicosPrestadosVP = 'O' Then 'F' When @ImpServicosPrestadosVP = 'N' Then '' Else @ImpServicosPrestadosVP End
        Else
          Case When @ImpServicosTomadosVP = 'O' Then 'F' When @ImpServicosTomadosVP = 'N' Then '' Else @ImpServicosTomadosVP End
        End,
        --PisRetido, 
        Coalesce(ValorPIS, 0),
        --CofinsRetido, 
        Coalesce(ValorCOFINS, 0),
        --CssllRetido, 
        Coalesce(ValorCSLL, 0),
        --Exportado, 
        'S',
        --TipoNota, 
        Case When Cast(DataEmissao as Date) <= '12/31/2018' Then
          'Normal'        
        Else
          '00'
        End,
        --TipoServico --1 - Tomado 2 - Prestado
        Case When N.CnpjPrestador = @CnpjEmpresaCorrente Then 
          2
        Else
          1
        End, 
        --Emissao, 
        @Emissao,
        --Alteracao,
        Case When N.CnpjPrestador = @CnpjEmpresaCorrente Then
          Case When @ImpServicosPrestadosCN = 'C' Then
             @Alteracao
          Else
            NULL
          End
        Else
          Case When @ImpServicosTomadosCN = 'C' Then 
            @Alteracao
          Else
            NULL
          End
        End,
        --Observacao, 
        '',
        --StatusNf, 
        null,
        --SubSerie, 
        null,
        --FkIntegra, 
        null,
        --ChaveNfe, 
        N.CodigoVerificacao,
        --DataConclusaoServicos, 
        Coalesce(DataRPS, null),
        --Descontos, 
        ValorDeducoes + DescontoIncondicionado,
        --TotalServicos, 
        ValorServicos,
        --FkTomador, 
        null,
        --Modelo, 
        Coalesce((Select top 1 ModeloNF From TributacaoMunicipal Tm Where Tm.CodEmpresa = @CodEmpresa),''),
        --FkInfComplementares, 
        null,
        --InfComplementares
        null,
        --TipoDeclaranteDmed
        Case When @Pg405 = 'Sim' Then @TipoDeclaranteDmed Else NULL End,
        --Retencao
         Case When IssRetido = 1 and @TipoNfse <> 5 Then
            'Sim'
          When @TipoNfse = 5 and IssRetido = 2 Then
            'Sim'
          Else
            'Não'
          End,
        --FkCidades
        (Select top 1 Pk From Cidades Where Codigo = @CodigoMunicipio)
        From #NotaFiscal N
        Where (N.Numero = @Numero) and 
        (N.CodigoVerificacao = @CodigoVerificacao) and
        ((N.CnpjPrestador = @CnpjEmpresaCorrente) or (N.CnpjTomador = @CnpjEmpresaCorrente))

        --Este if tem que ficar logo após o insert, caso contrário a variável @@ROWCONT perde seu valor
        If (@@ROWCOUNT > 0)
          Begin
            Set @PkNota = SCOPE_IDENTITY()
          End      
          
        Insert RegPrestServicosItens 
        (Fk, FkListaServicos, ValorContabil, Aliquota, Issqn, Inss, Irrf, Pis, Cofins, 
        Cssll, CentroCusto, vBcPis, pPis, vPis, vBcCofins, pCofins, vCofins, ValorServicos, 
        ValorDesconto, BaseCalculoPisImport, BaseCalculoCofinsImport, PisPagoImport, CofinsPagoImport, 
        DataPagtoCofinsImport, DataPagtoPisImport, LocalExecucaoImport, NumeroItem, IndicadorOrigemCredito,
        CstCofins, CstPis, TipoDebitoCreditoPis, TipoDebitoCreditoCofins, FkCadNaturezaOperacao, vBcIssqn, 
        FkCadProdutos)
        Select Distinct
        --Fk,
        R.Pk,
        --FkListaServicos, 
        Coalesce((Select Top 1 Pk From ListaServicos Where Replace(Item, '.', '') = Right('0000' + N.ItemListaServico, 4) and (FkEscritorio = @PkEscritorio)), @FkListaServicos),
        --ValorContabil,  
        ValorServicos,
        --Aliquota
        Case When (Coalesce(ValorIss, 0) = 0) and (Coalesce(ValorIssRetido, 0) = 0) Then
          0
        When (@TipoNfse = 4 And CHARINDEX('.',Aliquota) = 0 ) Then
          Convert(Decimal(18,2), Substring(Convert(Varchar, Aliquota), 1, 1) + '.' + Substring(Convert(Varchar,  Aliquota), 2, 2)) --Importação de Carmo da Mata e Conselheiro Pena Élio 12.01.2018 
        When (@TipoNfse = 4 And CHARINDEX('.',Aliquota) > 0) --Matozinhos
          Then
            Coalesce(Aliquota, 0)
        When (@TipoNfse in (8, 5)) --Cubatao / Guanhães
          Then
            Coalesce(Aliquota, 0)
        Else 
          Coalesce(Aliquota * 100, 0) 
        End,
        --Issqn, 
        Case When IssRetido = 1 And @TipoNfse <> 5 Then Coalesce(ValorIssRetido, 0) Else Coalesce(ValorIss, 0) End,
        --Inss, 
        Coalesce(ValorINSS, 0),
        --Irrf, 
        Coalesce(ValorIR, 0),
        --Pis,
        Coalesce(ValorPIS, 0),
        --Cofins, 
        Coalesce(ValorCOFINS, 0), 
        --Cssll, 
        Coalesce(ValorCSLL, 0), 
        --CentroCusto,       
        dbo.FCentroCustoServicos(Coalesce((Select Top 1 Pk From ListaServicos Where (FkEscritorio = @PkEscritorio) and Replace(Item, '.', '') = Right('0000' + N.ItemListaServico, 4)), @FkListaServicos), R.TipoServico, R.VP),       
        --vBcPis, 
        0,
        --pPis, 
        0,
        --vPis, 
        0,
        --vBcCofins, 
        0,
        --pCofins, 
        0,
        --vCofins, 
        0,
        --ValorServicos, 
        Coalesce(ValorServicos, 0),
        --ValorDesconto, 
        DescontoIncondicionado,
        --BaseCalculoPisImport, 
        0,
        --BaseCalculoCofinsImport, 
        0,
        --PisPagoImport, 
        0,
        --CofinsPagoImport, 
        0,
        --DataPagtoCofinsImport, 
        null,
        --DataPagtoPisImport, 
        null,
        --LocalExecucaoImport, 
        null,
        --NumeroItem, 
        1,
        --IndicadorOrigemCredito,
        0,
        --CstCofins, 
        '',
        --CstPis, 
        '',
        --TipoDebitoCreditoPis, 
        null,
        --TipoDebitoCreditoCofins, 
        null,
        --FkCadNaturezaOperacao, 
        null,
        --vBcIssqn, 
        Case When (Coalesce(ValorIss, 0) = 0) and (Coalesce(ValorIssRetido, 0) = 0) Then 0 Else Coalesce(BaseCalculo, 0) End,
        --FkCadProdutos
        Case When @PkCodigoProdutoPadrao = 0 Then NULL Else @PkCodigoProdutoPadrao End
        From #NotaFiscal N
        inner join RegPrestServicos R on (R.ChaveNfe = N.CodigoVerificacao)
        --Left Outer Join #deducoes d on (d.senha = n.senha)
        Where (N.Numero = @Numero) and 
        (N.CodigoVerificacao = @CodigoVerificacao) and 
        (R.CodEmpresa = @CodEmpresa) and
        (R.Data between @DataInicialP and @DataFinalP)            
        

        --Altera os campos das guias Pis e Cofins
        Update RegPrestServicosItens
        Set CstPis = Case When R.TipoServico = 1 Then CstPisEntrada Else CstPisSaida End,
        CstCofins = Case When R.TipoServico = 1 Then CstCofinsEntrada Else CstCofinsSaida End,
        TipoDebitoCreditoPis = Case When R.TipoServico = 1 Then TipoCreditoPis Else TipoDebitoPis End,
        TipoDebitoCreditoCofins = Case When R.TipoServico = 1 Then TipoCreditoCofins Else TipoDebitoCofins End,
        pPis = AliquotaPis,
        pCofins = AliquotaCofins
        From RegPrestServicos R
        Inner Join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
        Inner JOin CadProdutos C on (C.Pk = Ri.FkCadProdutos) and 
        (R.CodEmpresa = C.CodEmpresa)
        Where (R.ChaveNfe = @CodigoVerificacao) and 
        (R.CodEmpresa = @CodEmpresa) and 
        (R.Data between @DataInicialP and @DataFinalP)
        
        
        Update RegPrestServicosItens
        Set vBcPis = Case When pPis > 0 Then Ri.ValorContabil Else 0 End,
        vBcCofins = Case When pCofins > 0 Then Ri.ValorContabil Else 0 End,
        vPis = Case When pPis > 0 Then Ri.ValorContabil * pPis / 100 Else 0 End,
        vCofins = Case When pCofins > 0 Then Ri.ValorContabil * pCofins / 100 Else 0 End
        From RegPrestServicos R
        Inner Join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
        WHere (R.ChaveNfe = @CodigoVerificacao) and 
        (R.CodEmpresa = @CodEmpresa) and 
        (R.Data between @DataInicialP and @DataFinalP)

        Exec PcRegPrestServicosInsertContabil @PkNota, @PkUsuario
        Exec PcInsertRetencoes @PkNota, @PkUsuario, 'RegPrestServicos'

        If not exists(
            Select Pk 
            From RegPrestServicos 
             Where (CodEmpresa = @CodEmpresa) and
            (Data between @DataInicialP and @DataFinalP) and 
            (DocN = Right(@Numero, 10)) and 
            (ChaveNfe = @CodigoVerificacao))
          Begin
            Insert MSistema(Abort, FkUsuario, Descricao, Texto)
            Select 'Não',
            @PkUsuario,
            'A nota Fiscal nº: ' + Convert(Varchar, @Numero) + ', não pertence a empresa corrente, por isso não foi importada!',
            'Verifique dentro do arquivo XML a situação!'
          End

        -----------------------------------------------------------------------------------------------------------------------------------------------
        Fetch next from CrNota Into @Numero, @CodigoVerificacao
      End
    Close CrNota
    Deallocate CrNota

     
    ---------------------------------------------------------------------------------------------------------------------------------------------
    --Removendo o arquivo xml...
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Exec SP_XML_REMOVEDOCUMENT @PkXml
    ---------------------------------------------------------------------------------------------------------------------------
    Fetch next from CrNomeArquivo Into @FileName
  end
Close CrNomeArquivo
Deallocate CrNomeArquivo

-----------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------
--Incluindo duplicatas no controle de clientes e fornecedores
-----------------------------------------------------------------------------------------------------------------------------------------
if (@ImpServicosPrestadosVP = 'P') and (@DataBalancoAbertura <= @DataInicialP)
  Begin
    Insert ControleClientes
    (PkC, Fk, FkC, FkClientes, CodEmpresa, Duplicata, Parcela, Serie, 
    DataNotaFiscal, NotaFiscal, Valor, Situacao, Vencimento, Emissao,
    VrIrrf, VrCssllRetido, VrInssRetido, VrPisRetido, VrCofinsRetido, Total, TarifaCobranca)
    Select 9, R.Pk, R.Pkc, R.FkClientes, R.CodEmpresa, 
    R.DocN, --Duplicata
    1, --Parcela
    R.Serie, --Serie
    R.Data, --DataNotaFiscal
    R.DocN, --NotaFiscal
    Case When (TipoNota = 'Retida' Or Retencao = 'Sim') Then (R.ValorContabil - R.Issqn - R.Irrf - R.Inss) Else R.ValorContabil - R.Irrf - R.Inss End, --Valor
    'Normal', --Situacao
    DateAdd(mm, 1, R.Data), --Vencimento  
    @Emissao, --Emissao
    0, --VrIrrf, Este valor já abatido no valor da duplicata
    R.CssllRetido, --VrCssllRetido, 
    0, --VrInssRetido, Este valor já foi abatido no valor da duplicata
    R.PisRetido, --VrPisRetido, 
    R.CofinsRetido,  --VrCofinsRetido
    Case When (TipoNota = 'Retida' Or Retencao = 'Sim') Then (R.ValorContabil - R.Issqn - R.Irrf - R.Inss) Else R.ValorContabil - R.Irrf - R.Inss End, --Total
    0 --TarifaCobranca
    From RegPrestServicos R
    Left Outer join ControleClientes C on (C.Fk = R.Pk) and (C.FkC = R.PkC)
    Where (R.CodEmpresa = @CodEmpresa) and 
    (Data Between @DataInicialP and @DataFinalP) and 
    (R.VP = 'P') and (TipoServico = 2) and
    (C.Pk is null)
  End

If (@ImpServicosTomadosVP = 'P')
  Begin
    Insert ControleFornecedores 
    (Pkc, Fk, Fkc, FkFornecedores, CodEmpresa, Vencimento, Duplicata, Parcela, DataEmissao, DataNotaFiscal, NotaFiscal, Valor, Total, Situacao, Emissao,
    VrIrrf, VrCssllRetido, VrInssRetido, VrPisRetido, VrCofinsRetido)
    Select 1, R.Pk, R.Pkc, R.FkClientes, R.CodEmpresa, 
    DateAdd(mm, 1, R.Data), --Vencimento
    R.DocN, --Duplicata
    1, --Parcela
    R.Data, --DataEmissao
    R.Data, --DataNotaFiscal
    R.DocN, --NotaFiscal
    Case When (TipoNota = 'Retida' Or Retencao = 'Sim') Then (R.ValorContabil - R.Issqn - R.Irrf - R.Inss) Else R.ValorContabil - R.Irrf - R.Inss End, --Valor
    Case When (TipoNota = 'Retida' Or Retencao = 'Sim') Then (R.ValorContabil - R.Issqn - R.Irrf - R.Inss) Else R.ValorContabil - R.Irrf - R.Inss End, --Total
    'Normal', 
    @Emissao,
    0, --VrIrrf, Este valor já foi abatido no valor da duplicata
    R.CssllRetido, --VrCssllRetido, 
    0, --VrInssRetido, Este valor já foi abatido no valor da duplicata
    R.PisRetido, --VrPisRetido, 
    R.CofinsRetido  --VrCofinsRetido
    From RegPrestServicos R
    Left outer join ControleFornecedores C on (C.Fk = R.Pk) and (C.Fkc = R.Pkc)
    Where (R.CodEmpresa = @CodEmpresa) and 
    (R.Data Between @DataInicialP and @DataFinalP) and 
    (R.VP = 'P') and
    (R.ValorContabil > 0) and (TipoServico = 1) and
    (C.Pk is null)
  End

-----------------------------------------------------------------------------------------------------------------------------------------  
Update RegPrestServicos
Set Vp = 'V'
From RegPrestServicos R
Left Outer join ControleClientes C on (C.Fk = R.Pk) and (C.FkC = R.PkC)
Where (R.CodEmpresa = @CodEmpresa) and 
(Data Between @DataInicialP and @DataFinalP) and 
(R.VP = 'P') and (TipoServico = 2) and
(C.Pk is null)

Update RegPrestServicos
Set Vp = 'V'
From RegPrestServicos R
Left outer join ControleFornecedores C on (C.Fk = R.Pk) and (C.Fkc = R.Pkc)
Where (R.CodEmpresa = @CodEmpresa) and 
(R.Data Between @DataInicialP and @DataFinalP) and 
(R.VP = 'P') and
(R.ValorContabil > 0) and (TipoServico = 1) and
(C.Pk is null)

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

--Registra Log da importação na Auditoria
Set @Texto = 'Período: ' + Convert(Varchar, @DataInicialP, 103) + ' a ' + Convert(Varchar, @DataFinalP, 103) + 
' Sobrepor: ' + @Sobrepor + 
' Tipo Importação: ' + Convert(Varchar, @TipoImportacao) +
' Data Emissão: ' + @BtDataEmissao +
' Data Competência: ' + @BtDataCompetencia

Insert LogAuditoria
(DataHora, DataHoraFinal, FkUsuario, CodEmpresa, Acao, Modulo, Descricao)
Values (@DataHoraInicial, getdate(), @PkUsuario, @CodEmpresa, 'Importação', 'Importação de NFE padrão GINFES.', @Texto)

-----------------------------------------------------------------------------------------------------------------------------------------
End Try

Begin Catch

DECLARE @ErrorMessage NVARCHAR(4000)

Set @ErrorMessage = char(13) + 
'- MSGE: ' + Coalesce(ERROR_MESSAGE(), '') + char(13) +
'- LINHA: ' + Convert(Varchar, Coalesce(ERROR_LINE(), 0)) + char(13) +
'- PC/TG: ' + Coalesce(ERROR_PROCEDURE(), '- Não foi em trigger ou procedure') + char(13) +
'- SEVERITY: ' + Convert(Varchar, Coalesce(ERROR_SEVERITY(), 0)) + char(13) +
'- STATE: ' + Convert(Varchar, Coalesce(ERROR_STATE(), 0)) + char(13) 
Raiserror(@ErrorMessage, 16, 1)

End Catch

If not exists (Select Pk From MSistema Where FkUsuario = @PkUsuario)
  Begin
    Insert MSistema
    (FkUsuario, Descricao, Texto, Abort)
    Select @PkUsuario, 'Arquivo Importado Com Sucesso!', ' ','Ok' 
  End
  --Print(@TipoNfse)
-----------------------------------------------------------------------------------------------------------------------------------------
--Exec PcAtualizaTodasProcedures 'PcImportaNfeServicosGinfes'
-----------------------------------------------------------------------------------------------------------------------------------------ListaNfse
--[dbo].[PcImportaNfeServicosGinfes] @CodEmpresa = 7, @DataInicialP = '09/01/2018', @DataFinalP = '09/30/2018', @PkUsuario = 143, 
--@Caminho = '\\192.168.0.5\Arquivo\1\Usuários\143\TOP CONTROLER\nfses\201800000003064.xml', @Sobrepor = 'Sim', @TipoImportacao = 1, 
--@BtDataEmissao = 'Sim', @BtDataCompetencia = 'Sim'
------------------------------------------------------------------------------------------------------------------------------------------

--Exec PcImportaNfeServicosGinfes 21343, '01/01/2019', '01/31/2019', 2517, '\\192.168.0.5\Arquivo\1\Usuários\2940\xml_SOROCABA.xml',  'Sim', 2,'Sim', 'Não' 