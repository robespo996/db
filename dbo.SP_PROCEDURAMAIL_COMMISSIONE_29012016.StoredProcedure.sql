USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_29012016]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_29012016]
AS
DECLARE
            @OGGETTO				VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL					VARCHAR(500),
            @CODICEREGIONE	        VARCHAR(50),
			@COGNOME				VARCHAR(255),
			@NOME			        VARCHAR(255),
            @RETURN                 BIT
            
      SET @TESTO =
'<p>Si trasmette in allegato la comunicazione del Capo del Dipartimento della gioventù e del servizio civile nazionale,
relativa alle prossime elezioni della rappresentanza dei Volontari di servizio civile.</p>
<p>Cordialmente<br/>
La Commissione Elettorale</p>'

      DECLARE MYCUR CURSOR LOCAL FOR
			select distinct codiceregione, email
			from _Mail_Commissione_29012016_Enti
			--where codiceregione = ''	-- solo per TEST
		 
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEREGIONE, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
           
		   SET @OGGETTO='Elezioni 2016'
		    
	   -- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
       EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\Allegati_invioemail\Comunicazione Elezioni Enti di Servizio civile 2016.pdf'  
       
	   FETCH NEXT FROM MYCUR INTO @CODICEREGIONE, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = 'Elezioni 2016 - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\Allegati_invioemail\Comunicazione Elezioni Enti di Servizio civile 2016.pdf'




GO
