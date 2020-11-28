Select R.DocN, R.Data, Sum(R.ValorContabil) ValorContabil, Sum(Ri.ValorServicos) ValorServicos
From RegPrestServicos R
Join RegPrestServicosItens Ri on (Ri.Fk = R.Pk)
Where (R.CodEmpresa = 895) and
(R.Data between '2020-04-01' and '2020-06-30')
Group by R.DocN, R.Data
Having Sum(R.ValorContabil) <> Sum(Ri.ValorServicos)