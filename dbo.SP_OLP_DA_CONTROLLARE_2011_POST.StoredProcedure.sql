USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_OLP_DA_CONTROLLARE_2011_POST]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--select b.identepersonaleruolo 
----into APPO_OLP_DA_CONTROLLARE
--from dbo.AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione a
--inner join entepersonaleruoli b on a.identepersonaleruolo = b.identepersonaleruolo
--inner join dbo.attivit‡entisediattuazione c on a.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
--inner join dbo.attivit‡ d on c.idattivit‡ = d.idattivit‡
--inner join bandiattivit‡ e on d.idbandoattivit‡ = e.idbandoattivit‡
--inner join bando f on e.idbando = f.idbando
--where b.idruolo = 1 and f.gruppo = 17
--group by b.identepersonaleruolo 
--having count(*)>1


ALTER PROCEDURE [dbo].[SP_OLP_DA_CONTROLLARE_2011_POST] 
AS
BEGIN
	declare @IDENTEPERSONALERUOLO as int,
			@IDATTIVITAENTESEDEATTUAZIONE AS INT,
			@NMAXVOL AS INT,
			@NVOLTOT AS INT,
			@NOLPPERSEDE AS INT,
			@NVOLCUMULATO AS DECIMAL(10,2)

	CREATE TABLE #TMP
	(
		IdEntePersonaleRuolo int NOT NULL,
		Anomalo bit NOT NULL
	)  ON [PRIMARY]

	INSERT INTO #TMP 
	SELECT     DISTINCT AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione.IdEntePersonaleRuolo,0
	FROM         attivit‡ INNER JOIN BANDIATTIVIT‡ ON ATTIVIT‡.IDBANDOATTIVIT‡ = BANDIATTIVIT‡.IDBANDOATTIVIT‡ INNER JOIN
						  attivit‡entisediattuazione ON attivit‡.IDAttivit‡ = attivit‡entisediattuazione.IDAttivit‡ INNER JOIN
						  AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione ON 
						  attivit‡entisediattuazione.IDAttivit‡EnteSedeAttuazione = AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione.IdAttivit‡EnteSedeAttuazione INNER JOIN
						  entepersonaleruoli ON AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione.IdEntePersonaleRuolo = entepersonaleruoli.IDEntePersonaleRuolo
	WHERE     (attivit‡.IDStatoAttivit‡ IN (4, 5,9)) AND (entepersonaleruoli.IDRuolo = 1) AND IDBANDO>=220 AND ISNULL(CODICEENTE,'') <>''

	DECLARE MYCUR CURSOR LOCAL FOR
		SELECT IDENTEPERSONALERUOLO FROM #TMP

	OPEN MYCUR
	FETCH NEXT FROM MYCUR INTO @IDENTEPERSONALERUOLO

	WHILE @@Fetch_status = 0
	BEGIN
		SET @NMAXVOL = 0
		SET @NVOLTOT = 0
		SET @NOLPPERSEDE = 0
		SET @NVOLCUMULATO = 0

		IF EXISTS
			(select b.identepersonaleruolo 
			from dbo.AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione a
			inner join entepersonaleruoli b on a.identepersonaleruolo = b.identepersonaleruolo
			inner join dbo.attivit‡entisediattuazione c on a.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
			inner join dbo.attivit‡ d on c.idattivit‡ = d.idattivit‡
--			inner join bandiattivit‡ e on d.idbandoattivit‡ = e.idbandoattivit‡
--			inner join bando f on e.idbando = f.idbando
			inner join ambitiattivit‡ g on d.idambitoattivit‡ = g.idambitoattivit‡
			inner join macroambitiattivit‡ h on g.idmacroambitoattivit‡ = h.idmacroambitoattivit‡
			inner join iperambitiattivit‡ i on h.idiperambitoattivit‡ = i.idiperambitIattivit‡
			where b.idruolo = 1 and d.idstatoattivit‡ in (4,5,9) and a.identepersonaleruolo = @IDENTEPERSONALERUOLO and i.maxvolontariperolp = 4)
--			where b.idruolo = 1 and f.gruppo = 17 and a.identepersonaleruolo = @IDENTEPERSONALERUOLO and i.maxvolontariperolp = 4)
			BEGIN
				--MAX 4
				SET @NMAXVOL = 4
			END
		ELSE
			BEGIN
				--MAX 6
				SET @NMAXVOL = 6
			END

		DECLARE MYCURINTERNO CURSOR LOCAL FOR
		select A.idattivit‡entesedeattuazione
			from dbo.AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione a
			inner join entepersonaleruoli b on a.identepersonaleruolo = b.identepersonaleruolo
			inner join dbo.attivit‡entisediattuazione c on a.idattivit‡entesedeattuazione = c.idattivit‡entesedeattuazione
			inner join dbo.attivit‡ d on c.idattivit‡ = d.idattivit‡
--			inner join bandiattivit‡ e on d.idbandoattivit‡ = e.idbandoattivit‡
--			inner join bando f on e.idbando = f.idbando
			inner join ambitiattivit‡ g on d.idambitoattivit‡ = g.idambitoattivit‡
			inner join macroambitiattivit‡ h on g.idmacroambitoattivit‡ = h.idmacroambitoattivit‡
			inner join iperambitiattivit‡ i on h.idiperambitoattivit‡ = i.idiperambitIattivit‡
			where b.idruolo = 1 and d.idstatoattivit‡ in (4,5,9) and a.identepersonaleruolo = @IDENTEPERSONALERUOLO 
