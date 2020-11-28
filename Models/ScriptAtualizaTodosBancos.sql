-------------------------------------------------------------------------------------------
--Criado por Ademar em 09/08/2016
--Tem por finalidade rodar script em todos os bancos de dados
-------------------------------------------------------------------------------------------
Declare @Cmd Varchar(max), @NomeBanco Varchar(250)

Declare CrCursorBancos Cursor local static for 
Select name 
From sys.databases  
Where (Name not in ('Master', 'Model', 'Msdb', 'TempDb')) and 
(Name not like '%Report%') and 
(Name not like '%Proj%') and 
(Left(Name, 2) Not In ('NG', 'Bk', 'Ts','Up'))
Order by name
Open CrCursorBancos
Fetch Next From CrCursorBancos into @NomeBanco
While (@@Fetch_Status = 0)
	Begin

Print @NomeBanco
----------------------------------------------------------------------------------------------
--Trocar aqui o Script a ser rodado...Ademar.
---------------------------------------------
Set @Cmd = '
Use ' + @NomeBanco + ' 

---------------------------------------------------------------------------------------------------------------------------------------------------------------
Update ParametrosGlobais
Set Valor = ''Sim''
Where (Codigo = 442) and
(Valor <> ''Sim'')

---------------------------------------------------------------------------------------------------------------------------------------------------------------
'
		----------------------------------------------------------------------------------------------
		--Print @Cmd
		Exec (@Cmd)

		Fetch Next From CrCursorBancos into @NomeBanco
	End
Close CrCursorBancos
Deallocate CrCursorBancos

-------------------------------------------------------------------------------------------
--Alter table JoseGeraldoAlves.dbo.CatSefip Alter Column Historico Varchar(200) not null
-------------------------------------------------------------------------------------------
