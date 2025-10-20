USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[mc_SP_AGGIORNA_CHECKLIST_PAGAMENTI_BO]    Script Date: 14/10/2025 12:36:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[mc_SP_AGGIORNA_CHECKLIST_PAGAMENTI_BO]
	--@Esito varchar(10) output, --POSITIVO/NEGATIVO
	--@Messaggio varchar(255) output --CAUSALE ESITO NEGATIVO
	@dipendente varchar(10)
AS

DECLARE @OGGETTO varchar(255),
	@Esito varchar(10), --POSITIVO/NEGATIVO
	@Messaggio varchar(255) --CAUSALE ESITO NEGATIVO

SET NOCOUNT ON

BEGIN TRY
	BEGIN TRANSACTION
	
	set @OGGETTO = 'POPOLAMENTO TABELLA TAB_BO_CHECKLIST_PAGAMENTI'

	-- Cancella il contenuto della tabella non scrivendo il log
	delete TAB_BO_CHECKLIST_PAGAMENTI
	where DIPENDENTE = @dipendente

	-- Inserisce i dati dei pagamenti, letti da EUREKA
	INSERT INTO TAB_BO_CHECKLIST_PAGAMENTI
	SELECT 
		ENTE, 
		ANNO, 
		MESE, 
		DIPENDENTE, 
		MeseElab, 
		AnnoElab, 
		PeriodoPag,
		INIZIOPERIODO,
		FINEPERIODO
	FROM [sqldati].[eureka].[dbo].[vw_checklist_pagamenti] 
	where dipendente = @dipendente

	set @Esito = 'POSITIVO'
	set @Messaggio = 'POPOLAMENTO TABELLA ''TAB_BO_CHECKLIST_PAGAMENTI'' TERMINATO CON SUCCESSO.'
	IF (XACT_STATE()<>0) BEGIN
		COMMIT TRANSACTION;
	END
END TRY
BEGIN CATCH
	IF (XACT_STATE()<>0) BEGIN
		ROLLBACK TRANSACTION;
	END
	set @Esito = 'NEGATIVO'
	set @Messaggio = 'ERRORE IMPREVISTO DURANTE L''ELABORAZIONE: ' + convert(varchar, ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE()
	
	-- Aggiungo l'errore sull'oggetto
	SET @OGGETTO = @OGGETTO + '. ERRORE SU PROCEDURA SQL-SERVER ''SP_AGGIORNA_CHECKLIST_PAGAMENTI_BO'''
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
