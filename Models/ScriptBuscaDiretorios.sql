Declare @Caminho varchar(128) = 'E:\MakroWebNovo\MakroWeb.csproj', @DirPai varchar(128) = '', @Arquivo varchar(50) = ''


Begin Try Drop Table #ListaArquivosFinalMakroWeb End Try Begin Catch End Catch
Create Table #ListaArquivosFinalMakroWeb
(
	DirCompleto varchar(255),
	NomeArquivo varchar(128)
)


Begin Try Drop Table #ListaArquivosFiltro End Try Begin Catch End Catch
Create Table #ListaArquivosFiltro
(
	Caminho varchar(128),
	NomeArquivo varchar(128),
	Arquivo NVarchar(Max)

)

-- Ler o arquivo .CsProj
Exec PcLerArquivos @Caminho, ''

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aqui será a parte do filtro onde serão abertos cada documento LerArquivoProj
-- Filtros na Pc: LerArquivoProj

Declare CrArquivos Cursor Local static for

Select DirCompleto, NomeArquivo
From #ListaArquivosFinalMakroWeb

Open CrArquivos 
Fetch next from CrArquivos into @DirPai, @Arquivo
while (@@FETCH_STATUS = 0)
	Begin
		  
			Exec PcLerArquivos @DirPai, @Arquivo
					 			
		Fetch next from CrArquivos into @DirPai, @Arquivo
	End

		
Close CrArquivos
Deallocate CrArquivos

--Select *
--From #ListaArquivosFinalMakroWeb

Select NomeArquivo
From #ListaArquivosFiltro

