Declare @CodEmpresa int = 38, @DataInicial datetime = '2019-07-01', @DataFinal datetime = '2019-07-31', @Pg368 int = 1, @PkEscritorio int = 1, 
@VendaPrazo Numeric(18,2) = 0, @VendaAVista Numeric(18,2) = 0, @Ipi Numeric(18,2)



Select @VendaPrazo = Sum((Coalesce(Rsi.Total, 0) -
Case When @Pg368 = 1 Then --Parâmetro 368 define se abate icms st do faturamento
  0 
Else 
  Coalesce((Rsi.IcmsSt), 0) 
End))
From RegSaidas Rs
inner join RegSaidasItens Rsi on (Rs.Pk = Rsi.Fk)
inner join Cfop Cf on (Rsi.Cfop = Cf.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = Rsi.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Where (Rs.CodEmpresa = @CodEmpresa) and 
(Rs.DataEmissao between @DataInicial and @DataFinal) and 
(Ct.SomaValorFaturamento = 'Sim') and 
(Rs.Vp in('P', 'F') ) and --Everton - 17/01/2019 pedido da Vivy
(Rs.TipoNota not in(2, 3, 4, 5, 6)) and  --Adicionado o 6, ref nf do Tipo Complementar Élio 09.03.2018
(Cf.FkEscritorio = @PkEscritorio)


Select @VendaPrazo = Coalesce(@VendaPrazo, 0) + Coalesce(Sum(C.Valor), 0)
From RegSaidas R
Join CondPagto C on (C.FkRegSaidas = R.Pk)
Join CadCondPagto Cp on (Cp.Pk = C.FkCadCondPagto)
Where (R.CodEmpresa = @CodEmpresa) and
(R.DataEmissao between @DataInicial and @DataFinal) and
(R.Vp in ('D')) and
(Cp.Faturamento = 2) and -- A Prazo
(Cp.FkEscritorio = @PkEscritorio) and
(R.TipoNota not in(2, 3, 4, 5, 6)) 

---- A vista

Select @VendaAVista = Sum((Coalesce((Rsi.Total), 0) - 
Case When @Pg368 = 1 Then --Parâmetro 368 define se abate icms st do faturamento
  0 
Else 
  Coalesce((Rsi.IcmsSt), 0) 
End))
From RegSaidas Rs
inner join RegSaidasItens Rsi on (Rs.Pk = Rsi.Fk)
inner join Cfop Cf on (Rsi.Cfop = Cf.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = Rsi.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Where (Rs.CodEmpresa = @CodEmpresa) and 
(Rs.DataEmissao between @DataInicial and @DataFinal) and 
(Ct.SomaValorFaturamento = 'Sim') and 
(Rs.Vp in('V', 'A')) and 
(Rs.TipoNota not in(2, 3, 4, 5, 6)) and --Adicionado o 6, ref nf do Tipo Complementar Élio 09.03.2018
(Cf.FkEscritorio = @PkEscritorio)


Select @VendaAVista =  Coalesce(@VendaAVista, 0) + Coalesce(Sum(C.Valor), 0)
From RegSaidas R
Join CondPagto C on (C.FkRegSaidas = R.Pk)
Join CadCondPagto Cp on (Cp.Pk = C.FkCadCondPagto)
Where (R.CodEmpresa = @CodEmpresa) and
(R.DataEmissao between @DataInicial and @DataFinal) and
(R.Vp in ('D')) and
(Cp.Faturamento = 1) and 
(Cp.FkEscritorio = @PkEscritorio) and 
(R.TipoNota not in(2, 3, 4, 5, 6)) 

Select @VendaAVista


Select @Ipi = Coalesce(Sum(I.IPI), 0)
From RegSaidas Rs
inner join RegSaidasItens Rsi on (Rs.Pk = Rsi.Fk)
Inner Join RegSaidasItensIpi I on (I.Fk = Rs.Pk) and (Rsi.Cfop = I.Cfop)
inner join Cfop Cf on (Rsi.Cfop = Cf.Cfop)
Inner JOin CfopTipoTributacao Ctt on (Ctt.Pk = Rsi.FkCfopTipoTributacao)
Inner Join CfopTipo Ct on (Ct.Pk = Ctt.FkCfopTipo)
Where (Rs.CodEmpresa = @CodEmpresa) and 
(Rs.DataEmissao between @DataInicial and @DataFinal) and 
(Ct.SomaValorFaturamento = 'Sim') and 
(Rs.VP <> 'D') and
(Rs.TipoNota not in(2, 3, 4, 5, 6)) and 
(Cf.FkEscritorio = @PkEscritorio)


Select @VendaAVista - @Ipi, @VendaPrazo, (@VendaAVista - @Ipi) + @VendaPrazo