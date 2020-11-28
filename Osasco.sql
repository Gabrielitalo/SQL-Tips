--Parametros Procedure
Declare @CodEmpresa int = 13386, @PkUsuario int = 2528, @DataInicialP Datetime = '2019-01-01', @DataFinalP datetime = '2019-01-31'

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Bloco para declaração e atribuição de variáveis
Declare @Xml xml, @hdoc int, @Inicio varchar(60), @CnpjEmpresaCorrente varchar(14), @TipoServico int, @Emissao Varchar(30), @Cnpj Varchar(14), @Count Int, @Alteracao Varchar(30), 
@TipoDeclaranteDmed Int, @CodigoMunicipio Varchar(10), @FkListaServicos Int, @PkEscritorio Int, @PkCodigoProdutoPadrao Int,  @PkNota int, @DocN int, @DataBalancoAbertura Datetime

Set @Emissao = dbo.FEmissao(@PkUsuario)
Set @Alteracao = @Emissao
Set @PkEscritorio = dbo.FPkEscritorioUsuarios(@PkUsuario)

Select Top 1 @FkListaServicos = FkListaServicos
From TributacaoMunicipal
Where (CodEmpresa = @CodEmpresa) and 
(DataInicial <= @DataFinalP)
order by DataInicial Desc

Set @FkListaServicos = Case When @FkListaServicos is null Then 0 Else @FkListaServicos End

Set @PkCodigoProdutoPadrao = 0

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Bloco para declarção e atribuição de Parâmetros Globais

Declare  @ImpServicosTomadosVP Char(1), @ImpServicosPrestadosVP Char(1), @ImpServicosTomadosCN Char(1), @ImpServicosPrestadosCN Char(1), @CodigoProdutoPadrao Varchar(60), @Pg405 Char(3),
@Pg468 int

Set @ImpServicosTomadosCN = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 283)), 1)
Set @ImpServicosPrestadosCN = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 284)), 1)
Set @ImpServicosTomadosVP = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 281)), 1)
Set @ImpServicosPrestadosVP = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 282)), 1)
Set @CodigoProdutoPadrao = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 390)), 60)
Set @Pg405 = dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 405)
Set @Pg468 = Left((dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 468)), 20)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Top 1 @PkCodigoProdutoPadrao = Coalesce(Pk, 0)
From CadProdutos 
Where (CodEmpresa = @CodEmpresa) and
(CodigoProduto = LTrim(RTrim(@CodigoProdutoPadrao)))
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Bloco para criação e declaração de tabelas temporárias, todas tabelas deverão ser declaradas aqui
Create Table #Fornecedores 
(
  CNPJ varchar(14),
  CPF varchar(11),
  InscricaoMunicipal varchar(20),
  Nome varchar(120),
  Email varchar(100),
  Logradouro varchar(100),
  Numero bigint,
  Complemento varchar(30),
  Bairro varchar(20),
  Cidade varchar(25),
  CEP varchar(15),
  Estado varchar(15),
  Telefone varchar(15),
  TipoInscricao int
)

Create Table #NotaFiscal
(
  ValorServicos numeric(18,2),
  IssRetido char(3),
  ValorIss numeric(18,2),
  BaseCalculo numeric(18,2),
  Aliquota numeric(18,2),
  ValorLiquidoNfse numeric(18,2),
  ItemListaServico int,
  DataEmissao date, -- Necessário ser do tipo Date para evitar problemas na importação relacionado ao periódo
  Competencia date, -- Necessário ser do tipo Date para evitar problemas na importação relacionado ao periódo
  Numero varchar(12),
  Serie char(3),
  CodigoVerificacao varchar(15),
  CodigoControle varchar(15),
  ValorDeducoes numeric(18,2),
  DescontoIncondicionado numeric(18,2),
  ValorPIS numeric(18,2),
  ValorCOFINS numeric(18,2),
  ValorINSS numeric(18,2),
  ValorIR numeric(18,2),
  ValorCSLL numeric(18,2),
  ValorISSRetido numeric(18,2),
  CnpjTomador varchar(14),
  CnpjPrestador varchar(14)
)

