------------------------------------------------------------------------------------------------------------------------------------
--Criada em 10/04/2012 por Adriana
--Tem por finalidade gerar a apuração da Contribuição Previdenciária Patronal
--É chamada na Guia Fiscal/Apuração/Contr. Previdenciária
------------------------------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[PcRegApContrPrevidenciaria] @CodEmpresa Int, @DataInicialP DateTime, @PkUsuario Int, @LiberaTudo Char(3), 
@FkCadEmpresaScp Int = NULL
AS
------------------------------------------------------------------------------------------------------------------------------------f
Declare @DataFinalP DateTime, @BaseCalculoPatronal Int, @AliquotaContribuicao Numeric(18, 2),
@CodigoAuxiliar Int, @CodigoNcmReceitas Int, @PkReceita Int, @ReceitaBrutaTotalDevolucoes Numeric(18, 2), @Aux Int,
@Emissao Varchar(30), @CodigoMatriz Int, @ValorReceitaBrutaTotal Numeric(18, 2), @ValorDevolucoesComBeneficio Numeric(18, 2),
@ValorReceitaBrutaTotalComBeneficio Numeric(18, 2), @PkImposto Int, @EventoContabil Int, @DataInicialMesAnterior Datetime,
@DataFinalMesAnterior Datetime, @IndiceRateioIncentivado Numeric(18, 6), @ValorTotalReceitaBrutaComBeneficio Numeric(18, 2),
@FkControleServicos Int, @PkEscritorio Int = dbo.FPkEscritorioUsuarios(@PkUsuario), @ValorDeExclusãoTotal Numeric (18,2), @ValorAjuste Numeric(18,2)
 
Declare @ValorDeExclusoes Table (pk int, ValorDeExclusao Numeric (18, 2))

Set Nocount on

------------------------------------------------------------------------------------------------------------------------------------
Set @DataFinalP = DateAdd(mm, 1, @DataInicialP) -1
Set @DataInicialMesAnterior = DateAdd(mm, -1, @DataInicialP)
Set @DataFinalMesAnterior = DateAdd(mm, 1, @DataInicialMesAnterior) -1

Set @Emissao = dbo.FEmissaoSql()

-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Select @FkControleServicos = Pk
From ControleServicos C 
Where (C.DataInicial = @DataInicialP) and 
(C.CodEmpresa = @CodEmpresa) 

Delete From RegApContrPrevidenciaria
Where (CodEmpresa = @CodEmpresa) and
(DataInicial Between @DataInicialP and @DataFinalP) and
(FkControleServicos = 0) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)

-----------------------------------------------------------------------------------------------------------------------------------
Select Top 1 @BaseCalculoPatronal = T.BaseCalculoPatronal, 
@PkImposto = FkCodRecContrPrevsReceitaBruta,
@AliquotaContribuicao = PercentualFaturamento
From TributacaoPessoal T 
Where (T.CodEmpresa = @CodEmpresa) and 
(T.DataInicial <= @DataFinalP)
Order By T.DataInicial Desc

-----------------------------------------------------------------------------------------------------------------------------------
Select @CodigoMatriz = CodigoMatriz
From CadEmpresa
Where (CodEmpresa = @CodEmpresa) and
(FkEscritorio = @PkEscritorio)

-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
--Início da Validação definitiva...
-----------------------------------------------------------------------------------------------------------------------------------
Delete MSistema
Where (FkUsuario = @PkUsuario)

-----------------------------------------------------------------------------------------------------------------------------------
Exec PcVerificaEncerramento @CodEmpresa, 'Fiscal', @DataInicialP, 'Não', 'Não', @PkUsuario, @LiberaTudo

-----------------------------------------------------------------------------------------------------------------------------------
If(@CodigoMatriz <> @CodEmpresa)
  Begin
    Insert MSistema
    (FkUsuario, Abort, Descricao, Texto)
    Select @PkUsuario, 'Sim',
    'Só é possível gerar esta apuração na empresa Matriz.',
    'Operação cancelada.'
  End
 

If @BaseCalculoPatronal = 1 --Rendimentos Folha Pagamento
  Begin
    Insert MSistema
    (FkUsuario, Abort, Descricao, Texto)
    Select @PkUsuario, 'Sim',
    'Esta empresa está configurada para a geração da Contribuição Previdenciária pela Folha de Pagamento na Tributação Pessoal (Base de Cálculo Patronal).',
    'Operação cancelada.'

    Delete From RegApContrPrevidenciaria
    Where (CodEmpresa = @CodEmpresa) and
    (DataInicial = @DataInicialP) and 
    (Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)
  End  
  
-----------------------------------------------------------------------------------------------------------------------------------
If dbo.FAbort(@PkUsuario) = 'Sim'
  Begin
    Return
  End
  
