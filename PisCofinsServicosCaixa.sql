Declare @CodEmpresa int = 30546, @DataInicialP datetime = '2020-02-01', @DataFinalP datetime = '2020-02-29', @PkEscritorio int = 2932, @FkCadEmpresaScp int = null
 
Declare @RegimeApuracaoPeriodoAnterior int, @DataInicialMesAnterior datetime, @DataFinalMesAnterior datetime, @PkTributacaoFederalCorrente int, @DataTributacao datetime,
@DataTributacaoAnterior datetime, @RegimeApuracaoAnterior int  

Set @DataInicialMesAnterior = DateAdd(mm, -1, @DataInicialP)
Set @DataFinalMesAnterior = dbo.FDataFinalMes(@DataInicialMesAnterior)

Select Top 1 @RegimeApuracaoPeriodoAnterior = T.RegimeApuracao
From TributacaoFederal T 
Where (T.CodEmpresa = @CodEmpresa) and 
(T.DataInicial <= @DataFinalMesAnterior) and
(T.FkCadEmpresaScp is null)
Order By T.DataInicial Desc

Select Top 1 @PkTributacaoFederalCorrente = T.Pk, @DataTributacao = T.DataInicial
From TributacaoFederal T 
Where (T.CodEmpresa = @CodEmpresa) and 
(T.DataInicial <= @DataFinalP) and
(T.FkCadEmpresaScp is null)
Order By T.DataInicial Desc

--Select @PkTributacaoFederalCorrente 

Select Top 1 @RegimeApuracaoAnterior = T.RegimeApuracao, @DataTributacaoAnterior = T.DataInicial
From TributacaoFederal T 
Where (T.CodEmpresa = @CodEmpresa) and 
(T.DataInicial <= @DataFinalP) and
(T.FkCadEmpresaScp is null) and
(T.Pk not in (@PkTributacaoFederalCorrente))
Order By T.DataInicial Desc

Begin Try Drop Table #ApuracaoDuplicatasRegimeCaixa End Try Begin Catch End Catch
Create Table #ApuracaoDuplicatasRegimeCaixa(PkDuplicata int, FkRegPrestServicos int, FkC int, BaseCalculoDuplicata numeric(18,2), TotalDuplicata numeric(18,2), 
VrIrrfRetido numeric(18,2) Default 0, VrInssRetido numeric(18,2) Default 0, VrIssRetido numeric(18,2) Default 0, VrTotalRetencoes numeric(18, 2) Default 0) 

Begin Try Drop Table #ApuracaoDebito End Try Begin Catch End Catch
Create Table #ApuracaoDebito (Fkc Int, TipoContribuicao tinyint, TipoDebito Int, ValorContabil Numeric(18, 2), 
BaseCalculo Numeric(18, 2), Aliquota Numeric(18, 4), Valor Numeric(18, 2), FkCadEmpresaScp Int)

-- Busca todas duplicatas pagas no contábil
Insert #ApuracaoDuplicatasRegimeCaixa(PkDuplicata, FkRegPrestServicos, FkC, BaseCalculoDuplicata, TotalDuplicata)
Select Cc.Pk, Cc.Fk, Cc.Fkc, Sum(Cc.Valor), Sum(Cc.Total)
From CadEmpresa C
Inner Join ControleClientes Cc on (C.CodEmpresa = Cc.CodEmpresa)
Where (C.CodigoMatriz = @CodEmpresa) and
(Cc.DataPagamento Between @DataInicialP and @DataFinalP) and
(Cc.DataNotaFiscal Not Between @DataTributacaoAnterior and @DataTributacao)
Group by Cc.Pk, Cc.Fk, Cc.Fkc

Declare @PkDuplicataCr int, @FkRegPrestServicosCr int, @BaseCalculoDuplicataCr numeric(18,2), @TotalDuplicataCr numeric(18,2), @VrIRRFCr numeric(18,2), 
@VrISSRetidoCr numeric(18,2), @VrINSSRetidoCr numeric(18,2), @AliquotaCr numeric(18, 4), @TotalCssllIrrfInssCr numeric(18,2), @BasePisCofinsCr numeric(18,2)

