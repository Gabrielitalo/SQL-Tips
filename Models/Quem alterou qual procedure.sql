--------------------------------------------------------------------------------------------------------------------------------------------
--Checa quem alterou qual procedure
--------------------------------------------------------------------------------------------------------------------------------------------
Alter Procedure PcModificadasDia
as
--------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @filename VARCHAR(255), @BancoDados Varchar(250)

--------------------------------------------------------------------------------------------------------------------------------------------
Set @BancoDados = DB_NAME()

--------------------------------------------------------------------------------------------------------------------------------------------
SELECT @FileName = SUBSTRING(path, 0, LEN(path) - CHARINDEX('\', REVERSE(path)) + 1) + '\Log.trc'
FROM sys.traces
WHERE (is_default = 1)

--------------------------------------------------------------------------------------------------------------------------------------------
SELECT Distinct Gt.HostName, Gt.LoginName, Te.Name AS EventName,
Max(Convert(varchar, Gt.StartTime, 103) + ' ' + Convert(varchar, Gt.StartTime, 108)) DataAlteracao,
Gt.ObjectName, Gt.DatabaseName
FROM [fn_trace_gettable](@filename, DEFAULT) Gt
join sys.trace_events Te ON (Gt.EventClass = Te.trace_event_id)
Where (EventClass IN (164)) and --Gt.EventSubClass = 2 Não sei o porque desse parte estar comentada.
(DatabaseName = @BancoDados)
Group by  Gt.HostName, Gt.LoginName, Te.Name,	Gt.EventSubClass, Gt.ObjectName, Gt.DatabaseName

--------------------------------------------------------------------------------------------------------------------------------------------
--Exec PcAtualizaTodasProcedures 'PcModificadasDia'

--------------------------------------------------------------------------------------------------------------------------------------------
