Declare @tblBancos Table (nome varchar(100), pos int)
Declare @NumBancos int , @cmd VarChar(MAX)

Insert @tblBancos
Select Sd.name, ROW_NUMBER() OVER(ORDER BY name ASC) 
From Sys.Databases Sd
Where (Name not in ('Master', 'Model', 'Msdb', 'TempDb')) and 
(Name not like '%Report%') and 
(Name not like '%Proj%') and 
(Left(Name, 2) Not In ('NG', 'Bk', 'Ts','Up'))
Order by name 

Set @NumBancos = @@ROWCOUNT

While (@NumBancos != 0)
	Begin
	 Set @Cmd = 'Use '+ (Select nome From @tblBancos where (pos = @NumBancos)) + ' ' +
	 ''
		Set @NumBancos-=1
		Print @cmd
		--Exec (@Cmd)
	End









