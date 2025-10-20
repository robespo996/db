USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_INVIO_MAIL_STARTUP_PRIMO_ALERT]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Procedura Invio Mail relativo al giorno 5 del mese
ALTER PROCEDURE [dbo].[SP_INVIO_MAIL_STARTUP_PRIMO_ALERT]
AS
	DECLARE
		@CODICEVOLONTARIO		VARCHAR(15),
		@COGNOMENOME			VARCHAR(201),
		@CODICEFISCALE			VARCHAR(16),
		@PROGETTO			VARCHAR(1000),
		@DATAINIZIOPROGETTO		VARCHAR(50),
		@EMAILENTE			VARCHAR(100),
		@IDENTE				INT,
		@ENTENOME			VARCHAR(200),
		@OGGETTO			VARCHAR(200),
		@MESSAGGIO			VARCHAR(MAX),
		@MESSAGGIOCC			VARCHAR(4000),
		@IDENTITA			INT,
		@ENTESUFFISSO			VARCHAR(10),
		@CONTA				INT,
		@TIPODOC			VARCHAR(20),
		@PRIMAVOLTA			INT,
		@IDALERT			INT,
		@CODICESEDE			VARCHAR(15),
		@RUNESEGUITO			INT

	SET @CONTA = 0
	SET @PRIMAVOLTA = 1
	SET @IDALERT = 0 
	SET @RUNESEGUITO = 0 

	DECLARE MYCUR0 CURSOR LOCAL FOR
	SELECT DISTINCT	TipoDoc
	FROM TIPODOC_ALERT

	OPEN MYCUR0
	FETCH NEXT FROM MYCUR0 INTO @TIPODOC
	WHILE @@Fetch_status = 0
	BEGIN

		DECLARE MYCUR CURSOR LOCAL FOR
		SELECT DISTINCT	enti.email,
				enti.idente,
				enti.denominazione,
				enti.codiceregione
		FROM enti 
		INNER JOIN attivit‡ ON enti.IDEnte = attivit‡.IDEntePresentante 
		INNER JOIN tipiprogetto ON attivit‡.idtipoprogetto = tipiprogetto.idtipoprogetto
		INNER JOIN bandiattivit‡ ON attivit‡.idbandoattivit‡ = bandiattivit‡.idbandoattivit‡
		INNER JOIN bando ON bandiattivit‡.idbando = bando.idbando
		INNER JOIN attivit‡entisediattuazione ON attivit‡.IDAttivit‡ = attivit‡entisediattuazione.IDAttivit‡ 
		INNER JOIN attivit‡entit‡ ON attivit‡entisediattuazione.IDAttivit‡EnteSedeAttuazione = attivit‡entit‡.IDAttivit‡EnteSedeAttuazione and 			attivit‡entit‡.idstatoattivit‡entit‡=1
		INNER JOIN entit‡ ON attivit‡entit‡.IDEntit‡ = entit‡.IDEntit‡ 
		WHERE	entit‡.idstatoentit‡ in (3,5,6) 
		AND     (Entit‡.datafineservizio is null or (convert(date,Entit‡.datainizioservizio)<>convert(date,Entit‡.datafineservizio)))
		AND	Entit‡.datainizioservizio = CONVERT(date,'2024-06-06')
		AND	tipiprogetto.MacroTipoProgetto  <>'GG'
		AND	bando.DocumentiVolontari = 1
		AND     NOT EXISTS (select 1 from Entit‡Documenti 
				WHERE entit‡.IDEntit‡ = Entit‡Documenti.IDEntit‡  
				and   Entit‡Documenti.FILENAME LIKE @TIPODOC + '%')
			
		OPEN MYCUR
		FETCH NEXT FROM MYCUR INTO @EMAILENTE, @IDENTE, @ENTENOME, @ENTESUFFISSO
		WHILE @@Fetch_status = 0
		BEGIN

			SET @CONTA = 0
			SET @PRIMAVOLTA = 1
			SET @IDALERT = 0 
			SET @OGGETTO = 'ENTE ' + @ENTESUFFISSO + ' - AVVISO MANCATO CARICAMENTO A SISTEMA DEI DOCUMENTI AFFERENTI GLI O.V. AVVIATI AL SERVIZIO - PRIMO ALERT'
			SET @MESSAGGIO = '<FONT face="Verdana" size="4">Si segnala che, con riferimento agli O.V. indicati in tabella, non risulta il caricamento nel Sistema Unico del contratto.<br><br>
