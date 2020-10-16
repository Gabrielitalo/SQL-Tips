-- Criado por Gabriel em 05/10/2020
-- Tem por finalidade retornar as procedures que possuem o parâmetro @DataSessao
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Begin Try Drop Table #ProceduresComDataSessao End Try Begin Catch End Catch
Create Table #ProceduresComDataSessao
(
	Pk int identity,
	PcName varchar(250)
)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Declare @ProcedureCr varchar(250)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

Declare CrProcedures Cursor Local static for
Select s.name
From Sys.objects S
Where (type = 'P') and -- Stored Procedures
(s.name not like '%PcSelect%') and
(s.name not like '%PcRel%') 
Order by s.name

Open CrProcedures 
Fetch Next From CrProcedures into @ProcedureCr
While (@@FETCH_STATUS = 0)
	Begin
			If Exists
			(
				Select 0 
				From sys.parameters 
				Where object_id = object_id(@ProcedureCr) and
				(name = '@DataSessao')
			)
			Begin
				Insert #ProceduresComDataSessao (PcName)
				Select @ProcedureCr
			End
			

		Fetch next from CrProcedures into @ProcedureCr
	End

Close CrProcedures
Deallocate CrProcedures
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Select *
From #ProceduresComDataSessao