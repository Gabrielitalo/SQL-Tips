declare @BaseCalculoVendas numeric(18,2), @CodEmpresa int = 2, @DataInicialT datetime = '2019-03-01', @DataFinal datetime = '2019-03-31', @PkEscritorio int = 1, @TipoTributacao Varchar(30), @RegimeApuracao int,
@DataInicialTributacao DateTime, @TodasContabil varchar(max)

Select Top 1 @TipoTributacao = T.TipoTributacao, @RegimeApuracao = RegimeApuracao
From TributacaoFederal T 
Where  (T.CodEmpresa = @CodEmpresa) and 
(T.DataInicial <= @DataFinal)
Order by T.DataInicial Desc

Select Top 1 @DataInicialTributacao = T.DataInicial
From TributacaoFederal T 
Inner Join CodImpostos C On (C.Pk = T.FkCodRecIrpj)
Where  (T.CodEmpresa = @CodEmpresa) and 
(T.DataInicial <= @DataFinal) 
Order by T.DataInicial Desc


print(@RegimeApuracao)
print(@TipoTributacao)
print(@DataInicialTributacao)

Select @BaseCalculoVendas = Coalesce(Sum(Ri.Total - Ri.IcmsSt), 0)
From RegSaidas R 
Inner Join RegSaidasItens Ri on (Ri.Fk = R.Pk)
Inner Join Cfop C on (C.Cfop = Ri.Cfop)
inner join CfopTipoTributacao Ctt on (Ctt.Pk = Ri.FkCfopTipoTributacao)
inner join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadEmpresa Ce on (Ce.CodEmpresa = R.CodEmpresa)
Where (Ce.CodigoMatriz = @CodEmpresa) and 
(R.TipoNota not in(2, 3, 4, 5, 6, 7)) and
(R.DataEmissao Between @DataInicialT and @DataFinal) and (R.DataEmissao >= @DataInicialTributacao) and
(Ct.SomaBaseIrpjCsll = 'Sim') and
Vp = (Case When @RegimeApuracao = 2 Then 'V' Else Vp End) and
(C.FkEscritorio = @PkEscritorio) 
print(@BaseCalculoVendas)

----Implementação Regime Caixa
If(@RegimeApuracao = 2)
  Begin
    Select Cc.NotaFiscal, CC.Total, Ri.Cfop, Cc.DataPagamento
    From RegSaidas R 
    Inner Join RegSaidasItens Ri on (Ri.Fk = R.Pk)
    Inner Join ControleClientes Cc on (Cc.Fk = R.Pk) and (Cc.Fkc = R.Pkc)
    Inner Join Cfop C on (C.Cfop = Ri.Cfop)
    inner join CfopTipoTributacao Ctt on (Ctt.Pk = Ri.FkCfopTipoTributacao)
    inner join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
    Inner Join CadEmpresa Ce on (Ce.CodEmpresa = R.CodEmpresa)
    Where (Ce.CodigoMatriz = @CodEmpresa) and 
    (R.TipoNota in(0,1,8)) and
    (Cc.DataPagamento Between @DataInicialT and @DataFinal) and (R.DataEmissao >= @DataInicialTributacao) and
    (Ct.SomaBaseIrpjCsll = 'Sim') and
    (Vp = 'P') and
    (C.FkEscritorio = @PkEscritorio) 
		order by Cc.NotaFiscal
  End
	print(@TodasContabil)
	

	Select Cc.NotaFiscal, 
	CC.Total,
	Cc.DataPagamento
	From ControleClientes CC
	Where CodEmpresa = 2 and 
	DataPagamento between '2019-03-01' and '2019-03-31'


	-- Este script tem por função saber quais notas foram utilizadas para calcular o imposto de renda
	-- Será usado até os relatórios ficarem prontos

-- Criado por Gabriel em 24/04/2019