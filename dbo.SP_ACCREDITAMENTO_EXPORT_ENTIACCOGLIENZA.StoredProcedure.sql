USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_ACCREDITAMENTO_EXPORT_ENTIACCOGLIENZA]    Script Date: 14/10/2025 12:36:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_ACCREDITAMENTO_EXPORT_ENTIACCOGLIENZA]
	@IdEnte as int --identificativo ente per il quale si richiedono i dati

as
BEGIN
	declare @CodiceEnte as varchar(50)
			,@nomefile as varchar(100)
			,@sql as varchar(max)
			,@comandobcp as varchar(8000)
	
	select @CodiceEnte = codiceregione from enti where IDEnte = @IdEnte			
	
	

	--csv
	set @nomefile = 'Export_EntiAccoglienza_' + @CodiceEnte + '_' + REPLACE(DBO.FORMATODATA(GETDATE()),'/','') + '.csv'	
	--intestazioni
	set @sql = 'select	''  Denominazione Ente'' as [Denominazione Ente], ''Codice Fiscale Ente''	as [Codice Fiscale Ente], ''Tipologia'' as Tipologia, ''Tipo Relazione'' as [Tipo Relazione], ''Codice Istat Comune'' as [Codice Istat Comune], ''Indirizzo'' as Indirizzo, ''Civico'' as Civico, ''CAP'' as CAP, ''Prefisso Telefonico'' as [Prefisso Telefonico], ''Telefono'' as [Telefono], ''Assistenza'' as Assistenza, ''Protezione Civile'' as [Protezione Civile],	''Ambiente'' as Ambiente, ''Patrimonio Artistico'' as [Patrimonio Artistico], ''Promozione Culturale'' as [Promozione Culturale], ''Estero'' as Estero,	''Agricoltura'' as Agricoltura '
	--dati
	set @sql = @sql + ' UNION select'
	set @sql = @sql + ' accoglienza.Denominazione'
		set @sql = @sql + ' ,accoglienza.CodiceFiscale'
		set @sql = @sql + ' ,TE.CodiceImport'
		set @sql = @sql + ' ,tr.CodiceImport'
		set @sql = @sql + ' ,CASE c.CodiceISTAT WHEN '''' THEN NULL ELSE c.CodiceISTAT END as CodiceIstat '
		set @sql = @sql + ' ,es.Indirizzo'
		set @sql = @sql + ' ,CASE es.Civico WHEN '''' THEN NULL ELSE es.Civico END AS Civico '
		set @sql = @sql + ' ,CASE es.CAP WHEN '''' THEN NULL ELSE es.CAP END AS CAP'
		set @sql = @sql + ' ,CASE accoglienza.PrefissoTelefonoRichiestaRegistrazione WHEN '''' THEN NULL ELSE accoglienza.PrefissoTelefonoRichiestaRegistrazione END AS PrefissoTelefonoRichiestaRegistrazione'
		set @sql = @sql + ' ,CASE accoglienza.TelefonoRichiestaRegistrazione WHEN '''' THEN NULL ELSE accoglienza.TelefonoRichiestaRegistrazione END AS TelefonoRichiestaRegistrazione'
		set @sql = @sql + ' ,settori.SettoreAssistenza'
		set @sql = @sql + ' ,settori.SettoreProtezioneCivile'
		set @sql = @sql + ' ,settori.SettoreAmbiente'
		set @sql = @sql + ' ,settori.SettorePatrimonioArtisticoCulturale'
		set @sql = @sql + ' ,settori.SettoreEducazionePromozioneCulturale'
		set @sql = @sql + ' ,settori.SettoreServizioCivileEstero'
		set @sql = @sql + ' ,settori.SettoreAgricoltura'
	set @sql = @sql + ' from unscproduzione.dbo.enti as capofila'
	set @sql = @sql + ' inner join unscproduzione.dbo.entirelazioni as er on capofila.IDEnte = er.IDEntePadre'
	set @sql = @sql + ' inner join unscproduzione.dbo.enti as accoglienza on er.IDEnteFiglio = accoglienza.IDEnte '
	set @sql = @sql + ' INNER JOIN unscproduzione.dbo.TipologieEnti AS TE ON accoglienza.Tipologia = TE.Descrizione'
	set @sql = @sql + ' inner join unscproduzione.dbo.tipirelazioni as tr on er.IDTipoRelazione = tr.IDTipoRelazione'
	set @sql = @sql + ' inner join unscproduzione.dbo.VW_BO_ENTI as es on accoglienza.IDEnte = es.IDEnte '
	set @sql = @sql + ' inner join unscproduzione.dbo.VW_BO_ENTI_SETTORI_DW as settori on accoglienza.IDEnte = settori.IDENTE'
	set @sql = @sql + ' left join unscproduzione.dbo.comuni as c on es.IDComune = c.IDComune '
	set @sql = @sql + ' where capofila.IDEnte = ' + CONVERT(VARCHAR(100),@IdEnte) + ' AND  accoglienza.idstatoente = 3 '
	set @sql = @sql + ' order by 1'
	
	select @comandobcp = 'bcp "'+@sql+'" queryout \\Appl\modhelios$\ExportToSCU\' + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
	
	exec master..xp_cmdshell @comandobcp

		--upload
		set @sql = 'UPDATE Accreditamento_Export_CSV 
						SET FileName_Accoglienza = ''' + @nomefile + ''', BinData_Accoglienza = CAST(bulkcolumn AS VARBINARY(MAX)) 
					FROM OPENROWSET(BULK ''\\Appl\modhelios$\ExportToSCU\' + @nomefile + ''' ,SINGLE_BLOB ) AS x 
					WHERE IdEnte = ' + convert(varchar,@IdEnte)
		EXEC (@SQL) 


	return @@rowcount
END
GO
