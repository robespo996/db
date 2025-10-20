USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_MAIL_SCADENZA_ORE_FORMAZIONE_PRIMATRANCHE_REV_2]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_MAIL_SCADENZA_ORE_FORMAZIONE_PRIMATRANCHE_REV_2]

@ESITO INT = 0 Output
AS
/*CREATA DA SIMONA CORDELLA IL 18/04/2012*/
/*AGGIORNATA IL 18/02/2020 PER NOTIFICA A RPA COMPETENTE DEL PROGETTO*/
DECLARE
		@CONTA				INT,
		@IDATTIVITA			INT,
		@COMPETENZA			VARCHAR(200),
		@ENTE				VARCHAR(1000),
		@PROGETTO			VARCHAR(1000),
		@DATAINIZIOPROGETTO	VARCHAR(50),
		@DATAFINEPROGETTO	VARCHAR(50),
		@NVOL				INT,
		@NVOL150			INT,
		@NVOLORE			INT,
		@PROGVERIFICA		INT,
		@OGGETTO			VARCHAR(200),
		@INTESTAZIONE		VARCHAR(MAX),
		@MESSAGGIO			VARCHAR(MAX),
		@CHIUSURAMESSAGGIO  VARCHAR(MAX),
		@MESSAGGIOCC		VARCHAR(4000), 
		@RICORDACOMPETENZA	VARCHAR(200) = '',
		@RICORDAMAILDESTINATARIO	VARCHAR(1000) = '',
		@MAILDESTINATARIO	VARCHAR(1000) = ''

SET @CONTA = 0
SET @OGGETTO = 'AVVISO SCADENZA ORE DI FORMAZIONE (PRIMA TRANCHE)'
SET @INTESTAZIONE = '<FONT face="Verdana" size="4" Color="Red">
		 <B>ELENCO PROGETTI PER I QUALI RISULTANO SCADUTI I TERMINI PER IL CARICAMENTO DELLE ORE DI FORMAZIONE EROGATE AI VOLONTARI </B></FONT><br><br>
		 <FONT face="Verdana" size="4"><br><br>
		
		<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD><B>Competenza</B></TD><TD><B>Ente</B></TD><TD><B>Progetto</B></TD><TD align="center"><B>Data Inizio Progetto</B></TD><TD align="center"><B>Data Fine Progetto</B></TD><TD align="center"><B>Progetto Sottoposto a Verifica</B></TD><TD align="center"><B>Totale Volontari</B></TD><TD align="center"><B>Volontari in Servizio alla scadenza</B></TD><TD align="center"><B>Totale Volontari con ore caricate della prima tranche</B></TD></TR>'
