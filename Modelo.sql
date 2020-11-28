-- Script Cabeçalho
-- Finalidade facilitar testes de procedure
-------------------------------------------------------------------------------------------------------------------
Declare @DataInicial datetime, @DataFinal datetime, @FkEscritorio int, @CodEmpresa int, @FkUsuario int

Set @DataInicial = '2019-07-01'
Set @DataFinal = @DataInicial + 30
Set @CodEmpresa = 21354
Set @FkEscritorio = dbo.FPkEscritorioCadEmpresa(@CodEmpresa)
Set @FkUsuario = 2528

--Select @DataInicial, @DataFinal, @FkEscritorio