Create Table #NotasDiversas
(
  FkRegPrestServicos int,
  ValorContabil numeric(18,2)
)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select @CnpjEmpresaCorrente = Cnpj,
@DataBalancoAbertura = DataBalancoAbertura
From CadEmpresa
Where (CodEmpresa = @CodEmpresa)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select @Xml = P
From OpenRowSet (Bulk '\\192.168.0.5\Arquivo\1\Usuários\4387\XMLsTeste\OSASCO\OSASCO\Copia1.XML', Single_Blob) as Notas(P)

--Select @Xml -- Exibindo Xml

Exec SP_XML_PREPAREDOCUMENT @hdoc Output, @Xml -- Atribuindo variável de saída para poder usar o xml como tabela

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Obtendo dados do prestador
Begin Try Drop Table #Prestador End Try Begin Catch End Catch 

Set @Inicio = '/NFE/NotaFiscalRelatorioDTO/Prestador'

Select NumeroNota, CNPJ, CPF, InscricaoMunicipal, Nome, Email, Logradouro, Numero, Complemento, Bairro, Cidade, CEP, Estado, Telefone into #Prestador
From OpenXml (@hdoc, @Inicio, 2)
with 
(
  NumeroNota bigint '../Numero',
  CNPJ varchar(14),
  CPF varchar(11),
  InscricaoMunicipal varchar(20),
  Nome varchar(120),
  Email varchar(100),
  Logradouro varchar(100) 'Endereco/Logradouro',
  Numero bigint 'Endereco/Numero',
  Complemento varchar(30) 'Endereco/Complemento',
  Bairro varchar(20) 'Endereco/Bairro',
  Cidade varchar(25) 'Endereco/Cidade',
  CEP varchar(15) 'Endereco/CEP',
  Estado varchar(15) 'Endereco/Estado',
  Telefone varchar(15) 'Telefone'
)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Obtendo dados do tomador
Begin Try Drop Table #Tomador End Try Begin Catch End Catch 

Set @Inicio = '/NFE/NotaFiscalRelatorioDTO/Tomador'

Select NumeroNota, CNPJ, CPF, InscricaoMunicipal, Nome, Email, Logradouro, Numero, Complemento, Bairro, Cidade, CEP, Estado, Telefone into #Tomador
From OpenXml (@hdoc, @Inicio, 2)
with 
(
  NumeroNota bigint '../Numero',
  CNPJ varchar(14),
  CPF varchar(11),
  InscricaoMunicipal varchar(20),
  Nome varchar(120),
  Email varchar(100),
  Logradouro varchar(100) 'Endereco/Logradouro',
  Numero bigint 'Endereco/Numero',
  Complemento varchar(30) 'Endereco/Complemento',
  Bairro varchar(20) 'Endereco/Bairro',
  Cidade varchar(25) 'Endereco/Cidade',
  CEP varchar(15) 'Endereco/CEP',
  Estado varchar(15) 'Endereco/Estado',
  Telefone varchar(15) 'Telefone'
)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Buscando apenas CNPJ ou CPF que não são iguais ao da empresa corrente
Begin Try Truncate Table #Fornecedores End Try Begin Catch End Catch 

Insert #Fornecedores
Select CNPJ, CPF, InscricaoMunicipal, Nome, Email, Logradouro, Numero, Complemento, Bairro, Cidade, CEP, Estado, Telefone, null
From #Prestador P
Where (P.CNPJ <> @CnpjEmpresaCorrente) or ((P.CPF <> @CnpjEmpresaCorrente))

Insert #Fornecedores
Select CNPJ, CPF, InscricaoMunicipal, Nome, Email, Logradouro, Numero, Complemento, Bairro, Cidade, CEP, Estado, Telefone, null 
From #Tomador T
Where (T.CNPJ <> @CnpjEmpresaCorrente) or (T.CPF <> @CnpjEmpresaCorrente)

