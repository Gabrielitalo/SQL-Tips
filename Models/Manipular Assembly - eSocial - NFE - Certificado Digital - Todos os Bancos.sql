-------------------------------------------------------------------------------------------
--Criado por Ademar em 19/02/2018
--Tem por finalidade rodar script em todos os bancos de dados, para Dlls e-Social e Nf-e
-------------------------------------------------------------------------------------------
Declare @Cmd Varchar(max), @NomeBanco Varchar(250)

Declare CrCursorBancos Cursor local static for 
Select Name 
From sys.databases  
Where (Name not in ('Master', 'Model', 'Msdb', 'TempDb')) and 
(Name not like '%Report%') and  
--(Name in ('WolidasCouto')) and
(Left(Name, 2) Not In ('NG', 'Bk', 'Ts','Up'))
Order by Name
Open CrCursorBancos
Fetch Next From CrCursorBancos into @NomeBanco
While (@@Fetch_Status = 0)
	Begin

		Print @NomeBanco
		----------------------------------------------------------------------------------------------
		--Trocar aqui o Script a ser rodado...Ademar.
		---------------------------------------------
		Set @Cmd = '
		Use ' + @NomeBanco + ' 

		ALTER DATABASE ' + @NomeBanco + '  SET TRUSTWORTHY ON

		------------------------------------------------------------------------------------------------------
		--É OBRIGATÓRIO DEFINIR O USUÁRIO OWNER DO BANCO DE DADOS, CASO CONTRÁRIO O PARÂMETRO UNSAFE DO ASSEMBLY NÃO IRÁ FUNCIONAR
		------------------------------------------------------------------------------------------------------
		Begin Try
			ALTER AUTHORIZATION 
			ON DATABASE::' + @NomeBanco + ' 
			TO [sa]
		End Try
		Begin Catch
			--O banco já possui esse proprietário
		End Catch

		---------------------------------------------------------------------------------------------------------------------------------------------------------------
		If exists (Select Name From sys.Objects Where (Name = ''FAssinadorDigital''))
			Drop Function FAssinadorDigital

		If exists (Select Name From sys.Objects Where (Name = ''FEnviarConsultarDigital''))
			Drop Function FEnviarConsultarDigital

		If exists (Select Name From sys.Objects Where (Name = ''FVerificaCertificadoDigital''))
			Drop Function FVerificaCertificadoDigital

		If exists (Select Name From sys.Objects Where (Name = ''TDadosCertificadoDigital''))
			Drop Function TDadosCertificadoDigital

		-----------------------
		If exists (Select Name From sys.assemblies Where (Name = ''AssinadorDigital''))
			Drop Assembly AssinadorDigital
	
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		If not exists (Select Name From sys.assemblies Where (Name = ''AssinadorDigital''))
			Create Assembly AssinadorDigital From ''\\192.168.0.5\Atualiza\MakroWeb_Dlls\Assinador.dll''
			WITH PERMISSION_SET = UNSAFE

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--Criação de Funções para acesso a DLLs.
		-----------------------------------------
		Declare @Cmd2 Varchar(Max)

		Set @Cmd2 = ''Use ' + @NomeBanco + ' 

		------------------------------------------------------------------------------------------------------
		--No script de atualização geral de todos os bancos selecionar para baixo até Exec (@Cmd2)
		------------------------------------------------------------------------------------------------------

		Declare @Cmd3 Varchar(Max)

		---------------------------------------------
		-- Assinador do e-Social
		---------------------------------------------
		Set @Cmd3 = ''''
		Create FUNCTION dbo.FAssinadorDigital (@ArquivoXml nvarchar(max), @Uri nvarchar(100), @Certificado varbinary(max), @SenhaCertificado nvarchar(100), @Id Nvarchar(200), @Tipo Nvarchar(200))
		RETURNS nvarchar(max) WITH EXECUTE AS CALLER
		AS 
		EXTERNAL NAME [AssinadorDigital].[ClasseAssinador].[Assinar]''''

		Exec (@Cmd3)

		---------------------------------------------
		-- Consulta do e-Social
		---------------------------------------------
		Set @Cmd3 = ''''
		Create FUNCTION dbo.FEnviarConsultarDigital (@ArquivoXml nvarchar(max), @Certificado varbinary(max), @SenhaCertificado nvarchar(100), @Tipo nvarchar(100), @TipoAmbiente nvarchar(1))
		RETURNS nvarchar(max) WITH EXECUTE AS CALLER
		AS 
		EXTERNAL NAME [AssinadorDigital].[ClasseAssinador].[EnviarConsultar]''''

		Exec (@Cmd3)

		---------------------------------------------
		-- Verifica Certificado Digital
		---------------------------------------------
		Set @Cmd3 = ''''
		CREATE FUNCTION [dbo].[FVerificaCertificadoDigital](@Certificado [varbinary](max), @SenhaCertificado [nvarchar](100))
		RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
		AS 
		EXTERNAL NAME [AssinadorDigital].[ClasseAssinador].[Verifica]''''

		Exec (@Cmd3)

		---------------------------------------------
		-- Extraindo dados do Certificado Digital
		---------------------------------------------
		Set @Cmd3 = ''''
		CREATE FUNCTION [dbo].[TDadosCertificadoDigital](@Certificado [varbinary](max), @SenhaCertificado [nvarchar](100))
		RETURNS  TABLE (
			[Pk] [int] NULL,
			[DataValidade] [nvarchar](20) NULL,
			[NumeroSerie] [nvarchar](50) NULL,
			[DataCertificacao] [nvarchar](20) NULL,
			[TipoInscricao] [nvarchar](10) NULL,
			[Cnpj] [nvarchar](14) NULL,
      [DadosCertificado][nvarchar](Max) NULL
		) WITH EXECUTE AS CALLER
		AS 
		EXTERNAL NAME [AssinadorDigital].[ClasseAssinador].[Dados]''''

		Exec (@Cmd3)
		'' 

		Exec(@Cmd2)


		---------------------------------------------------------------------------------------------------------------------------------------------------------------
		'

		---------------------------------------------------------------------------------------------------------------------------------------------------------------

		----------------------------------------------------------------------------------------------
		--Print @Cmd
		Exec (@Cmd)

		Fetch Next From CrCursorBancos into @NomeBanco
	End
Close CrCursorBancos
Deallocate CrCursorBancos

-------------------------------------------------------------------------------------------
--Alter table JoseGeraldoAlves.dbo.CatSefip Alter Column Historico Varchar(200) not null
-------------------------------------------------------------------------------------------

/*

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--Exclusão 
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Use Master
--------------------------------------------------

If exists (Select Name From SysLogins Where (Name = ''AssinadorDigital_Login''))
  Drop Login AssinadorDigital_Login

If exists(Select Name From sys.asymmetric_keys WHere Name = ''AssinadorDigital_Key'') 
  Drop ASYMMETRIC Key AssinadorDigital_Key


*/
