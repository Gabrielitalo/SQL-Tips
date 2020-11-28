---------------------------------------------------------------------------------------------------------------------
Declare @Procura1 NVarchar(4000), @Procura2 NVarchar(4000), @Procura3 NVarchar(4000), @Procura4 NVarchar(4000)

---------------------------------------------------------------------------------------------------------------------
--Declare @T Varchar(250) = 'Semanal'
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--Exec PcColumns TipoChcExportacao, 'RegSaidas'

Set @Procura1 = 'Para lançamento Simples será permiti' --@NomeArquivo
Set @Procura2 = 'FkFabricante' 
Set @Procura3 = 'Numeric(18, 2)'

--like ' + '%' + Replace(@Historico, '''', '') + '%'

---------------------------------------------------------------------------------------------------------------------
Select Distinct O.Name, O.modify_date, O.create_date
From SYS.sql_modules S
inner join sys.objects O on (O.object_id = S.Object_Id)
Where 
(S.definition like ('%' + @Procura1 + '%'))
--and (S.definition Like ('%' + @Procura2 + '%'))
--and (S.definition like('%' + @Procura3 + '%')) 
--and (S.definition like ('%' + @Procura3 + '%')) 
--or (S.definition like ('%' + @Procura3 + '%'))) 
--Order by O.name
Order by O.Name

---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--If @IndicativoPerApuracao = '' Set @IndicativoPerApuracao = 1