--			where b.idruolo = 1 and f.gruppo = 17 and a.identepersonaleruolo = @IDENTEPERSONALERUOLO
		
		OPEN MYCURINTERNO
		FETCH NEXT FROM MYCURINTERNO INTO @IDATTIVITAENTESEDEATTUAZIONE
		WHILE @@Fetch_status = 0
		BEGIN
			select @NOLPPERSEDE = COUNT(DISTINCT a.identepersonaleruolo)
			from dbo.AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione a
			inner join entepersonaleruoli b on a.identepersonaleruolo = b.identepersonaleruolo
			where b.idruolo = 1 And a.IDATTIVIT‡ENTESEDEATTUAZIONE = @IDATTIVITAENTESEDEATTUAZIONE

			select @NVOLTOT=convert(decimal(10,2),C.numeropostinovittonoalloggio)+convert(decimal(10,2),C.numeropostivitto)+convert(decimal(10,2),C.numeropostivittoalloggio)
			FROM dbo.attivit‡entisediattuazione c 
			where C.IDATTIVIT‡ENTESEDEATTUAZIONE = @IDATTIVITAENTESEDEATTUAZIONE
			
			SET @NVOLCUMULATO = @NVOLCUMULATO + CONVERT(DECIMAL(10,2),@NVOLTOT)/CONVERT(DECIMAL(10,2),@NOLPPERSEDE)
			
			FETCH NEXT FROM MYCURINTERNO INTO @IDATTIVITAENTESEDEATTUAZIONE
		END
		CLOSE MYCURINTERNO
		DEALLOCATE MYCURINTERNO

		IF @NVOLCUMULATO>@NMAXVOL
		BEGIN
			UPDATE #TMP SET ANOMALO = 1 WHERE IDENTEPERSONALERUOLO=@IDENTEPERSONALERUOLO
		END

		FETCH NEXT FROM MYCUR INTO @IDENTEPERSONALERUOLO
	END
	close MYCUR
	DEALLOCATE MYCUR

	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_Appo_Olp_TMP]') AND type in (N'U'))
	DROP TABLE [dbo].[_Appo_Olp_TMP]

	
	SELECT     A.IDEntePresentante, A.IDAttivit‡, A.Titolo, entepersonale.Cognome, entepersonale.Nome, A.DATACREAZIONERECORD, attivit‡entisediattuazione.identesedeattuazione, attivit‡entisediattuazione.numeropostinovittonoalloggio +attivit‡entisediattuazione.numeropostivittoalloggio+attivit‡entisediattuazione.numeropostivitto as PostiSede, maa.macroambitoattivit‡ as Settore, A.IDREGIONECOMPETENZA
	into _Appo_Olp_TMP
	FROM         attivit‡ AS A INNER JOIN
						  attivit‡entisediattuazione ON A.IDAttivit‡ = attivit‡entisediattuazione.IDAttivit‡ INNER JOIN
						  AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione ON 
						  attivit‡entisediattuazione.IDAttivit‡EnteSedeAttuazione = AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione.IdAttivit‡EnteSedeAttuazione INNER JOIN
						  entepersonaleruoli ON AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione.IdEntePersonaleRuolo = entepersonaleruoli.IDEntePersonaleRuolo INNER JOIN
						  entepersonale ON entepersonaleruoli.IDEntePersonale = entepersonale.IDEntePersonale INNER JOIN
						  ambitiattivit‡ aa on A.Idambitoattivit‡ = aa.idambitoattivit‡ INNER JOIN
						  macroambitiattivit‡ maa on aa.idmacroambitoattivit‡ = maa.idmacroambitoattivit‡
	WHERE     (A.IDStatoAttivit‡ IN (4, 5)) AND entepersonaleruoli.IDENTEPERSONALERUOLO IN (SELECT IDENTEPERSONALERUOLO FROM #TMP WHERE ANOMALO = 1)	
	ORDER BY A.IDEntePresentante,entepersonale.Cognome, entepersonale.Nome
	DECLARE @tableHTML  NVARCHAR(MAX);

	SET @tableHTML =
		N'<H1>Potenziali Anomalie OLP</H1>' +
		N'<table border="1">' +
		N'<tr><th>IdEntePresentante</th><th>IdAttivit‡</th>' +
		N'<th>Titolo</th><th>Cognome</th><th>Nome</th>' +
		N'<th>IdEnteSedeAttuazione</th><th>PostiSede</th>' +
		N'<th>Settore</th>' +
		N'<th>IdRegioneCompetenza</th>' +
		N'<th>DataCreazioneRecord</th></tr>' +
		CAST ( ( SELECT td = identepresentante,       '',
						td = IdAttivit‡, '',
						td = Titolo, '',
						td = Cognome, '',
						td = Nome, '',
						td = IdEnteSedeAttuazione, '',
						td = PostiSede, '',
						td = Settore, '',
						td = IdRegioneCompetenza, '',
						td = dbo.formatodata(DataCreazioneRecord)
				  FROM _Appo_Olp_TMP
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;

	if exists(select * from _Appo_Olp_TMP )
		EXEC  dbo.SSIS_sp_send_dbmail
			@profile_name = 'UNSC',
			@recipients = 'd.spagnulo@serap.it;r.macioce@serap.it',
			@subject			= 'POTENZIALI ANOMALIE OLP',
			@body = @tableHTML,
			@body_format = 'HTML'

END


 
GO
