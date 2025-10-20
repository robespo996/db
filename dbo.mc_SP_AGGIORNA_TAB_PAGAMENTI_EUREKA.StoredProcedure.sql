USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[mc_SP_AGGIORNA_TAB_PAGAMENTI_EUREKA]    Script Date: 14/10/2025 12:36:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








ALTER PROCEDURE [dbo].[mc_SP_AGGIORNA_TAB_PAGAMENTI_EUREKA]
	@dipendente varchar(10)
AS

DECLARE @OGGETTO varchar(255),
	@Esito varchar(10), --POSITIVO/NEGATIVO
	@Messaggio varchar(255) --CAUSALE ESITO NEGATIVO

SET NOCOUNT ON

BEGIN TRY
	--BEGIN TRANSACTION
	
	set @OGGETTO = 'POPOLAMENTO TABELLA SQLDATI.GestioneBanca.dbo.TAB_PAGAMENTI_EUREKA'

	-- Cancella il contenuto della tabella scrivendo il log
	delete FROM [SQLDATI].[gestioneBanca].[dbo].[TAB_PAGAMENTI_EUREKA]
	where dipendente = @dipendente

	-- Inserisce i dati dei pagamenti, letti dalla tabella unscproduzione.dbo.TAB_BO_CHECKLIST_PAGAMENTI
	INSERT INTO [SQLDATI].[gestioneBanca].[dbo].[TAB_PAGAMENTI_EUREKA]
	(
		   [ENTE]
	      ,[ANNO]
	      ,[MESE]
	      ,[DIPENDENTE]
	      ,[MeseElab]
	      ,[AnnoElab]
	      ,[PeriodoPag]
	      ,[INIZIOPERIODO]
	      ,[FINEPERIODO]
	      ,[MeseElabRend]
	)
	SELECT 
		   [ENTE]
	      ,[ANNO]
	      ,[MESE]
	      ,[DIPENDENTE]
	      ,[MeseElab]
	      ,[AnnoElab]
	      ,[PeriodoPag]
	      ,[INIZIOPERIODO]
	      ,[FINEPERIODO]
	      ,left(convert(varchar, case when meseElab = 1 then 12 else meseElab - 1 end) + '  ', 3) + convert(varchar(4), case when meseElab = 1 then annoElab - 1 else annoElab end) as MeseElabRend
	  FROM TAB_BO_CHECKLIST_PAGAMENTI
	  where DIPENDENTE = @dipendente

	set @Esito = 'POSITIVO'
	set @Messaggio = 'POPOLAMENTO TABELLA ''SQLDATI.GestioneBanca.dbo.TAB_PAGAMENTI_EUREKA'' TERMINATO CON SUCCESSO.'
	IF (XACT_STATE()<>0) BEGIN
		--COMMIT TRANSACTION;
		SELECT 'COMMIT'
	END
END TRY
BEGIN CATCH
	IF (XACT_STATE()<>0) BEGIN
		--ROLLBACK TRANSACTION;
		SELECT 'ROLLBACK'
	END
	set @Esito = 'NEGATIVO'
	set @Messaggio = 'ERRORE IMPREVISTO DURANTE L''ELABORAZIONE: ' + convert(varchar, ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE()
	
	-- Aggiungo l'errore sull'oggetto
	SET @OGGETTO = @OGGETTO + '. ERRORE SU PROCEDURA SQL-SERVER ''SP_AGGIORNA_TAB_PAGAMENTI_EUREKA'''
	-- Aggiungo l'esito al messaggio
	SET @Messaggio = '<br>   ESITO: ' + @Esito + '     MSG: ' + @MESSAGGIO

	EXEC  dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = 'sviluppo@serviziocivile.it', -- EMAIL DESTINATARIO sviluppo@serviziocivile.it
		@subject = @OGGETTO,
		@copy_recipients = '',
		@blind_copy_recipients = 'mpetracca@serviziocivile.it', --COPIA CARBONE NASCOSTA mpetracca@serviziocivile.it
		@body = @Messaggio,
		@body_format = 'HTML'

END CATCH
SET NOCOUNT OFF





GO
