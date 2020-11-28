----------------------------------------------------------------------------------------------------------------------------------------
--Criada em 23/04/2018 por Aaron Alves
--Tem por finalidade gerar o arquivo a ser enviado para sistema Reinf
--R-2060 - Contribui��o Previdenci�ria sobre a Receita Bruta - CPRB
----------------------------------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[PcGeraReinfR2060] @PkReinf int, @DataInicialP Datetime, @DataFinalP Datetime, @PkUsuario Int, @Sistema int = 1,
@TipoOrigem Varchar(50) = 'Manual'
as
-----------------------------------------------------------------------------------------------------------------------------------------
Declare @Acao Varchar(30), @ArquivoXml xml, @PerApur Varchar(7), @TipoAmbiente Varchar(1), @procEmi Varchar(1), @VersaoReinf Varchar(20), @PkEscritorio Int,
@ReceitaTotal Numeric(18, 2), @ReceitaComBeneficio Numeric(18, 2), @IndiceRateioIncentivado Numeric(18, 6), @CodEmpresa Int, @indRetif int,
@nrRecibo Varchar(52), @FkCadEmpresaScp Int = NULL, @Data DateTime, @Fk int, @Fkc int, @Origem Varchar(100), @FkCadTipoArquivoReinf int,
@DataInicialValidade DateTime, @DataFinalValidade DateTime, @PkReinfAnterior int, @CodigoTipoArquivoReinf Varchar(10)

-----------------------------------------------------------------------------------------------------------------------------------------
Select @Data = E.Data, @Fk = E.Fk, @Fkc = E.Fkc, @CodEmpresa = E.CodEmpresa,  @Origem = E.Origem, @FkCadTipoArquivoReinf = E.FkCadTipoArquivoReinf,
@DataInicialValidade = E.DataInicialValidade, @DataFinalValidade = E.DataFinalValidade, @TipoAmbiente = E.TipoAmbiente
From Reinf E
Where (E.Pk = @PkReinf)

Set @Acao = dbo.FReinfItens(@PkReinf, 2)

Set @CodigoTipoArquivoReinf = dbo.FCodigoCadTipoArquivoReinf (@FkCadTipoArquivoReinf)

-------------------------------------------------------------------
If (@Acao = '2') --Altera��o
  Begin
    Set @indRetif = 2
    Set @PkReinfAnterior = dbo.FReinfUltimoPkProcessado (@CodEmpresa, @Fk, @Fkc, 'R-2060', @TipoAmbiente, null) 

    Set @nrRecibo = dbo.FNumeroReciboProcessamentoReinf (@PkReinfAnterior)
  End
Else --Inclus�o
  Begin
    Set @indRetif = 1
    Set @nrRecibo = null
  End

-----------------------------------------------------------------------------------------------------------------------------------------
Begin Try
Set NoCount on

Set @PkEscritorio = dbo.FPkEscritorioUsuarios(@PkUsuario)
Set @PerApur = Left(Replace(Convert(Varchar, @DataInicialP, 102), '.', '-'), 7)
Set @procEmi = 1

Select @VersaoReinf = VersaoeSocial
From dbo.TFornecedorSoftware ()

Select @ReceitaTotal = ReceitaTotal,
@ReceitaComBeneficio = ReceitaComBeneficio,
@IndiceRateioIncentivado = IndiceRateioIncentivado
From TCalculaGpsFaturamento(@CodEmpresa, @DataInicialP, @DataFinalP, @FkCadEmpresaScp)

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- I N � C I O   D A S   R E G R A S   D E   V A L I D A � � O
-------------------------------------------------------------------------------------------------------------------------------------------------------------
Delete ReinfMSistema
Where (FkReinf = @PkReinf)
 
Delete MSistema
Where (FkUsuario = @PkUsuario)

-------------------------------------------------------------------------------------------------------------------------------------------------------------
--REGRA_EXISTE_INFO_EMPREGADOR
Exec PcRegraExisteInfoContribuinte @PkReinf, @CodEmpresa, @CodigoTipoArquivoReinf

