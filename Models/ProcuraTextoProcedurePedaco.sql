Declare @Texto Varchar(250) = 'dbo.FPg'

Select O.Name, SUBSTRING(s.definition, PATINDEX('%' + @Texto + '%', s.definition), 100) --, O.create_date, O.modify_date
From SYS.sql_modules S
inner join sys.objects O on (O.object_id = S.Object_Id)
Where (PATINDEX('%' + @Texto + '%', s.definition) > 0)	
--and (o.name <> @Name) 
and (SUBSTRING(s.definition, PATINDEX('%' + @Texto + '%', s.definition), 100) like '%0,%')

------------------------------------------------------------------------------------------------------------------------------------------------------
--Select * From FkComplementos Order By FkTable

------------------------------------------------------------------------------------------------------------------------------------------------------

