if not exists(Select Name from Sys.columns where (Name = 'FkRegApContrPrevidenciaria') and (object_id = object_id('RegApContrPrevidenciariaConsolidacaoAjustes')))
	Alter table RegApContrPrevidenciariaConsolidacaoAjustes add FkRegApContrPrevidenciaria int null
go

If Not Exists
(
	Select Name 
	From Sys.Objects 
	Where (name = 'FkRegApContrPrevidenciaria_RegApContrPrevidenciariaConsolidacaoAjustes_RegApContrPrevidenciaria')
)
	Begin
		ALTER TABLE [dbo].RegApContrPrevidenciariaConsolidacaoAjustes With Check 
		ADD CONSTRAINT FkRegApContrPrevidenciaria_RegApContrPrevidenciariaConsolidacaoAjustes_RegApContrPrevidenciaria
		FOREIGN KEY(FkRegApContrPrevidenciaria)
		REFERENCES [dbo].RegApContrPrevidenciaria ([Pk])
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
	End
GO  