Update #Fornecedores
Set TipoInscricao = Case When (CPF is null) Then 1 Else 2 End

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Removendo registros duplicados

-- CNPJ
Declare C Cursor local static for
Select Cnpj, Count(Cnpj)
From #Fornecedores
Where Coalesce(Cnpj, '') <> ''
Group by Cnpj
Having Count(Cnpj) > 1 
Open C
Fetch next from C into @Cnpj, @Count
While @@FETCH_STATUS = 0
  Begin
    Delete top (@Count -1) 
    From #Fornecedores
    Where Cnpj = @Cnpj

    Fetch next from C into @Cnpj, @Count
  End

Close C
Deallocate C

-- CPF
Set @Cnpj = 0 -- Usado mesma varável para economizar espaço na memória
Declare C Cursor local static for
Select Cpf, Count(Cpf)
From #Fornecedores
Group by Cpf
Having Count(Cpf) > 1 
Open C
Fetch next from C into @Cnpj, @Count
While @@FETCH_STATUS = 0
  Begin 
    Delete top (@Count -1) 
    From #Fornecedores
    Where (Cpf = @Cnpj)

    Fetch next from C into @Cnpj, @Count
  End

Close C
Deallocate C

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserindo fornecedores que não estão cadastrados

Insert CadFornecedores 
(CNPJ, TipoInscricao, Nome, Endereco, Numero, Complemento, Bairro, Cidade, UF, Cep, ProdutorRural, InscrEstadual, InscrMunicipal, Telefone, Fax, Email, TipoPrincipal, Emissao, 
InscrSuframa, FkCidades, ContribuinteICMS)
Select 
Case When (F.TipoInscricao = 1) Then -- Cnpj
  F.CNPJ
Else
  F.CPF
End,
F.TipoInscricao, -- TipoInscricao
F.Nome, -- Nome fornecedor
Coalesce(F.Logradouro, 'A CADASTRAR'), -- Endereço
Coalesce(F.Numero, 'A CADASTRAR'), -- Numero
F.Complemento, -- Complemento
Coalesce(F.Bairro, 'A CADASTRAR'), -- Bairro
Coalesce((Select Top 1 Cidade From Cidades Where (Cidade like (F.Cidade))), 'A CADASTRAR'), -- Cidade
F.Estado, -- UF
F.CEP, -- CEP
'Não', --ProdutorRural
'ISENTO', -- InscrEstadual (Este layout não possui InscrEstadual)
Case When (F.InscricaoMunicipal is null) Then '' Else F.InscricaoMunicipal End, -- InscrMunicipal
F.Telefone, -- Telefone
'', -- Fax
F.Email, -- Email
'Não', --TipoPrincipal
@Emissao, --Emissao 
'', --InscrSuframa
Coalesce((Select Top 1 Pk From Cidades Where (Cidade like (F.Cidade))), (Select Top 1 Pk From Cidades)), -- FkCidades
'Não' -- ContribuinteICMS
From #Fornecedores F
Left Outer Join CadFornecedores Cf on ((Cf.CNPJ = F.CNPJ) or (Cf.CNPJ = F.CPF))
Where (Cf.Pk is null)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Escolhendo o município de importação, inicialmente esta PC só atende a Osasco, caso for atender outros deverá ser alterado a variável abaixo

Set @CodigoMunicipio = '3534401'

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Obtendo dados da nota
-- Case será necesário em todas tags com xsi:nil e deve estar como varchar
Begin Try Drop Table #Valores End Try Begin Catch End Catch 
 
Set @Inicio = '/NFE/NotaFiscalRelatorioDTO'

Select Numero, 
CodigoAutenticidade, 
DataEmissao,
Case When (DataCancelamento = '') Then -- DataCancelamento
  null 
Else 
  DataCancelamento 
End DataCancelamento,
Serie, ValorIss, Valor, 
Case When (ValorDeducao = '') Then -- ValorDeducao
  0 
