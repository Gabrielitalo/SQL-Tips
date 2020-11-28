-- Caso seja necess�rio s� fazer um cursor nos inserts
Declare @CadNaturezaReceitaTemp Table (CodigoNatureza int, DescricaoNatureza varchar(8000), DataInicial datetime, NumeroTabela varchar(20))
Declare @PkCadNaturezaReceita int

Alter Table CadNaturezaReceita
Alter Column DescricaoNatureza varchar(8000)

Insert CadNaturezaReceita
(CodigoNatureza, DescricaoNatureza, DataInicial, NumeroTabela, Observacao)
Select 918, 
'Receita decorrente da venda de bebidas frias, classificadas nos c�digos 2106.90.10 Ex02; 22.01 (exceto os Ex 01 e Ex 02 do c�digo 2201.10.00); 22.02 (exceto os Ex 01, Ex 02 e Ex 03 do c�digo 2202.90.00); e 22.02.90.00 Ex 03 e 22.03 da TIPI, quando auferida pela pessoa jur�dica varejista, assim considerada, a pessoa jur�dica cuja receita decorrente de venda de bens e servi�os a consumidor final no ano-calend�rio imediatamente anterior ao da opera��o houver sido igual ou superior a 75% (setenta e cinco por cento) de sua receita total de venda de bens e servi�os no mesmo per�odo, depois de exclu�dos os impostos e contribui��es incidentes sobre a venda.',
'2015-05-01',
'4.3.13',
''

Select @PkCadNaturezaReceita = Pk
From CadNaturezaReceita
Where (CodigoNatureza = 918) 

Insert CadNaturezaReceitaItens
Select @PkCadNaturezaReceita,
58, -- Pis
'',
59 -- Cofins


Select *
From CadNaturezaReceita C
Join CadNaturezaReceitaItens Cn on (Cn.FkCadNaturezaReceita = C.Pk)
Where (C.CodigoNatureza = 918)