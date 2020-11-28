/*
OBS: 
1 - Datas foram convertidas para o tipo Date para evitar problemas com os segundos
2 - Se o cliente atualizou esta tabela, não achei outra alternativa para evitar que seja inserido novamente, isso no caso de o cliente colocar
uma data diferente do que esta no cadastro no banco oficial.
*/
---------------------------------------------------------------------------------------------------------------------------------------
Declare @RegistrosAlterados Table (Registro Varchar(10))
Declare @RegDataFinal Table (Pk int, Registro Varchar(10), DataFinal Datetime)
Declare @CodigoCr varchar(10), @PkPai int, @DataFinalTemp Date, @DataInicialTemp Date

---------------------------------------------------------------------------------------------------------------------------------------

--Insert @RegistrosAlterados
--Select '1010' 
--Insert @RegistrosAlterados
--Select 'C500'
--Insert @RegistrosAlterados
--Select 'G130'
--Insert @RegistrosAlterados
--Select 'G140'
--Insert @RegistrosAlterados
--Select '1391'

-- Obtendo registros do banco oficial
Insert @RegistrosAlterados
Select Registro
From MakroContabil..NiveisEFD

-- Obtendo dados do Banco oficial da Makrosystem
Begin Try Drop Table #NiveisEfdMakroContabil End Try Begin Catch End Catch

Select E.Registro, Ei.* Into #NiveisEfdMakroContabil
From MakroContabil..NiveisEFD E
Join MakroContabil..NiveisEfdItens Ei on (Ei.FkNiveisEfd = E.Pk)
Where (E.Registro in (Select Registro From @RegistrosAlterados)) and
(Ei.Aplicacao = 1) and -- Sped Fiscal
(Ei.DataFinal is null)
Order by Ei.Pk Desc

-- Obtendo dados do Banco Corrente
Begin Try Drop Table #PkEfdPai End Try Begin Catch End Catch

Select * Into #PkEfdPai
From NiveisEFD
Where (Registro in (Select Registro From @RegistrosAlterados))

---------------------------------------------------------------------------------------------------------------------------------------
-- Obtendo registros que serão alterados
Declare CrEncerraRegistro Cursor Local static for
Select E.Registro, E.Pk
From NiveisEFD E
Where (E.Registro in (Select Registro From @RegistrosAlterados))
Open CrEncerraRegistro 
Fetch Next From CrEncerraRegistro into @CodigoCr, @PkPai
While (@@FETCH_STATUS = 0)
	Begin

    Select @DataInicialTemp = Convert(Date, DataInicial)
    From #NiveisEfdMakroContabil
    Where (Registro = @CodigoCr)

    -- Se não existir o Registro irá continuar
    If Not Exists
    (
      Select N.Pk 
      From NiveisEFD N
      Join NiveisEfdItens Ni on (Ni.FkNiveisEfd = N.Pk)
      Where (N.Registro = @CodigoCr) and
      (Ni.Aplicacao = 1) and-- Sped Fiscal
      (Convert(Date, Ni.DataInicial) = @DataInicialTemp) and
      (Ni.DataFinal is null) 
    )
    Begin
      Insert @RegDataFinal
      Select @PkPai, @CodigoCr, 
      (
        Select Top 1 Ei.DataFinal
        From MakroContabil..NiveisEFD E
        Join MakroContabil..NiveisEfdItens Ei on (Ei.FkNiveisEfd = E.Pk)
        Where (E.Registro in (Select Registro From @RegistrosAlterados)) and
        (Ei.Aplicacao = 1) and -- Sped Fiscal
        (Convert(Date, DataFinal) is not null)
        Order by Ei.Pk Desc
      )
    End

		Fetch next from CrEncerraRegistro into @CodigoCr, @PkPai
	End

Close CrEncerraRegistro
Deallocate CrEncerraRegistro

Set @CodigoCr = ''
Set @PkPai = 0


