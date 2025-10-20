USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_INVIO_MAIL_ACCREDITAMENTO]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[SP_INVIO_MAIL_ACCREDITAMENTO]
	@MAILINVIATORE VARCHAR(100), 
	@NOMEINVIATORE VARCHAR(100),
	@MAILDESTINATARIO VARCHAR(400), 
	@COPIACARBONE VARCHAR(100),
	@COPIACARBONEB VARCHAR(100),
	@OGGETTO VARCHAR(200),
	@MESSAGGIO VARCHAR(4000),
	@ALLEGATI VARCHAR(4000),
	@RITORNO INT = 0 Output
	
AS

DECLARE @rc INT
/*
exec 	@rc = master.dbo.xp_smtp_sendmail
	@FROM			= @MAILINVIATORE,
	@FROM_NAME			= @NOMEINVIATORE,
	@TO				= @MAILDESTINATARIO,
    	@CC				= @COPIACARBONE,
	@BCC				= @COPIACARBONEB,
	@priority			= N'NORMAL',
	@subject			= @OGGETTO,
	@message			= @MESSAGGIO,
	@type				= N'text/html',
	@attachments			= @ALLEGATI,
	@codepage			= 0,
	--@server 			= N'192.168.2.2'
	@server 			= N'mailbus.fastweb.it'

SET @RITORNO = @rc
*/
EXEC @RC = dbo.SSIS_sp_send_dbmail
	@profile_name = 'ACCREDITAMENTO',
	@recipients = @MAILDESTINATARIO,
	@subject = @OGGETTO,
	@copy_recipients = @COPIACARBONE,
	@blind_copy_recipients = @COPIACARBONEB,
	@body = @MESSAGGIO,
	@body_format = 'TEXT'--,
	--@file_attachments = @ALLEGATI

SET @RITORNO = @rc

RETURN @RITORNO

GO
