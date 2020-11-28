--Declare @Devolucoes Table (pk int, Cod int, Devolucao numeric(18,2), Ipi numeric(18,2), ICmSt numeric(18,2), ValorOutr numeric(18,2))
--Declare @Saidas Table (pk int, Cod int, Ipi numeric(18,2), ICmSt numeric(18,2), ValorOutr numeric(18,2))
Declare @AjustesReinf Table (pk int, Cod int, ValorDeExclusao Numeric (18, 2), Ipi numeric(18,2), ICmSt numeric(18,2), ValorOutr numeric(18,2))
--Declare @CodEmpresa int = 648, @DataInicialP datetime = '2019-04-01', @DataFinalP datetime = '2019-04-30', @FkEscritorio int -- Sotec
Declare @CodEmpresa int = 21344, @DataInicialP datetime = '2019-02-01', @DataFinalP datetime = '2019-02-28', @FkEscritorio int -- Proj
--Declare @CodEmpresa int = 402, @DataInicialP datetime = '2019-04-01', @DataFinalP datetime = '2019-04-30', @FkEscritorio int -- LogicaContabil
--Declare @CodEmpresa int = 179, @DataInicialP datetime = '2019-04-01', @DataFinalP datetime = '2019-04-30', @FkEscritorio int -- Azevedo Contabil - Frigolemos
--Declare @CodEmpresa int = 2, @DataInicialP datetime = '2019-04-01', @DataFinalP datetime = '2019-04-30', @FkEscritorio int -- Sertecon Aeros


Create Table #ApuracaoDevolucoesReinf
(
	pk int, 
	Cod int, 
	Devolucao numeric(18,2), 
	Ipi numeric(18,2), 
	ICmSt numeric(18,2), 
	ValorOutr numeric(18,2)
)


select @FkEscritorio = FkEscritorio
from CadEmpresa
Where CodEmpresa = @CodEmpresa        


-- Apurando dados de Devoluções referente as notas de saídas e inserindo na tabela @Devolucoes
Insert #ApuracaoDevolucoesReinf
Select Cc.Pk, -- Pk do Codigo do Sped
Cc.Codigo, -- Código do Sped
Coalesce(SUM(P.Total - P.ValorIpi - P.IcmsSt - P.ValorOutro), 0) Total, 
Coalesce(SUM(P.ValorIpi), 0), -- Ipi
Coalesce(SUM(P.IcmsSt), 0), -- IcmsSt
Coalesce(SUM(P.ValorOutro), 0) -- Outros
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
(Coalesce(FkCadEmpresaScp, '') =  '') and
(Cf.FkEscritorio = @FkEscritorio) 
Group By Cc.Pk, Cc.Codigo


---- Apurando dados de impostos de notas de saída e unindo com a tabela @Devolucoes para unificar dados e inserindo na tabela @AjustesReinf
Insert #ApuracaoDevolucoesReinf
Select Cc.Pk, -- Pk do Codigo do Sped
Cc.Codigo, -- Código do Sped
null, -- Devolução
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
(Cf.FkEscritorio = @FkEscritorio) and 
(C.FkEscritorio = @FkEscritorio) and 
(R.TipoNota not in(2, 3, 4, 5))  
group by Cc.Pk, Cc.Codigo

Insert @AjustesReinf
Select pk,-- Pk do Codigo do Sped
Cod, -- Código do Sped
Devolucao, -- Valor da devolução
sum(Coalesce(Ipi, 0)), -- Somatório do IPI
sum(Coalesce(ICmSt, 0)), -- Somatório do ICmSt
sum(Coalesce(ValorOutr, 0)) -- Somatório do ValorOutr
From #ApuracaoDevolucoesReinf
Group by pk, Cod, Devolucao


 select * from @AjustesReinf

Drop Table #ApuracaoDevolucoesReinf