-------------------------------------------------------------------------------------------------------------------------------------------------------------
--Insert ReinfMSistema
--(FkReinf, Abort, Descricao, Texto)
--Select @PkReinf, 'Sim', 
--Descricao
--'Cadastre em Empresas/Outros e-Social, o tipo 10 - Obrigatoriedade de entrega do e-Social no ambiente de produ��o para a empresa: ' + 
--C.RazSoc  + ' - ' + Convert(Varchar, C.CodCliente), 
--Texto
--'Opera��o cancelada.'

-----------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- F I M   D A S   R E G R A S   D E   V A L I D A � � O
-------------------------------------------------------------------------------------------------------------------------------------------------------------
If(@TipoOrigem In('Autom�tico', 'FiltroCorrente'))
  Begin
    If dbo.FAbortReinf(@PkReinf) = 'Sim' Return 
  End
Else
  Begin
    Exec PcInsertMSistemaReinfParaMSistema @PkReinf, @PkUsuario
    If dbo.FAbort(@PkUsuario) = 'Sim' Return
  End

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--Fim da valida��o definitiva...
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------
set @ArquivoXml = 
(
  Select
  --3 Id - Identifica��o �nica do evento.
  dbo.FIdReinf (C.CodEmpresa, @Data) [@id],
  -----------------------------------------------------------------------------------
  --4 ideEvento - Informa��es de Identifica��o do Evento
  --N�vel 3
  ---------------------------------------
  (
    Select
    --5 indRetif - Informe [1] para arquivo original ou [2] para arquivo de retifica��o.
    @indRetif indRetif,
    --6 nrRecibo - Preencher com o n�mero do recibo do arquivo a ser retificado.
    @nrRecibo nrRecibo,
    --7 perApur - Informar o ano/m�s de refer�ncia das informa��es no formato AAAA-MM.
    @PerApur perApur,
    --8 tpAmb - Identifica��o do ambiente:
    @TipoAmbiente tpAmb,
    --9 procEmi - Processo de emiss�o do evento:
    @procEmi procEmi,
    --10 verProc - Vers�o do process
    @VersaoReinf verProc
    For Xml Path(''), Elements, Root('ideEvento'), Type
  ), 
  --------------------------------------------------------------------------------------
  --11 ideContri - Informa��es de identifica��o do contribuinte
  --N�vel 3
  ---------------------------
  (
    Select
    --12 tpInsc - Preencher com o c�digo correspondente ao tipo de inscri��o - Valida��o: Deve ser igual a [1] (CNPJ) ou [2] (CPF)
    dbo.FtpInscReinf(C.CodigoMatriz) tpInsc,
    --13 nrInsc - Informar o n�mero de inscri��o do contribuinte de acordo com o tipo de inscri��o indicado no campo {tpInsc}.
    dbo.FCnpjReinf(C.CodigoMatriz) nrInsc
    For Xml Path(''), Elements, Root('ideContri'), Type
  ),
  --------------------------------------------------------------------------------------
  --14 infoCPRB - Informa��o da contribui��o previdenci�ria sobre a receita bruta
  --N�vel 3
  -----------------------
  (
    Select
    ------------------------------------------------------------------------------------
    --15 ideEstab - Registro que identifica o estabelecimento que auferiu a receita bruta
    --N�vel 4
    ------------------
    (
      Select
      --16 tpInscEstab - Preencher com o c�digo correspondente ao tipo de inscri��o - Valida��o: Deve ser igual a [1] (CNPJ) ou [4] CNO
      Case When C.TipoInscricao = 'CNPJ' Then 1 Else 2 End tpInscEstab,
      --17 nrInscEstab - Informar o n�mero de inscri��o do estabelecimento pertencente ao contribuinte declarante, de acordo com o tipo de inscri��o indicado no campo {tpInscEstab}. 
      C.Cnpj nrInscEstab,
      --18 vlrRecBrutaTotal - Valor da Receita Bruta Total do Estabelecimento no Per�odo.
      --dbo.FPontoStrVirgula(Sum(R.ReceitaBrutaTotal)) vlrRecBrutaTotal,
      dbo.FPontoStrVirgula(R.ReceitaBrutaTotal) vlrRecBrutaTotal,
      --19 vlrCPApurTotal - Valor total da Contribui��o Previdenci�ria sobre Receita Bruta apurada pelo Estabelecimento no per�odo. 
      dbo.FPontoStrVirgula(Sum(Coalesce(R.ValorContribuicao, 0))) vlrCPApurTotal,
      --20 vlrCPRBSuspTotal - Valor da Contribui��o Previdenci�ria com exigibilidade suspensa.
      null vlrCPRBSuspTotal,
      ----------------------------------------------------------------------------------------------
      --21 tipoCod - Registro que apresenta o valor total da receita por tipo de c�digo de atividade
      --N�vel 5
      --------------------------------
      (
        Select
        --22 codAtivEcon - C�digo indicador correspondente � atividade comercial, produto ou servi�o sujeito a incid�ncia da Contribui��o Previdenci�ria sobre a Receita Bruta, conforme Tabela 09. 
        Right(Ca2.Codigo, 8) codAtivEcon,
        --23 vlrRecBrutaAtiv - Preencher com o valor total da receita da atividade. Valida��o: N�o pode ser maior que {vlrRecBrutaTotal}.
        dbo.FPontoStrVirgula(Sum(Coalesce(R2.ReceitaBrutaComBeneficio, 0))) vlrRecBrutaAtiv,
        --24 vlrExcRecBruta - Preencher com o Valor total das Exclus�es da Receita Bruta previstas em lei. 
        dbo.FPontoStrVirgula(Sum(Coalesce(R2.ValorExclusoes, 0))) vlrExcRecBruta,
        --25 vlrAdicRecBruta - Preencher com o Valor total das Adi��es da Receita Bruta previstas em lei.
        dbo.FPontoStrVirgula(Sum(0.00)) vlrAdicRecBruta, --Provis�rio - Temos que criar uma Fun��o
        --26 vlrBcCPRB - Preencher com o Valor da Base de C�lculo da Contribui��o Previdenci�ria sobre a Receita Bruta. 
        dbo.FPontoStrVirgula(Sum(Coalesce(R2.BaseCalculo, 0))) vlrBcCPRB,
        --27 vlrCPRBapur - Preencher com o Valor Contribui��o Previdenci�ria sobre a Receita Bruta.
        dbo.FPontoStrVirgula(Sum(Coalesce(R2.ValorContribuicao, 0))) vlrCPRBapur,
        ------------------------------------------------------------------------------------------------------------
        --28 tipoAjuste - Registro a ser preenchido caso a pessoa jur�dica tenha de proceder a ajustes da contribui��o apurada no per�odo, decorrentes da legisla��o tribut�ria da contribui��o, de estorno ou de outras situa��es.
        --N�vel 6
        --------------------- 
        Case When R2.ValorExclusoes > 0 Then
        (
           Select 
          --29 tpAjuste - Preencher com o c�digo correspondente ao tipo de ajuste - 0- Ajuste de redu��o; 1- Ajuste de acr�scimo - Valores V�lidos: 0,1
          Convert(Varchar, AR.TipoAjuste) tpAjuste,
          --30 codAjuste - Preencher com o c�digo de ajuste:
          Convert(Varchar,AR.CodAjusteReinf) codAjuste,
          --31 vlrAjuste - 
          dbo.FPontoStrVirgula(AR.ValorAjuste) vlrAjuste,
          --32 descAjuste - Descri��o resumida do ajuste
          AR.DescricaoAjuste descAjuste,
          --33 dtAjuste - Informar o m�s/ano (formato AAAA-MM) de refer�ncia do ajuste
          dbo.FStrDataAaaaMm(R.DataInicial, '-') dtAjuste
          From RegApContrPrevidenciariaAjustesReinf AR
          join RegApContrPrevidenciaria R on (R.Pk = AR.FkRegApContrPrevidenciaria)
          Where R.CodEmpresa = @CodEmpresa and
          (R2.Pk = AR.FkRegApContrPrevidenciaria) and
          (R.DataInicial between @DataInicialP and @DataFinalP)  and
          (AR.FkRegApContrPrevidenciaria = R.Pk) and
          (AR.ValorAjuste > 0)
          --------------
          For Xml Path('tipoAjuste'), Elements, Type
        )
        End, --Fim do N�vel 6
        -----------------------------------------------------------------------------------------------------      
        --Select * From RegApContrPrevidenciariaConsolidacaoAjustes 
        --34 infoProc - Informa��es de processos relacionados a Suspens�o da CPRB.
        --N�vel 6
        ---------------------------------
        Case When P2.NumeroProcesso is not null Then 
          ( --Case Adicionado por Everton em 11/02/2019, estava causando erro na entrega.
          Select
          --35 tpProc - Preencher com o c�digo correspondente ao tipo de processo - 1 - Administrativo; 2 - Judicial. Valores V�lidos: 1, 2.
          0 tpProc,
          --36 nrProc - Informar o n�mero do processo administrativo/judicial. - Valida��o: Deve ser um n�mero de processo administrativo ou judicial v�lido e existente na Tabela de Processos.
          '' nrProc,
          --37 codSusp - C�digo do Indicativo da Suspens�o, atribu�do pelo contribuinte. 
          0 codSusp,
          --38 vlrCPRBSusp - Valor da Contribui��o Previdenci�ria com exigibilidade suspensa.
          0 vlrCPRBSusp
         
          For Xml Path(''), Elements, Root('infoProc'), Type
          ) 
          Else '' End 
          --Fim do N�vel 6
        --------------------------------------
        From RegApContrPrevidenciaria R2 
        Join CadCodAtividadesContrPrevidenciaria Ca2 on (R2.FkCadCodAtividadesContrPrevidenciaria = Ca2.Pk)
        left Join RegApContrPrevidenciariaProcesso P2 on (R2.Pk = P2.FkRegApContrPrevidenciaria)
        ------
        Where (R2.CodEmpresa = @CodEmpresa) and 
        (R2.DataInicial between @DataInicialP and @DataFinalP) and
        (Coalesce(R2.FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is NULL Then '' Else @FkCadEmpresaScp End)
        ------
        Group By Ca2.Codigo, P2.NumeroProcesso, R2.ValorExclusoes, R2.Pk 
        --Everton 11/02/2019, Retirada de R2.Pk, pois estava "desagregando" Ca2.Codigo, Adicionado P2.NumeroProcesso para implementa��o futura
        ---------------------------------------
        For Xml Path('tipoCod'), Elements, Type
      ) --Fim do N�vel 5
      ---------------------------------------
      From RegApContrPrevidenciaria R 
      ------
      Where (R.CodEmpresa = @CodEmpresa) and 
      (R.DataInicial between @DataInicialP and @DataFinalP) and
      (Coalesce(R.FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is NULL Then '' Else @FkCadEmpresaScp End)
      Group by R.ReceitaBrutaTotal
      For Xml Path(''), Elements, Root('ideEstab'), Type
    )--Fim do N�vel 4
    --------------------------------------
  For Xml Path(''), Elements, Root('infoCPRB'), Type
) --Fim do N�vel 3
------
From CadEmpresa C
Where (C.CodEmpresa = @CodEmpresa)
------
For Xml Path('evtCPRB'), Elements, Root('Reinf'), Type
)

-------------------------------------------------------------------------------------------------------------------------------------------------------
--Exec PcAssinaReinf @PkReinf, @ArquivoXml, @PkUsuario, @Sistema, @TipoOrigem
Select @ArquivoXml

End Try
-------------------------------------------------------------------------------------------------------------------------------------------------------
Begin Catch
  DECLARE @ErrorMessage NVARCHAR(4000)

  Set @ErrorMessage = char(13) + 
  '- MSGE: ' + Coalesce(ERROR_MESSAGE(), '') + char(13) +
  '- LINHA: ' + Convert(Varchar, Coalesce(ERROR_LINE(), 0)) + char(13) +
  '- PC/TG: ' + Coalesce(ERROR_PROCEDURE(), '- N�o foi em trigger ou procedure') + char(13) +
  '- SEVERITY: ' + Convert(Varchar, Coalesce(ERROR_SEVERITY(), 0)) + char(13) +
  '- STATE: ' + Convert(Varchar, Coalesce(ERROR_STATE(), 0)) + char(13) 

  Raiserror(@ErrorMessage, 16, 1)
  
  RollBack Transaction
End Catch

---------------------------------------------------------------------------------------------------------------------------------------------------------
--dbo.PcGeraReinfR2060 @PkUsuario = 2528, @CodEmpresa = 21344, @DataInicialP = '2019-01-01', @DataFinalP = '2019-01-31' , @indRetif = 1, @nrRecibo = '0123456789'
--Exec PcAtualizaTodasProcedures 'PcGeraReinfR2060' 
---------------------------------------------------------------------------------------------------------------------------------------------------------