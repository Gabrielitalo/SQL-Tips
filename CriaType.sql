-- Esse script cria o tipo de Table usado em um objeto do lado do C# (Data Table)
-- Esse type é usado na Procedure PcImportaNfeServicosGinfesXlsSotec

If Not Exists (Select name From sys.types Where is_table_type = 1 AND name = 'ClasseParaMinasXLS')
	Begin
		Create Type ClasseParaMinasXLS as Table
		(
			NotaFiscal Varchar(30),
			Serie Varchar(30),
			Dia Varchar(10),
			Competencia Varchar(30),
			BaseCalculo Varchar(30),
			ValorAbatimento Varchar(30),
			Aliquota Varchar(30),
			ValorImposto Varchar(30),
			ValorNF Varchar(30),
			Situacao Varchar(30),
			IMTomadorPrestador Varchar(30),
			CnpjTomadorPrestador Varchar(30)
		)
	End