SET @MESSAGGIO = ''
SET @CHIUSURAMESSAGGIO = '</TABLE></FONT>'	

		SELECT attivit‡.IDAttivit‡, REGIONICOMPETENZE.DESCRIZIONE AS COMPETENZA, ENTI.DENOMINAZIONE + ' (' + enti.codiceregione + ')' as Ente, attivit‡.TITOLO + ' (' + attivit‡.CODICEENTE + ')' as Progetto, 
				dbo.formatodata(attivit‡.DataInizioAttivit‡) as DataInizioProgetto,
				dbo.formatodata(attivit‡.DataFineAttivit‡) as DataFineProgetto,
				(select count(distinct a.identit‡) 
					from entit‡ a 
					inner join attivit‡entit‡ b on a.identit‡ = b.identit‡
					inner join attivit‡entisediattuazione c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
					where c.idattivit‡ = attivit‡.idattivit‡ and b.idstatoattivit‡entit‡=1 and idstatoentit‡ in (3,5,6)) as Volontari,
				(select count(distinct a.identit‡) 
					from entit‡ a 
					inner join attivit‡entit‡ b on a.identit‡ = b.identit‡
					inner join attivit‡entisediattuazione c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
					inner join attivit‡ d on c.idattivit‡ = d.idattivit‡
					inner join attivit‡formazionegenerale e on d.idattivit‡ = e.idattivit‡
					where c.idattivit‡ = attivit‡.idattivit‡ and b.idstatoattivit‡entit‡=1 and idstatoentit‡ in (3,5,6)
					and dbo.formatodatadt(e.DataScadenzaPrimaTranche) between a.datainizioservizio and a.datafineservizio) as Volontari150,
				 (select  count(distinct a.identit‡) 
					from entit‡ a 
					inner join attivit‡entit‡ b on a.identit‡ = b.identit‡
					inner join attivit‡entisediattuazione c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
					where c.idattivit‡ = attivit‡.idattivit‡ and b.idstatoattivit‡entit‡=1 and idstatoentit‡ in (3,5,6) 
					and  not a.oreformazioneprimatranche is null ) as NVolOre,
				case attivit‡.idregionecompetenza when 22 then ISNULL(attivit‡.progettosottopostoverifica,0) else 0 end AS PROGETTOSOTTOPOSTOVERIFICA,
				ISNULL(REGIONICOMPETENZE.MailNotificheFormazione,'') AS MAIL
			into #tmp
			FROM attivit‡ 
			INNER JOIN Attivit‡FormazioneGenerale ON Attivit‡FormazioneGenerale.IdAttivit‡ = attivit‡.IDAttivit‡ 
			INNER JOIN ENTI ON ATTIVIT‡.IDENTEPRESENTANTE = ENTI.IDENTE
			INNER JOIN REGIONICOMPETENZE ON ATTIVIT‡.IDREGIONECOMPETENZA= REGIONICOMPETENZE.IDREGIONECOMPETENZA
			INNER JOIN BANDIATTIVIT‡ ON ATTIVIT‡.IDBANDOATTIVIT‡ = BANDIATTIVIT‡.IDBANDOATTIVIT‡
			INNER JOIN BANDO ON BANDIATTIVIT‡.IDBANDO = BANDO.IDBANDO			
			WHERE attivit‡.IDStatoAttivit‡ = 1 
			AND Attivit‡FormazioneGenerale.StatoFormazione is null	
			--AND ISNULL(DATEDIFF(dd, attivit‡.DataInizioAttivit‡, GETDATE()), 0) > 180	
			AND GETDATE() > DataScadenzaPrimaTranche	
			AND isnull(NotificaScadenzaPrimaTranche,0) = 0
			AND BANDO.REVISIONEFORMAZIONE>=2	
			AND ATTIVIT‡FORMAZIONEGENERALE.TIPOFORMAZIONEGENERALE = 2	
			AND ATTIVIT‡.DATAINIZIOATTIVIT‡ IS NOT NULL and 
			BANDO.idbando not in (549,550,551,553)---aggiunta per proroga titol	
	
	DELETE FROM #TMP WHERE NVOLORE>0 --RIMUOVO PROGETTI CON VOLONTARI CON ORE PRIMA TRANCHE CARICATE 	
			
	DECLARE MYCUR CURSOR LOCAL FOR
			SELECT * from #TMP order by Competenza, Ente	
			
	OPEN MYCUR
	FETCH NEXT FROM MYCUR INTO @IDATTIVITA, @COMPETENZA, @ENTE, @PROGETTO, @DATAINIZIOPROGETTO, @DATAFINEPROGETTO, @NVOL,@NVOL150,@NVOLORE,@PROGVERIFICA,@MAILDESTINATARIO
	WHILE @@Fetch_status = 0
	BEGIN
		IF @RICORDACOMPETENZA = ''
		BEGIN
			SET @RICORDACOMPETENZA = @COMPETENZA
			SET @MAILDESTINATARIO = CASE @MAILDESTINATARIO WHEN '' THEN 'formazione@serviziocivile.it' ELSE @MAILDESTINATARIO END
			SET @RICORDAMAILDESTINATARIO = @MAILDESTINATARIO
		END
		IF @RICORDACOMPETENZA <> @COMPETENZA
		BEGIN
			IF @CONTA>0
			BEGIN	
				SET @MESSAGGIO = @INTESTAZIONE + @MESSAGGIO + @CHIUSURAMESSAGGIO
				EXEC  dbo.SSIS_sp_send_dbmail
					@profile_name = 'UNSC',
					@recipients = @RICORDAMAILDESTINATARIO , -- EMAIL DESTINATARIO formazione@serviziocivile.it
					@subject = @OGGETTO,
					@copy_recipients = '',
					@blind_copy_recipients = 'heliosweb@serviziocivile.it', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
					@body = @MESSAGGIO,
					@body_format = 'HTML'	
				SET @CONTA = 0
				SET @MESSAGGIO = ''
			END		
	
			SET @RICORDACOMPETENZA = @COMPETENZA
			SET @MAILDESTINATARIO = CASE @MAILDESTINATARIO WHEN '' THEN 'formazione@serviziocivile.it' ELSE @MAILDESTINATARIO END
			SET @RICORDAMAILDESTINATARIO = @MAILDESTINATARIO
		END	
	
		SET @MESSAGGIO = @MESSAGGIO + 
				'<TR>
				<TD>' + @COMPETENZA + '</TD>
				<TD>' + @ENTE + '</TD>
				<TD>' + @PROGETTO + '</TD>
				<TD align="center">' + @DATAINIZIOPROGETTO + '</TD>
				<TD align="center">' + @DATAFINEPROGETTO + '</TD>
				<TD align="center">' + CASE convert(varchar,@PROGVERIFICA) WHEN '0' THEN '' ELSE 'SI' END + '</TD>
				<TD align="center">' + CONVERT(VARCHAR,@NVOL) + '</TD>
				<TD align="center">' + CONVERT(VARCHAR,@NVOL150) + '</TD>
				<TD align="center">' + CONVERT(VARCHAR,@NVOLORE) + '</TD>
				</TR>'	
		
		UPDATE Attivit‡FormazioneGenerale SET NotificaScadenzaPrimaTranche =1 WHERE IDAttivit‡ =@IDATTIVITA
		
		SET @CONTA =@CONTA +1
		FETCH NEXT FROM MYCUR INTO @IDATTIVITA, @COMPETENZA, @ENTE, @PROGETTO, @DATAINIZIOPROGETTO, @DATAFINEPROGETTO, @NVOL,@NVOL150,@NVOLORE,@PROGVERIFICA,@MAILDESTINATARIO

		IF @@Fetch_status <> 0 --ULTIMO RECORD
		BEGIN
			SET @MAILDESTINATARIO = CASE @MAILDESTINATARIO WHEN '' THEN 'formazione@serviziocivile.it' ELSE @MAILDESTINATARIO END
			SET @MESSAGGIO = @INTESTAZIONE + @MESSAGGIO + @CHIUSURAMESSAGGIO
			EXEC  dbo.SSIS_sp_send_dbmail
				@profile_name = 'UNSC',
				@recipients = @RICORDAMAILDESTINATARIO , -- EMAIL DESTINATARIO formazione@serviziocivile.it
				@subject = @OGGETTO,
				@copy_recipients = '',
				@blind_copy_recipients = 'heliosweb@serviziocivile.it', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
				@body = @MESSAGGIO,
				@body_format = 'HTML'			
		END
		
	END
CLOSE MYCUR
DEALLOCATE MYCUR


--IF @CONTA>0
--	EXEC  dbo.SSIS_sp_send_dbmail
--		@profile_name = 'UNSC',
--		@recipients = 'formazione@serviziocivile.it', -- EMAIL DESTINATARIO formazione@serviziocivile.it
--		@subject			= @OGGETTO,
--		@copy_recipients = '',
--		@blind_copy_recipients = 'heliosweb@serviziocivile.it', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
--		@body = @MESSAGGIO,
--		@body_format = 'HTML'

--
------NON VIENE ESEGUITO SU DB SVILUPPO!!!
--IF @CONTA>0
--	EXEC @ESITO = SP_INVIO_MAIL 
--		'heliosweb@serviziocivile.it', --MAIL MITTENTE
--		'HELIOSWEB', --MITTENTE
--		
--		'',--@CC, --COPIA CARBONE
--		'', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
--		@OGGETTO, --OGGETTO
--		@MESSAGGIO, --TESTO EMAIL
--		'' --ALLEGATI
--
--
--	
GO