Else 
  ValorDeducao 
End ValorDeducao,
BaseCalculo, -- BaseCalculo
Aliquota, -- Aliquota
Case When (ValorIR = '') Then -- ValorIR
  0 
Else 
  ValorIR 
End ValorIR,
Case When (ValorINSS = '') Then -- ValorINSS
  0 
Else 
  ValorINSS 
End ValorINSS,
Case When (ValorCofins = '') Then -- ValorCofins
  0 
Else 
  ValorCofins 
End ValorCofins,
Case When (ValorPisPasep = '') Then -- ValorPisPasep
  0 
Else 
  ValorPisPasep 
End ValorPisPasep,
Case When (ValorCSLL = '') Then -- ValorCSLL
  0 
Else 
  ValorCSLL 
End ValorCSLL,
Case When (ValorOutrosImpostos = '') Then -- ValorOutrosImpostos
  0 
Else 
  ValorOutrosImpostos 
End ValorOutrosImpostos,
Case When (ValorRepasse = '') Then -- ValorRepasse
  0 
Else 
  ValorRepasse 
End ValorRepasse into #Valores
From OpenXml (@hdoc, @Inicio, 2)
with
(
  Numero bigint,
  CodigoAutenticidade varchar(15),
  DataEmissao datetime,
  DataCancelamento  varchar(30),
  Serie varchar(5),
  ValorIss numeric(18,2),
  Valor numeric(18,2),
  ValorDeducao varchar(20),
  BaseCalculo numeric(18,2),
  Aliquota numeric(18,2),
  ValorIR  varchar(20),
  ValorINSS  varchar(20),
  ValorCofins  varchar(20),
  ValorPisPasep  varchar(20),
  ValorCSLL   varchar(20),
  ValorOutrosImpostos   varchar(20),
  ValorRepasse   varchar(20)
)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserindo dados na tabela temporária de NotaFiscal

Insert #NotaFiscal(ValorServicos, IssRetido, ValorIss, BaseCalculo, Aliquota, ValorLiquidoNfse, ItemListaServico, DataEmissao, Competencia, Numero, Serie, CodigoVerificacao, 
CodigoControle, ValorDeducoes, DescontoIncondicionado, ValorPIS, ValorCOFINS, ValorINSS, ValorIR, ValorCSLL, ValorISSRetido, CnpjTomador, CnpjPrestador)
Select V.Valor, -- ValorServicos
'Não' IssRetido, -- Retenção xml modelo não tem tag retenção
V.ValorIss, -- ValorIss
V.BaseCalculo, -- BaseCalculo
V.Aliquota, -- Aliquota
V.Valor ValorLiquidoNfse, -- ValorLiquidoNfse
0 ItemListaServico, -- ItemListaServico
V.DataEmissao, -- DataEmissao
null DataCompetencia, -- DataCompetencia
V.Numero, -- Numero da Nota
V.Serie, -- Serie
V.CodigoAutenticidade, -- CodigoVerificacao
null CodigoControle, -- CodigoControle
V.ValorDeducao, -- ValorDeducoes
0 DescontoIncondicionado, --DescontoIncondicionado
V.ValorPisPasep, -- ValorPIS
V.ValorCofins, -- ValorCofins
V.ValorINSS, -- ValorINSS
V.ValorIR, -- ValorIR
V.ValorCSLL, -- ValorCSLL
0 ValorISSRetido, -- ValorISSRetido
Case When (T.CNPJ is null) Then T.CPF Else T.CNPJ End CNPJTomador, -- CNPJTomador
Case When (P.CNPJ is null) Then P.CPF Else P.CNPJ End CNPJPrestador -- CNPJPrestador
From #Valores V
Join #Prestador P on (P.NumeroNota = V.Numero)
Join #Tomador T on (T.NumeroNota = V.Numero)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aqui será removido o arquivo da memória
Exec sp_xml_removedocument @hdoc
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agora será inserido nas tabelas oficiais

