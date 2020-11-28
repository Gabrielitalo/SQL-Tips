Declare @CodEmpresa int = 223, @DataInicialP datetime = '2019-11-01', @DataFinalP datetime = '2019-11-30', @PkUsuario int = 242, @PkNota int = 0



Declare CrSincFiscalContabil Cursor Local static for	
Select R.Pk
From RegSaidas R
Left Join Contabil C on ((C.Fk = R.Pk) and (C.FkC = R.PkC))
Where (R.CodEmpresa = @CodEmpresa) and
((R.DataEmissao between @DataInicialP and @DataFinalP) or
(R.DataSaida between @DataInicialP and @DataFinalP)) and
(R.TipoNota not in(2, 3, 4, 5, 6, 7)) and
(C.Pk is null)
Open CrSincFiscalContabil 
Fetch Next From CrSincFiscalContabil into @PkNota
While (@@FETCH_STATUS = 0)
	Begin
      -- Contabilizando nota a nota
    --Exec PcRegSaidasInsertContabil @PkNota, @PkUsuario    

		Fetch next from CrSincFiscalContabil into @PkNota
	End

Close CrSincFiscalContabil
Deallocate CrSincFiscalContabil
