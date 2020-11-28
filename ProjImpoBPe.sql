

Declare @Xml xml, @PkXml int, @Inicio varchar(255), @PkCliente int, @FkBilhete int, @chNfe varchar(100), @PkNota int, @InscrEstadual varchar(20), @UF char(2)

Declare @CodEmpresa int = 13386, @DataInicialP datetime = '2019-05-01', @DataFinalP datetime = '2019-05-31', @PkUsuario int = 2528,
@VP char(2),  @Modelo int, @DataNota datetime, @CnpjEmit varchar(14), @CnpjCodEmpresa varchar(14), 
@Cmd nvarchar(1000), @Extensao char(5) = '*.xml', @CaminhoCompleto varchar(150) = '\\192.168.0.5\Arquivo\1\Usu�rios\4387\Modelo63\Mod63.xml', @TipoImportacao int = 2,
@NomeAtual varchar(100), @QtdRegistrosAfetados int, @CaminhoArquivo varchar(150) = '', @QtdNfeImportada int = 0, @Sobrepor char(3) = 'Sim'

Declare @PkEscritorio Int = dbo.FPkEscritorioUsuarios(@PkUsuario), @Texto Varchar(8000), @DataHoraInicial DateTime = GetDate()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Par�metros Globais usados na Procedure

Declare @Pg478 char(3), @Pg490 char(3),  @Pg433 varchar(15), @Pg339 int, @Pg363 int, @Pg282 Char(1)

Set @Pg433 = dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 433) -- Produto
Set @Pg339 = dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 339) -- CFOP
Set @Pg478 = dbo.FPg(@CodEmpresa, GETDATE(), @PkUsuario, 478) -- N� da parcela Duplicata
Set @Pg490 = dbo.FPg(@CodEmpresa, GETDATE(), @PkUsuario, 490) -- Considerar o N� da nota na duplicata
Set @Pg363 = dbo.FPg(@CodEmpresa, @DataFinalP, @PkUsuario, 363) -- Usar arquivo ou Pg282
Set @Pg282 = dbo.FPg(@CodEmpresa, GETDATE(), @PkUsuario, 282)

-----------------------------------------------------------------------------------------------------------------------------------------
--In�cio da Valida��o Preliminar
-----------------------------------------------------------------------------------------------------------------------------------------
Delete MSistema
Where (FkUsuario = @PkUsuario)


Select @CnpjCodEmpresa = Cnpj, @InscrEstadual = InscrEstadual, @UF = UF
From CadEmpresa
Where (CodEmpresa = @CodEmpresa) and
(FkEscritorio = @PkEscritorio)

-----------------------------------------------------------------------------------------------------------------------------------------
Exec PcVerificaModuloSistema 6, @PkUsuario
Exec PcValidaCodEmpresa @CodEmpresa, @PkUsuario
Exec PcValidaDataPeriodo @DataInicialP, @DataFinalP, @PkUsuario

Exec PcVerificaDataLimiteUsoSistema @DataInicialP, @PkUsuario
Exec PcVerificaEncerramento @CodEmpresa, 'Fiscal', @DataInicialP, 'Sim', 'Sim', @PkUsuario, 'N�o'
Exec PcValidaSmallDateTime @PkUsuario, @DataInicialP, 'Data Inicial do Per�odo de Trabalho'
Exec PcValidaSmallDateTime @PkUsuario, @DataFinalP, 'Data Final do Per�odo de Trabalho'

--------------------------------------------------------------------------------------------------------------------------------------------
--Fim da valida��o preliminar
--------------------------------------------------------------------------------------------------------------------------------------------

If dbo.FAbort(@PkUsuario) = 'Sim' --Caso n�o exista o arquivo
  Begin
    Return
  End

