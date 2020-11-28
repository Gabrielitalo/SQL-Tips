Declare @CodEmpresa int = 21344, @DataInicialP datetime = '2019-02-01', @DataFinalP datetime = '2019-02-28'
Declare @DevolucoesPorCfopTipo Table (CodigoSped int, Total numeric(18,2))
--Select *
--From CfopTipo
--Where Pk = 25

--select *
--from CfopTipoTributacao
--Where FkCfop = 7101

--Insert @DevolucoesPorCfopTipo
Select Cpi.FkCadCodAtividadesContrPrevidenciaria,P.Total
From CadEmpresa Ce
inner join RegSaidas R on (Ce.CodEmpresa = R.CodEmpresa)
Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
Inner Join Cfop C on (C.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Where (Ce.CodigoMatriz = @CodEmpresa) and 
(Ce.FkEscritorio = 1) and
(R.DataEmissao Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in(2, 3, 4, 5)) and
(C.Cfop between 5000 and 7200) and
(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) And
(Ct.SomaReceitaBrutaTotal = 'Sim') and
(C.FkEscritorio = 1)

Select Cc.Pk, -- Pk do Codigo do Sped
Cc.Codigo, -- Código do Sped
PS.Total, -- Devolução
SUM(Coalesce(Ps.ValorIpi, 0)), -- Ipi referente a saída
SUM(Coalesce(Ps.IcmsSt, 0)),  -- IcmsSt referente a saída
SUM(Coalesce(Ps.ValorOutro, 0)) -- ValorOutro referente a saída
from CadEmpresa C
Join RegSaidas R on (R.CodEmpresa = C.CodEmpresa)
Join ProdutosSaidas PS on (PS.FkRegSaidas = R.Pk)
Join Cfop Cf on (Cf.Cfop = Ps.Cfop)
Join CfopTipoTributacao Ctt on (Ctt.Pk = Ps.FkCfopTipoTributacao)
Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Join CadProdutos Cp on (Cp.Pk = PS.FkCadProdutos)
Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and 
(R.DataSaida between @DataInicialP and @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Ct.SomaReceitaBrutaComBeneficio = 'Sim') and
(Cf.FkEscritorio = 1) and 
(C.FkEscritorio = 1) and 
(R.TipoNota not in(2, 3, 4, 5))  
group by Cc.Pk, Cc.Codigo, PS.Total

--If Exists(Select CodigoSped From @DevolucoesPorCfopTipo)
--	Begin
--		Update RegApContrPrevidenciaria
--		Set ValorExclusoes = Dv.Total,
--		BaseCalculo = (ReceitaBrutaComBeneficio - Dv.Total),
--		AliquotaContribuicao = 0,
--		ValorContribuicao = 0
--		From @DevolucoesPorCfopTipo Dv
--		Where Dv.CodigoSped = FkCadCodAtividadesContrPrevidenciaria
--	End

--Select *
--From RegApContrPrevidenciaria R
--join @AjustesReinf AR on (AR.pk = R.FkCadCodAtividadesContrPrevidenciaria)
--Where (CodEmpresa = @CodEmpresa) and
--(DataInicial between @DataInicialP and @DataFinalP) and 
--(R.ValorExclusoes > 0) and
--(AR.ValorDeExclusao is not null)
--Group by R.Pk

--select *
--from RegApContrPrevidenciaria
--Where CodEmpresa = @CodEmpresa and 
--DataInicial between @DataInicialP and @DataFinalP

-- Cod Sped 827 com problema