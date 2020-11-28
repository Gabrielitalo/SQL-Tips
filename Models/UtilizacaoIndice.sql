---------------------------------------------------------------------------------------------------------
--UTILIZAÇÃO DOS ÍNDICES
--Sp_HelpIndex 'ProdutosEntradas'
---------------------------------------------------------------------------------------------------------
Select DB_NAME(database_id) BancoDados, OBJECT_NAME(I.object_id) Tabela, I.Name Indice,
U.User_Seeks Seek, U.User_Scans Scan, U.User_Lookups LookUps,
U.Last_User_Seek UltimaPesquisa, U.Last_User_Scan UltimaVarredura,
U.Last_User_LookUp UltimoLookUp, U.Last_User_Update UltimaAtualiacao --Data que ocorreu a última operação na tabela (Insert, Updade, Delete)
From sys.indexes I
Inner Join sys.dm_db_index_usage_stats U ON (I.object_id = U.object_id) and (I.index_id = U.index_id)
Where (DB_NAME(database_id) = DB_NAME()) and
(U.User_Seeks = 0) and 
(U.User_Scans = 0) and 
(U.User_Lookups = 0) and
(Left(I.Name, 2) Not Like '%Pk%')
Order By Tabela