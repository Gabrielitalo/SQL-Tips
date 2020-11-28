Declare @PkCr int, @i int = 0, @CodEmpresaTemp int


Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Where (I.Tipo = 1)
--and (CodEmpresa = 135)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0

    Declare CrInfCompl Cursor Local static for
    Select Pk
    From InfComplementares
    Where (CodEmpresa = @CodEmpresaTemp) and
    (Tipo = 1) and
    (Origem = 'NFE')
    Order by Pk asc
    Open CrInfCompl 
    Fetch Next From CrInfCompl into @PkCr
    While (@@FETCH_STATUS = 0)
	    Begin

        Set @i += 1

        Update InfComplementares
        Set Codigo = Concat('N', @i)
        From InfComplementares
        Where (Pk = @PkCr) 

		    Fetch next from CrInfCompl into @PkCr
	    End

    Close CrInfCompl
    Deallocate CrInfCompl

	Fetch next from CrEmpresa into @CodEmpresaTemp
End

Close CrEmpresa
Deallocate CrEmpresa
