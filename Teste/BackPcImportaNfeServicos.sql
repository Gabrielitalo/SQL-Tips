--PcImportaNfeServicos
--Backup da parte alterada
-- Excluir após dia 25/08/2019

Insert RegPrestServicosItens 
(Fk, FkListaServicos, ValorContabil, Aliquota, Issqn, Inss, Irrf, Pis, Cofins, 
Cssll, CentroCusto, vBcPis, pPis, vPis, vBcCofins, pCofins, vCofins, ValorServicos, 
ValorDesconto, BaseCalculoPisImport, BaseCalculoCofinsImport, PisPagoImport, CofinsPagoImport, 
DataPagtoCofinsImport, DataPagtoPisImport, LocalExecucaoImport, NumeroItem, IndicadorOrigemCredito,
CstCofins, CstPis, TipoDebitoCreditoPis, TipoDebitoCreditoCofins, FkCadNaturezaOperacao, vBcIssqn, 
FkCadProdutos)
Select distinct 
--Fk,
@PkNota,
--FkListaServicos, 
Coalesce((Select Top 1 Pk From ListaServicos Where Replace(Item, '.', '') = Right('0000' + Replace(n.atividade, '.', ''), 4) and (FkEscritorio = @PkEscritorio)), @FkListaServicos),
            
--ValorContabil,      
Case When d.codigo = 'DESCONTO INCONDICIONAL' --o desconto reduz o valor da nota
Then
    Coalesce(n.valor, 0) - Coalesce(Td.ValorDesconto, 0)
else
  Case When d.codigo = 'DEDUCOES' --o desconto não reduz o valor da nota
  Then
    Coalesce(n.valor, 0)
  else                
    Coalesce(n.valor, 0)
  End
End,  
                      
--Aliquota
aliquota * 100,
            
--Issqn,       
(Coalesce(n.valor, 0) - Coalesce(Td.ValorDesconto, 0)) * aliquota,
                
--Inss, 
Coalesce((Select Convert(Numeric(18, 2), d.Valor) From #deducoes d Where (d.senha = n.senha) and (d.codigo = 'INSS')), 0),  --Estava sendo passado 0 Élio 01/08/2017
--Irrf, 
Coalesce((Select Round((n.Valor * 1.5 / 100),2,1) From #deducoes d Where (d.senha = n.senha) and (d.codigo = 'IRRF')), 0),
--Pis,
Coalesce((Select Round((n.Valor * 0.65 / 100),2,1) From #deducoes d Where (d.senha = n.senha) and (d.codigo = 'PIS')), 0),
--Cofins, 
Coalesce((Select Round((n.Valor * 3 / 100),2,1) From #deducoes d Where (d.senha = n.senha) and (d.codigo = 'COFINS')), 0), 
--Cssll, 
Coalesce((Select Round((n.Valor * 1 / 100),2,1) From #deducoes d Where (d.senha = n.senha) and (d.codigo = 'CSLL')), 0), 
--CentroCusto, 
dbo.FCentroCustoServicos(@FkListaServicos, R.TipoServico, R.VP),
--vBcPis, 
0,
--pPis, 
0,
--vPis, 
0,
--vBcCofins, 
0,
--pCofins, 
0,
--vCofins, 
0,
--ValorServicos, 
n.valor,
            
--ValorDesconto,       
Td.ValorDesconto,            

--BaseCalculoPisImport, 
0,
--BaseCalculoCofinsImport, 
0,
--PisPagoImport, 
0,
--CofinsPagoImport, 
0,
--DataPagtoCofinsImport, 
null,
--DataPagtoPisImport, 
null,
--LocalExecucaoImport, 
null,
--NumeroItem, 
R.FkIntegra,
--IndicadorOrigemCredito,
0,
--CstCofins, 
'',
--CstPis, 
'',
--TipoDebitoCreditoPis, 
null,
--TipoDebitoCreditoCofins, 
null,
--FkCadNaturezaOperacao, 
null,
--vBcIssqn, 
Case When aliquota = 0 Then 
0
Else       
Coalesce(n.valor, 0) - Coalesce(ValorDesconto, 0)                  
End,
--FkCadProdutos
Case When @PkCodigoProdutoPadrao = 0 Then NULL Else @PkCodigoProdutoPadrao End
From #nfe n
inner join RegPrestServicos R on (R.ChaveNfe = n.senha)
left join #deducoes d on (d.senha = n.senha)
Left Join @TpDescontos Td on (n.numero = Td.numero) and (n.senha = Td.senha) and (Td.Descricao = n.Descricao)
Where (n.numero = @numero) and 
(n.senha = @senha) and 
(R.CodEmpresa = @CodEmpresa) and
(R.Data between @DataInicialP and @DataFinalP) -- comentado temporariamente