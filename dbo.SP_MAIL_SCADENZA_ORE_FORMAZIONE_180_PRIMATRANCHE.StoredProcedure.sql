USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_MAIL_SCADENZA_ORE_FORMAZIONE_180_PRIMATRANCHE]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_MAIL_SCADENZA_ORE_FORMAZIONE_180_PRIMATRANCHE]

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
		@MESSAGGIO			VARCHAR(MAX),
		@MESSAGGIOCC		VARCHAR(4000)

SET @CONTA = 0
SET @OGGETTO = 'AVVISO SCADENZA ORE DI FORMAZIONE (180 GIORNI PRIMA TRANCHE)'
SET @MESSAGGIO = '<FONT face="Verdana" size="4" Color="Red">
		 <B>ELENCO PROGETTI PER I QUALI RISULTANO SCADUTI I TERMINI PER IL CARICAMENTO DELLE ORE DI FORMAZIONE EROGATE AI VOLONTARI </B></FONT><br><br>
		 <FONT face="Verdana" size="4"><br><br>
		
		<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD><B>Competenza</B></TD><TD><B>Ente</B></TD><TD><B>Progetto</B></TD><TD align="center"><B>Data Inizio Progetto</B></TD><TD align="center"><B>Data Fine Progetto</B></TD><TD align="center"><B>Progetto Sottoposto a Verifica</B></TD><TD align="center"><B>Totale Volontari</B></TD><TD align="center"><B>Volontari in Servizio al 180gg dall''inizio progetto</B></TD><TD align="center"><B>Totale Volontari con ore caricate della prima tranche</B></TD></TR>'

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
					where c.idattivit‡ = attivit‡.idattivit‡ and b.idstatoattivit‡entit‡=1 and idstatoentit‡ in (3,5,6)
					and dateadd(d,181,attivit‡.datainizioattivit‡) between a.datainizioservizio and a.datafineservizio) as Volontari150,
				 (select  count(distinct a.identit‡) 
					from entit‡ a 
					inner join attivit‡entit‡ b on a.identit‡ = b.identit‡
					inner join attivit‡entisediattuazione c on b.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
					where c.idattivit‡ = attivit‡.idattivit‡ and b.idstatoattivit‡entit‡=1 and idstatoentit‡ in (3,5,6) 
					and  not a.oreformazioneprimatranche is null ) as NVolOre,
				case attivit‡.idregionecompetenza when 22 then ISNULL(attivit‡.progettosottopostoverifica,0) else 0 end AS PROGETTOSOTTOPOSTOVERIFICA
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
			AND ATTIVIT‡.DATAINIZIOATTIVIT‡ IS NOT NULL and BANDO.idbando not in (549,550,551,553)
	
	DELETE FROM #TMP WHERE NVOLORE>0 --RIMUOVO PROGETTI CON VOLONTARI CON ORE PRIMA TRANCHE CARICATE 	
			
	DECLARE MYCUR CURSOR LOCAL FOR
			SELECT * from #TMP order by Competenza, Ente	
			
	OPEN MYCUR
	FETCH NEXT FROM MYCUR INTO @IDATTIVITA, @COMPETENZA, @ENTE, @PROGETTO, @DATAINIZIOPROGETTO, @DATAFINEPROGETTO, @NVOL,@NVOL150,@NVOLORE,@PROGVERIFICA
	WHILE @@Fetch_status = 0
	BEGIN
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
		FETCH NEXT FROM MYCUR INTO @IDATTIVITA, @COMPETENZA, @ENTE, @PROGETTO, @DATAINIZIOPROGETTO, @DATAFINEPROGETTO, @NVOL,@NVOL150,@NVOLORE,@PROGVERIFICA
	END
	SET @MESSAGGIO = @MESSAGGIO + '</TABLE></FONT>'
CLOSE MYCUR
DEALLOCATE MYCUR


IF @CONTA>0
	EXEC  dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = 'formazione@serviziocivile.it', -- EMAIL DESTINATARIO formazione@serviziocivile.it
		@subject			= @OGGETTO,
		@copy_recipients = '',
		@blind_copy_recipients = 'heliosweb@serviziocivile.it', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
		@body = @MESSAGGIO,
		@body_format = 'HTML'

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
