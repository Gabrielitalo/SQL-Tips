Declare @T table (TabelaFilha Varchar(250), Fk Varchar(250))

Insert @T (TabelaFilha, Fk)
Select S8.Name, S7.name
From sys.objects S1
inner join sys.foreign_keys S2 on (S1.object_id = S2.referenced_object_id)
inner join sys.columns S3 on (S3.object_id = S2.referenced_object_id) and (S2.schema_id = S3.column_id)
inner join sys.foreign_key_columns S4 on (S4.constraint_object_id = S2.object_id) 
inner join sys.columns S5 on (S5.object_id = S2.referenced_object_id) and (S5.column_id = S4.referenced_column_id)
inner join sys.sysforeignkeys S6 on (S6.constid = S2.object_id)
inner join sys.Columns S7 on (S7.object_id = S6.fkeyid) and (S7.column_id = S6.fkey)
left join sys.objects S8 on (S8.object_id = S6.Fkeyid)


Select T.Name, C.Name
From sys.objects T
Join sys.columns C On (C.object_id = T.object_id)
left join @T T2 on (T2.TabelaFilha = T.Name) and (T2.Fk = C.Name)
Where (T.type_desc = 'USER_TABLE') and
(Left(C.Name, 2) = 'Fk') and
(Left(T.Name, 2) <> 'Tp') and (T2.TabelaFilha Is Null)
Order By T.Name


