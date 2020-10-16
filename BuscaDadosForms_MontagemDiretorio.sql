-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Varíaveis
Declare @Caminho varchar(128), @Total varchar(128), @i int, @DirPai varchar(128), @DirPai2 varchar(128), @DirPai3 varchar(128), @DirPai4 varchar(128), 
@DirPai5 varchar(128), @DirPai6 varchar(128), @Arquivo varchar(128)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tabela Oficial
Begin Try Drop Table #ListaDiretoriosFinalMakroWeb End Try Begin Catch End Catch
Create Table #ListaDiretoriosFinalMakroWeb
(
	Nivel int,
  Diretorio varchar(255),
	DirPai varchar(128)

)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Begin Try Drop Table #Retorno End Try Begin Catch End Catch  
--Create Table #Retorno    
--(  
--  NumeroLinha INT IDENTITY(1, 1),  
--  ResultadoLinha VARCHAR(MAX)
--) 

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Nivel 1
Set @Caminho = 'C:\A\T' -- Diretório inicial
Set @i = 1 -- Nº do Nivel inicial 
Exec PcListaDiretorios @Caminho, @i, 1
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Início da listagem dos diretórios

Set @Total = ''

Declare CrNivel2 Cursor Local static for

Select Distinct Diretorio
From #ListaDiretoriosFinalMakroWeb

Open CrNivel2 
Fetch next from CrNivel2 into @DirPai
while (@@FETCH_STATUS = 0)
	Begin
		  Set @Total = @Caminho + '\' + @DirPai
			Set @i = 2
			Exec PcListaDiretorios @Total, @i, 1
					 			
		Fetch next from CrNivel2 into @DirPai
	End

		-- Fim nivel 2
Close CrNivel2
Deallocate CrNivel2