-----------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------

  
------------------------------------------------------------------------------------------------------------------------------------
--Receita Bruta Total
------------------------------------------------------------------------------------------------------------------------------------
Select @ValorReceitaBrutaTotal = Coalesce(Sum(P.Total - P.ValorOutro), 0) --Coalesce(Sum(P.Total - P.ValorIpi - P.IcmsSt - P.ValorOutro), 0) --Everton - 22/03/2019
From CadEmpresa Ce
inner join RegSaidas R on (Ce.CodEmpresa = R.CodEmpresa)
Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
Inner Join Cfop C on (C.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Where (Ce.CodigoMatriz = @CodEmpresa) and 
(Ce.FkEscritorio = @PkEscritorio) and
(R.DataEmissao Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in(2, 3, 4, 5)) and
(C.Cfop between 5000 and 7200) and
(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) And
(Ct.SomaReceitaBrutaTotal = 'Sim') and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(C.FkEscritorio = @PkEscritorio)
print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------------------
--DemaisDocumentos
------------------
Select @ValorReceitaBrutaTotal = @ValorReceitaBrutaTotal + Coalesce(Sum(ValorOperacaoItem), 0)
From CadEmpresa C 
inner join DemaisDocumentos A on (A.CodEmpresa = C.CodEmpresa)
Where (C.CodigoMatriz = @CodEmpresa) and
(A.DataOperacao Between @DataInicialP and @DataFinalP) and
(A.IndicadorTipoOperacao in (1, 2)) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(C.FkEscritorio = @PkEscritorio) and
(A.SomaFaturamento = 'Sim') -- Gabriel 03/05/2019 deve verificar apenas se estiver como sim, a pedido de Halssil
print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------
--AtividadeImobiliaria Select * From AtividadeImobiliaria
----------------------
Select @ValorReceitaBrutaTotal = @ValorReceitaBrutaTotal + Coalesce(SUM(A.vBcCprb), 0)
From CadEmpresa C
inner join AtividadeImobiliaria A on (A.CodEmpresa = C.CodEmpresa)
Where (C.CodigoMatriz = @CodEmpresa) and
(A.DataOperacao Between @DataInicialP and @DataFinalP) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(A.IndicadorTipoOperacao <> 6) and
(C.FkEscritorio = @PkEscritorio)
print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------
Insert @ValorDeExclusoes
Select Cpi.FkCadCodAtividadesContrPrevidenciaria, Coalesce(Sum(P.Total - P.ValorIpi - P.IcmsSt - P.ValorOutro), 0)
From CadEmpresa C
inner join RegEntradas R on (R.CodEmpresa = C.CodEmpresa) 
inner join ProdutosEntradas P on (P.FkRegEntradas = R.Pk)
inner join Cfop Cf on (Cf.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and 
(R.DataEntrada between @DataInicialP and @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Ct.DiminuiReceitaBrutaTotal = 'Sim') and 
(R.TipoNota not in(2, 3, 4, 5)) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(Cf.FkEscritorio = @PkEscritorio) and
(C.FkEscritorio = @PkEscritorio)
Group by Cpi.FkCadCodAtividadesContrPrevidenciaria

Update @ValorDeExclusoes
Set ValorDeExclusao = ValorDeExclusao + (P.ValorIpi + P.IcmsSt)
From CadEmpresa C
Inner Join RegSaidas R on (C.CodEmpresa = R.CodEmpresa)
Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
Inner Join Cfop Cf on (Cf.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
left join @ValorDeExclusoes Ve on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Ve.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and
(C.FkEscritorio = @PkEscritorio) and
(R.DataEmissao Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in(2, 3, 4, 5)) and
(Ct.SomaReceitaBrutaComBeneficio = 'Sim') and
(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(Cf.FkEscritorio = @PkEscritorio) and (Cpi.FkCadCodAtividadesContrPrevidenciaria = Ve.Pk)

Insert @ValorDeExclusoes
Select Cpi.FkCadCodAtividadesContrPrevidenciaria, (P.ValorIpi + P.IcmsSt)
From CadEmpresa C
Inner Join RegSaidas R on (C.CodEmpresa = R.CodEmpresa)
Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
Inner Join Cfop Cf on (Cf.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and
(C.FkEscritorio = @PkEscritorio) and
(R.DataEmissao Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in(2, 3, 4, 5)) and
(Ct.SomaReceitaBrutaComBeneficio = 'Sim') and
(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(Cf.FkEscritorio = @PkEscritorio) And Cpi.FkCadCodAtividadesContrPrevidenciaria not in (Select Pk From @ValorDeExclusoes)

--select * From @ValorDeExclusoes
--print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------
If (@ValorReceitaBrutaTotal < 0)
  Begin
    Set @ValorReceitaBrutaTotal = 0
  End
  print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------
Select @ValorReceitaBrutaTotal = @ValorReceitaBrutaTotal + Coalesce(Sum((Coalesce(Ri.ValorContabil,0) - Coalesce(Ri.ValorDesconto,0))), 0)
From CadEmpresa C
inner join RegPrestServicos R on (R.CodEmpresa = C.CodEmpresa)
inner join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
Where (C.CodigoMatriz = @CodEmpresa) and 
(R.Data Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in('Cancelada', 'Anulada')) and
(TipoServico = 2) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(C.FkEscritorio = @PkEscritorio)
   print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------------------
Declare @ApuracaoReceitas Table
(Pk Int Identity (1,1), ReceitaBrutaTotal Numeric(18, 2), CodigoSped Int, ReceitaBrutaComBeneficio Numeric(18, 2), EventoContabil Int, CodEmpresa Int,
Saldo Numeric(18, 2), Aliquota Numeric(18, 2), ValorExclusao Numeric(18, 2))

Declare @ApuracaoReceitasAuxiliar Table
(ReceitaBrutaTotal Numeric(18, 2), CodigoSped Int, ReceitaBrutaComBeneficio Numeric(18, 2), EventoContabil Int, CodEmpresa Int,
Saldo Numeric(18, 2), Aliquota Numeric(18, 2), ValorExclusao Numeric(18, 2))

------------------------------------------------------------------------------------------------------------------------------------
Select Top 1 @EventoContabil = Coalesce(Ci.EventoContabil, 0)
From CodImpostos C 
inner join CodImpostosItens Ci on (C.Pk = Ci.Fk)
Where Ci.Tipo = 'Provisão' and C.Pk = @PkImposto 

------------------------------------------------------------------------------------------------------------------------------------
--Receitas com Beneficio - Registro de Saídas
------------------------------------------------------------------------------------------------------------------------------------
Insert @ApuracaoReceitas
(ReceitaBrutaTotal, CodigoSped, ReceitaBrutaComBeneficio, EventoContabil, CodEmpresa, Aliquota)
Select @ValorReceitaBrutaTotal, Cc.Pk, Sum(Coalesce(P.Total - P.ValorOutro, 0)), @EventoContabil, @CodEmpresa, -- Sum(Coalesce(P.Total - P.ValorIpi - P.IcmsSt - P.ValorOutro, 0)) --Everton 22/03/2019
Cc.Aliquota
From CadEmpresa C
Inner Join RegSaidas R on (C.CodEmpresa = R.CodEmpresa)
Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
Inner Join Cfop Cf on (Cf.Cfop = P.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and
(C.FkEscritorio = @PkEscritorio) and
(R.DataEmissao Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in(2, 3, 4, 5)) and
(Ct.SomaReceitaBrutaComBeneficio = 'Sim') and
(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(Cf.FkEscritorio = @PkEscritorio)
Group by Cc.Pk, Cc.Aliquota
print Concat('0 ', @ValorReceitaBrutaTotal)

------------------------------------------------------------------------------------------------------------------------------------
--Receitas com Beneficio - Registro de Prestação de Serviços
------------------------------------------------------------------------------------------------------------------------------------
Insert @ApuracaoReceitas
(ReceitaBrutaTotal, CodigoSped, ReceitaBrutaComBeneficio, EventoContabil, CodEmpresa, Aliquota)
Select @ValorReceitaBrutaTotal, --ReceitaBrutaTotal
Cc.Pk, --CodigoSped
Coalesce(Sum((Coalesce(Ri.ValorContabil, 0) - Coalesce(Ri.ValorDesconto,0))), 0), --ReceitaBrutaComBeneficio
@EventoContabil, --EventoContabil
@CodEmpresa, --CodEmpresa
Cc.Aliquota --Aliquota
From CadEmpresa C
inner join RegPrestServicos R on (R.CodEmpresa = C.CodEmpresa)
inner join RegPrestServicosItens Ri on (R.Pk = Ri.Fk)
Inner Join ListaServicos L on (L.Pk = Ri.FkListaServicos)
inner join CadProdutos Cp on (Cp.Pk = Ri.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cpi.FkCadProdutos = Cp.Pk)
Inner Join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and 
(C.FkEscritorio = @PkEscritorio) and
(R.Data Between @DataInicialP and @DataFinalP) and
(R.TipoNota not in('Cancelada', 'Anulada')) and 
(R.TipoServico = 2) and 
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(L.FkEscritorio = @PkEscritorio)
Group by Cc.Pk, Cc.Aliquota
print Concat('0 ', @ValorReceitaBrutaTotal)
------------------------------------------------------------------------------------------------------------------------------------
--Receitas com Beneficio - DemaisDocumentos
------------------------------------------------------------------------------------------------------------------------------------
Insert @ApuracaoReceitas
(ReceitaBrutaTotal, CodigoSped, ReceitaBrutaComBeneficio, EventoContabil, CodEmpresa, Aliquota)
Select @ValorReceitaBrutaTotal, --ReceitaBrutaTotal
Cc.Pk, --CodigoSped
Coalesce(Sum(ValorOperacaoItem), 0), --ReceitaBrutaComBeneficio
@EventoContabil, --EventoContabil
@CodEmpresa, --CodEmpresa
Cc.Aliquota --Aliquota
From CadEmpresa C 
inner join DemaisDocumentos A on (A.CodEmpresa = C.CodEmpresa)
Inner Join CadProdutos Cp on (Cp.Pk = A.FkCadProdutos)
Inner Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
Inner join CadCodAtividadesContrPrevidenciaria Cc on (Cpi.FkCadCodAtividadesContrPrevidenciaria = Cc.Pk)
Where (C.CodigoMatriz = @CodEmpresa) and
(C.FkEscritorio = @PkEscritorio) and
(A.DataOperacao Between @DataInicialP and @DataFinalP) and
(A.IndicadorTipoOperacao in (1, 2)) and
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(A.SomaFaturamento = 'Sim') and -- Gabriel 03/05/2019 deve verificar apenas se estiver como sim, a pedido de Halssil
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)
Group by Cc.Pk, Cc.Aliquota
print Concat('0 ', @ValorReceitaBrutaTotal)
----------------------------------------------------------------------------------------------------------------------------------
--AtividadeImobiliaria
----------------------------------------------------------------------------------------------------------------------------------
Insert @ApuracaoReceitas
(ReceitaBrutaTotal, CodigoSped, ReceitaBrutaComBeneficio, EventoContabil, CodEmpresa, Aliquota)
Select @ValorReceitaBrutaTotal, --ReceitaBrutaTotal, 
A.FkCadCodAtividadesContrPrevidenciaria, --CodigoSped, 
Coalesce(Sum(A.vBcCprb), 0), --ReceitaBrutaComBeneficio, 
@EventoContabil, --EventoContabil, 
@CodEmpresa, --CodEmpresa, 
A.pCprb--Aliquota
From CadEmpresa C
inner join AtividadeImobiliaria A on (A.CodEmpresa = C.CodEmpresa)
inner join CadCodAtividadesContrPrevidenciaria Cc on (Cc.Pk = A.FkCadCodAtividadesContrPrevidenciaria)
Where (C.CodigoMatriz = @CodEmpresa) and
(C.FkEscritorio = @PkEscritorio) and
(A.DataOperacao Between @DataInicialP and @DataFinalP) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(A.IndicadorTipoOperacao <> 6)
Group by A.FkCadCodAtividadesContrPrevidenciaria, A.pCprb

--Select * from @ApuracaoReceitas
--print Concat('0 ', @ValorReceitaBrutaTotal)
----------------------------------------------------------------------------------------------------------------------------------
--Devoluções
------------------------------------------------------------------------------------------------------------------------------------
Declare @Devolucoes Table (Aliquota Numeric(18, 2), Valor Numeric(18, 2), CodigoSped int)

------------------------------------------------------------------------------------------------------------------------------------
Insert @Devolucoes (Aliquota, Valor, CodigoSped) 
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
(C.FkEscritorio = @PkEscritorio) and
(R.DataEntrada between @DataInicialP and @DataFinalP) and 
(Ct.DiminuiReceitaBrutaComBeneficio = 'Sim') and 
(R.TipoNota not in(2, 3, 4, 5)) and
(Ctt.Classe = (Case When Cc.Tipo = 3 Then 1 When Cc.Tipo = 2 Then 2 When Cc.Tipo = 1 Then Ctt.Classe End)) and
(Cpi.DataInicial <= @DataFinalP) and 
((Cpi.DataFinal >= @DataInicialP) or (Cpi.DataFinal is null)) and
(Coalesce(R.FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End) and
(Cf.FkEscritorio = @PkEscritorio) 
Group by Cc.Aliquota, Cc.Pk

Select @ValorDevolucoesComBeneficio = Coalesce(Sum(Valor), 0)
From @Devolucoes
Print Concat('1 ', @ValorDevolucoesComBeneficio)
------------------------------------------------------------------------------------------------------------------------------------
Select @ValorDevolucoesComBeneficio = @ValorDevolucoesComBeneficio + Coalesce(Sum(SaldoDevolucaoComBeneficio), 0)
From CadEmpresa C
Inner join Faturamento F on (C.CodEmpresa = F.CodEmpresa)
Where Data between @DataInicialMesAnterior and @DataFinalMesAnterior and
(C.CodigoMatriz = @CodEmpresa) and
(C.FkEscritorio = @PkEscritorio)

------------------------------------------------------------------------------------------------------------------------------------
Print Concat('1 ', @ValorDevolucoesComBeneficio)
If (@ValorDevolucoesComBeneficio > 0)
  Begin
    Declare CrApuracaoReceita Cursor local static for 
    Select Pk, ReceitaBrutaComBeneficio
    From @ApuracaoReceitas
    Order by CodigoSped
    Open CrApuracaoReceita
    Fetch Next From CrApuracaoReceita into @PkReceita, @ValorReceitaBrutaTotalComBeneficio
    While (@@Fetch_Status = 0)
      Begin
      
        Update @ApuracaoReceitas
        Set ReceitaBrutaComBeneficio = Case When ReceitaBrutaComBeneficio > Valor Then ReceitaBrutaComBeneficio Else 0 End
        From @Devolucoes D
        Inner Join @ApuracaoReceitas R on (D.Aliquota = R.Aliquota) and (D.CodigoSped = R.CodigoSped)
        Where Pk = @PkReceita
                
        Update @Devolucoes
        Set Valor = Case When ReceitaBrutaComBeneficio > Valor Then 0 Else Valor - ReceitaBrutaComBeneficio End
        From @Devolucoes D
        Inner Join @ApuracaoReceitas R on (D.Aliquota = R.Aliquota) and (D.CodigoSped = R.CodigoSped)
        Where Pk = @PkReceita

        Fetch Next From CrApuracaoReceita into  @PkReceita, @ValorReceitaBrutaTotalComBeneficio
      End
    Close CrApuracaoReceita
    Deallocate CrApuracaoReceita
  End  
  
--Select 'A',* From RegApContrPrevidenciaria Where DataInicial >= @DataInicialP
------------------------------------------------------------------------------------------------------------------------------------  
Delete From @ApuracaoReceitas
Where ReceitaBrutaComBeneficio = 0

If (@ValorDevolucoesComBeneficio > 0)
  Begin
    Update Faturamento
    Set SaldoDevolucaoComBeneficio = @ValorDevolucoesComBeneficio
    Where Data Between @DataInicialP and @DataFinalP and
    CodEmpresa = @CodEmpresa
  End
  
-----------------------------------------------------------------------------------------------------------------------------------

Delete RegApContrPrevidenciaria
Where DataInicial = @DataInicialP and
(CodEmpresa = @CodEmpresa)
------------------------------------------------------------------------------------------------------------------------------------
--Inserindo na tabela oficial
------------------------------------------------------------------------------------------------------------------------------------
Insert RegApContrPrevidenciaria
(DataInicial, CodEmpresa, ReceitaBrutaTotal, FkCadNcm, ReceitaBrutaComBeneficio, ValorExclusoes, 
BaseCalculo, AliquotaContribuicao, ValorContribuicao, EventoContabil, InfComplementares, 
Emissao, FkControleServicos, FkCadCodAtividadesContrPrevidenciaria, FkCadEmpresaScp)
Select 
@DataInicialP, --DataInicial
@CodEmpresa, --CodEmpresa
Sum(Coalesce(Ap.ReceitaBrutaTotal, 0)), --ReceitaBrutaTotal
null, --FkCadNcm
Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0)), --ReceitaBrutaComBeneficio
(Coalesce(Ve.ValorDeExclusao , 0)), --ValorExclusoes
Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0)) -  Coalesce(Ve.ValorDeExclusao, 0), --BaseCalculo
Ap.Aliquota, --AliquotaContribuicao
Sum((Coalesce(Ap.ReceitaBrutaComBeneficio, 0)) * Ap.Aliquota / 100), --ValorContribuicao
Ap.EventoContabil, --EventoContabil
'', --InfComplementares
@Emissao, --Emissao
@FkControleServicos, --FkControleServicos
Ap.CodigoSped,
@FkCadEmpresaScp
From @ApuracaoReceitas Ap 
Left outer join RegApContrPrevidenciaria R on (R.FkCadCodAtividadesContrPrevidenciaria = Ap.CodigoSped) and 
(R.CodEmpresa = Ap.CodEmpresa) and (R.DataInicial = @DataInicialP) and 
(Coalesce(R.EventoContabil, 0) = Coalesce(Ap.EventoContabil, 0)) and
(Coalesce(R.FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)
left join @ValorDeExclusoes Ve on (Ve.pk = FkCadCodAtividadesContrPrevidenciaria )
Where R.Pk is null
Group by Ap.CodigoSped, Ap.EventoContabil, Ap.Aliquota, Ve.ValorDeExclusao

print 'A'
Select 'Culpa do Halssil',
@DataInicialP, --DataInicial
@CodEmpresa, --CodEmpresa
Sum(Coalesce(Ap.ReceitaBrutaTotal, 0)), --ReceitaBrutaTotal
null, --FkCadNcm
Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0)), --ReceitaBrutaComBeneficio
(Coalesce(Ve.ValorDeExclusao , 0)), --ValorExclusoes
Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0)) -  Coalesce(Ve.ValorDeExclusao, 0), --BaseCalculo
Ap.Aliquota, --AliquotaContribuicao
Sum((Coalesce(Ap.ReceitaBrutaComBeneficio, 0)) * Ap.Aliquota / 100), --ValorContribuicao
Ap.EventoContabil, --EventoContabil
'', --InfComplementares
@Emissao, --Emissao
@FkControleServicos, --FkControleServicos
Ap.CodigoSped,
@FkCadEmpresaScp
From @ApuracaoReceitas Ap 
Left outer join RegApContrPrevidenciaria R on (R.FkCadCodAtividadesContrPrevidenciaria = Ap.CodigoSped) and 
(R.CodEmpresa = Ap.CodEmpresa) and (R.DataInicial = @DataInicialP) and 
(Coalesce(R.EventoContabil, 0) = Coalesce(Ap.EventoContabil, 0)) and
(Coalesce(R.FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)
left join @ValorDeExclusoes Ve on (Ve.pk = FkCadCodAtividadesContrPrevidenciaria )
Where R.Pk is null
Group by Ap.CodigoSped, Ap.EventoContabil, Ap.Aliquota, Ve.ValorDeExclusao

print 'B'
Select Ap.CodigoSped, Ap.EventoContabil, Ap.Aliquota, Ve.ValorDeExclusao, Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0))
From @ApuracaoReceitas Ap 
Left outer join RegApContrPrevidenciaria R on (R.FkCadCodAtividadesContrPrevidenciaria = Ap.CodigoSped) and 
(R.CodEmpresa = Ap.CodEmpresa) and (R.DataInicial = @DataInicialP) and 
(Coalesce(R.EventoContabil, 0) = Coalesce(Ap.EventoContabil, 0)) and
(Coalesce(R.FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)
left join @ValorDeExclusoes Ve on (Ve.pk = FkCadCodAtividadesContrPrevidenciaria )
Group by Ap.CodigoSped, Ap.EventoContabil, Ap.Aliquota, Ve.ValorDeExclusao
------------------------------------------------------------------------------------------------------------------------------------
Insert @ApuracaoReceitasAuxiliar(ReceitaBrutaTotal, CodigoSped, ReceitaBrutaComBeneficio, EventoContabil, CodEmpresa, Aliquota)   
Select ReceitaBrutaTotal, CodigoSped, Sum(ReceitaBrutaComBeneficio), EventoContabil, CodEmpresa, Aliquota
From @ApuracaoReceitas
Group by CodigoSped, EventoContabil, CodEmpresa, ReceitaBrutaTotal, Aliquota

------------------------------------------------------------------------------------------------------------------------------------
Update RegApContrPrevidenciaria
Set
ReceitaBrutaTotal = Coalesce(Ap.ReceitaBrutaTotal, 0),
ReceitaBrutaComBeneficio = Coalesce(Ap.ReceitaBrutaComBeneficio, 0),
BaseCalculo = (Coalesce(Ap.ReceitaBrutaComBeneficio, 0) -  Coalesce(Ve.ValorDeExclusao , 0)),
AliquotaContribuicao = Ap.Aliquota,
ValorExclusoes =  Ve.ValorDeExclusao
From RegApContrPrevidenciaria R
inner join @ApuracaoReceitasAuxiliar Ap on (Ap.CodigoSped = R.FkCadCodAtividadesContrPrevidenciaria) and 
(R.CodEmpresa = Ap.CodEmpresa) and 
(Coalesce(R.EventoContabil, 0) = Coalesce(Ap.EventoContabil, 0))
left join @ValorDeExclusoes Ve on (Ve.pk = R.FkCadCodAtividadesContrPrevidenciaria )
Where R.CodEmpresa = @CodEmpresa and
(R.DataInicial between @DataInicialP and @DataFinalP) and
(FkControleServicos > 0) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)

