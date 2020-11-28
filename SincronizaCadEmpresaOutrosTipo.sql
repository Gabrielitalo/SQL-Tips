-----------------------------------------------------------------------------------------------------------
-- Criado por Gabriel
-----------------------------------------------------------------------------------------------------------
Declare @CodigoCr int

-- Busca com base nos dados que estão no Proj.
Declare CrUsuario Cursor Local static for	
Select Pk
From MakroContabil..CadEmpresaOutrosTipo
Open CrUsuario 
Fetch Next From CrUsuario into @CodigoCr
While (@@FETCH_STATUS = 0)
	Begin
			-- Se não existir o código na tabela irá inserir.
			If Not Exists(Select Pk From CadEmpresaOutrosTipo Where Pk = @CodigoCr)
				Begin
					Insert CadEmpresaOutrosTipo(Pk, Descricao, Observacao)
					Select Pk, Descricao, Observacao
					From MakroContabil..CadEmpresaOutrosTipo
					Where (Pk = @CodigoCr)
				End

		Fetch next from CrUsuario into @CodigoCr
	End

Close CrUsuario
Deallocate CrUsuario