-- Nivel 3
Declare CrNivel3 Cursor Local static for	
	Select Distinct Concat(DirPai,'\', Diretorio)
	From #ListaDiretoriosFinalMakroWeb
	Where (Nivel = 2)
Open CrNivel3 
Fetch next from CrNivel3 into @DirPai2
while (@@FETCH_STATUS = 0)
	Begin
		Set @Total = @DirPai2
		Set @i = 3
		Exec PcListaDiretorios @Total, @i, 1
					
		Fetch next from CrNivel3 into @DirPai2
	End
	-- Fim Nivel 3
Close CrNivel3
Deallocate CrNivel3


-- Nivel 4
Declare CrNivel4 Cursor Local static for
	
	Select Distinct Concat(DirPai,'\', Diretorio)
	From #ListaDiretoriosFinalMakroWeb
	Where (Nivel = 3)

Open CrNivel4 
Fetch next from CrNivel4 into @DirPai3
while (@@FETCH_STATUS = 0)
Begin
	Set @Total = @DirPai3
	Set @i = 4
	Exec PcListaDiretorios @Total, @i, 1

	Fetch next from CrNivel4 into @DirPai3
End
-- Fim Nivel 4
Close CrNivel4
Deallocate CrNivel4


-- Nivel 5
Declare CrNivel5 Cursor Local static for
	
	Select Distinct Concat(DirPai,'\', Diretorio)
	From #ListaDiretoriosFinalMakroWeb
	Where (Nivel = 4)

Open CrNivel5 
Fetch next from CrNivel5 into @DirPai4
while (@@FETCH_STATUS = 0)
	Begin
		Set @Total = @DirPai4
		Set @i = 5
		Exec PcListaDiretorios @Total, @i, 1
								
		Fetch next from CrNivel5 into @DirPai4
	End
	-- Fim Nivel 5
Close CrNivel5
Deallocate CrNivel5


-- Nivel 6
Declare CrNivel6 Cursor Local static for
	
	Select Distinct Concat(DirPai,'\', Diretorio)
	From #ListaDiretoriosFinalMakroWeb
	Where (Nivel = 5)

Open CrNivel6 
Fetch next from CrNivel6 into @DirPai5
while (@@FETCH_STATUS = 0)
	Begin
		Set @Total = @DirPai5
		Set @i = 6
		Exec PcListaDiretorios @Total, @i, 1
								
		Fetch next from CrNivel6 into @DirPai5
	End
	-- Fim Nivel 6
Close CrNivel6
Deallocate CrNivel6

-- Nivel 7
Declare CrNivel7 Cursor Local static for
	
	Select Distinct Concat(DirPai,'\', Diretorio)
	From #ListaDiretoriosFinalMakroWeb
	Where (Nivel = 6)

Open CrNivel7 
Fetch next from CrNivel7 into @DirPai6
while (@@FETCH_STATUS = 0)
	Begin
		Set @Total = @DirPai6
		Set @i = 7
		Exec PcListaDiretorios @Total, @i, 1
								
		Fetch next from CrNivel7 into @DirPai6
	End
	-- Fim Nivel 7
Close CrNivel7
Deallocate CrNivel7

--Select *
--From #ListaDiretoriosFinalMakroWeb

-- Fim da listagem dos diretórios
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Buscando todos arquivos de cada diretório

Begin Try Drop Table #ListaArquivosFinalMakroWeb End Try Begin Catch End Catch
Create Table #ListaArquivosFinalMakroWeb
(
	Nivel int,
  Arquivo varchar(255),
	DirPai varchar(128)
)

Set @DirPai = ''
Declare CrArquivos Cursor Local static for

Select Distinct Concat(DirPai, '\', Diretorio)
From #ListaDiretoriosFinalMakroWeb

Open CrArquivos 
Fetch next from CrArquivos into @DirPai
while (@@FETCH_STATUS = 0)
	Begin
  	Set @i = 0
		Exec PcListaDiretorios @DirPai, @i, 2
					 			
		Fetch next from CrArquivos into @DirPai
	End

		
Close CrArquivos
Deallocate CrArquivos


--Select Concat(DirPai, '\', Arquivo) Caminho
--From #ListaArquivosFinalMakroWeb
--return

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aqui será a parte do filtro onde serão abertos cada documento LerArquivoProj
-- Filtros na Pc: LerArquivoProj
Begin Try Drop Table #ListaArquivosFiltro End Try Begin Catch End Catch
Create Table #ListaArquivosFiltro
(
	Caminho varchar(128),
	NomeArquivo varchar(128),
	Arquivo Varchar(Max)
)

Set @DirPai = ''
Declare CrArquivos Cursor Local static for

Select Distinct Concat(DirPai, '\', Arquivo), Arquivo
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

--ConstrCivilCadEntidadeEducativaDetalhes.aspx.cs não entra na consulta porque o caminho é grande
-------------------------------------------------------------------------------------------------------
--Select Caminho, NomeArquivo, Arquivo
--From #ListaArquivosFiltro
--Where (NomeArquivo like '%.cs') and
----(Arquivo not like '%using %')
----Where (NomeArquivo like 'PlanoContasCustosLinksDetalhes%')
--(Arquivo like '%, DataSessao%')  and 
------(Arquivo like '%cmd.Parameters.AddWithValue("@DataSessao", DataSessao);%') and 
----(Arquivo not like '%DataSessao =%')
--Order by NomeArquivo


Select Caminho, NomeArquivo
From #ListaArquivosFiltro
Where (NomeArquivo like '%Detalhes.cs') and
(Arquivo like '%@CodEmpresa, DataSessao%')  --and 
--(Arquivo like '%cmd.Parameters.AddWithValue("@DataSessao", DataSessao);%') and 
--(Arquivo like '%((HiddenField)Master.FindControl("hdDataSessao")).Value = DataSessao;%')
Order by NomeArquivo


--and (Substring(Arquivo, CharIndex(@InicioSelect, Arquivo), CharIndex(@FimSelect, Arquivo))  like '%@DataSessao%')
-------------------------------------------------------------------------------------------------------
--Select L1.Caminho, L1.NomeArquivo
--From #ListaArquivosFiltro	L1
--join #ListaArquivosFiltro L2 on (L2.NomeArquivo = (L1.NomeArquivo + '.cs'))
--Where (L1.NomeArquivo not like '%detalhes.aspx') and
--(L1.Arquivo not like '%ID="BtnExcluir"%')	and
--(L2.NomeArquivo like '%.cs') and
--(L2.Arquivo like '%protected void BtnExcluir_Click%')
--Order by L1.NomeArquivo

-------------------------------------------------------------------------------------------------------
-- Buscar arquivos com texto e faz mais filtros do conteúdo
--Begin Try Drop Table #FiltroArquivoCursor End Try Begin Catch End Catch
--Create Table #FiltroArquivoCursor 
--(
--	Caminho varchar(128),
--	NomeArquivo varchar(128),
--	Arquivo Varchar(Max)
--)
--Declare @InicioSelect varchar(250) = 'cmd = new SqlCommand("PcSelect', @FimSelect varchar(250) = 'da.Fill(ds);'

--Declare @CaminhoCr varchar(250), @NomeArquivoCr varchar(120), @ArquivoCr varchar(MAX)

--Declare CrVerificaArquivo Cursor Local static for
--Select Caminho, NomeArquivo, Arquivo
--From #ListaArquivosFiltro
--Where (NomeArquivo like '%.cs') and
--(Arquivo like '%cmd = new SqlCommand("PcSelect%') 

--Open CrVerificaArquivo 
--Fetch Next From CrVerificaArquivo into @CaminhoCr, @NomeArquivoCr, @ArquivoCr
--While (@@FETCH_STATUS = 0)
--	Begin
--			Begin Try
--				Set @ArquivoCr = Substring(@ArquivoCr, CharIndex(@InicioSelect, @ArquivoCr), CharIndex(@FimSelect, @ArquivoCr) - CharIndex(@InicioSelect, @ArquivoCr)) 

--				If (@ArquivoCr like '%cmd.Parameters.AddWithValue("@DataSessao", DataSessao);%')
--					Begin
--						Insert #FiltroArquivoCursor
--						Select @CaminhoCr, @NomeArquivoCr, @ArquivoCr
--					End
--			End Try
--			Begin Catch
--			End Catch

--		Fetch next from CrVerificaArquivo into @CaminhoCr, @NomeArquivoCr, @ArquivoCr
--	End

--Close CrVerificaArquivo
--Deallocate CrVerificaArquivo

--Select *
--From #FiltroArquivoCursor