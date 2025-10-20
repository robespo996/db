USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_ISTANZA_SOSTITUZIONE_OLP_VERIFICA_PRESIDIO]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_ISTANZA_SOSTITUZIONE_OLP_VERIFICA_PRESIDIO] 
	@IdIstanzaSostituzioneOLP int,
	@Esito bit output,
	@Messaggio varchar(max) output
AS
/*  (DI SERVIZIO PER PRESIDIO!!!)
Realizzata da:	
Creata il:		26/11/2021
Data Ultima Modifica:	--
Funzionalit‡: Verifica il pacchetto modifiche di una Istanza Sostituzione OLP .

	1. CONTROLLO SE OLP SUBENTRANTI IMPEGNATI SU ALTRE SEDI
	2. CONTROLLO SE OLP SUBENTRANTI SONO SOVRAUTILIZZATI
*/ 
BEGIN
	SET @Esito = 1
	SET @Messaggio=''

	BEGIN TRY
	--1. CONTROLLO SE OLP SUBENTRANTI IMPEGNATI SU ALTRE SEDI
		--ESTRAGGO TUTTI GLI OLP ASSOCIATI A PROGETTI IN CORSO, PIANIFICATI O DA PIANIFICARE
		SELECT AESA.IDAttivit‡, AESA.IDAttivit‡EnteSedeAttuazione, AESA.IDEnteSedeAttuazione, EPR.IDEntePersonaleRuolo, EP.IDEntePersonale, EP.CodiceFiscale, A.DataInizioAttivit‡, A.DataFineAttivit‡, ASA.DataInizioDifferita, ASA.DataFineDifferita , A.DataInizioPrevista, A.DataFinePrevista, AESA.NumeroPostiVitto+AESA.NumeroPostiVittoAlloggio+AESA.NumeroPostiNoVittoNoAlloggio AS NVol, IA.MaxVolontariPerOLP
		INTO #TMPOLPATTIVI
		FROM entepersonale EP 
			INNER JOIN entepersonaleruoli EPR ON EP.IDEntePersonale = EPR.IDEntePersonale
			INNER JOIN AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione X ON EPR.IDEntePersonaleRuolo = X.IdEntePersonaleRuolo
			INNER JOIN attivit‡entisediattuazione AESA ON X.IdAttivit‡EnteSedeAttuazione = AESA.IDAttivit‡EnteSedeAttuazione
			INNER JOIN attivit‡ A ON AESA.IDAttivit‡ = A.IDAttivit‡ 
			INNER JOIN entisediattuazioni ESA ON AESA.IDEnteSedeAttuazione = ESA.IDEnteSedeAttuazione
			INNER JOIN entisedi ES ON ESA.IDEnteSede = ES.IDEnteSede
			INNER JOIN Attivit‡SediAssegnazione ASA ON ES.IDEnteSede = ASA.IDEnteSede AND A.IDAttivit‡ = ASA.IDAttivit‡
			INNER JOIN ambitiattivit‡ AA ON A.IDAmbitoAttivit‡ = AA.IDAmbitoAttivit‡
			INNER JOIN macroambitiattivit‡ MA ON AA.IDMacroAmbitoAttivit‡ = MA.IDMacroAmbitoAttivit‡
			INNER JOIN iperambitiattivit‡ IA ON MA.IDIperAmbitoAttivit‡ = IA.IDIperAmbitiAttivit‡
		WHERE EPR.IDRuolo = 1
			AND A.IDStatoAttivit‡ = 1
			--AND GETDATE() BETWEEN COALESCE(ASA.DataInizioDifferita,A.DataInizioAttivit‡,A.DataInizioPrevista) AND COALESCE(ASA.DataFineDifferita,A.DataFineAttivit‡,a.DataFinePrevista)
			--AND GETDATE() < COALESCE(ASA.DataFineDifferita,A.DataFineAttivit‡,a.DataFinePrevista,'31/12/2099')
			AND GETDATE() < COALESCE(ASA.DataFineDifferita,A.DataFineAttivit‡,'01/01/2099')
	
		--RIMUOVO OLP IN CORSO DI SOSTITUZIONE 
		DELETE FROM #TMPOLPATTIVI
		FROM #TMPOLPATTIVI A
		INNER JOIN SostituzioniOLP B ON A.IDAttivit‡EnteSedeAttuazione = B.IdAttivit‡EnteSedeAttuazione AND A.IDEntePersonaleRuolo = B.IdEntePersonaleRuoloSostituito
		INNER JOIN IstanzeSostituzioniOLP C ON B.IdIstanzaSostituzioneOLP = C.IdIstanzaSostituzioneOLP
		WHERE (C.Stato = 2  OR C.IdIstanzaSostituzioneOLP = @IdIstanzaSostituzioneOLP) --ISTANZE PRESENTATE O ISTANZA IN LAVORAZIONE
			AND B.Stato <> 5 --ESCLUDO LE SOSTITUZIONI RESPINTE

		--AGGIUNGO OLP IN CORSO DI SOSTITUZIONE PER L'ISTANZA IN LAVORAZIONE
		INSERT INTO #TMPOLPATTIVI
		SELECT AESA.IDAttivit‡, AESA.IDAttivit‡EnteSedeAttuazione, AESA.IDEnteSedeAttuazione, EPR.IDEntePersonaleRuolo, EP.IDEntePersonale, EP.CodiceFiscale, A.DataInizioAttivit‡, A.DataFineAttivit‡, ASA.DataInizioDifferita, ASA.DataFineDifferita , A.DataInizioPrevista, A.DataFinePrevista, AESA.NumeroPostiVitto+AESA.NumeroPostiVittoAlloggio+AESA.NumeroPostiNoVittoNoAlloggio AS NVol, IA.MaxVolontariPerOLP
		FROM IstanzeSostituzioniOLP ISO
				INNER JOIN SostituzioniOLP SO ON ISO.IdIstanzaSostituzioneOLP = SO.IdIstanzaSostituzioneOLP
				INNER JOIN entepersonaleruoli EPR ON SO.IdEntePersonaleRuoloSubentrante = EPR.IDEntePersonaleRuolo
				INNER JOIN entepersonale EP ON EPR.IDEntePersonale = EP.IDEntePersonale
				INNER JOIN attivit‡entisediattuazione AESA ON SO.IdAttivit‡EnteSedeAttuazione = AESA.IDAttivit‡EnteSedeAttuazione
				INNER JOIN attivit‡ A ON AESA.IDAttivit‡ = A.IDAttivit‡
				INNER JOIN entisediattuazioni ESA ON AESA.IDEnteSedeAttuazione = ESA.IDEnteSedeAttuazione
				INNER JOIN entisedi ES ON ESA.IDEnteSede = ES.IDEnteSede
				INNER JOIN Attivit‡SediAssegnazione ASA ON ES.IDEnteSede = ASA.IDEnteSede AND ASA.IDAttivit‡ = AESA.IDAttivit‡
				INNER JOIN ambitiattivit‡ AA ON A.IDAmbitoAttivit‡ = AA.IDAmbitoAttivit‡
				INNER JOIN macroambitiattivit‡ MA ON AA.IDMacroAmbitoAttivit‡ = MA.IDMacroAmbitoAttivit‡
				INNER JOIN iperambitiattivit‡ IA ON MA.IDIperAmbitoAttivit‡ = IA.IDIperAmbitiAttivit‡
				WHERE ISO.IdIstanzaSostituzioneOLP = @IdIstanzaSostituzioneOLP
		
		SELECT CodiceFiscale, COUNT(DISTINCT IDEnteSedeAttuazione) as NSEDI
		INTO #OLP_ANOMALIA_SEDI
		FROM #TMPOLPATTIVI
		where CodiceFiscale in
			(SELECT  EP.CodiceFiscale -- SONO I CF SUBENTRANTI
			FROM IstanzeSostituzioniOLP A
			INNER JOIN SostituzioniOLP B ON A.IdIstanzaSostituzioneOLP = B.IdIstanzaSostituzioneOLP
			INNER JOIN entepersonaleruoli EPR ON B.IdEntePersonaleRuoloSubentrante = EPR.IDEntePersonaleRuolo
			INNER JOIN entepersonale EP ON EPR.IDEntePersonale = EP.IDEntePersonale
			WHERE A.IdIstanzaSostituzioneOLP = @IdIstanzaSostituzioneOLP 
				AND B.Stato <> 5) --ESCLUDO LE SOSTITUZIONI RESPINTE) 
			and CodiceFiscale not in ('PNNLRT73B03C351L','BRGCLD79D63G693U','CCOCML57C20H175A','GMMVCN47R07C351J','GRGCST76A46E058W','ZNRTZN69S70A944V')
		GROUP BY CodiceFiscale 
		HAVING COUNT(DISTINCT IDEnteSedeAttuazione)>1 

		SELECT 'ANOMALIA SEDI' AS Controllo,* FROM #OLP_ANOMALIA_SEDI where CodiceFiscale not in ('PNNLRT73B03C351L','BRGCLD79D63G693U','CCOCML57C20H175A','GMMVCN47R07C351J','GRGCST76A46E058W')
		select b.CODICEENTE AS CodiceProgetto, b.titolo, a.* from #TMPOLPATTIVI a 
		inner join attivit‡ b on a.IDAttivit‡ = b.IDAttivit‡ 
		where CodiceFiscale in (select CodiceFiscale from #OLP_ANOMALIA_SEDI)
		order by CodiceFiscale
		IF EXISTS(SELECT * FROM #OLP_ANOMALIA_SEDI where CodiceFiscale not in ('PNNLRT73B03C351L','BRGLSS90T65I577Q','DSTVLR92M17B602F',
		'BRGCLD79D63G693U','CCOCML57C20H175A','GMMVCN47R07C351J','GRGCST76A46E058W','GBLMRC78T12G674U','PNCDMZ62D59A421Y','MLGMSM82P27G273S')) -- bypass eccezione per gestire sostituzione corretta (date congrue)
		BEGIN
			SET @Esito = 0
			SELECT  @Messaggio = STUFF((
				 SELECT ' OLP su pi˘ sedi:' + CodiceFiscale
					FROM #OLP_ANOMALIA_SEDI
					FOR XML PATH('')
				 ), 1, 1, '')
		END
	--2. CONTROLLO SE OLP SUBENTRANTI SONO SOVRAUTILIZZATI
		--INDIVIDUO GLI OLP SUBENTRANTI LEGATI ALL'ISTANZA
		SELECT AESA.IDAttivit‡EnteSedeAttuazione, EPR.IDEntePersonaleRuolo, AESA.NumeroPostiVitto+AESA.NumeroPostiVittoAlloggio+AESA.NumeroPostiNoVittoNoAlloggio AS NVol, IA.MaxVolontariPerOLP, EP.CodiceFiscale
		INTO #SUBENTRANTI
		FROM IstanzeSostituzioniOLP ISO
				INNER JOIN SostituzioniOLP SO ON ISO.IdIstanzaSostituzioneOLP = SO.IdIstanzaSostituzioneOLP
				INNER JOIN entepersonaleruoli EPR ON SO.IdEntePersonaleRuoloSubentrante = EPR.IDEntePersonaleRuolo
				INNER JOIN entepersonale EP ON EPR.IDEntePersonale = EP.IDEntePersonale
				INNER JOIN attivit‡entisediattuazione AESA ON SO.IdAttivit‡EnteSedeAttuazione = AESA.IDAttivit‡EnteSedeAttuazione
				INNER JOIN attivit‡ A ON AESA.IDAttivit‡ = A.IDAttivit‡
				INNER JOIN entisediattuazioni ESA ON AESA.IDEnteSedeAttuazione = ESA.IDEnteSedeAttuazione
				INNER JOIN entisedi ES ON ESA.IDEnteSede = ES.IDEnteSede
				INNER JOIN Attivit‡SediAssegnazione ASA ON ES.IDEnteSede = ASA.IDEnteSede AND ASA.IDAttivit‡ = AESA.IDAttivit‡
				INNER JOIN ambitiattivit‡ AA ON A.IDAmbitoAttivit‡ = AA.IDAmbitoAttivit‡
				INNER JOIN macroambitiattivit‡ MA ON AA.IDMacroAmbitoAttivit‡ = MA.IDMacroAmbitoAttivit‡
				INNER JOIN iperambitiattivit‡ IA ON MA.IDIperAmbitoAttivit‡ = IA.IDIperAmbitiAttivit‡
				WHERE ISO.IdIstanzaSostituzioneOLP = @IdIstanzaSostituzioneOLP

		declare @ID_AESA int
		declare @ID_EPR int
		declare @NVOL_AESA INT
		DECLARE @NOLP_SEDE INT
		DECLARE @VOL_OLP INT
		DECLARE @MAXVOLPEROLP INT
		DECLARE @CODICEFISCALE VARCHAR(100)

		CREATE TABLE #APPOCFANOMALI (CODICEFISCALE VARCHAR(1000) NOT NULL)
		CREATE TABLE #CURSORE (NOLP INT NULL, IDAttivit‡EnteSedeAttuazione INT NULL, NVol INT NULL)

		DECLARE MYCUR CURSOR LOCAL FOR
			SELECT IDEntePersonaleRuolo, min(MaxVolontariPerOLP) as MaxVolontariPerOLP, CodiceFiscale  FROM #SUBENTRANTI group by IDEntePersonaleRuolo, CodiceFiscale
		OPEN MYCUR
		FETCH NEXT FROM MYCUR INTO @ID_EPR,@MAXVOLPEROLP,@CODICEFISCALE
		WHILE @@Fetch_status = 0
		BEGIN
			INSERT INTO #CURSORE
			select COUNT(DISTINCT a.IDEntePersonaleRuolo) As NOlp, a.IDAttivit‡EnteSedeAttuazione, NVol  
			from #TMPOLPATTIVI a
			where a.IDAttivit‡EnteSedeAttuazione in (select IDAttivit‡EnteSedeAttuazione from #TMPOLPATTIVI where IDEntePersonaleRuolo = @ID_EPR)
			group by  a.MaxVolontariPerOLP, a.IDAttivit‡EnteSedeAttuazione, NVol

			select @VOL_OLP = sum(NVol/NOlp) from #Cursore

			IF @MAXVOLPEROLP<@VOL_OLP and @CODICEFISCALE not in ('MSSLTZ69A71D623B','LZZGPP70A43F158E','BRTPLA74D08D442O','BTTVNT89R57A345T','LMRSVT95P30E532Z','RNNSVT75D15D768U','CRTNNN94B13L219X','GRBLRA75E63C351F',
'GRSCCT68T47A027S','GBLMRC78T12G674U',
'MSSCRN68A68I829O','CVLPLA57T03E974B',
'MSSMHL64S57C351Z','CRLNTN64E30H501O',
'TMSMNL81T45C351Q','MCCLRA65A55L191Z',
'DLCMNO80M62E058Q','SLLGAI75P44H501W ',
'DLLNRC78H30E058Q','LBNDIA83C71G762L',
'GRGCST76A46E058W','FRSFRZ77H16F839D',
'PLLGNE59M63L103P',
'SNSSLV88M45H769L',
'CPRMTN88A64C858Z',
'LNGDRA86P23C351Q',
'MRNLSS98H27M289Z',
'MSTMCL97L67H282C',
'PGLMNT85R64L452L',
'RCTRRA98E65C351Q',
'SCMSVT47M27A535F',
'TRSDLA66S44B202D',
'TRVNTN97B09C351O','CRCSST78C27A509D') -- bypass eccezione per gestire sostituzione corretta (ridistribuendo i volontari)
			BEGIN
				SET @Esito = 0
				SET @Messaggio = @Messaggio + ' OLP Sovrautilizzato: ' + @CodiceFiscale
				INSERT INTO #APPOCFANOMALI VALUES (@CodiceFiscale)
			END
			
			
			
			DELETE FROM #CURSORE
			FETCH NEXT FROM MYCUR INTO @ID_EPR,@MAXVOLPEROLP,@CODICEFISCALE
		END
		CLOSE MYCUR
		DEALLOCATE MYCUR

		SELECT C.Titolo, a.*, (select COUNT(*) from AssociaEntePersonaleRuoliAttivit‡EntiSediAttuazione where IdAttivit‡EnteSedeAttuazione = a.IDAttivit‡EnteSedeAttuazione) NOlpPresentiSuSede,   C.CodiceEnte AS CodiceProgetto, C.Titolo as TitoloProgetto FROM #TMPOLPATTIVI a 
		inner join #APPOCFANOMALI b on a.CodiceFiscale = b.CODICEFISCALE
		INNER JOIN attivit‡ C ON a.IDAttivit‡ = C.IDAttivit‡ 
		order by b.CODICEFISCALE
	END TRY

	
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN
		END
		SET @Messaggio = 'ERRORE IMPREVISTO IN FASE DI VERIFICA. ' + ERROR_MESSAGE() 
	END CATCH
END
GO
