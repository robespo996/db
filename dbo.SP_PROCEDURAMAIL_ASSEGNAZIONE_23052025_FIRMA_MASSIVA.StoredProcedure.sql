USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_ASSEGNAZIONE_23052025_FIRMA_MASSIVA]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_ASSEGNAZIONE_23052025_FIRMA_MASSIVA]

AS
DECLARE
			-- variabili obbligatorie
            @OGGETTO						VARCHAR(500),
            @TESTO							VARCHAR(8000),
            @TESTOAPPO						VARCHAR(8000),
            @MAIL							VARCHAR(500),
            @RETURN							BIT,
			@gruppo							INT
            
      SET @OGGETTO='Sottoscrizione digitale dei contratti di Servizio Civile Universale'

      SET @TESTO =
'
<p>Gentile candidato/a,</p>
<p>Ti informiamo che l''ente titolare del progetto da te scelto ha aderito alla <b>sperimentazione</b> concernente la <b>sottoscrizione digitale</b> dei contratti di servizio civile universale.<br/>
Potresti essere tra i primi operatori volontari a sottoscrivere il contratto di servizio civile universale in modalità <b>totalmente digitale</b>, direttamente su IO, l''app dei servizi pubblici, grazie a Firma con IO, la funzionalità che consente di firmare digitalmente i documenti degli Enti Pubblici.</p>
<p>Ti invitiamo a leggere attentamente le informazioni contenute nell''allegato di questa e-mail.</p>
<p><i>Saremo lieti di vivere insieme questa esperienza!</i></p>
<br/>
<p style="line-height:100%">
<b>Dipartimento delle politiche giovanili e del Servizio Civile Universale</b>
</p>
<p style="line-height:100%;font-size: 0.8em">
<b><i>Ufficio per il Servizio Civile Universale</i></b><br/>
<i>Servizio gestione degli operatori volontari e formazione</i><br/>
<i>Via della Ferratella in Laterano, 51</i><br/>
<i>00184 Roma</i><br/>
<i>assegnazionegestione@serviziocivile.it</i><br/>
</p>
'

	  -- Legge l'ultimo gruppo inviato (1 se è il primo)
	  -- ATTENZIONE!! Svuotare(TRUNCATE table _mail_gruppi_inviati) prima di fare il primo invio massivo delle e-mail
	  --select @gruppo = isnull(max(gruppo),0)+1 from _mail_gruppi_inviati
	  --select isnull(max(gruppo),0)+1 from _mail_gruppi_inviati -- check collaudo

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  -- COMMENTA in modo da non aggiornare
	  --insert into _mail_gruppi_inviati (gruppo) values (@gruppo) -- PRODUZIONE

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct 
				 email
			from [unscproduzione].[dbo]._Mail_Assegnazione_24052025_Firma_Massiva
			--where gruppo = @gruppo -- produzione
			order by 1
      
	  OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN

		-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
		EXEC @RETURN = [SP_INVIO_MAIL_ASSEGNAZIONEGESTIONE] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\firmamassiva\COMUNICAZIONE_OV.pdf'
        FETCH NEXT FROM MYCUR INTO @MAIL

      END
CLOSE MYCUR
DEALLOCATE MYCUR

--produzione
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
--EXEC @RETURN = [SP_INVIO_MAIL_ASSEGNAZIONEGESTIONE] '','','sviluppo@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\firmamassiva\COMUNICAZIONE_OV.pdf'
EXEC @RETURN = [SP_INVIO_MAIL_ASSEGNAZIONEGESTIONE] '','','sviluppo@serviziocivile.it;assegnazionegestione@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\firmamassiva\COMUNICAZIONE_OV.pdf'

GO
