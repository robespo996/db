USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_SIGMA_GENERAZIONE]    Script Date: 14/10/2025 12:36:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_SIGMA_GENERAZIONE] 
	(@CODICELOCALEMANDATO VARCHAR(50), 
	 @USERNAMERICHIESTA VARCHAR(50), 
	 @ESITO VARCHAR(255) OUTPUT)
AS
	DECLARE @Dataora datetime,
			@IdGenerazione int,
			@EsitoAP00 varchar(255),
			@EsitoAP02 varchar(255),
			@EsitoAP03 varchar(255),
			@EsitoAP06 varchar(255),
			@EsitoFN00 varchar(255),
			@EsitoFN02 varchar(255),
			@EsitoFN06 varchar(255),
			@EsitoFN08 varchar(255),
			@EsitoFO00 varchar(255),			
			@EsitoPR00 varchar(255),
			@EsitoPR01 varchar(255),
			@EsitoSC00 varchar(255),
			@EsitoSC01 varchar(255),
			@EsitoSD01 varchar(255),
			@EsitoSD02 varchar(255),
			@EsitoSD03 varchar(255),			
			@EsitoSD04 varchar(255),
			@EsitoSD06 varchar(255)

	declare @sql varchar(8000),
			@comandobcp varchar(8000),
			@nomefile varchar(255),
			@flagformazione varchar(2),
			@pathSharedFolder varchar(512),
			@pathSharedCSVFolder varchar(512),
			@DBNAME varchar(30)
					
	set @Dataora = getdate()
	set @flagformazione = 'NO'
	set @DBNAME=db_name()
	
