Declare @i int, @CodigoCr int, @CodEmpresaTemp int

-- Update nas Informa��es Complementares
Print 'Iniciando Informa��es Complementares'
Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Where (I.Tipo = 1)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0
		----------------------------------------------------------------------------------------------------------------
		-- Cursor que ir� buscar os c�digos de cada empresa
		Declare CrUpInfComplementares Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 1) and-- Informa��es complementares
		((I.Codigo is null) or (I.Codigo = ''))
		Order by Pk

		Open CrUpInfComplementares 
		Fetch next from CrUpInfComplementares into @CodigoCr
		While (@@FETCH_STATUS = 0)
			Begin
				Set @i += 1
						
				Update InfComplementares
				Set Codigo = @i,
				Origem = 'Manual'
				Where (Pk = @CodigoCr)

				Fetch next from CrUpInfComplementares into @CodigoCr
			End

			Close CrUpInfComplementares
			Deallocate CrUpInfComplementares
					 		
		----------------------------------------------------------------------------------------------------------------
		Fetch next from CrEmpresa into @CodEmpresaTemp
	End

Close CrEmpresa
Deallocate CrEmpresa

----------------------------------------------------------------------------------------------------------------------------
-- Update nas observa��es
Print 'Iniciando Observa��es'
Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Where (I.Tipo = 1)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0
		----------------------------------------------------------------------------------------------------------------
		-- Cursor que ir� buscar os c�digos de cada empresa
		Declare CrUpObservacos Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 2) and -- Observa��es
		((I.Codigo is null) or (I.Codigo = ''))
		Order by Pk

		Open CrUpObservacos 
		Fetch next from CrUpObservacos into @CodigoCr
		While (@@FETCH_STATUS = 0)
			Begin
				Set @i += 1
						
				Update InfComplementares
				Set Codigo = @i,
				Origem = 'Manual'
				Where (Pk = @CodigoCr)

				Fetch next from CrUpObservacos into @CodigoCr
			End

			Close CrUpObservacos
			Deallocate CrUpObservacos
					 		
		----------------------------------------------------------------------------------------------------------------
		Fetch next from CrEmpresa into @CodEmpresaTemp
	End

Close CrEmpresa
Deallocate CrEmpresa




