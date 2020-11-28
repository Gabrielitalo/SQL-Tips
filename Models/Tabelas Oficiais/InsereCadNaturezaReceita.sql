-- Caso seja necessário só fazer um cursor nos inserts
Declare @CadNaturezaReceitaTemp Table (CodigoNatureza int, DescricaoNatureza varchar(8000), DataInicial datetime, NumeroTabela varchar(20))
Declare @PkCadNaturezaReceita int

Alter Table CadNaturezaReceita
Alter Column DescricaoNatureza varchar(8000)

Insert CadNaturezaReceita
(CodigoNatureza, DescricaoNatureza, DataInicial, NumeroTabela, Observacao)
Select 918, 
'Receita decorrente da venda de bebidas frias, classificadas nos códigos 2106.90.10 Ex02; 22.01 (exceto os Ex 01 e Ex 02 do código 2201.10.00); 22.02 (exceto os Ex 01, Ex 02 e Ex 03 do código 2202.90.00); e 22.02.90.00 Ex 03 e 22.03 da TIPI, quando auferida pela pessoa jurídica varejista, assim considerada, a pessoa jurídica cuja receita decorrente de venda de bens e serviços a consumidor final no ano-calendário imediatamente anterior ao da operação houver sido igual ou superior a 75% (setenta e cinco por cento) de sua receita total de venda de bens e serviços no mesmo período, depois de excluídos os impostos e contribuições incidentes sobre a venda.',
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