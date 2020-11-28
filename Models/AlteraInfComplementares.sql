Declare @i int, @CodigoCr int, @CodEmpresaTemp int

-- Update nas Informações Complementares
Print 'Iniciando Informações Complementares'
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
		-- Cursor que irá buscar os códigos de cada empresa
		Declare CrUpInfComplementares Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 1) and-- Informações complementares
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
-- Update nas observações
Print 'Iniciando Observações'
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
		-- Cursor que irá buscar os códigos de cada empresa
		Declare CrUpObservacos Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 2) and -- Observações
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




