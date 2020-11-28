Select 'Exec PcAtualizaTodasProcedures ''' + Name + ''''
From sys.Objects
Where (type = 'P') and
(Left(Name, 3) <> 'sp_') and
(Modify_Date >= '04/24/2018') and
(Name not in('PcRegApIcmsDifAliquota', 'PcRelRelacaoDuplicatas', 'PcControleClientesPagto', 'PcRelProdutosRetencao', 'PcSalvaCadEmpregados', 
'PcRelProdutosFunRural'))
Order by Modify_date