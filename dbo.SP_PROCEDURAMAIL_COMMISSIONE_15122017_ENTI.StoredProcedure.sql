USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_15122017_ENTI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_15122017_ENTI]
--@gruppo as int
AS
DECLARE
            @OGGETTO                VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @OGGETTOCOSTANTE        VARCHAR(500),
            @TESTOCOSTANTE          VARCHAR(8000),
			@TABELLA                VARCHAR(8000),
            
            @CODICEVOLONTARIO       VARCHAR(50),
			@COGNOME				VARCHAR(50),
			@NOME				    VARCHAR(50),
			@MAILVOLONTARIO			VARCHAR(500),
			@CODICEENTE				VARCHAR(50),
			@DENOMINAZIONE			VARCHAR(50),
			@MAILENTE			    VARCHAR(500),
			@MAILENTEPREC		    VARCHAR(500),
			@CODICEENTEPREC			VARCHAR(50),

            @RETURN                 BIT
            
      SET @OGGETTOCOSTANTE='Elezioni Rappresentanza 2018 - Comunicazione per i volontari'
      SET @TESTOCOSTANTE =
'<p>Il 15 dicembre 2017 sono state avviate le procedure elettorali per il rinnovo della Rappresentanza dei volontari di servizio civile.  
<br/>Nei giorni successivi è stata trasmessa, a tutti i volontari in servizio alla data di indizione, una email con l’indicazione delle procedure per la candidatura e l’elezione della rappresentanza. 
<br/>Molte di queste email non hanno raggiunto i destinatari in quanto sul sistema “Helios”non è stato possibile reperire l’indirizzo di posta elettronica o quello inserito è risultato errato. 
<br/>Al riguardo, si prega codesto Ente di consegnare la lettera in allegato ai volontari di cui all’unito elenco,  pregandoli di accedere all’area riservata e inserire/modificare il proprio indirizzo di posta elettronica.
<br/>Ringraziandovi per la collaborazione, si porgono cordiali saluti.
<br/>
<br/>La Commissione Elettorale
<br/>
<br/>Presidenza del Consiglio dei Ministri 
<br/>Dipartimento della Gioventù e del Servizio Civile Nazionale
<br/>Via della Ferratella in Laterano, 51 - 00184 Roma Tel. 06.67794027 - 06.67794303
<br/>commissioneelettorale@serviziocivile.it
</p>
<p>ELENCO VOLONTARI</p>'

	  SET @CODICEENTEPREC = ''
	  SET @TABELLA = ''
	  SET @TESTO = ''

      DECLARE MYCUR CURSOR LOCAL FOR
            select [codicevolontario],[Cognome],[Nome],[email_volontario],[codiceente],[Denominazione],[email_ente]
	    	   from [unscproduzione].[dbo].[_Mail_Commissione_15122017_Enti]
			WHERE codiceente not in ('NZ00014', 'NZ00018', 'NZ00045')
			ORDER BY codiceente, codicevolontario
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEVOLONTARIO, @COGNOME, @NOME, @MAILVOLONTARIO, @CODICEENTE, @DENOMINAZIONE, @MAILENTE
      WHILE @@Fetch_status = 0
      BEGIN
            
			--PRINT 'Codice Ente: ' + @CODICEENTE

			IF (@CODICEENTE = @CODICEENTEPREC OR @CODICEENTEPREC = '')
			BEGIN
				SET @TABELLA = @TABELLA + '<P>' + @CODICEVOLONTARIO + ' ' + @COGNOME + ' ' + @NOME + ' ' + @MAILVOLONTARIO + ' </P>'
			END
			
			--PRINT @TABELLA

			-- Aggiunge la TABELLA al testo
			--SET @TESTO = @TESTO + @TABELLA

			IF (@CODICEENTE <> @CODICEENTEPREC AND @CODICEENTEPREC <> '')
			BEGIN
				-- Aggiungi codice ente all'oggetto
				SET @OGGETTO = @OGGETTOCOSTANTE + ' ' + @CODICEENTEPREC
				
			
				-- Aggiunge la TABELLA al testo
				SET @TESTO = @TESTOCOSTANTE + @TESTO
				SET @TESTO = @TESTO + @TABELLA

				--PRINT @TESTO

				-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
				--EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,''

				EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAILENTEPREC,'','',@OGGETTO ,@TESTO,'d:\allegati\Lettera_Volontari_indizione.pdf'

				--PRINT 'INVIA E-MAIL'

				SET @OGGETTO = ''
				SET @TABELLA = ''
				set @TESTO = ''

				SET @TABELLA = @TABELLA + '<P>' + @CODICEVOLONTARIO + ' ' + @COGNOME + ' ' + @NOME + ' ' + @MAILVOLONTARIO + ' </P>'
			END

			SET @CODICEENTEPREC = @CODICEENTE
			SET @MAILENTEPREC = @MAILENTE
            
			FETCH NEXT FROM MYCUR INTO @CODICEVOLONTARIO, @COGNOME, @NOME, @MAILVOLONTARIO, @CODICEENTE, @DENOMINAZIONE, @MAILENTE


      END
CLOSE MYCUR
DEALLOCATE MYCUR

SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Lettera_Volontari_indizione.pdf'










GO
