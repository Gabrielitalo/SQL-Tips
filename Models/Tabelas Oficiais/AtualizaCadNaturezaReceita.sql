Declare @Registros Table (Codigo int, DescNatureza varchar(800), DataInicial datetime, DataFinal datetime, NumeroTabela varchar(20))
Declare @RegistrosFilhos Table (Tabela varchar(20), FkCstPis int, FkCstCofins int)

Declare @Codigo int, @DescNatureza varchar(800), @DataInicial datetime, @DataFinal datetime, @NumeroTabela varchar(20), @PkTemp int
---------------------------------------------------------------------------------------------------------------------------------------------------

Begin Try Drop Table #TempCadNatureza End Try Begin Catch End Catch

-- Obtendo dados da tabela em Excel
Select * Into #TempCadNatureza
From OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0',
'Data Source=\\192.168.0.5\Arquivo\1\Usuários\4387\CadNaturezaReceita.xlsx;Extended Properties=Excel 12.0')...[Plan1$]

Delete #TempCadNatureza
Where (Pk is not null)

Insert @Registros
Select T.CodigoNatureza, DescricaoNatureza, Convert(Date, DataInicial), Convert(Date, DataFinal), NumeroTabela
From #TempCadNatureza T


-- Cst 02
Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.10', 38, 38

Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.10', 75, 75

Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.10', 42, 42

-- Cst 04
Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.10', 44, 44

Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.10', 77, 77

Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.10', 108, 108

	
-- Cst 04
Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.16', 49, 49

-- Cst 04
Insert @RegistrosFilhos
(Tabela, FkCstPis, FkCstCofins)
Select '4.3.16', 82, 82

-- Registros do banco oficial
Insert @Registros
Select CodigoNatureza,
DescricaoNatureza,
DataInicial,
DataFinal,
NumeroTabela
From MakroContabil..CadNaturezaReceita

---------------------------------------------------------------------------------------------------------------------------------------------------

Declare CrInsertCadNaturezaReceita Cursor Local static for
Select Codigo, DescNatureza, DataInicial, DataFinal, NumeroTabela
From @Registros
Open CrInsertCadNaturezaReceita 
Fetch Next From CrInsertCadNaturezaReceita into @Codigo, @DescNatureza, @DataInicial, @DataFinal, @NumeroTabela
While (@@FETCH_STATUS = 0)
	Begin
    If Not Exists
    (
      Select Pk
      From CadNaturezaReceita
      Where (CodigoNatureza = @Codigo) and
      (DescricaoNatureza = @DescNatureza) and
      (DataInicial = @DataInicial) and
      (NumeroTabela = @NumeroTabela)
    )
      Begin
        Insert CadNaturezaReceita
        (CodigoNatureza, DescricaoNatureza, DataInicial, DataFinal, NumeroTabela, Observacao)
        Select @Codigo, -- Codigo Natureza
        @DescNatureza, -- Descrição Natureza
        @DataInicial, -- DataInicial
        @DataFinal, -- DataFinal
        @NumeroTabela, -- NumeroTabela
        '' -- Observacao
      End
		Else
			Begin
				Update CadNaturezaReceita
				Set DataFinal = @DataFinal
				Where (CodigoNatureza = @Codigo) and
				(DataInicial = @DataInicial) and
				(NumeroTabela = @NumeroTabela)
			End
		Fetch next from CrInsertCadNaturezaReceita into @Codigo, @DescNatureza, @DataInicial, @DataFinal, @NumeroTabela
	End

Close CrInsertCadNaturezaReceita
Deallocate CrInsertCadNaturezaReceita

Set @Codigo = 0
Set @NumeroTabela = ''

Declare CrRegistrosFilhos Cursor Local static for
Select Codigo, NumeroTabela
From @Registros
Open CrRegistrosFilhos 
Fetch Next From CrRegistrosFilhos into @Codigo, @NumeroTabela
While (@@FETCH_STATUS = 0)
	Begin

    Set @PkTemp = 0
    
    Select @PkTemp = Pk
    From CadNaturezaReceita
    Where (CodigoNatureza = @Codigo) and
    (NumeroTabela = @NumeroTabela)

    If Not Exists
    (
      Select Pk
      From CadNaturezaReceitaItens
      Where (FkCadNaturezaReceita = @PkTemp)
    )
      Begin
        Insert CadNaturezaReceitaItens
        (FkCadNaturezaReceita, FkCstPis, FkCstCofins)
        Select @PkTemp,
        FkCstPis,
        FkCstCofins
        From @RegistrosFilhos 
        Where (Tabela = @NumeroTabela) 
      End

		Fetch next from CrRegistrosFilhos into @Codigo, @NumeroTabela
	End

Close CrRegistrosFilhos
Deallocate CrRegistrosFilhos

--Select *
--From CadNaturezaReceita
--Where (CodigoNatureza in (Select Codigo From @Registros))

--Select *
--From CadNaturezaReceitaItens
--Where (FkCadNaturezaReceita in (699, 702, 703, 704))

--Delete CadNaturezaReceitaItens
--Where (FkCadNaturezaReceita in (699, 702, 703, 704))


--Select *
--From CodigoSituacaoTributaria
--Where (Codigo in (09))