BEGIN TRY

    select @pathSharedFolder=valore from Configurazioni where parametro='PATH_GENERAZIONE_FILE_SIGMA' --\\Appl\modhelios$\SIGMA_FILES
	set @pathSharedCSVFolder=@pathSharedFolder+'CSV\'

	print @pathSharedFolder
	print @DBNAME

	SET @ESITO = ''

	IF EXISTS (SELECT * FROM sigma_generazione_file with(nolock) WHERE CODICELOCALEMANDATO = @CODICELOCALEMANDATO AND ISNULL(CARICATO,1) = 1)
	BEGIN
		SET @esito = 'IMPOSSIBILE ESEGUIRE L''ELABORAZIONE. PER IL MANDATO ESISTE GIA'' UNA GENERAZIONE CARICATA O IN ATTESA DI CARICAMENTO. ' 
		RETURN
	END	

	INSERT INTO sigma_generazione_file 
	VALUES (@CODICELOCALEMANDATO,@Dataora,@USERNAMERICHIESTA,null,null,null,null)
	set @IdGenerazione = SCOPE_IDENTITY()

	print 'ID GENERAZIONE: ' + convert(varchar,@IdGenerazione)

	BEGIN TRAN 

	PRINT 'SIGMA_SNAPSHOT_VW_MANDATI'
	insert into SIGMA_SNAPSHOT_VW_MANDATI 
			(IdGenerazione
			,codiceMandato
			,codiceLocaleMandato 
			,descrizioneOperazione
			,capitoloSpesa
			,Esercizio
			,numeroMandato
			,Data_ElencoMandato
			,Data_Mandato
			,TEXT_CAUSALE_PAGAMENTO
			,ImportoLordo)
	select	distinct @IdGenerazione
			,codiceMandato
			,codiceLocaleMandato 
			,descrizioneOperazione
			,capitoloSpesa
			,Esercizio
			,numeroMandato
			,Data_ElencoMandato
			,Data_Mandato
			,TEXT_CAUSALE_PAGAMENTO
			,ImportoLordo
	from [SQLDATI].gestionebanca.dbo.VW_MANDATI with(nolock)
	union
	select	distinct @IdGenerazione
			,codiceMandato
			,codiceLocaleMandato 
			,descrizioneOperazione
			,capitoloSpesa
			,Esercizio
			,numeroMandato
			,Data_ElencoMandato
			,Data_Mandato
			,TEXT_CAUSALE_PAGAMENTO
			,ImportoLordo
	from [SQLDATI].gestionebanca.dbo.VW_MANDATI_FORMAZIONE_GG with(nolock)
	
	
	PRINT 'SIGMA_SNAPSHOT_VW_MANDATI_VOLONTARIPAGATI'
	insert into SIGMA_SNAPSHOT_VW_MANDATI_VOLONTARIPAGATI 
			(IdGenerazione
			,codiceMandato
			,codiceLocaleMandato
			,IdDisposizione
			,IdRiga
			,idVolontario
			,ANNO
			,MESE)
	select @IdGenerazione
			,codiceMandato
			,codiceLocaleMandato
			,IdDisposizione
			,IdRiga
			,idVolontario
			,ANNO
			,MESE
	from [SQLDATI].gestionebanca.dbo.VW_MANDATI_VOLONTARIPAGATI with(nolock)
	
	PRINT 'SIGMA_SNAPSHOT_VW_REND_MANDATI_VOLONTARIPAGATI'
	insert into SIGMA_SNAPSHOT_VW_REND_MANDATI_VOLONTARIPAGATI 
			(IdGenerazione
			,codiceMandato
			,codiceLocaleMandato
			,IdDisposizione
			,IdRiga
			,idVolontario
			,ANNO
			,MESE)
	select @IdGenerazione
			,codiceMandato
			,codiceLocaleMandato
			,IdDisposizione
			,IdRiga
			,idVolontario
			,ANNO
			,MESE
	from [SQLDATI].gestionebanca.dbo.VW_REND_MANDATI_VOLONTARIPAGATI with(nolock)
	
	PRINT 'SIGMA_SNAPSHOT_VW_GG_PAGAMENTI_RIMBORSI'
	insert into SIGMA_SNAPSHOT_VW_GG_PAGAMENTI_RIMBORSI 
			(IdGenerazione
			,IdDisposizione
			,IdRiga
			,codicedebitore
			,importo
			,importoRimborso)
	select	@IdGenerazione
			,IdDisposizione
			,IdRiga
			,codicedebitore
			,importo
			,importoRimborso
	from [SQLDATI].gestionebanca.dbo.VW_GG_PAGAMENTI_RIMBORSI with(nolock)
	
	--modifica per mandati formazione generale
	PRINT 'SIGMA_SNAPSHOT_VW_PAGAMENTI_FORMAZIONE_GG_Progetti'
	insert into SIGMA_SNAPSHOT_VW_PAGAMENTI_FORMAZIONE_GG_Progetti
			(IdGenerazione
			  ,codiceMandato
			  ,codiceLocaleMandato
			  ,Importo
			  ,DataValuta
			  ,codiceprogetto)
	select	@IdGenerazione
			,idmandato
			,codiceLocaleMandato
			,Importo
			,DataValuta
			,codiceprogetto
	from [SQLDATI].gestionebanca.dbo.VW_PAGAMENTI_FORMAZIONE_GG_Progetti with(nolock)


	--VERIFICO SE MANDATO RELATIVO A FORMAZIONE GENERALE
	IF EXISTS(SELECT DISTINCT codiceLocaleMandato 
				FROM SIGMA_SNAPSHOT_VW_PAGAMENTI_FORMAZIONE_GG_Progetti with(nolock)
				WHERE IdGenerazione = @IdGenerazione AND CODICELOCALEMANDATO = @CODICELOCALEMANDATO)
		BEGIN --CASO MANDATO FORMAZIONE	
			SET @flagformazione = 'SI'
		END		

	--INIZIO PRODUZIONE TABELLE
	IF @flagformazione = 'NO'
	BEGIN

		PRINT 'AP00'
		EXEC	[dbo].[SP_SIGMA_TABELLA_AP00] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoAP00 OUTPUT
		
		SET @ESITO = @ESITO + @EsitoAP00
	END

	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'AP02'
		EXEC	[dbo].[SP_SIGMA_TABELLA_AP02] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoAP02 OUTPUT
		
		SET @ESITO = @ESITO + @EsitoAP02
	END
	
	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'AP03'
		EXEC	[dbo].[SP_SIGMA_TABELLA_AP03] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoAP03 OUTPUT

		SET @ESITO = @ESITO + @EsitoAP03
	END

	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'AP06'				
		EXEC	[dbo].[SP_SIGMA_TABELLA_AP06] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoAP06 OUTPUT
		
		SET @ESITO = @ESITO +@EsitoAP06
	END

	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'FN00'
		EXEC	[dbo].[SP_SIGMA_TABELLA_FN00] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoFN00 OUTPUT
		
		SET @ESITO = @ESITO +@EsitoFN00
	END

	PRINT 'FN02' --SEMPRE, ANCHE PER MANDATO FORMAZIONE
	EXEC	[dbo].[SP_SIGMA_TABELLA_FN02] 
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoFN02 OUTPUT

	SET @ESITO = @ESITO +@EsitoFN02
	
	PRINT 'FN06' --SEMPRE, ANCHE PER MANDATO FORMAZIONE		
	EXEC	[dbo].[SP_SIGMA_TABELLA_FN06] 
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoFN06 OUTPUT

	SET @ESITO = @ESITO +@EsitoFN06

	
	PRINT 'FN08' --SEMPRE, ANCHE PER MANDATO FORMAZIONE
	EXEC	[dbo].[SP_SIGMA_TABELLA_FN08] 
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoFN08 OUTPUT

	SET @ESITO = @ESITO +@EsitoFN08

	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'FO00'
		EXEC	[dbo].[SP_SIGMA_TABELLA_FO00] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoFO00 OUTPUT
			
		SET @ESITO = @ESITO +@EsitoFO00
	END
	
	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'PR00'
		EXEC	[dbo].[SP_SIGMA_TABELLA_PR00] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoPR00 OUTPUT		
		
		SET @ESITO = @ESITO +@EsitoPR00
	END

	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'PR01'
		EXEC	[dbo].[SP_SIGMA_TABELLA_PR01] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoPR01 OUTPUT			
		
		SET @ESITO = @ESITO +@EsitoPR01
	END
	
	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'SC00'
		EXEC	[dbo].[SP_SIGMA_TABELLA_SC00] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoSC00 OUTPUT		
			
		SET @ESITO = @ESITO +@EsitoSC00
	END
	
	IF @flagformazione = 'NO'
	BEGIN	
		PRINT 'SC01'
		EXEC	[dbo].[SP_SIGMA_TABELLA_SC01] 
			@IdGenerazione
			,@CODICELOCALEMANDATO 
			,@EsitoSC01 OUTPUT	
		
		SET @ESITO = @ESITO +@EsitoSC01
	END
	
	PRINT 'SD01' --SEMPRE, ANCHE PER MANDATO FORMAZIONE	
	EXEC	[dbo].[SP_SIGMA_TABELLA_SD01] 
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoSD01 OUTPUT	
	
	SET @ESITO = @ESITO +@EsitoSD01
	
	PRINT 'SD02' --SEMPRE, ANCHE PER MANDATO FORMAZIONE
	EXEC	[dbo].[SP_SIGMA_TABELLA_SD02]
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoSD02 OUTPUT	

	SET @ESITO = @ESITO +@EsitoSD02

	PRINT 'SD03' --SEMPRE, ANCHE PER MANDATO FORMAZIONE
	EXEC	[dbo].[SP_SIGMA_TABELLA_SD03] 
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoSD03 OUTPUT	

	SET @ESITO = @ESITO +@EsitoSD03
		
	PRINT 'SD04' --SEMPRE, ANCHE PER MANDATO FORMAZIONE
	EXEC	[dbo].[SP_SIGMA_TABELLA_SD04] 
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoSD04 OUTPUT	
		
	SET @ESITO = @ESITO +@EsitoSD04
	
	PRINT 'SD06' --SEMPRE, ANCHE PER MANDATO FORMAZIONE
	EXEC	[dbo].[SP_SIGMA_TABELLA_SD06]
		@IdGenerazione
		,@CODICELOCALEMANDATO 
		,@EsitoSD06 OUTPUT	
	
	SET @ESITO = @ESITO +	@EsitoSD06				


	IF ISNULL(@ESITO,'') = ''
		BEGIN
			
			UPDATE sigma_generazione_file SET Esito = 'POSITIVO'
			WHERE IdGenerazione = @IdGenerazione
			
			COMMIT

			--AP00
			IF @flagformazione = 'NO'
			BEGIN			
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP00.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([TITOLO_PROGETTO],''''),nullif([SINTESI_PRG],''''),nullif([COD_MISURA],''''),nullif([TIPO_OPERAZIONE],''''),nullif([CUP],''''),nullif([TIPO_AIUTO],''''),nullif([DATA INIZIO],''''),nullif([DATA FINE PREVISTA],''''),nullif([DATA FINE EFFETTIVA],''''),nullif([COD_PROC_ATT_LOCALE],'''') ,nullif([NOTE_PROGETTO],''''),nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername

				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''AP00 Anagrafica Progetti''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 	
								
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP00.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''TITOLO_PROGETTO'' as TITOLO_PROGETTO,''SINTESI_PRG'' as SINTESI_PRG,''COD_MISURA'' as COD_MISURA,''TIPO_OPERAZIONE'' as TIPO_OPERAZIONE,''CUP'' as CUP,''TIPO_AIUTO'' as TIPO_AIUTO,''DATA INIZIO'' as INIZIO,''DATA FINE PREVISTA'' as [DATA FINE PREVISTA],''DATA FINE EFFETTIVA'' as [DATA FINE EFFETTIVA],''COD_PROC_ATT_LOCALE'' as COD_PROC_ATT_LOCALE,''NOTE_PROGETTO'' as NOTE_PROGETTO,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE, 0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([TITOLO_PROGETTO],''''),nullif([SINTESI_PRG],''''),nullif([COD_MISURA],''''),nullif([TIPO_OPERAZIONE],''''),nullif([CUP],''''),nullif([TIPO_AIUTO],''''),nullif([DATA INIZIO],''''),nullif([DATA FINE PREVISTA],''''),nullif([DATA FINE EFFETTIVA],''''),nullif([COD_PROC_ATT_LOCALE],'''') ,nullif([NOTE_PROGETTO],''''),nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''AP00 Anagrafica Progetti'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
				
			--AP02
			IF @flagformazione = 'NO'
			BEGIN			
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP02.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([GENERATORE_ENTRATE],''''),nullif([LIV_ISTRUZIONE_STR_FIN],''''),nullif([FONDO_DI_FONDI],''''),nullif([TIPO_LOCALIZZAZIONE],''''),nullif([COD_VULNERABILI],''''),nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP02 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''AP02 Informazioni Generali''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
									
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP02.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''GENERATORE_ENTRATE'' as GENERATORE_ENTRATE,''LIV_ISTRUZIONE_STR_FIN'' as LIV_ISTRUZIONE_STR_FIN,''FONDO_DI_FONDI'' as FONDO_DI_FONDI,''TIPO_LOCALIZZAZIONE'' as TIPO_LOCALIZZAZIONE,''COD_VULNERABILI'' as COD_VULNERABILI,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE, 0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([GENERATORE_ENTRATE],''''),nullif([LIV_ISTRUZIONE_STR_FIN],''''),nullif([FONDO_DI_FONDI],''''),nullif([TIPO_LOCALIZZAZIONE],''''),nullif([COD_VULNERABILI],''''),nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP02 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp
				
					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''AP02 Informazioni Generali'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END	
											
			--AP03
			IF @flagformazione = 'NO'
			BEGIN			
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP03.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([TIPO_CLASS],'''') ,nullif([COD_CLASSIFICAZIONE],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP03 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''AP03 Classificazioni''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP03.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''TIPO_CLASS'' as TIPO_CLASS,''COD_CLASSIFICAZIONE'' as COD_CLASSIFICAZIONE,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE, 0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([TIPO_CLASS],'''') ,nullif([COD_CLASSIFICAZIONE],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP03 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''AP03 Classificazioni'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
											
			--AP06
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP06.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_REGIONE],''''),nullif([COD_PROVINCIA],''''),nullif([COD_COMUNE],''''),nullif([INDIRIZZO],''''),nullif([COD_CAP],''''),nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP06 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp		

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''AP06 Localizzazione Geografica''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_AP06.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_REGIONE'' as COD_REGIONE,''COD_PROVINCIA'' as COD_PROVINCIA,''COD_COMUNE'' as COD_COMUNE,''INDIRIZZO'' as INDIRIZZO,''COD_CAP'' as COD_CAP,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_REGIONE],''''),nullif([COD_PROVINCIA],''''),nullif([COD_COMUNE],''''),nullif([INDIRIZZO],''''),nullif([COD_CAP],''''),nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_AP06 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''AP06 Localizzazione Geografica'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
								
			--FN00
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN00.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_MISURA],''''),nullif([DATA_IMPEGNO],''''),nullif([COD_IMPEGNO],''''),nullif([TIPOLOGIA_IMPEGNO],''''),nullif([COD_FONDO],''''),nullif([COD_NORMA],''''),nullif([COD_DEL_CIPE],''''),nullif([COD_LOCALIZZAZIONE],''''),nullif([CF_COFINANZ],''''),nullif([IMPORTO],''''),nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO,COD_FONDO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp		

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''FN00 Finanziamento''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN00.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_MISURA'' as COD_MISURA,''DATA_IMPEGNO'' as DATA_IMPEGNO,''COD_IMPEGNO'' as COD_IMPEGNO,''TIPOLOGIA_IMPEGNO'' as TIPOLOGIA_IMPEGNO,''COD_FONDO'' as COD_FONDO,''COD_NORMA'' as COD_NORMA,''COD_DEL_CIPE'' as COD_DEL_CIPE,''COD_LOCALIZZAZIONE'' as COD_LOCALIZZAZIONE,''CF_COFINANZ'' as CF_COFINANZ,''IMPORTO'' as IMPORTO,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_MISURA],''''),nullif([DATA_IMPEGNO],''''),nullif([COD_IMPEGNO],''''),nullif([TIPOLOGIA_IMPEGNO],''''),nullif([COD_FONDO],''''),nullif([COD_NORMA],''''),nullif([COD_DEL_CIPE],''''),nullif([COD_LOCALIZZAZIONE],''''),nullif([CF_COFINANZ],''''),nullif([IMPORTO],''''),nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO,COD_FONDO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	
				
					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''FN00 Finanziamento'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 				
			END
				
			--FN02 
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN02.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([VOCE_SPESA],'''') ,nullif([IMPORTO],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN02 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO, IMPORTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''FN02 Quadro Economico''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN02.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''VOCE_SPESA'' as VOCE_SPESA,''IMPORTO'' as IMPORTO,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([VOCE_SPESA],'''') ,nullif([IMPORTO],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN02 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO, IMPORTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''FN02 Quadro Economico'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
									
			--FN06
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN06.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_PAGAMENTO],'''') ,nullif([TIPOLOGIA_PAG],'''') ,nullif([DATA_PAGAMENTO],'''') ,nullif([COD_LOCALE_DDR],'''') ,nullif([DATA_COMPETENZA_DAL],'''') ,nullif([DATA_COMPETENZA_AL],'''') ,nullif([IMPORTO_PAG],'''') ,nullif([CAUSALE_PAGAMENTO],'''') ,nullif([NOTE_PAG],''''),nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN06 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO,COD_PAGAMENTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''FN06 Pagamenti (Gruppi spesa)''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN06.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_PAGAMENTO'' as COD_PAGAMENTO,''TIPOLOGIA_PAG'' as TIPOLOGIA_PAG,''DATA_PAGAMENTO'' as DATA_PAGAMENTO,''COD_LOCALE_DDR'' as COD_LOCALE_DDR,''DATA_COMPETENZA_DAL'' as DATA_COMPETENZA_DAL,''DATA_COMPETENZA_AL'' as DATA_COMPETENZA_AL,''IMPORTO_PAG'' as IMPORTO_PAG,''CAUSALE_PAGAMENTO'' as CAUSALE_PAGAMENTO,''NOTE_PAG'' as NOTE_PAG,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_PAGAMENTO],'''') ,nullif([TIPOLOGIA_PAG],'''') ,nullif([DATA_PAGAMENTO],'''') ,nullif([COD_LOCALE_DDR],'''') ,nullif([DATA_COMPETENZA_DAL],'''') ,nullif([DATA_COMPETENZA_AL],'''') ,nullif([IMPORTO_PAG],'''') ,nullif([CAUSALE_PAGAMENTO],'''') ,nullif([NOTE_PAG],''''),nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN06 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO,COD_PAGAMENTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''FN06 Pagamenti (Gruppi spesa)'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
									
			--FN08
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN08.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_PAGAMENTO],''''),nullif([TIPOLOGIA_PAG],'''') ,nullif([DATA_PAGAMENTO],'''') ,nullif([CODICE_FISCALE],'''') ,nullif([FLAG_SOGGETTO_PUBBLICO],'''') ,nullif([TIPO_PERCETTORE],'''') ,nullif([IMPORTO],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN08 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO,COD_PAGAMENTO,DATA_PAGAMENTO,CODICE_FISCALE'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''FN08 Percettori''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FN08.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_PAGAMENTO'' as COD_PAGAMENTO,''TIPOLOGIA_PAG'' as TIPOLOGIA_PAG,''DATA_PAGAMENTO'' as DATA_PAGAMENTO,''CODICE_FISCALE'' as CODICE_FISCALE,''FLAG_SOGGETTO_PUBBLICO'' as FLAG_SOGGETTO_PUBBLICO,''TIPO_PERCETTORE'' as TIPO_PERCETTORE,''IMPORTO'' as IMPORTO,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_PAGAMENTO],''''),nullif([TIPOLOGIA_PAG],'''') ,nullif([DATA_PAGAMENTO],'''') ,nullif([CODICE_FISCALE],'''') ,nullif([FLAG_SOGGETTO_PUBBLICO],'''') ,nullif([TIPO_PERCETTORE],'''') ,nullif([IMPORTO],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FN08 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO,COD_PAGAMENTO,DATA_PAGAMENTO,CODICE_FISCALE'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''FN08 Percettori'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
								
			--FO00
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FO00.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_CORSO],'''') ,nullif([INDICE_ANNUALITA],'''') ,nullif([NUMERO_ANNUALITA],'''') ,nullif([TITOLO_CORSO],'''') ,nullif([COD_MODALITA_FORMATIVA],'''') ,nullif([COD_CONTENUTO_FORMATIVO],'''') ,nullif([DATA_AVVIO],'''') ,nullif([DATA_CONCLUSIONE],'''') ,nullif([COD_CRITERI_SELEZIONE],'''') ,nullif([ESAME_FINALE],'''') ,nullif([COD_ATTESTAZIONE_FINALE],'''') ,nullif([COD_QUALIFICA],'''') ,nullif([STAGE_TIROCINI] ,''''),nullif([DURATA_AULA],'''') ,nullif([DURATA_WE],'''') ,nullif([DURATA_LABORATORIO],'''') ,nullif([DOCENTI_TUTOR],'''') ,nullif([FLAG_VOUCHER],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FO00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''FO00 Formazione''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_FO00.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_CORSO'' as COD_CORSO,''INDICE_ANNUALITA'' as INDICE_ANNUALITA,''NUMERO_ANNUALITA'' as NUMERO_ANNUALITA,''TITOLO_CORSO'' as TITOLO_CORSO,''COD_MODALITA_FORMATIVA'' as COD_MODALITA_FORMATIVA,''COD_CONTENUTO_FORMATIVO'' as COD_CONTENUTO_FORMATIVO,''DATA_AVVIO'' as DATA_AVVIO,''DATA_CONCLUSIONE'' as DATA_CONCLUSIONE,''COD_CRITERI_SELEZIONE'' as COD_CRITERI_SELEZIONE,''ESAME_FINALE'' as ESAME_FINALE,''COD_ATTESTAZIONE_FINALE'' as COD_ATTESTAZIONE_FINALE,''COD_QUALIFICA'' as COD_QUALIFICA,''STAGE_TIROCINI'' as STAGE_TIROCINI,''DURATA_AULA'' as DURATA_AULA,''DURATA_WE'' as DURATA_WE,''DURATA_LABORATORIO'' as DURATA_LABORATORIO,''DOCENTI_TUTOR'' as DOCENTI_TUTOR,''FLAG_VOUCHER'' as FLAG_VOUCHER,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE, 0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([COD_CORSO],'''') ,nullif([INDICE_ANNUALITA],'''') ,nullif([NUMERO_ANNUALITA],'''') ,nullif([TITOLO_CORSO],'''') ,nullif([COD_MODALITA_FORMATIVA],'''') ,nullif([COD_CONTENUTO_FORMATIVO],'''') ,nullif([DATA_AVVIO],'''') ,nullif([DATA_CONCLUSIONE],'''') ,nullif([COD_CRITERI_SELEZIONE],'''') ,nullif([ESAME_FINALE],'''') ,nullif([COD_ATTESTAZIONE_FINALE],'''') ,nullif([COD_QUALIFICA],'''') ,nullif([STAGE_TIROCINI] ,''''),nullif([DURATA_AULA],'''') ,nullif([DURATA_WE],'''') ,nullif([DURATA_LABORATORIO],'''') ,nullif([DOCENTI_TUTOR],'''') ,nullif([FLAG_VOUCHER],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_FO00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder+ @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''FO00 Formazione'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
												
			--PR00
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_PR00.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_FASE],'''') ,nullif([DATA_INIZIO_PREVISTA],'''') ,nullif([DATA_INIZIO_EFFETTIVA] ,''''),nullif([DATA_FINE_PREVISTA],'''') ,nullif([DATA_FINE_EFFETTIVA],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_PR00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''PR00 Iter di Progetto''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_PR00.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_FASE'' as COD_FASE,''DATA_INIZIO_PREVISTA'' as DATA_INIZIO_PREVISTA,''DATA_INIZIO_EFFETTIVA'' as DATA_INIZIO_EFFETTIVA,''DATA_FINE_PREVISTA'' as DATA_FINE_PREVISTA,''DATA_FINE_EFFETTIVA'' as DATA_FINE_EFFETTIVA,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_FASE],'''') ,nullif([DATA_INIZIO_PREVISTA],'''') ,nullif([DATA_INIZIO_EFFETTIVA] ,''''),nullif([DATA_FINE_PREVISTA],'''') ,nullif([DATA_FINE_EFFETTIVA],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_PR00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''PR00 Iter di Progetto'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
								
			--PR01
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_PR01.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([STATO_PROGETTO],'''') ,nullif([DATA_RIFERIMENTO],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_PR01 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''PR01 Stato Attuazione Progetto''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_PR01.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''STATO_PROGETTO'' as STATO_PROGETTO,''DATA_RIFERIMENTO'' as DATA_RIFERIMENTO,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],'''') ,nullif([STATO_PROGETTO],'''') ,nullif([DATA_RIFERIMENTO],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_PR01 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder+ @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp
				
					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''PR01 Stato Attuazione Progetto'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
											
			--SC00
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SC00.txt'	
				set @sql = 'SELECT nullif([COD_ENTE_EROGATORE],'''') ,nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_RUOLO_SOG],'''') ,nullif([CODICE_FISCALE] ,''''),nullif([FLAG_SOGGETTO_PUBBLICO] ,'''') ,nullif([COD_UNI_IPA],'''') ,nullif([DENOMINAZIONE_SOG],'''') ,nullif([FORMA_GIURIDICA],'''') ,nullif([SETT_ATT_ECONOMICA],'''') ,nullif([NOTE],'''') ,nullif([FLG_CANCELLAZIONE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SC00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_ENTE_EROGATORE, COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SC00 Soggetti Collegati''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
									
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SC00.csv'	
				--intestazioni
				set @sql = 'select	''COD_ENTE_EROGATORE'' as COD_ENTE_EROGATORE,''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_RUOLO_SOG'' as COD_RUOLO_SOG,''CODICE_FISCALE'' as CODICE_FISCALE,''FLAG_SOGGETTO_PUBBLICO'' as FLAG_SOGGETTO_PUBBLICO,''COD_UNI_IPA'' as COD_UNI_IPA,''DENOMINAZIONE_SOG'' as DENOMINAZIONE_SOG,''FORMA_GIURIDICA'' as FORMA_GIURIDICA,''SETT_ATT_ECONOMICA'' as SETT_ATT_ECONOMICA,''NOTE'' as NOTE,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE, 0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_ENTE_EROGATORE],'''') ,nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_RUOLO_SOG],'''') ,nullif([CODICE_FISCALE] ,''''),nullif([FLAG_SOGGETTO_PUBBLICO] ,'''') ,nullif([COD_UNI_IPA],'''') ,nullif([DENOMINAZIONE_SOG],'''') ,nullif([FORMA_GIURIDICA],'''') ,nullif([SETT_ATT_ECONOMICA],'''') ,nullif([NOTE],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SC00 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_ENTE_EROGATORE, COD_LOCALE_PROGETTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder+ @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SC00 Soggetti Collegati'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
											
			--SC01
			IF @flagformazione = 'NO'
			BEGIN
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SC01.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([CODICE_CORSO],'''') ,nullif([CODICE_FISCALE] ,''''),nullif([SESSO],'''') ,nullif([DATA_NASCITA],'''') ,nullif([COD_ISTAT_RES] ,''''),nullif([COD_ISTAT_DOM],'''') ,nullif([CITTADINANZA],'''') ,nullif([TITOLO_STUDIO],'''') ,nullif([COND_MERCATO_INGRESSO],'''') ,nullif([DURATA_RICERCA],'''') ,nullif([CODICE_VULNERABILE_PA] ,''''),nullif([STATO_PARTECIPANTE],'''') ,nullif([DATA_USCITA],'''') ,nullif([TIPO_LAVORO],'''') ,nullif([FLG_CANCELLAZIONE],'''') 	FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SC01 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_PROGETTO,CODICE_FISCALE'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SC01 Partecipanti Politiche Attive''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SC01.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''CODICE_CORSO'' as CODICE_CORSO,''CODICE_FISCALE'' as CODICE_FISCALE,''SESSO'' as SESSO,''DATA_NASCITA'' as DATA_NASCITA,''COD_ISTAT_RES'' as COD_ISTAT_RES,''COD_ISTAT_DOM'' as COD_ISTAT_DOM,''CITTADINANZA'' as CITTADINANZA,''TITOLO_STUDIO'' as TITOLO_STUDIO,''COND_MERCATO_INGRESSO'' as COND_MERCATO_INGRESSO,''DURATA_RICERCA'' as DURATA_RICERCA,''CODICE_VULNERABILE_PA'' as CODICE_VULNERABILE_PA,''STATO_PARTECIPANTE'' as STATO_PARTECIPANTE,''DATA_USCITA'' as DATA_USCITA,''TIPO_LAVORO'' as TIPO_LAVORO,''FLG_CANCELLAZIONE'' as FLG_CANCELLAZIONE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_PROGETTO],''''),nullif([CODICE_CORSO],'''') ,nullif([CODICE_FISCALE] ,''''),nullif([SESSO],'''') ,nullif([DATA_NASCITA],'''') ,nullif([COD_ISTAT_RES] ,''''),nullif([COD_ISTAT_DOM],'''') ,nullif([CITTADINANZA],'''') ,nullif([TITOLO_STUDIO],'''') ,nullif([COND_MERCATO_INGRESSO],'''') ,nullif([DURATA_RICERCA],'''') ,nullif([CODICE_VULNERABILE_PA] ,''''),nullif([STATO_PARTECIPANTE],'''') ,nullif([DATA_USCITA],'''') ,nullif([TIPO_LAVORO],'''') ,nullif([FLG_CANCELLAZIONE],''''),idgenerazione 	FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SC01 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_PROGETTO,CODICE_FISCALE'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SC01 Partecipanti Politiche Attive'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
			END
												
			--SD01
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD01.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_SPESA],'''') ,nullif([COD_FISCALE],'''') ,nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_LOCALE_UCS],'''') ,nullif([QUANTITA],'''') ,nullif([IMPORTO],'''') ,nullif([COD_TIPOLOGIA_COSTO],'''') ,nullif([COD_ENTE_EROGATORE],'''') ,nullif([PIANO_FINANZIARIO],'''') ,nullif([COD_LOCALE_DDR],'''') ,nullif([DATA_COMPETENZA],'''') ,nullif([NOTE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD01 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_SPESA, COD_FISCALE'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SD01 Spese''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD01.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_SPESA'' as COD_LOCALE_SPESA,''COD_FISCALE'' as COD_FISCALE,''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_LOCALE_UCS'' as COD_LOCALE_UCS,''QUANTITA'' as QUANTITA,''IMPORTO'' as IMPORTO,''COD_TIPOLOGIA_COSTO'' as COD_TIPOLOGIA_COSTO,''COD_ENTE_EROGATORE'' as COD_ENTE_EROGATORE,''PIANO_FINANZIARIO'' as PIANO_FINANZIARIO,''COD_LOCALE_DDR'' as COD_LOCALE_DDR,''DATA_COMPETENZA'' as DATA_COMPETENZA,''NOTE'' as NOTE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_SPESA],'''') ,nullif([COD_FISCALE],'''') ,nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_LOCALE_UCS],'''') ,nullif([QUANTITA],'''') ,nullif([IMPORTO],'''') ,nullif([COD_TIPOLOGIA_COSTO],'''') ,nullif([COD_ENTE_EROGATORE],'''') ,nullif([PIANO_FINANZIARIO],'''') ,nullif([COD_LOCALE_DDR],'''') ,nullif([DATA_COMPETENZA],'''') ,nullif([NOTE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD01 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_SPESA, COD_FISCALE'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder+ @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SD01 Spese'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
									
			--SD02
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD02.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_MANDATO],'''') ,nullif([NUMERO_MANDATO],'''') ,nullif([DATA_MANDATO],'''') ,nullif([IMPORTO_MANDATO],'''') ,nullif([NOTE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD02 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_MANDATO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SD02 Mandati''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD02.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_MANDATO'' as COD_LOCALE_MANDATO,''NUMERO_MANDATO'' as NUMERO_MANDATO,''DATA_MANDATO'' as DATA_MANDATO,''IMPORTO_MANDATO'' as IMPORTO_MANDATO,''NOTE'' as NOTE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_MANDATO],'''') ,nullif([NUMERO_MANDATO],'''') ,nullif([DATA_MANDATO],'''') ,nullif([IMPORTO_MANDATO],'''') ,nullif([NOTE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD02 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_MANDATO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder+ @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SD02 Mandati'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 

			--SD03
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD03.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_DOCUMENTO],'''') ,nullif([NOME_FILE],'''') ,nullif([TIPOLOGIA_FILE],'''') ,nullif([CATEGORIA_FILE],''''), nullif([COD_LOCALE_PROGETTO],''''), nullif([COD_LOCALE_MANDATO],''''), nullif([COD_SPESA_LOCALE],''''), nullif([NOTE],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD03 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_DOCUMENTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SD03 Documenti''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD03.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_DOCUMENTO'' as COD_LOCALE_DOCUMENTO,''NOME_FILE'' as NOME_FILE,''TIPOLOGIA_FILE'' as TIPOLOGIA_FILE,''CATEGORIA_FILE'' as CATEGORIA_FILE,''COD_LOCALE_PROGETTO'' as COD_LOCALE_PROGETTO,''COD_LOCALE_MANDATO'' as COD_LOCALE_MANDATO,''COD_SPESA_LOCALE'' as COD_SPESA_LOCALE,''NOTE'' as NOTE,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_DOCUMENTO],'''') ,nullif([NOME_FILE],'''') ,nullif([TIPOLOGIA_FILE],'''') ,nullif([CATEGORIA_FILE],'''') ,nullif([COD_LOCALE_PROGETTO],'''') ,nullif([COD_LOCALE_MANDATO],'''') ,nullif([COD_SPESA_LOCALE],'''') ,nullif([NOTE],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD03 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_DOCUMENTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SD03 Documenti'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
													
			--SD04
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD04.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_MANDATO],''''),nullif([COD_LOCALE_SPESA],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD04 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_MANDATO,COD_LOCALE_SPESA'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SD04 Mandati-Spese''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD04.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_MANDATO'' as COD_LOCALE_MANDATO,''COD_LOCALE_SPESA'' as COD_LOCALE_SPESA,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_MANDATO],''''),nullif([COD_LOCALE_SPESA],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD04 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_MANDATO,COD_LOCALE_SPESA'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SD04 Mandati-Spese'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 
												
			--SD06
			--SEMPRE, ANCHE PER MANDATO FORMAZIONE
				--txt
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD06.txt'	
				set @sql = 'SELECT nullif([COD_LOCALE_SPESA],''''),nullif([COD_PAGAMENTO],'''') FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD06 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY COD_LOCALE_SPESA, COD_PAGAMENTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedFolder + @nomefile + ' -c -t"|" -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'INSERT INTO SIGMA_Generazione_File_Allegati
					SELECT 
						'+convert(varchar,@idgenerazione)+'
						,''SD06 Pagamento (gruppi spesa)-Spesa''	
						,CAST(bulkcolumn AS VARBINARY(MAX)) 
						,''' + @nomefile + '''
						,null
						,null
						,''' + DBO.FORMATODATA(@Dataora) + '''
						,''' + @USERNAMERICHIESTA + '''
					FROM OPENROWSET(BULK ''' + @pathSharedFolder + @nomefile +''' ,SINGLE_BLOB ) AS x '
					EXEC (@SQL) 
					
				--csv
				set @nomefile = CONVERT(VARCHAR,@IdGenerazione) + '_' + @CODICELOCALEMANDATO + '_' + REPLACE(DBO.FORMATODATA(@Dataora),'/','') + '_SD06.csv'	
				--intestazioni
				set @sql = 'select	''COD_LOCALE_SPESA'' as COD_LOCALE_SPESA,''COD_PAGAMENTO'' as COD_PAGAMENTO,0 as idgenerazione'
				--dati
				set @sql = @sql + ' UNION SELECT nullif([COD_LOCALE_SPESA],''''),nullif([COD_PAGAMENTO],''''),idgenerazione FROM '+@DBNAME+'.dbo.SIGMA_TABELLA_SD06 with(nolock) where idgenerazione = ' +  CONVERT(VARCHAR,@IdGenerazione) + ' ORDER BY idgenerazione,COD_LOCALE_SPESA, COD_PAGAMENTO'
				select @comandobcp = 'bcp "'+@sql+'" queryout ' + @pathSharedCSVFolder + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
				exec master..xp_cmdshell @comandobcp	

					--upload
					set @sql = 'UPDATE SIGMA_Generazione_File_Allegati 
									SET FileNameCSV = ''' + @nomefile + ''', BINDATACSV = CAST(bulkcolumn AS VARBINARY(MAX)) 
								FROM OPENROWSET(BULK ''' + @pathSharedCSVFolder + @nomefile + ''' ,SINGLE_BLOB ) AS x 
								WHERE TABELLA = ''SD06 Pagamento (gruppi spesa)-Spesa'' AND IDGENERAZIONE = ' + convert(varchar,@idgenerazione)
					EXEC (@SQL) 									
		END
	ELSE
		BEGIN
			if @@trancount > 0
				ROLLBACK		
		
			PRINT @ESITO 
			
			UPDATE sigma_generazione_file SET Esito = 'NEGATIVO'
			WHERE IdGenerazione = @IdGenerazione		
			 
		END
	
	RETURN

END TRY
BEGIN CATCH
	if @@trancount > 0
		ROLLBACK
	SET @esito = 'ERRORE IMPREVISTO IN FASE DI ELABORAZIONE. ' + ERROR_MESSAGE()

	UPDATE sigma_generazione_file SET Esito = 'NEGATIVO'
	WHERE IdGenerazione = @IdGenerazione		
END CATCH
GO
