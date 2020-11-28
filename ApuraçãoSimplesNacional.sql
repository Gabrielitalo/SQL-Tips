CREATE FUNCTION [dbo].[FRetornaSubLimiteSimples2018] (@CodEmpresa int, @DataInicialP datetime, @DataFinalP datetime, @Imposto varchar(15))
Returns @TbRetorno Table (BaseCalculoSubLimite numeric(18,2), ImpostoAli numeric(18,2))
as
------------------------------------------------------------------------------------------------------------------------
Begin

--Declare @CodEmpresa int = 21344, @DataInicialP datetime = '2019-06-01', @DataFinalP datetime = '2019-06-30'

Declare @ReceitaAnual numeric(18,2),  @ComIss numeric(18,2) = 0, @SemIss numeric(18,2) = 0, @SubLimite numeric(18,2) = 3600000.00, @ReceitaMensal numeric(18,2), @BaseCalculoSub numeric(18,2),
@ReceitaAnualAteMesAnterior numeric(18,2), @DataInicialMesmoAno datetime, @DataInicialAnoAnterior datetime, @DataFinalMesAnterior datetime, @Ano char(4), @AliqCIss numeric(12, 8),
@BaseCalculo numeric(18,2), @AliqExc numeric(18, 8), @AliqFaixa6 numeric(18, 8), @RBT12 numeric(18,2)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aliquotas finais dos Impostos 
Declare @IRPJ numeric(18,8), @CSLL numeric(18,8), @COFINS numeric(18,8), @PIS numeric(18,8), @CPP numeric(18,8)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tabela Oficial do Simples Nacional

Declare @AliqSimp numeric(12, 8) = 0.21, @DeduSimp numeric(18,2) = 125640, @AliqSimp2 numeric(12, 8) = 0.335
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Set @Ano = Convert(Char(4), @DataInicialP, 102) 

Set @DataInicialMesmoAno = @Ano + '-01-01'
Set @DataFinalMesAnterior = @DataInicialP - 1
Set @DataInicialAnoAnterior = DATEADD (m, -12, @DataInicialP)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Obtendo receita do ano corrente
Set @ReceitaAnual = dbo.FReceitaBrutaTotalSimplesNacional (@CodEmpresa, @DataInicialMesmoAno, @DataFinalP)
Set @RBT12 = dbo.FReceitaBrutaTotalSimplesNacional (@CodEmpresa, @DataInicialAnoAnterior, @DataFinalMesAnterior)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fazendo apuração dos valores de serviços SEM retenção de Iss

Select @SemIss = Sum(R.ValorContabil)
From RegPrestServicos R
Where (R.CodEmpresa = @CodEmpresa) and
(R.Data between @DataInicialP and @DataFinalP) and
(R.TipoServico = 2) and
(R.Retencao = 'Sim') and 
(R.TipoNota not in ('02', '03', '04', '05'))

--Select @SemIss
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fazendo apuração dos valores de serviços COM retenção de Iss

Select @ComIss = Sum(R.ValorContabil)
From RegPrestServicos R
Where (R.CodEmpresa = @CodEmpresa) and
(R.Data between @DataInicialP and @DataFinalP) and
(R.TipoServico = 2) and
(R.Retencao = 'Não') and
(R.TipoNota not in ('02', '03', '04', '05'))

--Select @ComIss

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Definindo a ReceitaMensal para serviços
Set @ReceitaMensal = @SemIss + @ComIss

--Select @ReceitaMensal

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Definindo a Aliquota COM ISS e obtendo a Base de Calculo do Sub Limite e Sem o Sub Limite

Set @AliqCIss = @ComIss/@ReceitaMensal
Set @BaseCalculoSub = (@ReceitaAnual - @SubLimite) * @AliqCIss
Set @BaseCalculo = @ComIss - @BaseCalculoSub

--Select @BaseCalculo, @BaseCalculoSub

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculando a Aliquota que excedeu o Sub Limite

Set @AliqExc = (((@SubLimite * @AliqSimp) - @DeduSimp) / @SubLimite) * @AliqSimp2

--Select @AliqExc

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Apurando receita dos últimos 12 meses para encontrar a aliquota
-- Calculo abaixo com base na tabela anexo III

Set @RBT12 = 5866908.11 --################### Apenas para teste simulação pois já foi calculado anteriormente ###################

Set @AliqFaixa6 = (((@RBT12 * 0.33) - 648000) / @RBT12)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculando aliquotas finais dos impostos


Set @CSLL = ((@AliqExc - 0.05) * 0.0526) + (@AliqFaixa6 * 0.15)
Set @COFINS = ((@AliqExc - 0.05) * 0.1928) + (@AliqFaixa6 * 0.1603)
Set @PIS = ((@AliqExc - 0.05) * 0.0418) + (@AliqFaixa6 * 0.0347)
Set @CPP = ((@AliqExc - 0.05) * 0.6526) + (@AliqFaixa6 * 0.305)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

If (@Imposto = 'IRPJ')
	Begin
		Set @IRPJ = ((@AliqExc - 0.05) * 0.0602) + (@AliqFaixa6 * 0.35)

		Insert @TbRetorno
		Select @BaseCalculoSub, @IRPJ
	End

--Select @BaseCalculoSub * @IRPJ
Return

End