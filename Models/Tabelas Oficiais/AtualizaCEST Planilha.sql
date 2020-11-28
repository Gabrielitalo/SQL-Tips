Declare @Caminho varchar(128), @Cmd varchar(8000)

-- Caminho da planilha
--Set @Caminho = '\\192.168.0.5\Arquivo\1\Usuários\4387\cest2020.xlsx'

--Set @Cmd = Concat('
--Select * 
--From OPENDATASOURCE(''Microsoft.ACE.OLEDB.12.0'',
--''Data Source=', @Caminho, ';Extended Properties=Excel 12.0'')...[Sheet1$]') -- Sheet1$ = Nome da planilha

--print @Cmd
--Exec @Cmd

Begin Try Drop Table #TempCest End Try Begin Catch End Catch
Begin Try Drop Table #CadCestFaltantes End Try Begin Catch End Catch

-- Resultado do print
Select * Into #TempCest
From OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0',
'Data Source=\\192.168.0.5\Arquivo\1\Usuários\4387\cest2020.xlsx;Extended Properties=Excel 12.0')...[Sheet1$]

--Select *
--From #TempCest
--return

Delete #TempCest
Where (cest = 'REVOGADO')

Select TC.cest, TC.descricao, 
(Select Pk From CadCestSeguimento C Where (Left(C.Descricao, 2) = (Left(TC.item, 2)))) FkSeguimento
Into #CadCestFaltantes
From #TempCest TC
Left Join CadCEST C on (C.CEST = TC.cest)
Where (C.Pk is null)

--Select *
--From #CadCestFaltantes
--return

Declare @CestCt varchar(50), @Decricaco varchar(8000), @FkSeguimento int

--sp_columns 'CadCEST'

Declare CrInsertCadCest Cursor Local static for
Select Left(cest, 9), Left(descricao, 8000), FkSeguimento
From #CadCestFaltantes T
Open CrInsertCadCest 
Fetch Next From CrInsertCadCest into @CestCt, @Decricaco, @FkSeguimento
While (@@FETCH_STATUS = 0)
	Begin
		  Insert CadCEST (CEST, Descricao, FkCadCestSeguimento)
			Select @CestCt, 
			@Decricaco,
			@FkSeguimento


		Fetch next from CrInsertCadCest into @CestCt, @Decricaco, @FkSeguimento
	End

Close CrInsertCadCest
Deallocate CrInsertCadCest