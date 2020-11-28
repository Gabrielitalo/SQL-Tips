Declare @Caminho varchar(128) = 'E:\MakroWebNovo\MakroWeb.csproj', @DirPai varchar(800) = '', @Arquivo varchar(50) = ''

Begin Try Drop Table #ListaArquivosFinalMakroWeb End Try Begin Catch End Catch
Create Table #ListaArquivosFinalMakroWeb
(
	DirCompleto varchar(800),
	NomeArquivo varchar(128)
)


Begin Try Drop Table #ListaArquivosFiltro End Try Begin Catch End Catch
Create Table #ListaArquivosFiltro
(
	Caminho varchar(800),
	NomeArquivo varchar(128),
	Arquivo NVarchar(Max)
)

Begin Try Drop Table #Retorno End Try Begin Catch End Catch  
Create Table #Retorno    
(  
  NumeroLinha INT IDENTITY(1, 1),  
  ResultadoLinha VARCHAR(MAX)
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

-------------------------------------------------------------------------------------------------------
--Select Caminho, NomeArquivo
--From #ListaArquivosFiltro
--Where (NomeArquivo like '%.cs') and
--(NomeArquivo like '%Detalhes%') and
--(Arquivo not like '%Page.link("/App_Themes/CSS");%')
--Order by NomeArquivo

-------------------------------------------------------------------------------------------------------
Select L2.Caminho, L2.NomeArquivo
From #ListaArquivosFiltro	L1
join #ListaArquivosFiltro L2 on (L2.NomeArquivo = L1.NomeArquivo)
Where (L1.NomeArquivo like '%Detalhes.aspx') and
(L2.NomeArquivo like '%Detalhes.aspx') and
(L2.Arquivo not like '%BtnVoltar%')
--and (L2.Arquivo like '%protected void BtnExcluir_Click%')
Order by L1.NomeArquivo

-------------------------------------------------------------------------------------------------------
--Select Caminho, NomeArquivo
--From #ListaArquivosFiltro
--Where (NomeArquivo like '%Detalhes.aspx') and
--(Arquivo like '%ID="BtnVoltar%') --and
----(Arquivo not like '%OnClick="Btn_Relatorios_Click"%')
--Order by NomeArquivo
---------------------------------------------------------------------------------------------------------
--Select L1.Caminho, L1.NomeArquivo
--From #ListaArquivosFiltro L1
--Join #ListaArquivosFiltro L2 on (L2.NomeArquivo = L1.NomeArquivo)
--Where (L1.NomeArquivo like '%Detalhes.aspx') and
--(L2.Arquivo not like '%ID="BtnVoltar%') --and
----(Arquivo not like '%OnClick="Btn_Relatorios_Click"%')
--Order by NomeArquivo

-------------------------------------------------------------------------------------------------------
--Select L1.Caminho, L1.NomeArquivo
--From #ListaArquivosFiltro	L1
--join #ListaArquivosFiltro L2 on (L2.NomeArquivo = (L1.NomeArquivo + '.cs'))
--Where 
--(L1.NomeArquivo like '%.aspx') and
--(L1.Arquivo like '%ID="BtnExcluir"%')	and
--(L2.NomeArquivo like '%.cs') and
--(L2.Arquivo not like '%_RowDeleting(object%')
--Order by L1.NomeArquivo

-------------------------------------------------------------------------------------------------------

--E:\MakroWebNovo\FormFiscal\RegApContrPrevidenciaria\RegApContrPrevidenciariaDetalhes\RegApContrPrevidenciariaDetalhes.aspx
--E:\MakroWebNovo\FormFiscal\BlocoI\BlocoIDetalhes\RegApPisCofinsEfdBlocoIDetalhes.aspx
--E:\MakroWebNovo\FormFiscal\RegApPisCofinsEfd\Credito\Ajustes\Detalhes\RegApPisCofinsEfdCreditoAjustesDetalhes.aspx
--E:\MakroWebNovo\FormFiscal\RegApPisCofinsEfd\Debito\Ajustes\Detalhes\RegApPisCofinsEfdDebitoAjustesDetalhes.aspx
--E:\MakroWebNovo\FormContatos\SubDetalhes\TelUteisSubDetalhes.aspx