Declare CrApuraDuplicatasPagasRegimeCaixa Cursor Local static for	
Select PkDuplicata, FkRegPrestServicos, BaseCalculoDuplicata, TotalDuplicata
From #ApuracaoDuplicatasRegimeCaixa
Open CrApuraDuplicatasPagasRegimeCaixa 
Fetch Next From CrApuraDuplicatasPagasRegimeCaixa into @PkDuplicataCr, @FkRegPrestServicosCr, @BaseCalculoDuplicataCr, @TotalDuplicataCr
While (@@FETCH_STATUS = 0)
	Begin
		Select @VrIRRFCr = R.Irrf,
		@VrISSRetidoCr = Case When (R.Retencao = 'Sim') Then Coalesce(R.Issqn, 0) Else 0 End,
		@VrINSSRetidoCr = Coalesce(R.Inss, 0),
		@BasePisCofinsCr = R.ValorContabil
		From RegPrestServicos R
		Where (R.CodEmpresa = @CodEmpresa) and
		(R.Pk = @FkRegPrestServicosCr)

		Select Top 1 @AliquotaCr = R.Aliquota
		From RegPrestServicosItens R
		Where (R.Fk = @FkRegPrestServicosCr)

		Select @TotalCssllIrrfInssCr = (Cc.VrCofinsRetido + Cc.VrCssllRetido + CC.VrPisRetido)
		From ControleClientes Cc
		Where (Cc.CodEmpresa = @CodEmpresa) and
		(Cc.Pk = @PkDuplicataCr)

		 --Calculando IRRF se for maior que zero
		If (@VrIRRFCr > 0)
			Begin
				Update #ApuracaoDuplicatasRegimeCaixa
				--Set VrIrrfRetido = ((@BaseCalculoDuplicataCr * 1.5) / 100)
				Set VrIrrfRetido = ((@BasePisCofinsCr * 1.5) / 100)
				Where (PkDuplicata = @PkDuplicataCr)
			End

		-- Calculando ISS se for maior que zero
		If (@VrISSRetidoCr > 0)
			Begin
				Update #ApuracaoDuplicatasRegimeCaixa
				Set VrIssRetido = ((@BasePisCofinsCr * @AliquotaCr) / 100)
				Where (PkDuplicata = @PkDuplicataCr)
			End

		-- Calculando INSS se for maior que zero
		If (@VrINSSRetidoCr > 0)
			Begin
				Update #ApuracaoDuplicatasRegimeCaixa
				Set VrInssRetido = ((BaseCalculoDuplicata * 11) / 100)
				Where (PkDuplicata = @PkDuplicataCr)
			End

		-- Calculando Total das Retençõees de Pis, Cofins e CSSLL se for maior que zero
		If (@TotalCssllIrrfInssCr > 0)
			Begin
				Update #ApuracaoDuplicatasRegimeCaixa
				Set VrTotalRetencoes = @TotalCssllIrrfInssCr
				Where (PkDuplicata = @PkDuplicataCr)
			End

			-- Pis
			Insert #ApuracaoDebito(Fkc, TipoContribuicao, TipoDebito, ValorContabil, BaseCalculo, Aliquota, Valor)
			Select R.Pkc, --Fkc
			1, --TipoContribuicao Pis
			Ri.TipoDebitoCreditoPis, --TipoDebito
			Sum(Ar.TotalDuplicata + Ar.VrInssRetido + Ar.VrIrrfRetido + Ar.VrIssRetido + Ar.VrTotalRetencoes), --ValorContabil
			Sum(Ar.TotalDuplicata + Ar.VrInssRetido + Ar.VrIrrfRetido + Ar.VrIssRetido + Ar.VrTotalRetencoes), --BaseCalculo
			Ri.pPis, --Aliquota
			Round((Sum(Ar.TotalDuplicata + Ar.VrInssRetido + Ar.VrIrrfRetido + Ar.VrIssRetido + Ar.VrTotalRetencoes) * Ri.pPis / 100), 2)--Valor
			From RegPrestServicos R
			Join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
			Join #ApuracaoDuplicatasRegimeCaixa Ar on (Ar.FkRegPrestServicos = R.Pk)
			Where (R.Pk = @FkRegPrestServicosCr) and 
			Coalesce(Ri.TipoDebitoCreditoPis, 0) > 0
			Group by Ri.TipoDebitoCreditoPis, Ri.pPis, R.Pkc

			-- Cofins
			Insert #ApuracaoDebito(Fkc, TipoContribuicao, TipoDebito, ValorContabil, BaseCalculo, Aliquota, Valor)
			Select R.Pkc, --Fkc
			2, --TipoContribuicao Cofins
			Ri.TipoDebitoCreditoCofins, --TipoDebito
			Sum(Ar.TotalDuplicata + Ar.VrInssRetido + Ar.VrIrrfRetido + Ar.VrIssRetido + Ar.VrTotalRetencoes), --ValorContabil
			Sum(Ar.TotalDuplicata + Ar.VrInssRetido + Ar.VrIrrfRetido + Ar.VrIssRetido + Ar.VrTotalRetencoes), --BaseCalculo
			Ri.pCofins, --Aliquota
			Round((Sum(Ar.TotalDuplicata + Ar.VrInssRetido + Ar.VrIrrfRetido + Ar.VrIssRetido + Ar.VrTotalRetencoes) * Ri.pCofins / 100), 2)--Valor
			From RegPrestServicos R
			Join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
			Join #ApuracaoDuplicatasRegimeCaixa Ar on (Ar.FkRegPrestServicos = R.Pk)
			Where (R.Pk = @FkRegPrestServicosCr) and 
			Coalesce(Ri.TipoDebitoCreditoCofins, 0) > 0
			Group by Ri.TipoDebitoCreditoCofins, Ri.pCofins, R.Pkc

		Fetch next from CrApuraDuplicatasPagasRegimeCaixa into @PkDuplicataCr, @FkRegPrestServicosCr, @BaseCalculoDuplicataCr, @TotalDuplicataCr
	End

Close CrApuraDuplicatasPagasRegimeCaixa
Deallocate CrApuraDuplicatasPagasRegimeCaixa


Select Sum(VrTotalRetencoes)--(TotalDuplicata + VrInssRetido + VrIrrfRetido + VrIssRetido + VrTotalRetencoes) TotalFinal, *
From #ApuracaoDuplicatasRegimeCaixa

Select Sum(BaseCalculo)
From #ApuracaoDebito
Where (TipoContribuicao = 1)

--2.248.269,22
--2.214.472,92