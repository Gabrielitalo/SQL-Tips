Declare @NotaCr int, @PkUsuario int = 242, @DataInicial datetime = '2019-09-01', @DataFinal datetime = '2019-10-01'
Declare @Teste Table (Pk int)


----------------------------------------------------------------------------------------------------------------------------- 
-- Entradas

--Declare CrNotasContabiliza Cursor Local static for

--Select R.Pk
--From RegEntradas R
--Left Join Contabil C on (C.Fk = R.Pk) and (C.FkC = R.PkC)
--left Join ContabilItens Ci on (Ci.FkContabil = C.Pk)
--Where ((R.DataEmissao between @DataInicial and @DataFinal) or (R.DataEntrada between @DataInicial and @DataFinal)) and
--(Ci.Pk is null) and
--(C.Pk is not null) and
--(C.Alteracao is null)


--Open CrNotasContabiliza 
--Fetch next from CrNotasContabiliza into @NotaCr
--while (@@FETCH_STATUS = 0)
--	Begin
		 
--		Exec PcRegEntradasInsertContabil @NotaCr, @PkUsuario


--		Fetch next from CrNotasContabiliza into @NotaCr
--	End

--Close CrNotasContabiliza
--Deallocate CrNotasContabiliza

-----------------------------------------------------------------------------------------------------------------------------
-- Saídas

--Declare CrNotasContabiliza Cursor Local static for
	
--Select R.Pk
--From RegSaidas R
--Left Join Contabil C on (C.Fk = R.Pk) and (C.FkC = R.PkC)
--left Join ContabilItens Ci on (Ci.Pk = C.Fk)
--Where ((R.DataEmissao between @DataInicial and @DataFinal) or (R.DataSaida between @DataInicial and @DataFinal)) and
--(Ci.Pk is null) and
--(C.Pk is not null) and
--(C.Alteracao is null)

--Open CrNotasContabiliza 
--Fetch next from CrNotasContabiliza into @NotaCr
--while (@@FETCH_STATUS = 0)
--	Begin
		  
--		Exec PcRegSaidasInsertContabil @NotaCr, @PkUsuario


--		Fetch next from CrNotasContabiliza into @NotaCr
--	End

--Close CrNotasContabiliza
--Deallocate CrNotasContabiliza

-----------------------------------------------------------------------------------------------------------------------------
-- Serviços


Declare CrNotasContabiliza Cursor Local static for

Select R.Pk
From RegPrestServicos R
Left Join Contabil C on (C.Fk = R.Pk) and (C.FkC = R.PkC)
Left Join ContabilItens Ci on (Ci.Pk = C.Fk)
Where (R.Data between @DataInicial and @DataFinal) and
(Ci.Pk is null) and
(C.Pk is not null) and
(C.Alteracao is null)

Open CrNotasContabiliza 
Fetch next from CrNotasContabiliza into @NotaCr
while (@@FETCH_STATUS = 0)
	Begin

			Exec PcRegPrestServicosInsertContabil @NotaCr, @PkUsuario
			Exec PcInsertRetencoes @NotaCr, @PkUsuario, 'RegPrestServicos'

		Fetch next from CrNotasContabiliza into @NotaCr
	End

Close CrNotasContabiliza
Deallocate CrNotasContabiliza