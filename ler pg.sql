-- Não pode haver namespace no xml, por padrão o Sql não aceita
-- É necessário sempre remover o arquivo da memória
-- Este script serve para visualizar um Xml puro no sql e serve de base para estudo
-- Criado por Gabriel

Declare @x xml, @hdoc int


Select @x = P
From OpenRowSet (Bulk '\\192.168.0.5\Arquivo\4\Usuários\2528\GINFES\PG copia.xml', Single_Blob) as Notas(P)

Set @x = REPLACE(convert(nvarchar(max),@x), ' xmlns:ts="http://www.issnetonline.com.br/webserviceabrasf/vsd/tipos_simples.xsd"', '') -- Removendo namespace
Set @x = REPLACE(convert(nvarchar(max),@x), ' xmlns="http://www.issnetonline.com.br/webserviceabrasf/vsd/servico_consultar_nfse_rps_resposta.xsd"', '') -- Removendo namespace

Set @x = REPLACE(convert(nvarchar(max),@x), 'tc:', '') -- Removendo namespace


--Select @x -- Exibindo Xml

Exec SP_XML_PREPAREDOCUMENT @hdoc Output, @x -- Atribuindo variável de saída para poder usar o xml como tabela

--Insert @PrestadorServico(Endereco, Numero, Bairro, Cidade, Uf, CodigoMunicipio, Cep, RazaoSocial, Cnpj, CodigoVerificacao)

--ConsultarNfseRpsResposta/CompNfse/Nfse/InfNfse/PrestadorServico/Endereco
Select *
From OpenXml (@hdoc, 'ConsultarNfseRpsResposta/CompNfse/Nfse/InfNfse/TomadorServico/Endereco', 2)
with 
(
	Logradouro varchar(255) 'Endereco',
	Numero int ,
	Bairro varchar(50) ,
	Cidade varchar(20),
	UF char(2) 'Estado',
	CodMunicipio varchar(15) 'Cidade', -- Codigo Municipio
	CEP varchar(12) 'Cep',
	RazSoc varchar(120) '../RazaoSocial',
	Cnpj varchar(14) '../IdentificacaoPrestador/CpfCnpj/Cnpj',
	Cpf varchar(14) '../Cpf',
	CodigoVerificaco varchar(10)
)

--Set @Inicio = 'BPe/Signature/SignedInfo/Reference' 

--Select *
--From OpenXml (@PkXml, @Inicio, 1) -- Para ler atributo usar 1 ao invés de 2
--with 
--	(
--		URI varchar(100)-- Chave da nota  -- Colocar o nome do atributo aqui
--	)


Exec sp_xml_removedocument @hdoc -- Removendo da memória