---------------------------------------------------------------------------------------------------------------------------------------
---- Colocando DataFinal nos Registros
Declare CrUsuario Cursor Local static for	
Select Pk, DataFinal
From @RegDataFinal
Open CrUsuario 
Fetch Next From CrUsuario into @PkPai, @DataFinalTemp
While (@@FETCH_STATUS = 0)
	Begin
    Update NiveisEfdItens
    Set DataFinal = @DataFinalTemp
    Where (FkNiveisEfd = @PkPai) and
    (Pk = 
      (    -- Obtendo último registro
        Select Top 1 Pk
        From NiveisEfdItens
        Where (FkNiveisEfd = @PkPai) 
        Order by Pk Desc
      )
    )
		Fetch next from CrUsuario into @PkPai, @DataFinalTemp
	End

Close CrUsuario
Deallocate CrUsuario

-----------------------------------------------------------------------------------------------------------------------------------------
---- Inserindo novos Registros

Set @CodigoCr = ''
Set @PkPai = 0
Set @DataInicialTemp = null

Declare CrInsertFilhosEfd Cursor Local static for
Select Registro, Convert(Date, DataInicial)
From #NiveisEfdMakroContabil
Open CrInsertFilhosEfd 
Fetch Next From CrInsertFilhosEfd into @CodigoCr, @DataInicialTemp
While (@@FETCH_STATUS = 0)
	Begin
    If Not Exists
    (
      Select N.Pk 
      From NiveisEFD N
      Join NiveisEfdItens Ni on (Ni.FkNiveisEfd = N.Pk)
      Where (N.Registro = @CodigoCr) and
      (Ni.Aplicacao = 1) and-- Sped Fiscal
      (Convert(Date, Ni.DataInicial) = @DataInicialTemp) and
      (Ni.DataFinal is null) 
    )
    Begin
      Insert NiveisEfdItens
      (FkNiveisEfd, DataInicial, DataFinal, ObrigatoriedadeEntradasA, ObrigatoriedadeSaidasA, ObrigatoriedadeEntradasB, ObrigatoriedadeSaidasB, Quantidade, Aplicacao )
      Select P.Pk, -- FkNiveisEfd Banco atual
      N.DataInicial, -- Banco MakroContabil
      N.DataFinal, -- Banco MakroContabil
      N.ObrigatoriedadeEntradasA, -- Banco MakroContabil
      N.ObrigatoriedadeSaidasA, -- Banco MakroContabil
      N.ObrigatoriedadeEntradasB, -- Banco MakroContabil
      N.ObrigatoriedadeSaidasB, -- Banco MakroContabil 
      N.Quantidade, -- Banco MakroContabil
      N.Aplicacao -- Banco MakroContabil
      From #NiveisEfdMakroContabil N
      Join #PkEfdPai P on (P.Registro = N.Registro)
      Where (N.Registro = @CodigoCr)
    End

		Fetch next from CrInsertFilhosEfd into @CodigoCr, @DataInicialTemp
	End

Close CrInsertFilhosEfd
Deallocate CrInsertFilhosEfd

-----------------------------------------------------------------------------------------------------------------------------------------



--Declare @RegistrosAlterados Table (Registro Varchar(10))
--Declare @RegDataFinal Table (Pk int, Registro Varchar(10), DataFinal Datetime)
--Declare @CodigoCr varchar(10), @PkPai int, @DataFinalTemp Datetime

--Declare @PkNiveisItens Table (Pk int, Registro Varchar(10))
-----------------------------------------------------------------------------------------------------------------------------------------

--Insert @RegistrosAlterados
--Select '1010' 
--Insert @RegistrosAlterados
--Select 'C500'
--Insert @RegistrosAlterados
--Select 'G130'
--Insert @RegistrosAlterados
--Select 'G140'
--Insert @RegistrosAlterados
--Select '1391'

--Select N.Registro, Ni.*
--From NiveisEFD N
--Join NiveisEfdItens Ni on (Ni.FkNiveisEfd = N.Pk)
--Where (N.Registro in (Select Registro From @RegistrosAlterados)) 

----Insert @PkNiveisItens
----Select Max(Ni.Pk), N.Registro
----From NiveisEFD N
----Join NiveisEfdItens Ni on (Ni.FkNiveisEfd = N.Pk)
----Where (N.Registro in (Select Registro From @RegistrosAlterados)) 
----Group by N.Registro

----Update NiveisEfdItens
----Set DataFinal = null
----Where (Pk in (Select Pk From @PkNiveisItens))