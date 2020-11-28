
---------------------------------------------------------------------------------------------------
-- Exclusões por Cfop Tipo, inicialmente será apenas o CfopTipo 25, mas pode ser acrescentado outros
-- Valor(es) retornados precisam ser abatidos totalmente dos devidos códigos do Sped
-- Resumo do Calculo: ReceitaBrutaDoBeneficio - RetornoAbaixo = 0
-- Feito por Gabriel em 21/05/2019 a pedido de Vivyane
Declare @DevolucoesPorCfopTipo Table (CodigoSped int, Total numeric(18,2))

Insert @DevolucoesPorCfopTipo
Select Coalesce(Cpi.FkCadCodAtividadesContrPrevidenciaria, 0), Coalesce(P.Total, 0)
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
(Ct.Pk in (25)) and
(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) And
(Ct.SomaReceitaBrutaTotal = 'Sim') and
(C.FkEscritorio = 1)

-- Só irá realizar o Update se existir algo na tabela
-- Não alterar Set = 0 pois é necessário
If Exists(Select CodigoSped From @DevolucoesPorCfopTipo)
	Begin
		Update RegApContrPrevidenciaria
		Set ValorExclusoes += Dv.Total,
		BaseCalculo = (ReceitaBrutaComBeneficio - Dv.Total),
		AliquotaContribuicao = 0,
		ValorContribuicao = 0
		From @DevolucoesPorCfopTipo Dv
		Where Dv.CodigoSped = FkCadCodAtividadesContrPrevidenciaria
	End

-----------------------------------------------------------------------------------