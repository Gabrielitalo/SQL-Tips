-- Não pode haver namespace no xml, por padrão o Sql não aceita
-- É necessário sempre remover o arquivo da memória
-- Este script serve para visualizar um Xml puro no sql e serve de base para estudo
-- Criado por Gabriel

Declare @x xml, @hdoc int


Select @x = P
From OpenRowSet (Bulk '\\192.168.0.5\Arquivo\4\Usuários\2528\GINFES\Copia1.xml', Single_Blob) as Notas(P)

Set @x = REPLACE(convert(nvarchar(max),@x), ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', '') -- Removendo namespace
Set @x = REPLACE(convert(nvarchar(max),@x), ' xmlns:xsd="http://www.w3.org/2001/XMLSchema"', '') -- Removendo namespace
Set @x = REPLACE(convert(nvarchar(max),@x), ' xmlns="http://www.saojoaodemeriti.sigiss.com.br"', '') -- Removendo namespace
Set @x = REPLACE(convert(nvarchar(max),@x), '?o', 'ão')

Select @x -- Exibindo Xml

Exec SP_XML_PREPAREDOCUMENT @hdoc Output, @x -- Atribuindo variável de saída para poder usar o xml como tabela

-- Prestador
Select *
From OpenXml (@hdoc, '/NFe/EnderecoPrestador', 2)
with 
(
	InscrPrestador varchar(20) '../InscricaoPrestador',
	CPF varchar(20) '../CPFCNPJPrestador/CPF',
	RazaoSocialPrestador varchar(150) '../RazaoSocialPrestador',
	CNPJ varchar(20) '../CPFCNPJPrestador/CNPJ',
	Logradouro varchar(100),
	NumeroEndereco varchar(5),
	ComplementoEndereco varchar(10), 
	Bairro varchar(20), 
	Cidade varchar(20),
	UF char(2),
	CEP char(9),
	TelefonePrestador varchar(15) '../TelefonePrestador',
	EmailPrestador varchar(50) '../EmailPrestador'
)

-- Tomador
Select *
From OpenXml (@hdoc, '/NFe/EnderecoTomador', 2)
with 
(
	InscrTomador varchar(20) '../InscricaoTomador',
	CPF varchar(20) '../CPFCNPJTomador/CPF',
	CNPJ varchar(20) '../CPFCNPJTomador/CNPJ',
	Logradouro varchar(100),
	NumeroEndereco varchar(5),
	ComplementoEndereco varchar(10), 
	Bairro varchar(20), 
	Cidade varchar(20),
	UF char(2),
	CEP char(9),
	TelefoneTomador varchar(15) '../TelefoneTomador',
	EmailTomador varchar(50) '../EmailTomador',
	RazaoSocialTomador varchar(150) '../RazaoSocialTomador'
)

-- Valores Serviços
Select *
From OpenXml (@hdoc, '/NFe', 2)
with 
(
	ValorServicos varchar(10), 
	ValorBase varchar(10), 
	CodigoServico varchar(5),
	AliquotaServicos char(5),
	ValorINSS varchar(10), 
	ValorIR varchar(10), 
	ValorPIS varchar(5),
	ValorCOFINS char(5),
	ValorCSLL char(5),
	ValorISS varchar(10), 
	ISSRetido char(3)

)


-- Informações da Nota

Exec sp_xml_removedocument @hdoc -- Removendo da memória

