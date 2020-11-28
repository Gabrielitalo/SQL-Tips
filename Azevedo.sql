Declare @CodEmpresa int = 179, @DataInicialP datetime = '2019-04-01', @DataFinalP datetime = '2019-04-30', @FkEscritorio int -- Azevedo Contabil - Frigolemos
Declare @ValorDeExclusoes Table (pk int, ValorDeExclusao Numeric (18, 2))

select @FkEscritorio = FkEscritorio
from CadEmpresa
Where CodEmpresa = @CodEmpresa        

--Insert @ValorDeExclusoes
--Select Cpi.FkCadCodAtividadesContrPrevidenciaria, Coalesce(Sum(P.Total - P.ValorIpi - P.IcmsSt - P.ValorOutro), 0)
--From CadEmpresa C
--inner join RegEntradas R on (R.CodEmpresa = C.CodEmpresa) 
--inner join ProdutosEntradas P on (P.FkRegEntradas = R.Pk)
--inner join Cfop Cf on (Cf.Cfop = P.Cfop)
--Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
--Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
--Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
--Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
--Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
--Where (C.CodigoMatriz = @CodEmpresa) and 
--(C.FkEscritorio = @FkEscritorio) and
--(R.DataEntrada between @DataInicialP and @DataFinalP) and 
--(Ct.DiminuiReceitaBrutaComBeneficio = 'Sim') and 
--(R.TipoNota not in(2, 3, 4, 5)) and
--(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
--(Cpi.DataInicial <= @DataFinalP) and 
--((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
--(Coalesce(FkCadEmpresaScp, '') =  '') and
--(Cf.FkEscritorio = @FkEscritorio) 
--Group by Cpi.FkCadCodAtividadesContrPrevidenciaria

--Insert @ValorDeExclusoes
--Select Cpi.FkCadCodAtividadesContrPrevidenciaria, sum((P.ValorIpi + P.IcmsSt))
--From CadEmpresa C
--Inner Join RegSaidas R on (C.CodEmpresa = R.CodEmpresa)
--Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
--Inner Join Cfop Cf on (Cf.Cfop = P.Cfop)
--Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
--Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
--Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
--Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
--Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
--Where (C.CodigoMatriz = @CodEmpresa) and
--(C.FkEscritorio = @FkEscritorio) and
--(R.DataEmissao Between @DataInicialP and @DataFinalP) and
--(R.TipoNota not in(2, 3, 4, 5)) and
--(Ct.SomaReceitaBrutaComBeneficio = 'Sim') and
--(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
--(Cpi.DataInicial <= @DataFinalP) and 
--((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
--(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
--(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) and
--(Cf.FkEscritorio = @FkEscritorio) 
--Group by Cpi.FkCadCodAtividadesContrPrevidenciaria

--Update @ValorDeExclusoes
--Set ValorDeExclusao = ValorDeExclusao + (P.ValorIpi + P.IcmsSt)
--From CadEmpresa C
--Inner Join RegSaidas R on (C.CodEmpresa = R.CodEmpresa)
--Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
--Inner Join Cfop Cf on (Cf.Cfop = P.Cfop)
--Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
--Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
--Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
--Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
--Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
--left join @ValorDeExclusoes Ve on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Ve.Pk)
--Where (C.CodigoMatriz = @CodEmpresa) and
--(C.FkEscritorio = @FkEscritorio) and
--(R.DataEmissao Between @DataInicialP and @DataFinalP) and
--(R.TipoNota not in(2, 3, 4, 5)) and
--(Ct.SomaReceitaBrutaComBeneficio = 'Sim') and
--(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
--(Cpi.DataInicial <= @DataFinalP) and 
--((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
--(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
--(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) and
--(Cf.FkEscritorio = @FkEscritorio) and (Cpi.FkCadCodAtividadesContrPrevidenciaria = Ve.Pk)

--select pk, SUM(ValorDeExclusao) 
--from @ValorDeExclusoes
--Group by pk

Select Cc.Aliquota, Coalesce(Sum(P.Total - P.ValorIpi - P.IcmsSt - P.ValorOutro), 0), Cc.Pk
From CadEmpresa C
inner join RegEntradas R on (C.CodEmpresa = R.CodEmpresa)
inner join ProdutosEntradas P on (P.FkRegEntradas = R.Pk)
inner join Cfop Cf on (Cf.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
inner join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Inner Join CadCodAtividadesContrPrevidenciaria Cc on (Cc.Pk = Cpi.FkCadCodAtividadesContrPrevidenciaria)
Where (C.CodigoMatriz = @CodEmpresa) and 
(C.FkEscritorio = @FkEscritorio) and
(R.DataEntrada between @DataInicialP and @DataFinalP) and 
(Ct.DiminuiReceitaBrutaComBeneficio = 'Sim') and 
(R.TipoNota not in(2, 3, 4, 5)) and
(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Cf.FkEscritorio = @FkEscritorio) 
Group by Cc.Aliquota, Cc.Pk