Begin Try

	Begin Try Drop Table #TbNomeArquivo End Try Begin Catch End Catch

	Create Table #TbNomeArquivo (Pk int identity , Nome varchar(300))

	If (@TipoImportacao = 1) -- Todos arquivos do diret�rio
		Begin
			Set @CaminhoCompleto = dbo.FNomeArquivoDiretorio(@CaminhoCompleto)
			Set @Cmd = 'master.dbo.xp_cmdshell "dir ""' + @CaminhoCompleto + @Extensao + '"" /b"'
			Insert #TbNomeArquivo(Nome) Exec(@Cmd)
			Delete From #TbNomeArquivo Where Nome is null -- Removendo valores nulos
		End
	Else
		Begin
			Set @Cmd = 'master.dbo.xp_cmdshell "dir ""' + @CaminhoCompleto + '"" /b"'
			Insert #TbNomeArquivo(Nome) Exec(@Cmd)
			Delete From #TbNomeArquivo Where Nome is null -- Removendo valores nulos
		End

	If (@TipoImportacao in(1, 2))
		Begin
			If (LEN(@CaminhoCompleto) > 128) -- Gabriel em 21/05/2019 substituido @Cmd por @CaminhoCompleto
				Begin
					Insert MSistema
					(FkUsuario, Descricao, Texto, Abort)
					Select @PkUsuario, --FkUsuario 
					Left('O caminho do diret�rio escolhido � muito longo. Por favor escolha outro caminho!', 255), --Descricao
					'Retire as notas fiscais do diretorio escolhido: ' + @CaminhoCompleto + ', e coloque em um diret�rio mais curto!', --Texto
					'Sim' --Abort
    
					return
				End

			If @CodEmpresa = 0
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select Distinct @PkUsuario, --FkUsuario 
					'Sim', --Abort
					Left('Escolha a empresa que ser� importada a NFe primeiro.', 255), --Descricao
					'A empresa corrente ainda dever� ser escolhida, � poss�vel que voc� tenha feito um filtro em EMPRESAS.' --Texto
				End
  
			If @InscrEstadual = ''
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select Distinct @PkUsuario, --FkUsuario
					'N�o', --Abort 
					Left('Esta empresa dever� ter Inscri��o Estadual cadastrada.', 255), --Descricao
					'Em EMPRESAS, esta empresa dever� ser cadastrada no cadastro de Inscri��o Estadual.' +
					' Verifique a necessidade de preenchimento do campo.' --Texto
				End

			---------------------------------------------------------------------------------------------------------------------------------------------------- 
			If @Sobrepor = ''
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select @PkUsuario, --FkUsuario
					'Sim', --Abort 
					'Informe se o sistema ir� sobrepor as Notas j� existentes do per�odo.',
					'Opera��o cancelada.'
				End
  
			If Coalesce(@TipoImportacao, 0) = 0
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select @PkUsuario, --FkUsuario
					'Sim', --Abort 
					'Informe que tipo de importa��o ser� aplicado sobre o diret�rio escolhido.',
					'Opera��o cancelada.'
				End

			----------------------------------------------------------------------------------------------------------------------------------------------------  
			If @DataFinalP < @DataInicialP
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select Distinct @PkUsuario, --FkUsuario 
					'Sim', --Abort
					Left('A data final tem que ser maior ou igual a data inicial.', 255), --Descricao
					'Verifique no per�odo de trabalho escolhido.' --Texto
				end

			If DatePart(mm, @DataInicialP) <> DatePart(mm, @DataFinalP)
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select Distinct @PkUsuario, --FkUsuario 
					'N�o', --Abort
					Left('O sistema s� permite importar NFe em at� um m�s calend�rio.', 255), --Descricao
					'Voc� pode escolher apenas um per�odo.' --Texto
				End
  
			If DatePart(yy, @DataInicialP) <> DatePart(yy, @DataFinalP)
				Begin
					Insert MSistema 
					(FkUsuario, Abort, Descricao, Texto)
					Select Distinct @PkUsuario, --FkUsuario
					'N�o', --Abort
					Left('O sistema s� permite importar NFe em at� um ano calend�rio.', 255), --Descricao
					'Voc� pode escolher apenas um per�odo.' --Texto
				End

			If not exists(Select Top 1 Nome From #TbNomeArquivo Where (Nome like '%.Xml'))
				Begin
					If @TipoImportacao = 1 --Todas as NF-e do diret�rio escolhido
						Begin
							Insert MSistema 
							(FkUsuario, Abort, Descricao, Texto)
							Select @PkUsuario, --FkUsuario
							'Sim', --Abort
							Left(@CaminhoCompleto, 255), --Descricao
							'N�o foi encontrado nenhum arquivo XML no diret�rio escolhido' --Texto
						End
					Else If @TipoImportacao = 2
						Begin
							Insert MSistema 
							(FkUsuario, Abort, Descricao, Texto)
							Select @PkUsuario, --FkUsuario 
							'Sim', --Abort
							Left('Arquivo escolhido: ' + @CaminhoCompleto, 255), --Descricao
							'Este arquivo ainda ter� que ser importado, pois sua extens�o � diferente da extens�o .XML' --Texto
							From #TbNomeArquivo
         
						End
		End


	------------------------------------------------------------------------------------------------------------------------------------------
	--Verificando se existe algum CFOP sem tipo de cfop Cadastrado
	------------------------------------------------------------------------------------------------------------------------------------------
	Insert MSistema
	(FkUsuario, Descricao, Texto, Abort)
	Select @PkUsuario, --FkUsuario 
	Left('O CFOP: ' + CONVERT(Varchar, CFOP) + ' n�o possui nenhum tipo de tributa��o cadastrado!', 255),
	'Cadastre um tipo de tributa��o para o cfop especificado acima e tente importar novamente.',
	'Sim'
	From CFOP C
	Left join CfopTipoTributacao Ctt on (C.Pk = Ctt.FkCfop)
	Where Ctt.Pk is null and
	(C.FkEscritorio = @PkEscritorio)

	------------------------------------------------------------------------------------------------------------------------------------------
	If (dbo.FAbort (@PkUsuario) = 'Sim')
		Begin
			Insert MSistema 
			(FkUsuario, Abort, Descricao, Texto)
			Select @PkUsuario, --FkUsuario 
			'Sim', --Abort
			Left('Na valida��o inicial da importa��o foram encontrados erros. Verifique acima.', 255), --Descricao
			'Nenhuma NFe. foi importada' --Texto 

			Return
		End

	---------------------------------------------------------
	--Fim da Valida��o
	------------------------------------------------------------------------------------------------------------------------------------------------------

			End

	-- In�cio do cursor que far� a importa��o
	Begin Try Close CrNomeArquivo Deallocate CrNomeArquivo End try Begin Catch End Catch
	Declare CrNomeArquivo cursor local static for
	Select Nome
	From #TbNomeArquivo
	Where (Nome like '%.Xml')
	Order By Nome
	Open CrNomeArquivo
	Set @QtdRegistrosAfetados = @@CURSOR_ROWS
	Fetch next from CrNomeArquivo Into @NomeAtual
	While @@Fetch_Status = 0
		Begin
			If(@TipoImportacao = 1) -- Definindo qual o tipo de importa��o
			Begin
			Set @CaminhoArquivo = @CaminhoCompleto + @NomeAtual
			End
			Else
			Begin
			Set @CaminhoArquivo = @CaminhoCompleto 
			End

			Set @Cmd = '' 
			Set @Cmd = 'Select @Xml = P From OpenRowSet (Bulk ' + '''' + @CaminhoArquivo + ''''  + ', Single_Blob) as Notas(P)'

			Begin Try
				Exec sp_executesql @Cmd, N'@Xml xml out', @Xml out 
			End Try
			Begin Catch
				Insert MSistema 
				(FkUsuario, Abort, Descricao, Texto, TipoValidacao)
				Select @PkUsuario, --FkUsuario 
				'N�o', --Abort
				Left('O arquivo: ' + @NomeAtual + ', n�o est� na pasta ou seu nome cont�m caracteres especiais e n�o ser� importado. Verfique e tente importar essa nota novamente.', 255), --Descricao
				'Verifique a situa��o no caminho: ' + @CaminhoCompleto, 6 --Texto 
      
				Fetch next from CrNomeArquivo Into @NomeAtual
				Continue      
			End Catch
		
			Set @Xml = REPLACE(convert(nvarchar(max),@Xml), ' xmlns="http://www.portalfiscal.inf.br/bpe"', '') -- Removendo namespace
			Set @Xml = REPLACE(convert(nvarchar(max),@Xml), ' versao="1.00"', '') -- Removendo namespace
			Set @Xml = REPLACE(convert(nvarchar(max),@Xml), ' xmlns="http://www.w3.org/2000/09/xmldsig#"', '') -- Removendo namespace
			Set @Xml = REPLACE(convert(nvarchar(max),@Xml), ' Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"', '') -- Removendo namespace
			Set @Xml = REPLACE(convert(nvarchar(max),@Xml), ' Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"', '') -- Removendo namespace
			Set @Xml = REPLACE(convert(nvarchar(max),@Xml), 'URI="#BPe', 'URI="') -- Removendo namespace

			--Select @Xml -- Exibindo Xml

			--Exec SP_XML_PREPAREDOCUMENT @PkXml Output, @Xml -- Atribuindo vari�vel de sa�da para poder usar o xml como tabela
			Begin Try
				Exec SP_XML_PREPAREDOCUMENT @PkXml Output, @Xml -- Atribuindo vari�vel de sa�da para poder usar o xml como tabela
			End Try
			Begin Catch
				Insert MSistema 
				(FkUsuario, Abort, Descricao, Texto)
				Select @PkUsuario, --FkUsuario 
				'N�o', --Abort
				Case when @TipoImportacao in(1, 2) then
					'O arquivo: ' + @NomeAtual + ', est� fora do padr�o XML e n�o ser� importado.'
				End, --Descricao
				--Texto 
				Case when @TipoImportacao in(1, 2) then 
					'Verifique a situa��o do arquivo no caminho: ' + @CaminhoCompleto 
				End 

				Fetch next from CrNomeArquivo Into @NomeAtual
				Continue
      
			End Catch

			---------------------------------------------------------------------------------------------
			-- Obtendo chave da nota

			Set @Inicio = 'BPe/Signature/SignedInfo/Reference' 

			Select @chNfe = URI
			From OpenXml (@PkXml, @Inicio, 1)
			with 
				(
					URI varchar(100)-- Chave da nota
				)
			-----------------------------------------------------------------------------------------------------------------------
			-- Obtendo informa��es do BPe
			Begin Try Drop Table #ide End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/ide'

			Select * into #ide
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					UFIni char(2), -- Municipio inicial
					UFFim char(2), -- Municipio final 
					mod int,
					serie int,
					nBP bigint, -- N� do BPe ,
					modal int, -- 1 - Rodovi�rio;, 3 - Aquavi�rio; 4 - Ferrovi�rio. 					dhEmi datetime, -- Data Emiss�o
					tpEmis int, -- 1 - Normal; 2 - Conting�ncia Off-Line
					tpBPe int, -- 0 - BP-e normal; 3 - BP-e substitui��o 					-- 1=Opera��o presencial n�o embarcado; 2=Opera��o n�o presencial, pela Internet; 3=Opera��o n�o presencial, Teleatendimento; 4=BP-e em opera��o com entrega a domic�lio;					-- 5=Opera��o presencial embarcada;9=Opera��o n�o presencial, outros. 					indPres int, 					cMunIni bigint, -- C�digo do munic�pio inicial					cMunFim bigint, -- C�digo do munic�pio final					dhCont datetime, --Data e Hora da entrada em conting�ncia					xJust varchar(255) -- Justificativa de entrada na contig�ncia
				)

			-- Atribuindo valor a constraint da nota para vincular todas a tabelas
			Set @FkBilhete = 0
			Set @FkBilhete = (Select nBP From #ide)
			------------------------------------------------------------------------------------------------
			-- Obtendo informa��es do emitente
			Begin Try Drop Table #emit End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/emit'

			Select *, @FkBilhete FkBilhete into #emit
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					CNPJ varchar(14), 
					IE varchar(20), -- Inscri��o estadual
					xNome varchar(255), -- Raz�o Social
					xFant varchar(255), -- Nome fantasia
					IM varchar(20), -- Inscri��o municipal
					CNAE varchar(20), -- CNAE fiscal
					CRT int, -- C�digo de Regime Tribut�rio. 
					xLgr varchar(200) 'enderEmit/xLgr', -- Rua 
					nro int 'enderEmit/nro', -- N�mero
					xBairro varchar(50) 'enderEmit/xBairro', -- Bairro
					xMun varchar(50) 'enderEmit/xMun', -- Mun�cipio
					CEP varchar(20) 'enderEmit/CEP', -- Cep
					UF char(2) 'enderEmit/UF', -- UF - Estado
					fone varchar(20) 'enderEmit/fone', -- Telefone
					email varchar(20) 'enderEmit/email' -- E-Mail
				)

			Set @CnpjEmit = ''	
			Set @CnpjEmit = (Select CNPJ From #emit)

			If (@CnpjEmit <> @CnpjCodEmpresa)
				Begin
					Insert MSistema
					(FkUsuario, Descricao, Texto, Abort)
					Select @PkUsuario, --FkUsuario 
					Left('O CNPJ: ' + @CnpjEmit + ' do emitente do arquivo n�o � o mesmo CNPJ: ' + @CnpjCodEmpresa + ' da empresa que est� tentando importar!', 255), --Descricao
					'Portanto, n�o ser� importado esta nota!', --Texto
					'Sim' --Abort
				End

				If (dbo.FAbort(@PkUsuario) = 'Sim')
					Begin	
						Fetch next from CrNomeArquivo Into @NomeAtual
						Continue
					End
			---------------------------------------------------------------------------------------------
			-- Obtendo dados da ag�ncia
			Begin Try Drop Table #agencia End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/agencia'

			Select *, @FkBilhete FkBilhete into #agencia
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					xNome varchar(255), -- Raz�o Social
					CNPJ varchar(14), 
					xLgr varchar(200) 'enderAgencia/xLgr', -- Rua 
					nro int 'enderAgencia/nro', -- N�mero
					xBairro varchar(50) 'enderAgencia/xBairro', -- Bairro
					xMun varchar(50) 'enderAgencia/xMun', -- Mun�cipio
					CEP varchar(20) 'enderAgencia/CEP', -- Cep
					UF char(2) 'enderAgencia/UF', -- UF - Estado
					fone varchar(20) 'enderAgencia/fone', -- Telefone
					email varchar(20) 'enderAgencia/email' -- E-Mail
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo dados da passagem
			Begin Try Drop Table #InfPassagem End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/infPassagem'

			Select *, @FkBilhete FkBilhete into #InfPassagem
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					xLocOrig varchar(50), -- Cidade de Origem
					xLocDest varchar(50), -- Cidade de destino
					dhEmb datetime, -- Data de embarque 
					dhValidade datetime -- Data de validade do bilhete 
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo dados do passageiro
			Begin Try Drop Table #InfPassageiro End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/infPassageiro'

			Select *, @FkBilhete FkBilhete into #InfPassageiro
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					xNome varchar(50), -- Nome do passageiro
					CPF varchar(14), -- CPF
					CNPJ varchar(14) ,-- CNPJ
					tpDoc int, -- Tipo de documento de identifica��o
					nDoc varchar(20), -- N�mero do documento de identifica��o
					dNasc date, -- Data de nascimento Formato AAAA-MM-DD
					fone varchar(14), -- Telefone
					email varchar(120)  -- Endere�o de E-Mail
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo dados do Comprador
			Begin Try Drop Table #comp End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/comp'

			Select *, @FkBilhete FkBilhete into #comp
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					xNome varchar(50), -- Nome do passageiro
					CPF varchar(14), -- CPF
					CNPJ varchar(14) ,-- CNPJ
					IE varchar(20), -- Inscri��o estadual
					xLgr varchar(150) 'enderComp/xLgr', -- Rua
					nro varchar(15) 'enderComp/nro', -- N�mero
					xBairro varchar(50) 'enderComp/xBairro', -- Bairro
					cMun varchar(16) 'enderComp/cMun', -- C�digo do municipio
					xMun varchar(40) 'enderComp/xMun', -- Nome do municipio
					xCpl varchar(60) 'enderComp/xCpl', -- Complemento
					CEP varchar(15) 'enderComp/CEP', -- CEP
					UF varchar(15) 'enderComp/UF', -- Estado
					cPais varchar(15) 'enderComp/cPais', -- Pa�s
					fone varchar(14) 'enderComp/cPais', -- Telefone
					email varchar(120) 'enderComp/cPais' -- Endere�o de E-Mail
				)
			---------------------------------------------------------------------------------------------
			-- Obtendo dados da viagem
			Begin Try Drop Table #infViagem End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/infViagem'

			Select *, @FkBilhete FkBilhete into #infViagem
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					xPercurso varchar(100), -- Descri��o do percurso
					tpViagem int, -- Tipo da viagem
					tpServ int, -- tipo de servi�o
					tpAcomodacao int, -- Tipo de acomoda��o
					tpTrecho int, -- Tipo de trecho
					dhViagem datetime, -- Data da viagem
					prefixo int, -- Prefixo da linha
					poltrona int -- Poltrona		
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo valores do BPe
			Begin Try Drop Table #valorBPe End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/infValorBPe'

			Select *, @FkBilhete FkBilhete into #valorBPe
			From OpenXml (@PkXml, @Inicio, 3)
			with 
				(
					vBP numeric(18,2), -- Valor do bilhete
					vDesconto numeric(18,2), -- Desconto do bilhete
					vPgto numeric(18,2), -- Valor Pago
					vTroco numeric(18,2) -- Troco
				)

			Begin Try Drop Table #valorBPeDesc End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/infValorBPe/Comp'

			Select *, @FkBilhete FkBilhete into #valorBPeDesc
			From OpenXml (@PkXml, @Inicio, 3)
			with 
				(
					tpComp int, -- Tipo do Componente conforme a tabela
					vComp numeric(18,2)  -- Valor do componente		
				)
			---------------------------------------------------------------------------------------------
			-- Obtendo valores do imposto ICMS00
			-- Presta��o sujeito � tributa��o normal do ICMS
			Begin Try Drop Table #icms00 End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/imp/ICMS/ICMS00' 

			Select *, @FkBilhete FkBilhete into #icms00
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					CST char(3), -- CST
					vBC numeric(18,2), -- Valor da base de calculo
					pICMS numeric(18,2), -- Aliquota em %
					vICMS numeric(18,2) -- Valor Pago de ICMS	
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo valores do imposto ICMS20
			--Presta��o sujeito � tributa��o com redu��o deBC do ICMS
			Begin Try Drop Table #icms20 End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/imp/ICMS/ICMS20' 

			Select *, @FkBilhete FkBilhete into #icms20
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					CST char(3), -- CST
					pRedBC int, -- Percentual de redu��o da Base de calculo
					vBC numeric(18,2), -- Valor da base de calculo
					pICMS numeric(18,2), -- Aliquota em %
					vICMS numeric(18,2) -- Valor Pago de ICMS
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo valores do imposto ICMS90
			--ICMS Outros
			Begin Try Drop Table #icms90 End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/imp/ICMS/ICMS90' 

			Select *, @FkBilhete FkBilhete into #icms90
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					CST char(3), -- CST
					pRedBC int, -- Percentual de redu��o da Base de calculo
					vBC numeric(18,2), -- Valor da base de calculo
					pICMS numeric(18,2), -- Aliquota em %
					vICMS numeric(18,2), -- Valor Pago de ICMS
					vCred numeric(18,2) -- Valor do Cr�dito Outorgado/Presumido	
				)

			---------------------------------------------------------------------------------------------
			-- Obtendo forma de pagamento
			Begin Try Drop Table #pag End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/pag' 

			Select *, @FkBilhete FkBilhete into #pag
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					tPag int, -- Forma de pagamento
					vPag numeric(18,2), -- Valor do pagamento
					xPag varchar(80) -- Descri��o do pagamento caso tPag = 99
				)

			Begin Try Drop Table #pagDesc End Try Begin Catch End Catch

			Set @Inicio = 'BPe/infBPe/Card' 

			Select *, @FkBilhete FkBilhete into #pagDesc
			From OpenXml (@PkXml, @Inicio, 2)
			with 
				(
					tpIntegra varchar(80) 'card/tpIntegra', -- Tipo de Integra��o do processo de pagamentocom o sistema de automa��o da empresa
					CNPJ varchar(14) 'card/CNPJ', -- CNPJ da prestadora do cart�o
					tBand int 'card/tBand', -- Bandeira do cart�o
					xBand varchar(20) 'card/xBand' -- Descri��o da bandeira caso tPag = 99
				)

			----------------------------------------------------------------------------------------------
			Exec sp_xml_removedocument @PkXml -- Removendo da mem�ria
			----------------------------------------------------------------------------------------------
			-- Valida��es


			--Fim Valida��es
			----------------------------------------------------------------------------------------------
			-- Apurando ICMS
			Begin Try Drop Table #IcmsAp End Try Begin Catch End Catch

			Select (Coalesce(i00.vICMS, 0) + Coalesce(i20.vICMS, 0) + Coalesce(i90.vICMS, 0)) IcmsTot,
			i00.vBC,
			i00.pICMS, 
			i00.CST into #IcmsAp
			From #icms00 i00
			Left Join #icms20 i20 on (i20.FkBilhete = i00.FkBilhete)
			Left Join #icms90 i90 on (i90.FkBilhete = i00.FkBilhete) 
			----------------------------------------------------------------------------------------------
			-- Cadastro cliente

			If Exists(Select xNome From #InfPassageiro) -- Verificando se a tag foi preenchida
				Begin
					Set @PkCliente = 0

					Select @PkCliente = Coalesce(C.Pk, 0)
					From CadFornecedores C 
					Join #InfPassageiro Cd on ((Case When Coalesce(Cd.CNPJ, '') = '' Then Right('00000000000000' + Cd.CPF, 14) Else Cd.Cnpj End  = C.Cnpj))
		
					If (@PkCliente = 0)
						Begin
							-- Caso n�o exista ir� fazer o cadastro do cliente
							Insert CadFornecedores 
							(CNPJ, TipoInscricao, Nome, Endereco, Numero, Complemento, Bairro, Cidade, UF, Cep, 
							ProdutorRural, InscrEstadual, InscrMunicipal, Telefone, Fax, Email, TipoPrincipal, Emissao, 
							InscrSuframa, FkCidades, ContribuinteICMS)
							Select 
							Case When Coalesce(CNPJ, '') = '' Then 
								Right('00000000000000' + CPF, 14) 
							Else 
								CNPJ 
							End, --CNPJ
							Case When Coalesce(Cd.CNPJ, '') = '' Then 
								2 
							Else 
								1 
							End, --TipoInscricao
							Substring(Cd.xNome, 1, 80), --Nome
							Substring(Cd.xLgr, 1, 50), --Endereco
							Substring(Cd.nro, 1, 10), --Numero
							Substring(Cd.xCpl, 1, 30), --Complemento
							Substring(Cd.xBairro, 1, 25), --Bairro 
							'',--Coalesce(Substring(Cd.xMun, 1, 25), 'A Cadastrar'), --Cidade 
							Coalesce(Substring(Cd.UF, 1, 2), ''), --UF
							Cd.Cep, --Cep
							'N�o', --ProdutorRural
							Case When Coalesce(Cd.IE, '') = '' Then 'ISENTO' Else Substring(Cd.IE, 1, 20) End, --InscrEstadual
							'', --InscrMunicipal 
							Cd.fone, --Telefone
							'', --Fax
							Substring(Cd.email, 1, 50), --Email 
							'N�o', --TipoPrincipal
							'', --Emissao 
							'', --InscrSuframa
							(Select Top 1 Pk From Cidades Where Codigo = Convert(Varchar, Cd.cMun)),
							--ContribuinteIcms
							Case When Coalesce(Cd.IE, '') = '' Then 'N�o' When Cd.IE = 'ISENTO' Then 'N�o' Else 'Sim' End
							From #comp Cd
        
						End
		
				End
			Else
				Begin
					Select top 1 @PkCliente = Pk
					From CadFornecedores
					Where (Nome like '%CONSUMIDOR FINAL%') and
					(InscrEstadual = 'ISENTO')
				End


			If (@Sobrepor = 'Sim')
				Begin
					Delete From RegSaidas
					Where (CodEmpresa = @CodEmpresa) and
					(DataEmissao between @DataInicialP and @DataFinalP) and
					(DocN in (Select nBP From #ide)) and 
					(Modelo in (Select Mod From #ide))
				End
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Inserindo na RegSaidas

			Insert RegSaidas(PkC, FkClientes, CodEmpresa, DataEmissao, DocN, ADocN, Modelo, Tipo, Serie, ValorContabil, BaseCalculo, Icms, OutrasDespesasAcessorias, FretePorConta, Frete, 
			Seguros, Descontos,Cancelamentos, BaseIpi, Ipi, Vp, IcmsFrete, BaseSt, IcmsSt,TotalProdutos, Importado, TipoNota, Emissao, ChaveNfe, TipoTransporte, DataSaida, vPisSt, vCofinsSt, 
			TipoEmissao, TipoCte,  ValorAbatimento, VrTotalFCP, VrTotalFCPST, VrTotalFCPSTRet, FkCidadesOrigem, FkCidadesDestino)
			Select 3, -- FkC Sa�da
			@PkCliente, -- FkClientes
			@CodEmpresa, -- CodEmpresa
			Convert(Date, I.dhEmi), -- Data Emiss�o
			I.nBP, -- DocN
			I.nBP, -- ADocN
			I.Mod, -- Modelo
			(Select Tipo From ModeloNotaFiscal Where (Modelo = Convert(char(2), I.Mod))), -- Tipo de Nota
			I.Serie,
			vb.vBP, -- Valor contabil
			0, --BC ICMS
			0, -- Valor do ICMS
			0, -- Otros D.Acess
			'Emitente', -- Frete por conta
			0, -- Valor do frete
			0, -- Seguros
			vb.vDesconto, -- Desconto 
			0, -- Cancelamentos
			0, -- Base Calculo IPI
			0, -- IPI
			Case When Pg.tPag in(1) Then -- Condi��o de pagamento
				'V'
			Else
				'P'
			End,
			0, -- ICMS Frete
			0, -- BC Cacl ST
			0, -- Icms St
			0, -- Total produtos ser� feito no update
			'S', -- Importado
			0, -- Tipo Nota
			GETDATE(), -- Emiss�o
			@chNfe, -- Chave NFe
			Case -- Tipo de transporte 
			 When I.Modal = 1 Then
					0
				When I.Modal = 3 Then
					3
				When I.Modal = 4 Then
					1
			End, 
			null, -- Data sa�da
			0, -- Vr. Pis ST
			0, -- Vr. Cofins ST
			0, -- Pr�pria
			I.tpBPe, -- Tipo de CTe
			0, -- Valor Abatimento
			0, -- Valor FCP
			0, -- Valor FCP ST
			0, -- Valor FCP ST Ret
			(Select Top 1 Pk From Cidades Where Codigo in (I.cMunIni)), -- FkCidadeOrigem
			(Select Top 1 Pk From Cidades Where Codigo in (I.cMunFim)) -- FkCidadeDestino
			From #ide I
			Left join #emit E on (E.FkBilhete = I.nBP)
			Left Join #InfPassagem P on (P.FkBilhete = I.nBP)
			Left Join #infViagem IV on (IV.FkBilhete = I.nBP)
			Left Join #pag PG on (PG.FkBilhete = I.nBP)
			Left Join #pagDesc PG2 on (PG2.FkBilhete = I.nBP)
			Left Join #valorBPe VB on (VB.FkBilhete = I.nBP)
			Left Join #comp c on (c.FkBilhete = I.nBP)

			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Obtendo informa��es da Nota 

			Set @PkNota = 0
			Set @VP = ''
			Set @Modelo = 0
			Set @DataNota = 0

			Select @PkNota = Pk, 
			@VP = VP,  
			@Modelo = Modelo,
			 @DataNota = DataEmissao
			From RegSaidas
			Where DocN in (Select top 1 nBP From #ide)

			If(@PkNota > 0) 
				Begin
					Set @QtdNfeImportada += 1 -- Contabilizando total de notas importadas
					---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- Inserindo na Produtos Saidas

					Insert ProdutosSaidas(FkRegSaidas, CodEmpresa, FkCadProdutos, NumeroItem, Cfop, Cst, Quantidade, ValorProduto, ValorDesconto, BaseCalculo, BaseCalculoSt, ValorIpi, AliquotaIcms, ValorIcms, 
					Total, ValorFrete, ValorSeguro, ValorOutro, IndicadorTotal,vBCCofins, vBCPis,FkCadUnidade,CentroCusto, FkCfopTipoTributacao, vPisRetido, vCofinsRetido, vCssllRetido, vIrrfRetido, vInssRetido)
					Select Top 1 
					@PkNota, -- FkRegSaidas
					@CodEmpresa, -- CodEmpresa
					C.Pk, -- FkCadProdutos
					1, -- N� do item
					@Pg339, -- CFOP estudar forma de buscar
					Left('0' + Coalesce(Ic.CST, '000'), 3), -- CST 
					1, -- Quantidade
					Case When Cc.tpComp = 01 Then -- Valor do produto
						Cc.vComp
					End,
					vB.vDesconto, -- Desconto
					Ic.vBc, -- Base de C. do ICms
					0, -- Base de C. ST
					0, -- Valor IPi
					Ic.pICMS, -- Aliquota ICMS
					Ic.IcmsTot, -- Valor ICMS
					vB.vBP, -- Total de produtos
					0, -- Frete
					(Select Sum(vComp) From #valorBPeDesc Where tpComp  in (4)),
					(Select Sum(vComp) From #valorBPeDesc Where tpComp not in (1)),
					1, -- Indicator total
					Case When Cc.tpComp = 1 Then -- Valor Base de C. Pis
						Cc.vComp
					End,
					Case When Cc.tpComp = 1 Then -- Valor Base de C. Cofins
						Cc.vComp
					End,
					C.FkCadUnidade, -- FkCadUnidade
					dbo.FCentroCusto(@DataNota, @Pg339, @VP, @CodEmpresa, @Modelo), -- Centro de Custo
					dbo.FTipoTributacao(@Pg339, @PkUsuario), --FkCfopTipoTributacao,
					0, -- Valor Pis Retido
					0, -- Valor Cofins Retido
					0, -- Valor Cssll Retido
					0, -- Valor Irrf Retido
					0 -- Valor Inss Retido
					From CadProdutos C
					Cross Join #valorBPeDesc Cc
					Cross Join #valorBPe vB
					Cross Join #IcmsAp Ic
					Where C.CodigoProduto = @Pg433

					-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- Inserindo na RegSaidasItens
					Insert RegSaidasItens (Fk, Cfop, Aliquota, Exclusao, Icms, IcmsSt, BaseCalculo, BaseSt, Isentas, Outras, Total, CentroCusto, BasePisCofins, FkCfopTipoTributacao)
					Select @PkNota, -- FK
					@Pg339, -- CFOP estudar forma de buscar
					P.AliquotaIcms, -- Aliquota ICMS
					1, -- Exclus�o
					P.ValorIcms, -- Valor do ICMS
					0, -- ICMS ST
					P.ValorProduto, -- Base de Calculo
					0, -- Base St
					0, -- Isentas
					Coalesce(P.ValorOutro, 0), -- Outras
					P.Total, -- Total
					--dbo.FCentroCusto(@DataNota, P.Cfop, @VP, @CodEmpresa, @Modelo), -- Centro de Custo,
					P.Total, -- BasePisCofins
					0, -- CodAntec Tributaria
					dbo.FTipoTributacao(P.Cfop, @PkUsuario) --FkCfopTipoTributacao
					From ProdutosSaidas P
					Where (P.FkRegSaidas = @PkNota)


					-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- Atualizando informa��es da RegSa�das

					Update RegSaidas
					Set BaseCalculo = Ps.BaseCalculo,
					Icms = Ps.ValorIcms,
					OutrasDespesasAcessorias = Ps.ValorOutro,
					TotalProdutos = Ps.ValorProduto
					From ProdutosSaidas Ps
					Where Ps.FkRegSaidas = @PkNota


					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- Caso a nota seja a prazo dever� ser gerado a duplicata e inserido na Controle Clientes
					If (@VP = 'P') or ((@Pg363 = 2) and (@Pg282 = 'P'))
						Begin
							-- Aqui ser� gerado as duplicatas
							Begin Try Drop Table #duplicatas End Try Begin Catch End Catch

							Select 
							Case when @Pg490 = 'Sim' Then
							Right('000000000' + Coalesce(R.DocN, ''), 9) + ' 1/1'
							When @Pg478 = 'Sim' Then
							Right('000000000' + Coalesce(R.DocN, ''), 9) + ' 1/1'
							End nDup,
							Convert(Date, R.DataEmissao + 30) dVenc, 
							R.ValorContabil vDup into #duplicatas
							From RegSaidas R
							Where Pk = @PkNota

							Insert ControleClientes
							(PkC, Fk, FkC, FkClientes, CodEmpresa, Duplicata, Parcela, Serie, DataNotaFiscal, NotaFiscal, Valor, 
							Total, Situacao, Vencimento, Emissao,
							VrIrrf, VrCssllRetido, VrInssRetido, VrPisRetido, VrCofinsRetido, TarifaCobranca)
							Select 9, R.Pk, R.Pkc, R.FkClientes, R.CodEmpresa,
							D.nDup, -- Duplicata 
                            
							--Parcela provis�rio, ser� alterado no cursor abaixo
							1, 
							R.Serie, --Serie
							R.DataEmissao, --DataNotaFiscal
							R.DocN, --NotaFiscal 
							Coalesce(D.vDup, 0), --Valor
							Coalesce(D.vDup, 0), --Total
							'Normal', 
							Case When dbo.FValidaData(D.dVenc) = '1' Then D.dVenc Else @DataInicialP End, --Vencimento
							GETDATE(),
							0, --VrIrrf, 
							0, --VrCssllRetido, 
							0, --VrInssRetido, 
							0, --VrPisRetido, 
							0,  --VrCofinsRetido
							0 --TarifaBancaria
							From RegSaidas R
							Cross join #duplicatas D
							Where (R.Pk = @PkNota) and
							(R.ValorContabil > 0) and
							R.Pk not in (Select Fk From ControleClientes Where CodEmpresa = @CodEmpresa) and
							(R.VP = 'P')
	
						End

					-- Caso O BPe seja a prazo e n�o tenha sido gerado deuplicatas ser� alterado para a vista	
					Update RegSaidas
					Set VP = 'V'
					From RegSaidas R
					Left join ControleClientes C on (C.Fk = R.Pk) and (C.Fkc = R.Pkc)
					Where (R.Pk = @PkNota) and
					(C.Fk is null) and 
					(R.Vp = 'P') and
					(R.CodEmpresa = @CodEmpresa) and
					(R.DataEmissao Between @DataInicialP and @DataFinalP)

				End -- Fim do If @PkNota > 0

			Fetch next from CrNomeArquivo Into @NomeAtual
		End

	Close CrNomeArquivo
	Deallocate CrNomeArquivo

	-- Fim do cursor que realizou as importa��es
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	If @QtdRegistrosAfetados is null Set @QtdRegistrosAfetados = 0

	Set @Texto = 
	'Per�odo: ' + Convert(Varchar, @DataInicialP, 103) + ' a ' + Convert(Varchar, @DataFinalP, 103) + '. ' +
	'Sobrepor: ' + @Sobrepor + '. ' +
	'Tipo Importa��o: ' + Case @TipoImportacao 
		When 1 Then 'Todas as NF-es do diret�rio escolhido na tela Fiscal/Importa��o/NF-e' 
		when 2 then 'Somente a NF-e escolhida na tela Fiscal/Importa��o/NF-e' 
		when 3 then 'Todas as NF-e(s) Selecionadas no periodo e na tela Fiscal/Importa��o/NF-e' 
		when 4 then 'NF-e Baixada e importada automaticamente' End + '. ' + 'Caminho Completo: ' + @CaminhoCompleto + '.'

	Insert LogAuditoria
	(DataHora, DataHoraFinal, FkUsuario, CodEmpresa, Acao, Modulo, Descricao, QtdRegistrosAfetados)
	Values (@DataHoraInicial, getdate(), @PkUsuario, @CodEmpresa, 'Importa��o', 'Importa��o do Nfe.', @Texto, @QtdRegistrosAfetados)

End Try
Begin Catch

	Declare @ErrorMessage NVARCHAR(4000)

	Set @ErrorMessage = char(13) + 
	'- MSGE: ' + Coalesce(ERROR_MESSAGE(), '') + char(13) +
	'- LINHA: ' + Convert(Varchar, Coalesce(ERROR_LINE(), 0)) + char(13) +
	'- PC/TG: ' + Coalesce(ERROR_PROCEDURE(), '- N�o foi em trigger ou procedure') + char(13) +
	'- SEVERITY: ' + Convert(Varchar, Coalesce(ERROR_SEVERITY(), 0)) + char(13) +
	'- STATE: ' + Convert(Varchar, Coalesce(ERROR_STATE(), 0)) + char(13) 

	Raiserror(@ErrorMessage, 16, 1)

End Catch


-- Finalizou com sucesso!
Insert MSistema
(FkUsuario, Descricao, Texto, Abort, TipoValidacao)
Select @PkUsuario, 'Procedimento executado com sucesso! Foram importadas: ' + Convert(Varchar, @QtdNfeImportada) + ' NF-e(s).', '', 'Ok', 6 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Select * From MSistema Where FkUsuario = 2528