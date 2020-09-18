---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Criado por Gabriel em 17/09/2020
-- Tem por finalidade criar um arquivo físico no disco, a ideia é exportar dados da tabela para arquivo.
---------------------------------------------------------------------------------------------------------------------------------------------------------------

ALTER PROCEDURE [dbo].[PcEscreveArquivoBancoDados](@CaminhoSalvar VARCHAR(255), @Texto VARCHAR(MAX), @Sobrescreve bit = 0)
AS 
Begin
    SET NOCOUNT ON
    /*
			@Sobrescreve = 0 não irá sobrepor.
			@Sobrescreve = 1 irá sobrepor.
		*/

    Declare @Query VARCHAR(8000) = 'ECHO ' + @Texto + (CASE WHEN @Sobrescreve = 1 THEN ' > ' ELSE ' >> ' END) + ' ' + @CaminhoSalvar + '"'

    EXEC master.dbo.xp_cmdshell @command_string = @Query
    
		Select @CaminhoSalvar
End

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--Exec PcAtualizaTodasProcedures 'PcEscreveArquivoBancoDados'
---------------------------------------------------------------------------------------------------------------------------------------------------------------
