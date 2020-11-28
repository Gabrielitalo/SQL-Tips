Declare @Caminho nvarchar(max), @query nvarchar(max), @Query2 nvarchar(max)


Begin try drop table #Conteudo End try Begin Catch end Catch      
Create Table #Conteudo ()

Declare @CaminhoC Varchar(8000)


Set @Caminho = '\\192.168.0.5\Arquivo\4\Usuários\2528\denyParaMinas.xls'
Set @CaminhoC = '' + @Caminho + ''''


Set @Query = 'Select * FROM OPENROWSET (''Microsoft.ACE.OLEDB.12.0'',
''EXCEL 12.0;Database=' + @CaminhoC + ', escrituracao$)'

--Exec (@Query)
Exec sp_ExecuteSql @Query


--Select *
--From #Conteudo