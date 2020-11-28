------------------------------------------------------------------------------------------------------------------------
Declare @query varchar(1000), @FileName varchar(200), @Caminho varchar(1000), @Extensao varchar(100),
@CaminhoC Varchar(1000), @PkConteudoArquivo Int, @textoProcurar Varchar(255), @teste Varchar(Max)

------------------------------------------------------------------------------------------------------------------------
Begin Try Drop Table #NomeArquivo End Try Begin Catch End Catch
Create table #NomeArquivo (nome varchar(300))

Begin Try Drop Table #ConteudoArquivo End Try Begin Catch End Catch
Create table #ConteudoArquivo (Conteudo varchar(Max))

Set @Caminho = 'G:\Makrosystem\MakroSite\'
Set @Extensao = '*.aspx'
Set @query = 'master.dbo.xp_cmdshell "dir ' + @Caminho + @Extensao + ' /s /d /b"'

Set @TextoProcurar = 'programa para contabilidade'

Insert #NomeArquivo exec(@query)

Delete #NomeArquivo 
Where Nome is NULL

Alter Table #NomeArquivo Add Achou Char(3)

------------------------------------------------------------------------------------------------------------------------
Declare CrNomeArquivo cursor static for
Select Nome
From #NomeArquivo
Order By Nome
Open CrNomeArquivo
Fetch next from CrNomeArquivo Into @FileName
While @@Fetch_Status = 0
  begin
		Delete #ConteudoArquivo

		Set @Teste = ''
    Set @CaminhoC = @FileName
		Set @CaminhoC = '''' + @CaminhoC + ''''

    set @Query = ('BULK INSERT #ConteudoArquivo FROM ' + @CaminhoC) --+ 'With(KEEPNULLS)')-- + 'WITH(FIELDTERMINATOR = ''|'')')
    exec (@query)

		Select @Teste = Conteudo
		From #ConteudoArquivo
    Where (Conteudo like '%' + @TextoProcurar + '%')
    
    --Não pode por not like Ademar 18/09/2012
    --pois cada arquivo retorna n registros, sendo assim não funciona
    --Use o Where Abaixo Achou = 'Não'

		If Coalesce(@Teste, '') <> ''
			Begin
				Update #NomeArquivo
				Set Achou = 'Sim'
				Where (Nome = @FileName)
			End
    Else
      Begin
				Update #NomeArquivo
				Set Achou = 'Não'
				Where (Nome = @FileName)
      End
      
    Fetch next from CrNomeArquivo Into @FileName
  end
  
------------------------------------------------------------------------------------------------------------------------
Close CrNomeArquivo
Deallocate CrNomeArquivo

------------------------------------------------------------------------------------------------------------------------
Select Nome
From #NomeArquivo
Where (Achou = 'Não')
Order By Nome

------------------------------------------------------------------------------------------------------------------------