Insert RegPrestServicos 
(PkC, FkClientes, CodEmpresa, Data, DocN, ADocN, Tipo, Serie, ValorContabil, Issqn, Inss, Irrf, VP, PisRetido, 
CofinsRetido, CssllRetido, Exportado, TipoNota, TipoServico, Emissao, Alteracao, Observacao, StatusNf, SubSerie, FkIntegra, ChaveNfe, 
DataConclusaoServicos, Descontos, TotalServicos, FkTomador, Modelo, FkInfComplementares, InfComplementares, TipoDeclaranteDmed, 
Retencao, FkCidades)
Select 4, -- PkC
Case When Right('00000000000000' + N.CnpjPrestador, 14) = Right('00000000000000' + @CnpjEmpresaCorrente, 14) Then -- FkCLientes
  Coalesce((Select Top 1 Pk From CadFornecedores C Where Right('00000000000000' + C.CNPJ, 14) = Right('00000000000000' + N.CnpjTomador, 14)), (Select Top 1 Pk From CadFornecedores)) 
Else
  Coalesce((Select Top 1 Pk From CadFornecedores C Where Right('00000000000000' + C.CNPJ, 14) = Right('00000000000000' + N.CnpjPrestador, 14)), (Select Top 1 Pk From CadFornecedores))
End,
@CodEmpresa, -- CodEmpresa
N.DataEmissao, -- Data
N.Numero, -- DocN
N.Numero, -- ADocN
'NF', -- Tipo
N.Serie, -- Serie
N.ValorServicos, -- ValorContabil
N.ValorIss, -- Issqn
N.ValorINSS, -- ValorInss
N.ValorIR, -- Irrf
Case When N.CnpjPrestador = @CnpjEmpresaCorrente Then  -- VP
  Case When @ImpServicosPrestadosVP = 'O' Then 'F' When @ImpServicosPrestadosVP = 'N' Then '' Else @ImpServicosPrestadosVP End
Else
  Case When @ImpServicosTomadosVP = 'O' Then 'F' When @ImpServicosTomadosVP = 'N' Then '' Else @ImpServicosTomadosVP End
End,
0, -- PisRetido
0, -- CofinsRetido
0, -- CssllRetido
'S', -- Exportado
Case When Cast(DataEmissao as Date) <= '12/31/2018' Then -- Tipo Nota
  'Normal'      
Else
  '00'
End,
Case When N.CnpjPrestador = @CnpjEmpresaCorrente Then -- Tipo Serviço Prestado ou Tomado
  2
Else
  1
End,
@Emissao, -- Emissao, 
Case When N.CnpjPrestador = @CnpjEmpresaCorrente Then -- Alteracao,
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
'', -- Observacao
null, -- StatusNf
null, -- SubSerie
null, -- FkIntegra
N.CodigoVerificacao, -- ChaveNfe
null, -- DataConclusaoServicos não possui data RPs
N.ValorDeducoes + N.DescontoIncondicionado, -- Descontos,
ValorServicos, -- TotalServicos
null, --FkTomador
Coalesce((Select top 1 ModeloNF From TributacaoMunicipal Tm Where Tm.CodEmpresa = @CodEmpresa),''), --Modelo
null, -- FkInfComplementares, 
null, -- InfComplementares
Case When @Pg405 = 'Sim' Then @TipoDeclaranteDmed Else NULL End, -- TipoDeclaranteDmed
Case When (N.IssRetido = 'Sim') Then 'Sim' Else 'Não' End, -- Retencao
(Select top 1 Pk From Cidades Where Codigo = @CodigoMunicipio) -- FkCidades
From #NotaFiscal N

