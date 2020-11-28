Declare @PkEscritorio int = 1, @Certificado Varbinary(Max), @SenhaCertificado Varchar(100), @PkCadNfeEmpresaTemp int, @ChaveNFe varchar(44), @CodEmpresa int = 21, @PkUsuario int = 1,
@ultNSU varchar(15) = '000000000000000', @Nsu varchar(15) 

Select @Certificado = Certificado, @SenhaCertificado = Senha  
From dbo.TCertDigitalNfe  
(@CodEmpresa)  

--Update CadNfeEmpresa
--Set Fkc = 2
--Where (FkModeloNotaFiscal = 55) and
--(Fkc = 3)

--Select *
--From CadNfeEmpresa C
--Where C.CodEmpresa = @CodEmpresa and
--(Fkc = 3)
--return

--Select *
--From CadEmpresa
--Where (CodCliente = 109)


--Select C.Pk, C.ChaveNfe  
--From CadNfeEmpresa C  
--Where (C.CodEmpresa = @CodEmpresa) and  
--(C.Situacao = 1) and --Resumo  
--(C.TipoEvento = 0)  


------------------------------------------------------------
Declare CrCadNfeEmpresa cursor local static for   
  
Select C.Pk, C.ChaveNfe  
From CadNfeEmpresa C  
Where (C.CodEmpresa = @CodEmpresa) and  
(C.Situacao = 1) and --Resumo  
(C.TipoEvento = 0)  
  
Open CrCadNfeEmpresa  
Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe  
  
While (@@FETCH_STATUS = 0)  
  Begin  
    --Begin Try
    --  Exec PcBuscaNfeManifestoDestinatario @PkCadNfeEmpresaTemp, @Certificado, @SenhaCertificado, @ChaveNFe, '210210', 'Ciencia da Operacao', 2  
    --End Try
    --Begin Catch
    -- -- Select 'Não foi possível manifestar ' + @ChaveNFe
    --End Catch
    Exec PcBuscaNfeManifestoDestinatario @PkCadNfeEmpresaTemp, @Certificado, @SenhaCertificado, @ChaveNFe, '210210', 'Ciencia da Operacao', 2  

    Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe  
  End  
Close CrCadNfeEmpresa  
Deallocate CrCadNfeEmpresa  

Declare CrCadNfeEmpresa cursor local static for   
  
Select C.Pk, C.ChaveNfe, C.Nsu  
From CadNfeEmpresa C  
Where (C.CodEmpresa = @CodEmpresa) and  
(C.Situacao = 1) and  
(C.TipoEvento > 0) --Ciência  
  
Open CrCadNfeEmpresa  
Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe, @Nsu  
  
While (@@FETCH_STATUS = 0)  
  Begin  
    Exec PcBuscaNfeConsulta @CodEmpresa, @ultNSU, @Certificado, @SenhaCertificado, @ChaveNfe, @PkUsuario, @Nsu, 'consChNFe'  
  
    Fetch next from CrCadNfeEmpresa into @PkCadNfeEmpresaTemp, @ChaveNfe, @Nsu  
  End  
Close CrCadNfeEmpresa  
Deallocate CrCadNfeEmpresa  
