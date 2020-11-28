Declare @i int, @CodigoCr int, @CodEmpresaTemp int, @PkEscritorio int = 1

-- Update nas Informações Complementares
--Print 'Iniciando Informações Complementares'
Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Join CadEmpresa C on (C.CodEmpresa = I.CodEmpresa)
Where (I.Tipo = 1) and
(C.FkEscritorio = @PkEscritorio)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0


		--Select @i = Coalesce(Max(Codigo), 0)
		--From InfComplementares 
		--Where (CodEmpresa = @CodEmpresaTemp) and
		--(Tipo = 1) and
		--(Origem = 'Manual')
		----------------------------------------------------------------------------------------------------------------
		-- Cursor que irá buscar os códigos de cada empresa
		Declare CrUpInfComplementares Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 1) and-- Informações complementares
		--((I.Codigo is null) or (I.Codigo = ''))
    (Coalesce(Origem, '') <> 'NFE')
		Order by Pk Asc

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
--Print 'Iniciando Observações'
Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Join CadEmpresa C on (C.CodEmpresa = I.CodEmpresa) and
(C.FkEscritorio = @PkEscritorio)
Where (I.Tipo = 2)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0
		
		--Select @i = Coalesce(Max(Codigo), 0)
		--From InfComplementares 
		--Where (CodEmpresa = @CodEmpresaTemp) and
		--(Tipo = 1) and
		--(Origem = 'Manual')
		----------------------------------------------------------------------------------------------------------------
		-- Cursor que irá buscar os códigos de cada empresa
		Declare CrUpObservacos Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 2) and -- Observações
		--((I.Codigo is null) or (I.Codigo = ''))
    --((Origem = 'Manual') or (Origem is null))
    (Coalesce(Origem, '') <> 'NFE')
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

----------------------------------------------------------------------------------------------------------------
-- NFE


Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Join CadEmpresa C on (C.CodEmpresa = I.CodEmpresa)
Where (I.Tipo = 1) and
(C.FkEscritorio = @PkEscritorio)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0

    Set @CodEmpresaTemp = 24393

		--Select @i = Coalesce(Max(Codigo), 0)
		--From InfComplementares 
		--Where (CodEmpresa = @CodEmpresaTemp) and
		--(Tipo = 1) and
		--(Origem = 'Manual')
		----------------------------------------------------------------------------------------------------------------
		-- Cursor que irá buscar os códigos de cada empresa
		Declare CrUpInfComplementares Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 1) and-- Informações complementares
		--((I.Codigo is null) or (I.Codigo = ''))
    (Coalesce(Origem, '') = 'NFE')
		Order by Pk Asc

		Open CrUpInfComplementares 
		Fetch next from CrUpInfComplementares into @CodigoCr
		While (@@FETCH_STATUS = 0)
			Begin
				Set @i += 1
						
				Update InfComplementares
				Set Codigo = Concat('N', @i), 
        Origem = 'NFE'
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
--Print 'Iniciando Observações'
Declare CrEmpresa Cursor Local static for
	
Select Distinct I.CodEmpresa
From InfComplementares I
Join CadEmpresa C on (C.CodEmpresa = I.CodEmpresa) and
(C.FkEscritorio = @PkEscritorio)
Where (I.Tipo = 2)
Order by I.CodEmpresa

Open CrEmpresa 
Fetch next from CrEmpresa into @CodEmpresaTemp
While (@@FETCH_STATUS = 0)
	Begin
		Set @i = 0
		
		--Select @i = Coalesce(Max(Codigo), 0)
		--From InfComplementares 
		--Where (CodEmpresa = @CodEmpresaTemp) and
		--(Tipo = 1) and
		--(Origem = 'Manual')
		----------------------------------------------------------------------------------------------------------------
		-- Cursor que irá buscar os códigos de cada empresa
		Declare CrUpObservacos Cursor Local static for
	
		Select I.Pk
		From InfComplementares I
		Where (I.CodEmpresa = @CodEmpresaTemp) and
		(I.Tipo = 2) and -- Observações
		--((I.Codigo is null) or (I.Codigo = ''))
    --((Origem = 'Manual') or (Origem is null))
    (Coalesce(Origem, '') = 'NFE')
		Order by Pk

		Open CrUpObservacos 
		Fetch next from CrUpObservacos into @CodigoCr
		While (@@FETCH_STATUS = 0)
			Begin
				Set @i += 1
						
				Update InfComplementares
				Set Codigo = Concat('N', @i),
        Origem = 'NFE'
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


--Select CodEmpresa, Codigo, Count(Codigo)
--From InfComplementares I
--Where-- (I.CodEmpresa = @CodEmpresaTemp) and
--(I.Tipo = 1)
--Group by CodEmpresa, Codigo
--Having Count(Codigo) > 1


--Select Codigo, Count(Codigo)
--From InfComplementares I
--Where(I.CodEmpresa = 198) and
--(I.Tipo = 1)
--Group by Codigo
--Having Count(Codigo) > 1