Select 'C', *
From RegApContrPrevidenciaria R
inner join @ApuracaoReceitasAuxiliar Ap on (Ap.CodigoSped = R.FkCadCodAtividadesContrPrevidenciaria) and 
(R.CodEmpresa = Ap.CodEmpresa) and 
(Coalesce(R.EventoContabil, 0) = Coalesce(Ap.EventoContabil, 0))
left join @ValorDeExclusoes Ve on (Ve.pk = R.FkCadCodAtividadesContrPrevidenciaria )
Where R.CodEmpresa = @CodEmpresa and
(R.DataInicial between @DataInicialP and @DataFinalP) and
(FkControleServicos > 0) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)

Select Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0)) As ReceitaBruta From @ApuracaoReceitas Ap
------------------------------------------------------------------------------------------------------------------------------------
Update RegApContrPrevidenciaria
Set
ValorContribuicao = (BaseCalculo * AliquotaContribuicao / 100)
From RegApContrPrevidenciaria R
Where (R.CodEmpresa = @CodEmpresa) and
(R.DataInicial between @DataInicialP and @DataFinalP) and
(FkControleServicos > 0) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)

------------------------------------------------------------------------------------------------------------------------------------
Delete RegApContrPrevidenciaria
From RegApContrPrevidenciaria R 
Left outer join @ApuracaoReceitas Ap on (R.FkCadCodAtividadesContrPrevidenciaria = Ap.CodigoSped) and 
(R.CodEmpresa = Ap.CodEmpresa) and 
(Coalesce(R.EventoContabil, 0) = Coalesce(Ap.EventoContabil, 0))
Where Ap.CodigoSped is null and
(R.CodEmpresa = @CodEmpresa) and
(R.DataInicial between @DataInicialP and @DataFinalP) and
(FkControleServicos > 0) and
(Coalesce(FkCadEmpresaScp, '') = Case When @FkCadEmpresaScp is null Then '' Else @FkCadEmpresaScp End)
Print 'pos delete'
-------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
Insert MSistema
(FkUsuario, Abort, Descricao, Texto)
Select @PkUsuario, 'Não',
'Sucesso na geração da apuração da contribuição previdenciária.',
'Operação concluída.'

