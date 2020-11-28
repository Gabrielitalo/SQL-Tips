Declare @PkEscritorio int = 4048, @Certificado Varbinary(Max), @SenhaCertificado Varchar(100), @PkCadNfeEmpresaTemp int, @ChaveNFe varchar(44), @CodEmpresa int, @PkUsuario int,
@ultNSU varchar(15) = '000000000000000', @Nsu varchar(15), @Data90DiasAtras datetime = DateAdd(MM, -1, GetDate())  


--Update CadNfeEmpresa
--Set Situacao = 1,
--TipoEvento = 0,
--Observacao = ''
--Where (Situacao = 2) and
--(ArquivoNfeRetorno like '<retDistDFeInt%')

Begin Try Drop Table #EmpresasComErroScript End Try Begin Catch End Catch
Create Table #EmpresasComErroScript(CodEmpresa int)



Declare CrCadEmpresa Cursor Local static for
	
Select C.CodEmpresa
From CadEmpresa C
Join CadEmpresaOutros Ce on (Ce.CodEmpresa = C.CodEmpresa)
Where (C.TipoCadastro = 'Ativa') and
(Ce.FkCadEmpresaOutrosTipo = 4) and
(Ce.Valor <> '1')
Open CrCadEmpresa 
Fetch Next From CrCadEmpresa into @CodEmpresa
While (@@FETCH_STATUS = 0)
	Begin  

    -- Obtendo certficiado
    Select @Certificado = Certificado, @SenhaCertificado = Senha  
    From dbo.TCertDigitalNfe  
    (@CodEmpresa)  

		If (@Certificado is not null)
			Begin

				Select Top 1 @PkUsuario = Pk
				From Usuarios
				Where (Ativo = 'Sim') and
				(FkEscritorio = @PkEscritorio)
				------------------------------------------------------------
				-- Dando ciência da operação
				Declare CrCadNfeEmpresa cursor local static for   
  
				Select C.Pk, C.ChaveNfe  
				From CadNfeEmpresa C  
				Where (C.CodEmpresa = @CodEmpresa) and  
				(C.Situacao = 1) and --Resumo  
				(C.TipoEvento = 0) and
				(C.DataRecebimento >= @Data90DiasAtras) -- Receita só fornece últimos 90 dias
  
				Open CrCadNfeEmpresa  
				Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe  
  
				While (@@FETCH_STATUS = 0)  
					Begin  

						Exec PcBuscaNfeManifestoDestinatario @PkCadNfeEmpresaTemp, @Certificado, @SenhaCertificado, @ChaveNFe, '210210', 'Ciencia da Operacao', 2  

						Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe  
					End  
				Close CrCadNfeEmpresa  
				Deallocate CrCadNfeEmpresa  


				------------------------------------------------------------
				-- Manifestando
				Declare CrCadNfeEmpresa cursor local static for   
  
				Select C.Pk, C.ChaveNfe, C.Nsu  
				From CadNfeEmpresa C  
				Where (C.CodEmpresa = @CodEmpresa) and  
				(C.Situacao = 1) and  
				(C.TipoEvento > 0) and -- Ciência
				(C.DataRecebimento >= @Data90DiasAtras) -- Receita só fornece últimos 90 dias 
  
				Open CrCadNfeEmpresa  
				Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe, @Nsu  
  
				While (@@FETCH_STATUS = 0)  
					Begin  
						Exec PcBuscaNfeConsulta @CodEmpresa, @ultNSU, @Certificado, @SenhaCertificado, @ChaveNfe, @PkUsuario, @Nsu, 'consChNFe'  
  
						Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe, @Nsu  
					End  
				Close CrCadNfeEmpresa  
				Deallocate CrCadNfeEmpresa  


			End		
		Else
			Begin
				Insert #EmpresasComErroScript
				Select @CodEmpresa
			End

			Fetch next from CrCadEmpresa into @CodEmpresa

		End
Close CrCadEmpresa
Deallocate CrCadEmpresa

Select *
From #EmpresasComErroScript