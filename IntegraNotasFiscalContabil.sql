Declare @CodEmpresa int = 17079, @DataInicialP datetime = '2019-12-01', @DataFinalP datetime = '2019-12-31', @PkUsuario int = 142, @PkNota int = 0, @CodEmpresaTemp int = 0

    Select R.Pk
    From RegPrestServicos R
    Left Join Contabil C on ((C.Fk = R.Pk) and (C.FkC = R.PkC))
    Where (R.CodEmpresa = @CodEmpresaTemp) and
    (R.Data between @DataInicialP and @DataFinalP) and
    (C.Pk is null)

    return

Declare CrEmpresa Cursor Local static for
	
Select CodEmpresa
From CadEmpresa
Where (CodigoMatriz = @CodEmpresa) and
(TipoCadastro = 'Ativa')
Order by CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin

    -- Saídas
    Declare CrSincFiscalContabil Cursor Local static for	
    Select R.Pk
    From RegSaidas R
    Left Join Contabil C on ((C.Fk = R.Pk) and (C.FkC = R.PkC))
    Where (R.CodEmpresa = @CodEmpresaTemp) and
    ((R.DataEmissao between @DataInicialP and @DataFinalP) or
    (R.DataSaida between @DataInicialP and @DataFinalP)) and
    (R.TipoNota not in(2, 3, 4, 5, 6, 7)) and
    (C.Pk is null)
    Open CrSincFiscalContabil 
    Fetch Next From CrSincFiscalContabil into @PkNota
    While (@@FETCH_STATUS = 0)
	    Begin
          -- Contabilizando nota a nota
        Exec PcRegSaidasInsertContabil @PkNota, @PkUsuario    

		    Fetch next from CrSincFiscalContabil into @PkNota
	    End

    Close CrSincFiscalContabil
    Deallocate CrSincFiscalContabil

    -- Serviços
    Declare CrSincFiscalContabil Cursor Local static for	
    Select R.Pk
    From RegPrestServicos R
    Left Join Contabil C on ((C.Fk = R.Pk) and (C.FkC = R.PkC))
    Where (R.CodEmpresa = @CodEmpresaTemp) and
    (R.Data between @DataInicialP and @DataFinalP) and
    (C.Pk is null)
    Open CrSincFiscalContabil 
    Fetch Next From CrSincFiscalContabil into @PkNota
    While (@@FETCH_STATUS = 0)
	    Begin
          -- Contabilizando nota a nota
        Exec PcRegSaidasInsertContabil @PkNota, @PkUsuario    

		    Fetch next from CrSincFiscalContabil into @PkNota
	    End

    Close CrSincFiscalContabil
    Deallocate CrSincFiscalContabil


	Fetch next from CrEmpresa into @CodEmpresaTemp
End

Close CrEmpresa
Deallocate CrEmpresa


