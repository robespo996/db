USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_ACCREDITAMENTO_EXPORT_SEDI_BUTTA]    Script Date: 14/10/2025 12:36:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_ACCREDITAMENTO_EXPORT_SEDI_BUTTA]
	@IdEnte as int --identificativo ente per il quale si richiedono i dati

as
BEGIN
	declare @CodiceEnte as varchar(50)
			,@nomefile as varchar(100)
			,@sql as varchar(max)
			,@comandobcp as varchar(8000)
	
	select @CodiceEnte = codiceregione from enti where IDEnte = @IdEnte			
	
	--csv
	set @nomefile = 'Export_Sedi_' + @CodiceEnte + '_' + REPLACE(DBO.FORMATODATA(GETDATE()),'/','') + '.csv'	
	--intestazioni
	--, ''Data Stipula Contratto'' as [Data Stipula Contratto],	''Data Scadenza Contratto'' as [Data Scadenza Contratto]
	set @sql = 'select	''  C.F. Ente'' as [C.F. Ente], ''Nome Sede'' as [Nome Sede], ''Istat Comune'' as [Istat Comune], ''Indirizzo'' as [Indirizzo], ''Civico'' as [Civico], ''CAP'' as CAP, ''Prefisso Telefono'' as [Prefisso Telefono], ''Telefono'' as Telefono, ''Palazzina'' as [Palazzina], ''Scala'' as [Scala], ''Piano'' as Piano, ''Interno'' as [Interno],	''Titolo Possedimento'' as [Titolo Possedimento], ''Volontari Allocabili'' as [Volontari Allocabili], ''Volontari Maggiore di 20'' as [Volontari Maggiore di 20], ''CodiceSede'' as [Codice Sede] '
																																																																																																											
	
	set @sql = @sql + ' UNION select e.CodiceFiscale'
	set @sql = @sql + ' ,eS.Denominazione'
	set @sql = @sql + ' ,CASE c.CodiceISTAT WHEN '''' THEN NULL ELSE c.CodiceISTAT END AS CodiceISTAT'
	set @sql = @sql + ' ,es.Indirizzo'
	set @sql = @sql + ' ,CASE es.Civico WHEN '''' THEN NULL ELSE es.Civico END as Civico'
	set @sql = @sql + ' ,CASE es.CAP WHEN '''' THEN NULL ELSE es.CAP END as CAP'
	set @sql = @sql + ' ,CASE es.PrefissoTelefono WHEN '''' THEN NULL ELSE es.PrefissoTelefono END as PrefissoTelefono'
	set @sql = @sql + ' ,CASE es.Telefono WHEN '''' THEN NULL ELSE es.Telefono END as Telefono'
	set @sql = @sql + ' ,CASE es.Palazzina WHEN '''' THEN NULL ELSE es.Palazzina END as Palazzina'
	set @sql = @sql + ' ,CASE es.Scala WHEN '''' THEN NULL ELSE es.Scala END as Scala'
	set @sql = @sql + ' ,CONVERT(VARCHAR(10),es.Piano) as Piano'
	set @sql = @sql + ' ,CASE es.Interno WHEN '''' THEN NULL ELSE es.Interno END as Interno'
	set @sql = @sql + ' ,tg.DescrizioneAbbreviata as TitoloPossedimento'
	set @sql = @sql + ' ,convert(varchar(10),esa.NMaxVolontari) as NMaxVolontari'
	set @sql = @sql + ' ,case when ISNULL(esa.nmaxvolontari,0) >20 then ''SI'' else ''NO'' end as VolontariMaggioridi20'
	set @sql = @sql + ' ,convert(varchar(20),esa.identesedeattuazione) as CodiceSede'
	--set @sql = @sql + ' ,unscproduzione.dbo.FormatoData(es.DataStipulaContratto) as DataStipulaContratto'
	--set @sql = @sql + ' ,unscproduzione.dbo.formatodata(es.DataScadenzaContratto) as DataScadenzaContratto'
	set @sql = @sql + ' from unscproduzione.dbo.entisediattuazioni esa'
	set @sql = @sql + ' inner join unscproduzione.dbo.entisedi es on esa.IDEnteSede = es.IDEnteSede'
	set @sql = @sql + ' inner join unscproduzione.dbo.comuni c on es.IDComune = c.IDComune '
	set @sql = @sql + ' inner join unscproduzione.dbo.enti e on es.IDEnte = e.IDEnte'
	set @sql = @sql + ' LEFT join unscproduzione.dbo.TitoliGiuridici tg on es.IdTitoloGiuridico= tg.IdTitoloGiuridico'
	set @sql = @sql + ' where esa.IdEnteCapofila = ' + convert(varchar(10),@IdEnte) + ' and esa.IdStatoEnteSede = 1 '
	set @sql = @sql + ' order by 1'

	select @comandobcp = 'bcp "'+@sql+'" queryout \\Appl\modhelios$\ExportToSCU\' + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
	
	exec master..xp_cmdshell @comandobcp

		----upload
		--set @sql = 'UPDATE Accreditamento_Export_CSV 
		--				SET FileName_Sedi = ''' + @nomefile + ''', BinData_Sedi = CAST(bulkcolumn AS VARBINARY(MAX)) 
		--			FROM OPENROWSET(BULK ''\\Appl\modhelios$\ExportToSCU\' + @nomefile + ''' ,SINGLE_BLOB ) AS x 
		--			WHERE IdEnte = ' + convert(varchar,@IdEnte)
		--EXEC (@SQL) 

	return @@rowcount
END



GO
