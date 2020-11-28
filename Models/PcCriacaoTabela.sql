
----------------------------------------------------------------------------------------------------------------------------------
If not exists(Select Name From sys.objects Where (Name = 'NomeTabela'))
  Create table NomeTabela(
  Pk int identity(1, 1) not null CONSTRAINT [Pk_NomeTabela] PRIMARY KEY CLUSTERED,
  FkCadFornecedores int not null,
  FkEscritorio int not null,
  DataMatricula DateTime not null,
  Observacao Varchar(8000) null)
go	


----------------------------------------------------------------------------------------------------------------------------------
If not exists(Select Name From sys.Indexes Where (Name = 'IX_NomeTabela_NomeCampo'))
	Create index IX_NomeTabela_NomeCampo
	on dbo.NomeTabela
	(NomeCampo)
	With (FillFactor = 90)
go

----------------------------------------------------------------------------------------------------------------------------------

If not exists(Select Name From sys.objects Where (name = 'FkNomeCampo_NomeTabelaFilha_NomeTabelaPai'))
  ALTER TABLE NomeTabelaFilha With Check/Nocheck 
  ADD CONSTRAINT FkNomeCampo_NomeTabelaFilha_NomeTabelaPai
  FOREIGN KEY (Fk)
  REFERENCES NomeTabelaPai (Pk)
  ON DELETE NO ACTION/CASCADE
  ON UPDATE NO ACTION/CASCADE
Go  


If not exists (Select Name From sys.Objects Where (Name = 'DF_NomeTabela_NomeCampo'))
  ALTER TABLE NomeTabela 
	ADD CONSTRAINT DF_NomeTabela_NomeCampo DEFAULT '' 
	FOR NomeCampo

----------------------------------------------------------------------------------------------------------------------------------
/*
Exec PcModeloPcExclui 'NomeTabela', 'Modulo', 'Ademar'
Exec PcModeloPcSalva 'NomeTabela', 'Modulo', 'Ademar'
Exec PcModeloPcSelect 'NomeTabela', 'Ademar'

Exec Pc PcExcluiNomeTabela
Exec Pc PcSalvaNomeTabela
Exec Pc PcSelectNomeTabela
*/
----------------------------------------------------------------------------------------------------------------------------------
