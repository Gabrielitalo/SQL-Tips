Begin Transaction
Commit Transaction
Rollback Transaction




Update RegPrestServicos 
Set FkCidades = Case When TipoServico = 1
								Then  (Select Cf.FkCidades
											 From CadFornecedores Cf 
											 Where Cf.Pk = FkClientes)
								Else
								(Select Top 1 C.Pk
									From CadEmpresa Ca
									Inner Join Cidades C on (C.Codigo = Ca.CodFederal)      
									Where (Ca.CodEmpresa = CodEmpresa))
								End

Where Data >='01/01/2018'

Select FkCidades,TipoServico,* From RegPrestServicos R
Where R.Data >='01/01/2018'