USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_MAIL_SCADENZA_ORE_FORMAZIONE_SECONDATRANCHE_REV_2]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_MAIL_SCADENZA_ORE_FORMAZIONE_SECONDATRANCHE_REV_2]

@ESITO INT = 0 Output
AS
/*CREATA DA SIMONA CORDELLA IL 18/04/2012*/
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
SET @OGGETTO = 'AVVISO SCADENZA ORE DI FORMAZIONE (SECONDA TRANCHE)'
SET @INTESTAZIONE = '<FONT face="Verdana" size="4" Color="Red">
		 <B>ELENCO PROGETTI PER I QUALI RISULTANO SCADUTI I TERMINI PER LA CONFERMA DELLE ORE DI FORMAZIONE EROGATE AI VOLONTARI </B></FONT><br><br>
		 <FONT face="Verdana" size="4"><br><br>
		
		<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD><B>Competenza</B></TD><TD><B>Ente</B></TD><TD><B>Progetto</B></TD><TD align="center"><B>Data Inizio Progetto</B></TD><TD align="center"><B>Data Fine Progetto</B></TD><TD align="center"><B>Progetto Sottoposto a Verifica</B></TD><TD align="center"><B>Totale Volontari</B></TD><TD align="center"><B>Volontari in Servizio alla scadenza</B></TD><TD align="center"><B>Totale Volontari con ore caricate della seconda tranche</B></TD></TR>'
SET @MESSAGGIO = ''
SET @CHIUSURAMESSAGGIO = '</TABLE></FONT>'	

	DECLARE MYCUR CURSOR LOCAL FOR
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
					and dbo.formatodatadt(e.datascadenzasecondatranche) between a.datainizioservizio and a.datafineservizio) as Volontari150,
				 (select  count(distinct a.identit‡) 
					from entit‡ a 
					inner join attivit‡entit‡ b on a.identit‡ = b.identit‡
					inner join attivit‡entisediattuazione c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
					where c.idattivit‡ = attivit‡.idattivit‡ and b.idstatoattivit‡entit‡=1 and idstatoentit‡ in (3,5,6) 
					and  not a.oreformazione is null ) as NVolOre,
				case attivit‡.idregionecompetenza when 22 then ISNULL(attivit‡.progettosottopostoverifica,0) else 0 end AS PROGETTOSOTTOPOSTOVERIFICA,
				ISNULL(REGIONICOMPETENZE.MailNotificheFormazione,'') AS MAIL
			FROM attivit‡ 
			INNER JOIN Attivit‡FormazioneGenerale ON Attivit‡FormazioneGenerale.IdAttivit‡ = attivit‡.IDAttivit‡ 
			INNER JOIN ENTI ON ATTIVIT‡.IDENTEPRESENTANTE = ENTI.IDENTE
			INNER JOIN REGIONICOMPETENZE ON ATTIVIT‡.IDREGIONECOMPETENZA= REGIONICOMPETENZE.IDREGIONECOMPETENZA
			INNER JOIN BANDIATTIVIT‡ ON ATTIVIT‡.IDBANDOATTIVIT‡ = BANDIATTIVIT‡.IDBANDOATTIVIT‡
			INNER JOIN BANDO ON BANDIATTIVIT‡.IDBANDO = BANDO.IDBANDO			
			WHERE attivit‡.IDStatoAttivit‡ = 1 
			AND Attivit‡FormazioneGenerale.StatoFormazione is null	
			--AND ISNULL(DATEDIFF(dd, attivit‡.DataInizioAttivit‡, GETDATE()), 0) > 270	
			AND GETDATE() > DataScadenzaSecondaTranche			
			AND isnull(NotificaScadenza,0) = 0
			AND BANDO.REVISIONEFORMAZIONE>=2	
			AND ATTIVIT‡FORMAZIONEGENERALE.TIPOFORMAZIONEGENERALE = 2
			AND ATTIVIT‡.DATAINIZIOATTIVIT‡ IS NOT NULL
			--AND ATTIVIT‡.IDATTIVIT‡ NOT IN --ESCLUDO PROGETTI SENZA ORE PRIMA TRANCHE RICHIESTA ASCENZO 12/01/2016
			--	(select distinct a.idattivit‡
			--	from attivit‡ a
			--	inner join attivit‡entisediattuazione b on a.idattivit‡ = b.idattivit‡
			--	inner join attivit‡entit‡ c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione and idstatoattivit‡entit‡ = 1
			--	inner join entit‡ d on c.identit‡ = d.identit‡
			--	where isnull(oreformazioneprimatranche,0)>0)
			AND ATTIVIT‡.IDATTIVIT‡ NOT IN --ESCLUDO PROGETTI SENZA ORE PRIMA TRANCHE RICHIESTA ASCENZO 12/01/2016
										   --corretta il 31/03/2016 per errore nella subquery
				(select a.idattivit‡
				from attivit‡ a
				inner join attivit‡entisediattuazione b on a.idattivit‡ = b.idattivit‡
				inner join attivit‡entit‡ c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione and idstatoattivit‡entit‡ = 1
				inner join entit‡ d on c.identit‡ = d.identit‡ and 
				BANDO.idbando not in (549,550,551,553)---aggiunta per proroga titol	
				group  by a.idattivit‡
				having sum(isnull(oreformazioneprimatranche,0))=0)
			order by REGIONICOMPETENZE.DESCRIZIONE, enti.denominazione
			
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
		
		UPDATE Attivit‡FormazioneGenerale SET NotificaScadenza =1 WHERE IDAttivit‡ =@IDATTIVITA
		
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
