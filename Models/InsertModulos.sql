------------------------------------------------------------------------------------------------------------------------
--Update Modulos
--Set Hierarquia = Replace(Hierarquia, '06.06', '06.07')
--Where (Hierarquia like '06.06%')

-------------------------------------------------------------------------------------------------------------------------
/* 
Update Modulos Set FilhaPeriodoTrabalho = 'Sim' Where (Pk = 850)
Update Modulos Set Modulo = 'Contabil' Where (Pk = 687)
Update Modulos Set Descricao = 'Geração Massa' Where (Pk = 850)
Update Modulos Set LiberadoCliente = 'Não' Where (Pk = 962)

Update Modulos Set Cabecalho = 'Exclusão em massa de Notas Fiscais de Entradas conforme opções abaixo.' Where (Pk = 938)

Update Modulos Set Hierarquia = '12.01.06' Where (Pk = 854)
Update Modulos Set Hierarquia = '12.01.05' Where (Pk = 947)

Update Modulos Set Cabecalho = 'Dados iniciais e tabelas para alimentação do e-social - Ponto de Partida.' Where (Pk = 940)
Update Modulos Set Url = 'FormFiscal/Importacao/NFeCertificado/ResultadoConsulta/CadNfeResultadoConsulta.aspx' Where (Pk = 970)

Select * 
From Modulos 
Where (Hierarquia like '06.00.01%') 
Order By Hierarquia

Select *
From MakroContabilProj..Modulos
Where (Descricao = 'Nfe certificado')

*/
-------------------------------------------
Declare @Hierarquia Varchar(100) = '06.00.01.00'

If not exists(Select Pk From Modulos Where (Hierarquia = @Hierarquia))
	Begin
		Insert Modulos
		(Descricao, Hierarquia, ClasseForm, Visivel, Cabecalho, CaminhoAjuda, LiberadoCliente, FilhaCadEmpresa, Modulo, Url, FilhaPeriodoTrabalho, DataCriacao)
		Select 
		--Descricao (Varchar(500)
		'Unificar cadastro',
		--Hierarquia (Varchar(100)
		@Hierarquia,
		--ClasseForm (Varchar(100)
		'TFormUnificaCadUnidadeDuplicado',
		--Visivel Varchar(3)
		'Sim',
		--Cabecalho Varchar(500)
		'Unificar cadastro de unidades duplicadas.',
		--CaminhoAjuda Varchar(300)
		'',
		--LiberadoCliente Char(3)
		'Não',
		--FilhaCadEmpresa
		'Sim',
		--Modulo
		'Fiscal',
		'FormFiscal/CadastrosGlobais/CadUnidade/Unifica/UnificaCadUnidadeDuplicado.aspx',
		--FilhaPeriodoTrabalho
		'Não',
		--DataCriacao
		GetDate()
	End

/*
Update Modulos
Set Url = 'FormEmpresas/Certidao/Massa/CertidaoMassa.aspx'
Where (Pk = 725)

Delete Modulos
Where (Hierarquia = '05.16.04.01')
*/

-------------------------------------------------------------------------------------------------------------------------
--Alimentando a table UsuariosPermissao caso exista Modulos e Não exista UsuariosPermissao
------------------------------------------------------------------------------------------
Declare @PkUsuario1 Int

Declare C cursor local static for
Select Pk
From Usuarios
Open C
Fetch next from C into @PkUsuario1
While @@FETCH_STATUS = 0
  Begin
    If exists(
        Select top 1 M.Pk
        From Modulos M
        Left outer join UsuariosPermissao U on (U.FkModulos = M.Pk) and (U.FkUsuario = @PkUsuario1)
        Where (U.FkUsuario is null))
      Begin
        Exec PcUsuariosPermissao @PkUsuario1
      End
      
    Fetch next from C into @PkUsuario1
  End
Close C
Deallocate C
 
------------------------------------------------------------------------------------------
