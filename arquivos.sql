ALTER PROCEDURE ListaDiretoriosProj (@Ds_Diretorio VARCHAR(255))
AS BEGIN
    
    DECLARE @Query VARCHAR(8000) = 'dir/ -C /4 /N "' + @Ds_Diretorio + '"'

    DECLARE @Retorno TABLE (
        Linha INT IDENTITY(1, 1),
        Resultado VARCHAR(MAX)
    )

    DECLARE @Tabela_Final TABLE (
        Linha INT IDENTITY(1, 1),
        Dt_Criacao DATETIME,
        Fl_Tipo BIT,
        Qt_Tamanho INT,
        Ds_Arquivo VARCHAR(255)
    )

    Create Table #ListaArquivosFinal
    (
      Diretorio varchar(255)
    )

    INSERT INTO @Retorno
    EXEC Master.dbo.xp_cmdshell @command_string = @Query

  -- Arqui bsucar as pastas
    INSERT INTO @Tabela_Final(Dt_Criacao, Fl_Tipo, Qt_Tamanho, Ds_Arquivo)
    SELECT CONVERT(DATETIME, LEFT(Resultado, 17), 103) AS Dt_Criacao,
    0 AS Fl_Tipo, 
    0 AS Qt_Tamanho,
    SUBSTRING(Resultado, 37, LEN(Resultado)) AS Ds_Arquivo
    FROM @Retorno
    WHERE Resultado IS NOT NULL AND 
    Linha >= 6 AND 
    Linha < (SELECT MAX(Linha) FROM @Retorno) - 2 AND 
    Resultado LIKE '%<DIR>%' AND 
    SUBSTRING(Resultado, 37, LEN(Resultado)) NOT IN ('.', '..')
    ORDER BY Ds_Arquivo
        
  -- Aqui busca os arquivos
    INSERT INTO @Tabela_Final(Dt_Criacao, Fl_Tipo, Qt_Tamanho, Ds_Arquivo)
    SELECT CONVERT(DATETIME, LEFT(Resultado, 17), 103) AS Dt_Criacao,
    1 AS Fl_Tipo, 
    LTRIM(SUBSTRING(LTRIM(Resultado), 18, 19)) AS Qt_Tamanho,
    SUBSTRING(Resultado, CHARINDEX(LTRIM(SUBSTRING(LTRIM(Resultado), 18, 19)), Resultado, 18) + LEN(LTRIM(SUBSTRING(LTRIM(Resultado), 18, 19))) + 1, LEN(Resultado)) AS Ds_Arquivo
    FROM @Retorno
    WHERE Resultado IS NOT NULL AND 
    Linha >= 6 AND 
    Linha < (SELECT MAX(Linha) FROM @Retorno) - 2 AND 
    Resultado NOT LIKE '%<DIR>%'
    ORDER BY Ds_Arquivo

    --SELECT * FROM @Retorno
    
    -- Obtendo os diretorios
    Insert #ListaArquivosFinal
    Select Ds_Arquivo 
    From @Tabela_Final
    Where Ds_Arquivo not like '%.%'

    

END