-- Inserindo na tabela filha
Insert RegPrestServicosItens 
(Fk, FkListaServicos, ValorContabil, Aliquota, Issqn, Inss, Irrf, Pis, Cofins, 
Cssll, CentroCusto, vBcPis, pPis, vPis, vBcCofins, pCofins, vCofins, ValorServicos, 
ValorDesconto, BaseCalculoPisImport, BaseCalculoCofinsImport, PisPagoImport, CofinsPagoImport, 
DataPagtoCofinsImport, DataPagtoPisImport, LocalExecucaoImport, NumeroItem, IndicadorOrigemCredito,
CstCofins, CstPis, TipoDebitoCreditoPis, TipoDebitoCreditoCofins, FkCadNaturezaOperacao, vBcIssqn, 
FkCadProdutos)
Select R.Pk, -- Fk
Coalesce((Select Top 1 Pk From ListaServicos Where Replace(Item, '.', '') = Right('0000' + N.ItemListaServico, 4) and (FkEscritorio = @PkEscritorio)), @FkListaServicos), -- FkListaServicos
R.ValorContabil, -- ValorContabil
N.Aliquota, -- Aliquota
N.ValorIss, -- Issqn
N.ValorINSS, -- Inss
N.ValorIR, -- Irrf
N.ValorPIS, -- Pis,
N.ValorCOFINS, -- Cofins
N.ValorCSLL, -- Cssll
dbo.FCentroCustoServicosPadrao (Coalesce((Select Top 1 Pk From ListaServicos Where (FkEscritorio = @PkEscritorio) and Replace(Item, '.', '') = Right('0000' + N.ItemListaServico, 4)), @FkListaServicos), @CodEmpresa, R.TipoServico, R.VP), -- CentroCusto
0, -- vBcPis
0, -- pPis
0, -- vPis 
0, --vBcCofins
0, -- pCofins
0, --vCofins
Coalesce(N.ValorServicos, 0), -- ValorServicos
N.DescontoIncondicionado, -- ValorDesconto
0, -- BaseCalculoPisImport
0, -- BaseCalculoCofinsImport
0, -- PisPagoImport
0, -- CofinsPagoImport
null, -- DataPagtoCofinsImport
null, -- DataPagtoPisImport
null, -- LocalExecucaoImport
1, -- NumeroItem
0, -- IndicadorOrigemCredito
'', -- CstCofins
'', -- CstPis
null, -- TipoDebitoCreditoPis
null, -- TipoDebitoCreditoCofins
null, -- FkCadNaturezaOperacao
Case When (Coalesce(N.ValorIss, 0) = 0) and (Coalesce(N.ValorIssRetido, 0) = 0) Then 0 Else Coalesce(N.BaseCalculo, 0) End, -- vBcIssqn
Case When @PkCodigoProdutoPadrao = 0 Then NULL Else @PkCodigoProdutoPadrao End -- FkCadProdutos
From #NotaFiscal N
Join RegPrestServicos R on (R.DocN = N.Numero)
Where (R.CodEmpresa = @CodEmpresa) and
(R.Data between @DataInicialP and @DataFinalP) and
(R.ChaveNfe in (Select CodigoVerificacao From #NotaFiscal))

--Altera os campos das guias Pis e Cofins
Update RegPrestServicosItens
Set CstPis = Case When R.TipoServico = 1 Then CstPisEntrada Else CstPisSaida End,
CstCofins = Case When R.TipoServico = 1 Then CstCofinsEntrada Else CstCofinsSaida End,
TipoDebitoCreditoPis = Case When R.TipoServico = 1 Then TipoCreditoPis Else TipoDebitoPis End,
TipoDebitoCreditoCofins = Case When R.TipoServico = 1 Then TipoCreditoCofins Else TipoDebitoCofins End,
pPis = AliquotaPis,
pCofins = AliquotaCofins
From RegPrestServicos R
Join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
Join CadProdutos C on (C.Pk = Ri.FkCadProdutos) and 
(R.CodEmpresa = C.CodEmpresa)
Where (R.ChaveNfe in (Select CodigoVerificacao From #NotaFiscal)) and 
(R.CodEmpresa = @CodEmpresa) and 
(R.Data between @DataInicialP and @DataFinalP)
        
        
Update RegPrestServicosItens
Set vBcPis = Case When pPis > 0 Then Ri.ValorContabil Else 0 End,
vBcCofins = Case When pCofins > 0 Then Ri.ValorContabil Else 0 End,
vPis = Case When pPis > 0 Then Ri.ValorContabil * pPis / 100 Else 0 End,
vCofins = Case When pCofins > 0 Then Ri.ValorContabil * pCofins / 100 Else 0 End
From RegPrestServicos R
Join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
WHere (R.ChaveNfe in (Select CodigoVerificacao From #NotaFiscal)) and 
(R.CodEmpresa = @CodEmpresa) and 
(R.Data between @DataInicialP and @DataFinalP)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Caso a nota seja como diversos usar valor do parâmetro 468
-- Gabriel em 11/07/2019 a pedido do suporte fiscal

Insert #NotasDiversas 
Select Pk, ValorContabil
From RegPrestServicos R
WHere (R.ChaveNfe in (Select CodigoVerificacao From #NotaFiscal)) and 
(R.CodEmpresa = @CodEmpresa) and 
(R.Data between @DataInicialP and @DataFinalP) and
(R.VP = 'D')

If (@ImpServicosPrestadosVP = 'D') 
  Begin
    Insert CondPagtoServicos
    (FkRegPrestServicos, FkCadCondPagto, Valor, CentroCusto, Observacao) 
    Select N.FkRegPrestServicos, -- FkRegPrestServicos
    @Pg468, -- FkCadCondPagto
    N.ValorContabil, -- Valor Contabil
    Ci.CentroCusto, -- Centro Custo,
    null -- Observação
    From CadCondPagto C
    Join CadCondPagtoItens Ci on (Ci.FkCadCondPagto = C.Pk)
	Cross Join #NotasDiversas N
    Where (C.Pk = @Pg468)
  End

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserindo no contabil

Declare CrNotas Cursor Local static for	
Select Pk
From RegPrestServicos R
WHere (R.ChaveNfe in (Select CodigoVerificacao From #NotaFiscal)) and 
(R.CodEmpresa = @CodEmpresa) and 
(R.Data between @DataInicialP and @DataFinalP)
Open CrNotas 
Fetch next from CrNotas into @PkNota
while (@@FETCH_STATUS = 0)
  Begin

	  Exec PcRegPrestServicosInsertContabil @PkNota, @PkUsuario
	  Exec PcInsertRetencoes @PkNota, @PkUsuario, 'RegPrestServicos'

	Fetch next from CrNotas into @PkNota
  End

Close CrNotas
Deallocate CrNotas

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Informando ao usuário quais notas não foram importadas

Set @PkNota = 0

Declare CrNotasNImp Cursor Local static for

Select Pk, DocN 
From RegPrestServicos 
Where (CodEmpresa = @CodEmpresa) and
(Data between @DataInicialP and @DataFinalP) and 
(ChaveNfe not in (Select CodigoVerificacao From #NotaFiscal))
Open CrNotasNImp 
Fetch next from CrNotasNImp into @PkNota, @DocN
while (@@FETCH_STATUS = 0)
	Begin

	  Insert MSistema(Abort, FkUsuario, Descricao, Texto)
	  Select 'Não',
	  @PkUsuario,
	  'A nota Fiscal nº: ' + Convert(Varchar, @DocN) + ', não pertence a empresa corrente, por isso não foi importada!',
	  'Verifique dentro do arquivo XML a situação!'

	Fetch next from CrNotasNImp into @PkNota, @DocN
  End

Close CrNotasNImp
Deallocate CrNotasNImp

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Incluindo duplicatas no controle de clientes e fornecedores

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

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Begin Try Drop Table #NotaFiscal End Try Begin Catch End Catch 
Begin Try Drop Table #Fornecedores End Try Begin Catch End Catch 
Begin Try Drop Table #Prestador End Try Begin Catch End Catch 
Begin Try Drop Table #Tomador End Try Begin Catch End Catch 
Begin Try Drop Table #NotasDiversas End Try Begin Catch End Catch 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------