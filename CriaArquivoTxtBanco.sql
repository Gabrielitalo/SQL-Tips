---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Criado por Gabriel em 17/09/2020
-- Tem por finalidade criar um arquivo f�sico no disco, a ideia � exportar dados da tabela para arquivo.
---------------------------------------------------------------------------------------------------------------------------------------------------------------

ALTER PROCEDURE [dbo].[PcEscreveArquivoBancoDados](@CaminhoSalvar VARCHAR(255), @Texto VARCHAR(MAX), @Sobrescreve bit = 0)
AS 
Begin
    SET NOCOUNT ON
    /*
			@Sobrescreve = 0 n�o ir� sobrepor.
			@Sobrescreve = 1 ir� sobrepor.
		*/

    Declare @Query VARCHAR(8000) = 'ECHO ' + @Texto + (CASE WHEN @Sobrescreve = 1 THEN ' > ' ELSE ' >> ' END) + ' ' + @CaminhoSalvar + '"'

    EXEC master.dbo.xp_cmdshell @command_string = @Query
    
		Select @CaminhoSalvar
End

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--Exec PcAtualizaTodasProcedures 'PcEscreveArquivoBancoDados'
---------------------------------------------------------------------------------------------------------------------------------------------------------------