------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
--Receitas sem Beneficio mas superior a 95%
-------------------
Select @ValorReceitaBrutaTotal = ReceitaTotal, 
@ValorTotalReceitaBrutaComBeneficio = ReceitaComBeneficio,
@IndiceRateioIncentivado = IndiceRateioIncentivado
From dbo.TCalculaGpsFaturamento
(@CodEmpresa, @DataInicialP, @DataFinalP, @FkCadEmpresaScp)
Print concat('1, ',' Valor Receita bruta total: ',@ValorReceitaBrutaTotal , ' Com beneficio: ',@ValorTotalReceitaBrutaComBeneficio)

Select @ValorReceitaBrutaTotal as ReceitaTotal, 
@ValorTotalReceitaBrutaComBeneficio as ReceitaComBeneficio,
@IndiceRateioIncentivado as IndiceRateioIncentivado


Declare @ValorTotalReceitaBrutaComBeneficioApuracao Numeric(18,2)
Set @ValorTotalReceitaBrutaComBeneficioApuracao = (Select Sum(Coalesce(Ap.ReceitaBrutaComBeneficio, 0)) As ReceitaBruta From @ApuracaoReceitas Ap)

If (@IndiceRateioIncentivado = 0)
  Begin
    Insert MSistema
    (FkUsuario, Abort, Descricao, Texto)
    Select @PkUsuario, 'Não',
    'ATENÇÃO: Índice de rateio incentivado igual a zero.',
    'Operação concluída.'    
    return  
  End

 print Concat('Indicador rateio: ',@IndiceRateioIncentivado ,' Valor Receita bruta total: ',@ValorReceitaBrutaTotal , ' Com beneficio: ',@ValorTotalReceitaBrutaComBeneficio)
