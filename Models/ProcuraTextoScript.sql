------------------------------------------------------------------------------------------------------------------------------------------
Declare @Conteudo Varchar(Max)
Set @Conteudo = 'Insert ParametrosGlobais'

Select Distinct DataCriacao, Descricao
From Script
Where (Conteudo like '%' + @Conteudo + '%') or
(Conteudo2 like '%' + @Conteudo + '%') or
(Conteudo3 like '%' + @Conteudo + '%') or
(Conteudo4 like '%' + @Conteudo + '%') or
(Conteudo5 like '%' + @Conteudo + '%')
Order By DataCriacao Desc
------------------------------------------------------------------------------------------------------------------------------------------