Il contratto sottoscritto e vistato, con indicazione della data di effettiva presentazione in servizio deve essere caricato unitamente alla seguente documentazione:<br>
- modulo per líaccreditamento dei compensi; <br>
- comunicazione del domicilio fiscale dellíoperatore volontario; <br>
- copia della tessera sanitaria/C.F. dellíoperatore volontario,<br>
devono essere trasmessi al Dipartimento, caricandoli nel Sistema Unico.<br><br>
Si invita a voler procedere tempestivamente.
</FONT><br><br>
					 <FONT face="Verdana" size="4"><br><br>
		
			<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD><B>CodiceVolontario</B></TD><TD align="center"><B>Codice Progetto</B></TD><TD align="center"><B>Data Inizio Servizio</B></TD><TD align="center"><B>Tipo Documento</B></TD><TD align="center"><B>Codice Sede</B></TD></TR>'

			DECLARE MYCUR2 CURSOR LOCAL FOR
			SELECT DISTINCT	
				entit‡.identit‡,
				ENTIT‡.CODICEVOLONTARIO, 
				ENTIT‡.COGNOME + ' ' + NOME AS NOMINATIVO, 
				ENTIT‡.CODICEFISCALE,
				attivit‡.codiceente as codiceprogetto,
				convert(varchar,dbo.formatodata(DATAINIZIOSERVIZIO)) as DATAINIZIOSERVIZIO,
				convert(varchar,attivit‡entisediattuazione.identesedeattuazione) as CODICESEDE
			FROM attivit‡
			INNER JOIN tipiprogetto ON attivit‡.idtipoprogetto = tipiprogetto.idtipoprogetto
			INNER JOIN bandiattivit‡ ON attivit‡.idbandoattivit‡ = bandiattivit‡.idbandoattivit‡
			INNER JOIN bando ON bandiattivit‡.idbando = bando.idbando
			INNER JOIN attivit‡entisediattuazione ON attivit‡.IDAttivit‡ = attivit‡entisediattuazione.IDAttivit‡ 
			INNER JOIN attivit‡entit‡ ON attivit‡entisediattuazione.IDAttivit‡EnteSedeAttuazione = attivit‡entit‡.IDAttivit‡EnteSedeAttuazione and 							attivit‡entit‡.idstatoattivit‡entit‡=1
			INNER JOIN entit‡ ON attivit‡entit‡.IDEntit‡ = entit‡.IDEntit‡ 
			WHERE	entit‡.idstatoentit‡ in (3,5,6) 
			AND     (Entit‡.datafineservizio is null or (convert(date,Entit‡.datainizioservizio)<>convert(date,Entit‡.datafineservizio)))
			AND	Entit‡.datainizioservizio = CONVERT(date,'2024-06-06')
			AND	tipiprogetto.MacroTipoProgetto  <>'GG'
			AND	bando.DocumentiVolontari = 1
			AND     attivit‡.IDEntePresentante = @IDENTE
			AND     NOT EXISTS (select 1 from Entit‡Documenti 
					WHERE entit‡.IDEntit‡ = Entit‡Documenti.IDEntit‡  
					and   Entit‡Documenti.FILENAME LIKE  @TIPODOC + '%')

			OPEN MYCUR2
			FETCH NEXT FROM MYCUR2 INTO @IDENTITA, @CODICEVOLONTARIO, @COGNOMENOME, @CODICEFISCALE, @PROGETTO, @DATAINIZIOPROGETTO, @CODICESEDE
			WHILE @@Fetch_status = 0
			BEGIN
				SET @RUNESEGUITO = 1

				IF @PRIMAVOLTA = 1
				BEGIN
				
					INSERT INTO LOG_ALERT_SUMMARY (DataInvio, idEnte, CodiceEnte, NumeroVolontari,TipoAlert)
					VALUES (GETDATE(), @IDENTE, @ENTESUFFISSO, @@CURSOR_ROWS,'PRIMO ALERT')

					SET @PRIMAVOLTA = 0
					SET @IDALERT = @@IDENTITY
				END 

				SET @MESSAGGIO = @MESSAGGIO + 
					'<TR>
					<TD align="center">' + @CODICEVOLONTARIO + '</TD>
					<TD align="center">' + @PROGETTO + '</TD>
					<TD align="center">' + @DATAINIZIOPROGETTO + '</TD>
					<TD align="center">' + @TIPODOC + '</TD>
					<TD align="center">' + @CODICESEDE + '</TD>
					</TR>'	
				SET @CONTA = @CONTA +1
	
				INSERT INTO LOG_ALERT_DETAIL (idAlert, CodiceVolontario, Progetto, DataInizio, TipoDoc, CodiceSede)
				VALUES (@IDALERT, @CODICEVOLONTARIO, @PROGETTO, @DATAINIZIOPROGETTO,  @TIPODOC, @CODICESEDE)

				FETCH NEXT FROM MYCUR2 INTO @IDENTITA, @CODICEVOLONTARIO, @COGNOMENOME, @CODICEFISCALE, @PROGETTO, @DATAINIZIOPROGETTO, @CODICESEDE

			END
			SET @MESSAGGIO = @MESSAGGIO + '</TABLE></FONT>'
			CLOSE MYCUR2
			DEALLOCATE MYCUR2

			IF @CONTA>0
				BEGIN
				EXEC  dbo.SSIS_sp_send_dbmail
					@profile_name = 'UNSC',
					@recipients = @EMAILENTE, -- EMAIL DESTINATARIO 
					@subject = @OGGETTO,
					@copy_recipients = '',
					@blind_copy_recipients = '', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
					@body = @MESSAGGIO,
					@body_format = 'HTML'
				END

			FETCH NEXT FROM MYCUR INTO @EMAILENTE, @IDENTE, @ENTENOME, @ENTESUFFISSO

		END
		CLOSE MYCUR
		DEALLOCATE MYCUR

		FETCH NEXT FROM MYCUR0 INTO @TIPODOC
	END
	CLOSE MYCUR0
	DEALLOCATE MYCUR0

	IF @RUNESEGUITO = 0 
		BEGIN
			INSERT INTO LOG_ALERT_RUN (DataRun, Esito, TipoAlert)
			VALUES (GETDATE(), 'Nessuna occorrenza trovata per il run corrente','PRIMO ALERT')
		END
	ELSE
		BEGIN
			INSERT INTO LOG_ALERT_RUN (DataRun, Esito, TipoAlert)
			VALUES (GETDATE(), 'Trovata almeno una occorrenza il run corrente. Consultare tabelle SUMMARY e DETAIL','PRIMO ALERT')
		END
GO
