-- N�o pode haver namespace no xml, por padr�o o Sql n�o aceita
-- � necess�rio sempre remover o arquivo da mem�ria
-- Este script serve para visualizar um Xml puro no sql e serve de base para estudo
-- Criado por Gabriel

Declare @x xml, @hdoc int


Select @x = P
From OpenRowSet (Bulk '\\192.168.0.5\Arquivo\1\Usu�rios\4387\XMLsTeste\ginfesSM.xml', Single_Blob) as Notas(P)

Set @x = REPLACE(convert(nvarchar(max),@x), ' xmlns="http://www.el.com.br/nfse/xsd/el-nfse.xsd"', '') -- Removendo namespace

Select @x -- Exibindo Xml

Exec SP_XML_PREPAREDOCUMENT @hdoc Output, @x -- Atribuindo vari�vel de sa�da para poder usar o xml como tabela

Select *
From OpenXml (@hdoc, '/tcListaNFse/Nfse/DadosPrestador/Endereco', 2)
with (
Logradouro varchar(100)
)

--Set @Inicio = 'BPe/Signature/SignedInfo/Reference' 

--Select *
--From OpenXml (@PkXml, @Inicio, 1) -- Para ler atributo usar 1 ao inv�s de 2
--with 
--	(
--		URI varchar(100)-- Chave da nota  -- Colocar o nome do atributo aqui
--	)


Exec sp_xml_removedocument @hdoc -- Removendo da mem�ria

