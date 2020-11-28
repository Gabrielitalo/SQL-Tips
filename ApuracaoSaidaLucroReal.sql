Declare @CodEmpresa int = 2, @DataInicialP datetime = '2020-02-01', @DataFinalP datetime = '2020-02-29', @PkEscritorio int = 1, @FkCadEmpresaScp int = null

Begin Try Drop Table #RegSaidas End Try Begin Catch End Catch
Create Table #RegSaidas (
Pk Int, Pkc Int, CodEmpresa Int, DataEmissao DateTime, TipoNota Int, 
FkClientes Int, FkDepartamento int, FkCadEmpresaScp int)

Begin Try Drop Table #Produtos End Try Begin Catch End Catch
Create Table #Produtos (Fk Int, Fkc Int, Cfop Int, Total Numeric(18, 2), ValorProduto Numeric(18, 2),
CstPis Varchar(4), TipoDebitoCreditoPis Int, vBcPis numeric(18, 2), pPis Numeric(18, 4), vPis Numeric(18, 2),
CstCofins Varchar(4), TipoDebitoCreditoCofins Int, vBcCofins numeric(18, 2), pCofins Numeric(18, 4), vCofins Numeric(18, 2),
CentroCusto Int)


Insert #RegSaidas
(Pk, Pkc, CodEmpresa, DataEmissao, TipoNota, FkClientes, FkDepartamento, FkCadEmpresaScp)
Select R.Pk, R.Pkc, R.CodEmpresa, R.DataEmissao, R.TipoNota, R.FkClientes, 
R.FkDepartamento, R.FkCadEmpresaScp
From CadEmpresa C
Inner join RegSaidas R on (R.CodEmpresa = C.CodEmpresa)
Where (C.CodigoMatriz = @CodEmpresa) and
(R.DataEmissao Between @DataInicialP and @DataFinalP)
and (R.Modelo <> '18') and
(FkCadEmpresaScp is null)


Insert #Produtos
(Fk, Fkc, Cfop, Total, ValorProduto,
CstPis, TipoDebitoCreditoPis, vBcPis, pPis, vPis,
CstCofins, TipoDebitoCreditoCofins, vBcCofins, pCofins, vCofins,
CentroCusto)
Select R.Pk, R.Pkc, P.Cfop, P.Total, P.ValorProduto,
P.CstPis, P.TipoDebitoCreditoPis, P.vBCPis, P.pPis, P.vPis,
P.CstCofins, P.TipoDebitoCreditoCofins, P.vBcCofins, P.pCofins, P.vCofins,
P.CentroCusto
From #RegSaidas R
inner join ProdutosSaidas P on (P.FkRegSaidas = R.Pk)
Where (Coalesce(P.CodTotalizadorSintegra, '') not in ('CANC', 'DESC')) and 
(Coalesce(P.CodTotalizadorEfd, '') not in ('CAN-T', 'CAN-S', 'CAN-O', 'DT', 'DS', 'DO'))



Select --R.Pkc, 1, P.TipoDebitoCreditoPis, sum(P.ValorProduto), sum(P.vBcPis), P.pPis, sum(P.vPis)
Rs.DocN, P.vBcPis
From #RegSaidas R
Join RegSaidas Rs on (Rs.Pk = R.Pk)
inner join #Produtos P on (P.Fk = R.Pk) and (P.FkC = R.PkC)
Where (P.TipoDebitoCreditoPis > 0)
--and ((R.TipoNota in(2, 3, 4, 5))) -- Canceladas
--Group By R.Pkc, P.TipoDebitoCreditoPis, P.pPis