If (@IndiceRateioIncentivado = 1) and (@ValorReceitaBrutaTotal <> @ValorTotalReceitaBrutaComBeneficioApuracao) 
  Begin
    --Everton 04/01/2019 - Adequação para códigos genéricos válidos, de acordo com a ---------------------------------------------
    --TABELA 09 – Código de Atividades, Produtos e Serviços Sujeitos à CPRB           ---------------------------------------------

    Declare @CodigoCadCodAtividadesContrPrevidenciaria Varchar(8)

    Select @CodigoCadCodAtividadesContrPrevidenciaria = Codigo From CadCodAtividadesContrPrevidenciaria Cca 
    Where ( Left(Cca.Codigo,6) = '999900' ) And ( Cca.Aliquota = @AliquotaContribuicao) 

    If (Coalesce(@CodigoCadCodAtividadesContrPrevidenciaria, '') = '') 
      Begin     
        Set @CodigoCadCodAtividadesContrPrevidenciaria = '99999999'
      End
    ------------------------------------------------------------------------------------------------------------------------------
    Select @ValorDeExclusãoTotal = Sum(Ve.ValorDeExclusao) From @ValorDeExclusoes Ve
    Select @ValorDeExclusãoTotal,'valor' 
    ------------------------------------------------------------------------------------------------------------------------------
    Insert RegApContrPrevidenciaria
    (DataInicial, CodEmpresa, ReceitaBrutaTotal, FkCadNcm, ReceitaBrutaComBeneficio, ValorExclusoes, 
    BaseCalculo, AliquotaContribuicao, ValorContribuicao, EventoContabil, InfComplementares, 
    Emissao, FkControleServicos, FkCadCodAtividadesContrPrevidenciaria, FkCadEmpresaScp)
    Select @DataInicialP, --DataInicial
    @CodEmpresa, --CodEmpresa
    @ValorReceitaBrutaTotal, --ReceitaBrutaTotal
    null, --FkCadNcm
    (@ValorReceitaBrutaTotal - @ValorTotalReceitaBrutaComBeneficio -  @ValorDeExclusãoTotal), --ReceitaBrutaComBeneficio
    0, --ValorExclusoes
    (@ValorReceitaBrutaTotal - @ValorTotalReceitaBrutaComBeneficio -  @ValorDeExclusãoTotal), --BaseCalculo
    @AliquotaContribuicao, --AliquotaContribuição
    (@ValorReceitaBrutaTotal - @ValorTotalReceitaBrutaComBeneficio -  @ValorDeExclusãoTotal) * @AliquotaContribuicao / 100, --ValorContribuição 02/04/2019 - Refeito o cálculo por Gabriel a pedido de Vivyane
    @EventoContabil, --EventoContabil
    '', --InfComplementares
    @Emissao, --Emissao
    @FkControleServicos, --FkControleServicos
    (Select Top 1 Pk From CadCodAtividadesContrPrevidenciaria Where Codigo = @CodigoCadCodAtividadesContrPrevidenciaria), --Everton - 4/1/2019
    @FkCadEmpresaScp

    Select'Verificação', @DataInicialP, --DataInicial
    @CodEmpresa, --CodEmpresa
    @ValorReceitaBrutaTotal, --ReceitaBrutaTotal
    null, --FkCadNcm
    (@ValorReceitaBrutaTotal - @ValorTotalReceitaBrutaComBeneficio -  @ValorDeExclusãoTotal) as Beneficio, --ReceitaBrutaComBeneficio
    0, --ValorExclusoes
    (@ValorReceitaBrutaTotal - @ValorTotalReceitaBrutaComBeneficio -  @ValorDeExclusãoTotal), --BaseCalculo
    @AliquotaContribuicao, --AliquotaContribuição
    (@ValorReceitaBrutaTotal - @ValorTotalReceitaBrutaComBeneficio) * @AliquotaContribuicao / 100, --ValorContribuição
    @EventoContabil, --EventoContabil
    '', --InfComplementares
    @Emissao, --Emissao
    @FkControleServicos, --FkControleServicos
    (Select Top 1 Pk From CadCodAtividadesContrPrevidenciaria Where Codigo = @CodigoCadCodAtividadesContrPrevidenciaria), --Everton - 4/1/2019
    @FkCadEmpresaScp    
  End

    Update RegApContrPrevidenciaria
    Set ValorExclusoes = Ve.ValorDeExclusao,
    BaseCalculo = (ReceitaBrutaComBeneficio -  Coalesce(Ve.ValorDeExclusao , 0))
    From @ValorDeExclusoes Ve
    Where (FkCadCodAtividadesContrPrevidenciaria) = Ve.pk And (DataInicial>=@DataInicialP) And (DataInicial <= @DataFinalP) And
    (ReceitaBrutaTotal<>ReceitaBrutaComBeneficio) and
    (CodEmpresa = @CodEmpresa) -- Adicionado por Gabriel em 06/05/2019 antes estava atualizando toda a tabela


