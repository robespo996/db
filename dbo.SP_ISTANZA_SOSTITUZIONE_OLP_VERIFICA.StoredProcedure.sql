USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_ISTANZA_SOSTITUZIONE_OLP_VERIFICA]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_ISTANZA_SOSTITUZIONE_OLP_VERIFICA] 
	@IdIstanzaSostituzioneOLP int,
	@Username varchar(50),
	@Esito bit output,
	@Messaggio varchar(max) output
AS
/*
Realizzata da:	
Creata il:		26/11/2021
Data Ultima Modifica:	--
Funzionalit‡: Verifica il pacchetto modifiche di una Istanza Sostituzione OLP.
	1. CONTROLLO SE OLP SUBENTRANTI IMPEGNATI SU ALTRE SEDI
	2. CONTROLLO SE OLP SUBENTRANTI SONO SOVRAUTILIZZATI
*/ 
BEGIN
	SET @Esito = 1
	SET @Messaggio=''

	BEGIN TRY
	--1. CONTROLLO SE OLP SUBENTRANTI IMPEGNATI SU ALTRE SEDI
		--ESTRAGGO TUTTI GLI OLP ASSOCIATI A PROGETTI IN CORSO, PIANIFICATI O DA PIANIFICARE
		SELECT AESA.IDAttivit‡, AESA.IDAttivit‡EnteSedeAttuazione, AESA.IDEnteSedeAttuazione, EPR.IDEntePersonaleRuolo, EP.IDEntePersonale, EP.CodiceFiscale, A.DataInizioAttivit‡, A.DataFineAttivit‡, ASA.DataInizioDifferita, ASA.DataFineDifferita , A.DataInizioPrevista, A.DataFinePrevista, VW.NVol, IA.MaxVolontariPerOLP
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
			INNER JOIN VW_NVol_Attivit‡SedeAttuazione VW on vW.IdAttivit‡EnteSedeAttuazione=AESA.IDAttivit‡EnteSedeAttuazione
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
		SELECT AESA.IDAttivit‡, AESA.IDAttivit‡EnteSedeAttuazione, AESA.IDEnteSedeAttuazione, EPR.IDEntePersonaleRuolo, EP.IDEntePersonale, EP.CodiceFiscale, A.DataInizioAttivit‡, A.DataFineAttivit‡, ASA.DataInizioDifferita, ASA.DataFineDifferita , A.DataInizioPrevista, A.DataFinePrevista, VW.NVol, IA.MaxVolontariPerOLP
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
				INNER JOIN VW_NVol_Attivit‡SedeAttuazione VW on vW.IdAttivit‡EnteSedeAttuazione=AESA.IDAttivit‡EnteSedeAttuazione				
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
		GROUP BY CodiceFiscale 
		HAVING COUNT(DISTINCT IDEnteSedeAttuazione)>1 

		IF EXISTS(SELECT * FROM #OLP_ANOMALIA_SEDI where CodiceFiscale not in ('PNNLRT73B03C351L','BRGCLD79D63G693U','CCOCML57C20H175A','GMMVCN47R07C351J',
		'FLPFRC72C53H501U','GBLMRC78T12G674U','FRCNNL77H41B936I','MCHMCL70T68H501L','CLGFNC59R18H501Y','DSTVLR92M17B602F',
		'KMRDNL66B64H501I','MRUNMR67R50E387P','MNARME59P30I973N','FRCMGR58M54D662F','VSPSBN73D52A859O','CCCGNN82L14H501C','TRNMCN84P15C351F',
		'PLVRMN69H43L424Z','GRBLRA75E63C351F','PNCDMZ62D59A421Y','PTRMTN93D47B429Y','BRGLSS90T65I577Q',
'MSSCRN68A68I829O','MLGMSM82P27G273S','CSTVCN76M08I073D ','DLLNNL85M42A509V ','DMIMRD92L54A509G','PRRMSS95B43A509L','DSMRLL94A70F839B',
'MSSMHL64S57C351Z','BRNDTL71M47L419I','SRNKTA78E71H501E','DMRSDT92S04A024X','FTOMLD62M56A089R','ZNRTZN69S70A944V',
'GRGCST76A46E058W','RGACHR70C70M126G','SRPMHL70P27G511B','LNGNNL62S46A662U','MGSSLV71M57A048F','DMZLSE80S63E783T','CGNLRD55M08D643H','RZZPLA82H46B157Z','DNDGLI79D45L219D')) -- bypass eccezione per gestire sostituzione corretta (date congrue)
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
		SELECT AESA.IDAttivit‡EnteSedeAttuazione, EPR.IDEntePersonaleRuolo, VW.NVol, IA.MaxVolontariPerOLP, EP.CodiceFiscale
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
				INNER JOIN VW_NVol_Attivit‡SedeAttuazione VW on vW.IdAttivit‡EnteSedeAttuazione=AESA.IDAttivit‡EnteSedeAttuazione				
				WHERE ISO.IdIstanzaSostituzioneOLP = @IdIstanzaSostituzioneOLP

		declare @ID_AESA int
		declare @ID_EPR int
		declare @NVOL_AESA INT
		DECLARE @NOLP_SEDE INT
		DECLARE @VOL_OLP INT
		DECLARE @MAXVOLPEROLP INT
		DECLARE @CODICEFISCALE VARCHAR(100)

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

			IF @MAXVOLPEROLP<@VOL_OLP and @CODICEFISCALE not in ('MSSLTZ69A71D623B','LZZGPP70A43F158E','BRTPLA74D08D442O','BTTVNT89R57A345T','LMRSVT95P30E532Z','RNNSVT75D15D768U','CRTNNN94B13L219X','GNGGBT66P07M088T','CRCBTY64C53H850E','PLMRMR75C52C342J','RSSDRN92D26A509N','BNNDTL66T46B519V','CRDGRL86B15A638A','LBRFBA89M16C351Q','NRRDVD80R30D423J',
			'BUAMRA83B58E974Y', 'CLCFNC81L42F061P','LMNGPP70C52A056J','BTTMLD93L68L219N',
			'CTRGLI95P69H501W','GRCLCU78B66F839L','GBLMRC78T12G674U','SLLGAI75P44H501W ',
			'NCOLSE79H67G999B','PDRLCN79P52F924P','NDOLRA70S58I138G','CVLPLA57T03E974B',
			'PMTGLI89D42H501H', 'CLDLRD88M10A841L','CRLNTN64E30H501O','TRNMCN84P15C351F',
			'PRTGNI77T28A323N','CMNGPP57H29L837P','GRBLRA75E63C351F','DMNPLM66T52E953W','FRSLRZ97H53C351B',
'GRSCCT68T47A027S','MSSCRN68A68I829O','MSSMHL64S57C351Z','LBNDIA83C71G762L',
'TMSMNL81T45C351Q','MRALSN84L48H096Y','DLCMNO80M62E058Q','BNDFRC94A63L219I',
'DLLNRC78H30E058Q','GRGCST76A46E058W','PLLGNE59M63L103P','BLLLSN60M71G311B',
'SNSSLV88M45H769L','PLMFNC76D29H224F','CPRMTN88A64C858Z','GLLLSN67R68B963A',
'LNGDRA86P23C351Q','MRNLSS98H27M289Z','MSTMCL97L67H282C','DMRSDT92S04A024X','GNFMRM63L48H273O',
'PGLMNT85R64L452L','RCTRRA98E65C351Q','SCMSVT47M27A535F','MRRDTL74C53A091P','SRPMHL70P27G511B',
'TRSDLA66S44B202D','TRVNTN97B09C351O','CRCRRT69L14F023U','FRTFNC69M16I982P','LCNCRF62L18I982U','VRDLGU58L10F839Z',
'MLGLSS97D67D037L','DSDNNT61H57E372G','TRNMRA75D45E372K','BSGDTL92M42D086I','RMOGNR46S30D005S','SCFGLN78D58G317H','PLLSRN96M65G813Y','RRGLGU64L06G596L','NRDMCL80D28G793C','CSLPQL82S28H860Q','CRPFRI49H25L461S','CSTVCN76M08I073D','DNGMRA66B60C421S','RVLRCR93P22D458M','CRNGLI90D58H501C','CRCSST78C27A509D','FRSFRZ77H16F839D') -- bypass eccezione per gestire sostituzione corretta (ridistribuendo i volontari)
			BEGIN
				SET @Esito = 0
				SET @Messaggio = @Messaggio + ' OLP Sovrautilizzato: ' + @CodiceFiscale
			END
			
			
			
			DELETE FROM #CURSORE
			FETCH NEXT FROM MYCUR INTO @ID_EPR,@MAXVOLPEROLP,@CODICEFISCALE
		END
		CLOSE MYCUR
		DEALLOCATE MYCUR
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
