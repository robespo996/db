USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_WARNING_SCADENZA_ORE_FORMAZIONE]    Script Date: 14/10/2025 12:36:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Procedura Invio Mail relativo alla prossima scadenza ore formazione
ALTER PROCEDURE [dbo].[SP_WARNING_SCADENZA_ORE_FORMAZIONE]
AS
	DECLARE
		@PROGETTO			VARCHAR(1000),
		@IDPROGETTO			INT,
		@DATASCADENZA			VARCHAR(50),
		@EMAILENTE			VARCHAR(100),
		@IDENTE				INT,
		@ENTENOME			VARCHAR(200),
		@OGGETTO			VARCHAR(200),
		@MESSAGGIO			VARCHAR(MAX),
		@MESSAGGIOCC			VARCHAR(4000),
		@ENTESUFFISSO			VARCHAR(10),
		@CONTA				INT,
		@PRIMAVOLTA			INT,
		@IDALERT			INT,
		@CODICESEDE			VARCHAR(15),
		@RUNESEGUITO			INT

	SET @CONTA = 0
	SET @PRIMAVOLTA = 1
	SET @IDALERT = 0 
	SET @RUNESEGUITO = 0 

	-- Verifiche per Tranche Unica
	DECLARE MYCUR_UT CURSOR LOCAL FOR
	select DISTINCT	c.email,
			c.idente,
			c.denominazione,
			c.codiceregione
	from enti c
	INNER JOIN attivit‡ a ON c.IDEnte = a.IDEntePresentante 
	inner join bandiattivit‡ b on a.idbandoattivit‡ = b.idbandoattivit‡ 
	INNER JOIN tipiprogetto z ON a.idtipoprogetto = z.idtipoprogetto
	inner join bando c1 on b.IdBando = c1.IDBando
	inner join attivit‡formazionegenerale d on a.idattivit‡ = d.idattivit‡
	INNER JOIN attivit‡entisediattuazione e ON a.IDAttivit‡ = e.IDAttivit‡ 
	INNER JOIN attivit‡entit‡ f ON e.IDAttivit‡EnteSedeAttuazione = f.IDAttivit‡EnteSedeAttuazione and f.idstatoattivit‡entit‡ in (1,2)
	INNER JOIN entit‡ g ON f.IDEntit‡ = g.IDEntit‡ and g.IDStatoEntit‡ in (3,5,6)
	where a.datainizioattivit‡ is not null
	AND   z.MacroTipoProgetto  <>'GG'
	AND   g.OreFormazione is null
	AND   d.TipoFormazioneGenerale=1 -- UNICA TRANCHE
	and   convert(date, d.dataScadenzaUnicaTranche)=convert(date,GETDATE()+10)
	and   d.DataScadenzaUnicaTranche is not null
	and   c1.Circ2023Formazione=1
	
		
	OPEN MYCUR_UT
	FETCH NEXT FROM MYCUR_UT INTO @EMAILENTE, @IDENTE, @ENTENOME, @ENTESUFFISSO
	WHILE @@Fetch_status = 0
	BEGIN

		SET @CONTA = 0
		SET @PRIMAVOLTA = 1
		SET @IDALERT = 0 
		SET @OGGETTO = 'ENTE ' + @ENTESUFFISSO + ' - AVVISO MANCATO CARICAMENTO A SISTEMA DELLE ORE DI FORMAZIONE'
		SET @MESSAGGIO = '<FONT face="Verdana" size="4">Si segnala che, con riferimento ai progetti indicati in tabella, non risulta il caricamento nel Sistema Unico delle ore di formazione in vista della scadenza indicata in tabella.<br><br>