---------------------------------------------------------------------------------------------------
-- Exclusões por Cfop Tipo, inicialmente será apenas o CfopTipo 25, mas pode ser acrescentado outros
-- Valor(es) retornados precisam ser abatidos totalmente dos devidos códigos do Sped
-- Resumo do Calculo: ReceitaBrutaDoBeneficio - RetornoAbaixo = 0
-- Feito por Gabriel em 21/05/2019 a pedido de Vivyane
--Declare @DevolucoesPorCfopTipo Table (CodigoSped int, Total numeric(18,2))

--Insert @DevolucoesPorCfopTipo
--Select Coalesce(Cpi.FkCadCodAtividadesContrPrevidenciaria, 0), Coalesce(P.Total, 0)
--From CadEmpresa Ce
--inner join RegSaidas R on (Ce.CodEmpresa = R.CodEmpresa)
--Inner Join ProdutosSaidas P on (R.Pk = P.FkRegSaidas)
--Inner Join Cfop C on (C.Cfop = P.Cfop)
--Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = P.FkCfopTipoTributacao)
--Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
--Inner Join CadProdutos Cp on (Cp.Pk = P.FkCadProdutos)
--Join CadProdutosItens Cpi on (Cp.Pk = Cpi.FkCadProdutos)
--Where (Ce.CodigoMatriz = @CodEmpresa) and 
--(Ce.FkEscritorio = 1) and
--(R.DataEmissao Between @DataInicialP and @DataFinalP) and
--(R.TipoNota not in(2, 3, 4, 5)) and
--(C.Cfop between 5000 and 7200) and
--(Ct.Pk in (25)) and
--(Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
--(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO')) And
--(Ct.SomaReceitaBrutaTotal = 'Sim') and
--(C.FkEscritorio = 1)

---- Só irá realizar o Update se existir algo na tabela
---- Não alterar Set = 0 pois é necessário
--If Exists(Select CodigoSped From @DevolucoesPorCfopTipo)
--	Begin
--		Update RegApContrPrevidenciaria
--		Set ValorExclusoes += Dv.Total,
--		BaseCalculo = (ReceitaBrutaComBeneficio - Dv.Total),
--		AliquotaContribuicao = 0,
--		ValorContribuicao = 0
--		From @DevolucoesPorCfopTipo Dv
--		Where Dv.CodigoSped = FkCadCodAtividadesContrPrevidenciaria
--	End

-----------------------------------------------------------------------------------

----- Inserindo na RegApContrPrevidenciariaAjustesReinf 
-- Adicionado 29/04/2019 por Gabriel
Exec PcGeraRegApContrPrevidenciariaAjustesReinf 0, @PkUsuario, null, 0, null, @DataInicialP, 2, @CodEmpresa, @LiberaTudo, '', null, null, @DataInicialP, @DataFinalP -- Insert 

------------------------------------------------------------------------------------------------------------------------------------
--Exec PcAtualizaTodasProcedures 'PcRegApContrPrevidenciaria'
------------------------------------------------------------------------------------------------------------------------------------
--Exec PcRegApContrPrevidenciaria 13386, '2019-04-01', 2528, 'Não', ''