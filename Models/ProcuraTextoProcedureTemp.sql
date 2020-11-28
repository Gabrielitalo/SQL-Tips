Declare @Procura1 NVarchar(4000), @Procura2 NVarchar(4000), @Procura3 NVarchar(4000), @Procura4 NVarchar(4000)

Set @Procura1 = 'exigibilidade'
Set @Procura2 = 'Delete Contabil' + Char(13) 
Set @Procura3 = 'SubscreveLancAutomatico = '

Select Distinct O.Name, O.modify_date, O.create_date
From SYS.sql_modules S
inner join sys.objects O on (O.object_id = S.Object_Id)
Where 
(S.definition like('%' + @Procura1 + '%')) 
--or (S.definition like ('%' + @Procura2 + '%'))) 
--and (S.definition not like ('%' + @Procura3 + '%')) 
--and (Left(O.Name, 2) <> 'Tg')  
--and (O.Name not in('PcExcluiContabil', 'PcExcluiAtividadeImobiliaria', 
--'PcExcluiDemaisDocumentos', 'PcExcluiImpostosParcelamento'))
--Order by O.name
--Order by O.modify_date desc


/*
If exists(Select Pk From Contabil Where (Fk = @PkRegEntradas) and (Fkc = @Pkc) and (SubscreveLancAutomatico = 'Não'))

*/

------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Declare @Texto Varchar(250) = '@Formula'

Select O.Name, SUBSTRING(s.definition, PATINDEX('%' + @Texto + '%', s.definition), 600) --, O.create_date, O.modify_date
From SYS.sql_modules S
inner join sys.objects O on (O.object_id = S.Object_Id)
Where (PATINDEX('%' + @Texto + '%', s.definition) > 0)	
--and (o.name <> @Name) 
--and (SUBSTRING(s.definition, PATINDEX('%Exec ' + @Texto + ' %', s.definition), 100) not like '%@PkUsuario%')
*/

------------------------------------------------------------------------------------------------------------------------------------------------------