Si invita a voler procedere tempestivamente.
</FONT><br><br>
		 <FONT face="Verdana" size="4"><br><br>
		
		<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD align="center"><B>Codice Progetto</B></TD><TD align="center"><B>Data Scadenza</B></TD></TR>'

		DECLARE MYCUR2_UT CURSOR LOCAL FOR	
		select DISTINCT	a.idattivit‡,
				a.codiceente as codiceprogetto,
				convert(varchar,dbo.formatodata(d.DataScadenzaUnicaTranche)) as DataScadenza
		from enti c
		INNER JOIN attivit‡ a ON c.IDEnte = a.IDEntePresentante 
		inner join bandiattivit‡ b on a.idbandoattivit‡ = b.idbandoattivit‡ 
		INNER JOIN tipiprogetto z ON a.idtipoprogetto = z.idtipoprogetto
		inner join bando c1 on b.IdBando = c1.IDBando
		inner join attivit‡formazionegenerale d on a.idattivit‡ = d.idattivit‡
		INNER JOIN attivit‡entisediattuazione e ON a.IDAttivit‡ = e.IDAttivit‡ 
		INNER JOIN attivit‡entit‡ f ON e.IDAttivit‡EnteSedeAttuazione = f.IDAttivit‡EnteSedeAttuazione and f.idstatoattivit‡entit‡ in (1,2)
		INNER JOIN entit‡ g ON f.IDEntit‡ = g.IDEntit‡ and g.IDStatoEntit‡ in (3,5,6)
		left join [RichiesteFormazione] r on r.idattivit‡=d.idattivit‡
		left join [IstanzeRichiestaFormazione] irf on irf.idistanzarichiestaformazione=r.idistanzarichiestaformazione
		where a.datainizioattivit‡ is not null
		AND   z.MacroTipoProgetto  <>'GG'
		AND   g.OreFormazione is null
		AND   d.TipoFormazioneGenerale=1 -- UNICA TRANCHE
		and   convert(date, d.dataScadenzaUnicaTranche)=convert(date,GETDATE()+10)
		and   d.DataScadenzaUnicaTranche is not null
		and   c.idente=@IDENTE
		and   c1.Circ2023Formazione=1
		and (irf.stato <>7 or irf.stato is null)----modifica celestino Ticket#2025061155000695

		OPEN MYCUR2_UT
		FETCH NEXT FROM MYCUR2_UT INTO @IDPROGETTO, @PROGETTO, @DATASCADENZA
		WHILE @@Fetch_status = 0
		BEGIN
			SET @RUNESEGUITO = 1

			IF @PRIMAVOLTA = 1
			BEGIN
				
				INSERT INTO LOG_WARNING_FORMAZIONE_SUMMARY (DataInvio, idEnte, CodiceEnte, TipoFormazione)
				VALUES (GETDATE(), @IDENTE, @ENTESUFFISSO, 'UNICA TRANCHE')

				SET @PRIMAVOLTA = 0
				SET @IDALERT = @@IDENTITY
			END 

			SET @MESSAGGIO = @MESSAGGIO + 
				'<TR>
				<TD align="center">' + @PROGETTO + '</TD>
				<TD align="center">' + @DATASCADENZA + '</TD>
				</TR>'	
			SET @CONTA = @CONTA +1
	
			INSERT INTO LOG_WARNING_FORMAZIONE_DETAIL (idAlert, Progetto, DataScadenza)
			VALUES (@IDALERT, @PROGETTO, @DATASCADENZA)

			FETCH NEXT FROM MYCUR2_UT INTO @IDPROGETTO, @PROGETTO, @DATASCADENZA

		END
		SET @MESSAGGIO = @MESSAGGIO + '</TABLE></FONT>'
		CLOSE MYCUR2_UT
		DEALLOCATE MYCUR2_UT

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

		FETCH NEXT FROM MYCUR_UT INTO @EMAILENTE, @IDENTE, @ENTENOME, @ENTESUFFISSO

	END
	CLOSE MYCUR_UT
	DEALLOCATE MYCUR_UT

	IF @RUNESEGUITO = 0 
		BEGIN
			INSERT INTO LOG_WARNING_FORMAZIONE_RUN (DataRun, Esito)
			VALUES (GETDATE(), 'Nessuna occorrenza trovata per il run corrente')
		END
	ELSE
		BEGIN
			INSERT INTO LOG_WARNING_FORMAZIONE_RUN (DataRun, Esito)
			VALUES (GETDATE(), 'Trovata almeno una occorrenza per il run corrente. Consultare tabelle SUMMARY e DETAIL')
		END
GO
