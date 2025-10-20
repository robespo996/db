USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_INVIO_MAIL_SPOT]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


ALTER PROCEDURE [dbo].[SP_INVIO_MAIL_SPOT]
	@MAILINVIATORE VARCHAR(100), 
	@NOMEINVIATORE VARCHAR(100),
	@MAILDESTINATARIO VARCHAR(100), 
	@COPIACARBONE VARCHAR(100),
	@COPIACARBONEB VARCHAR(100),
	@OGGETTO VARCHAR(200),
	@MESSAGGIO VARCHAR(8000),
	@ALLEGATI VARCHAR(4000),
	@RITORNO INT = 0 Output
	
AS
DECLARE @rc INT

EXEC @RC = dbo.SSIS_sp_send_dbmail
	@profile_name = 'SPOT',
	@recipients = @MAILDESTINATARIO,
	@subject = @OGGETTO,
	@copy_recipients = @COPIACARBONE,
	@blind_copy_recipients = @COPIACARBONEB,
	@file_attachments = @ALLEGATI,
	@body = @MESSAGGIO,
	@body_format = 'HTML'

SET @RITORNO = @rc

RETURN @RITORNO

GO
