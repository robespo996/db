USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_ACCREDITAMENTO_EXPORT_RISORSE]    Script Date: 14/10/2025 12:36:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_ACCREDITAMENTO_EXPORT_RISORSE]
	@IdEnte as int --identificativo ente per il quale si richiedono i dati

as
BEGIN

	declare @CodiceEnte as varchar(50)
			,@nomefile as varchar(100)
			,@sql as varchar(max)
			,@comandobcp as varchar(8000)
	
	select @CodiceEnte = codiceregione from enti where IDEnte = @IdEnte			
	
	--csv
	set @nomefile = 'Export_Risorse_' + @CodiceEnte + '_' + REPLACE(DBO.FORMATODATA(GETDATE()),'/','') + '.csv'	
	--intestazioni
	set @sql = 'select	''  Ruolo'' as [Ruolo], ''Codice Fiscale''	as [Codice Fiscale], ''Cognome'' as Cognome, ''Nome'' as [Nome], ''Data di Nascita'' as [Data di Nascita], ''Istat Comune di Nascita'' as [Istat Comune di Nascita], ''Esperienza di Servizio Civile'' as [Esperienza di Servizio Civile], ''Corso di formazione'' as [Corso di formazione]'--, ''Corso OLP da frequentare'' as [Corso OLP] '
	
	--dati
	set @sql = @sql + ' UNION select c.DescrAbb as Ruolo, b.CodiceFiscale as [Codice Fiscale], b.Cognome, b.Nome, unscproduzione.dbo.FormatoData(b.DataNascita) as [Data di Nascita], d.CodiceISTAT as [Istat Comune di Nascita], NULL as [Esperienza di Servizio Civile], NULL as [Corso di formazione]'
	--set @sql = @sql + ' ,case CorsoOLP when ''0'' then ''NO'' else ''SI''  end as [Corso OLP]'
	set @sql = @sql + ' from unscproduzione.dbo.entepersonaleruoli a'
	set @sql = @sql + ' inner join unscproduzione.dbo.entepersonale b on a.IDEntePersonale = b.IDEntePersonale '
	set @sql = @sql + ' inner join unscproduzione.dbo.ruoli c on a.IDRuolo = c.IDRuolo'
	set @sql = @sql + ' left join unscproduzione.dbo.comuni d on b.IDComuneNascita = d.IDComune '
	set @sql = @sql + ' where a.IDRuolo =1 and b.IdEnte = ' + CONVERT(varchar(10),@IdEnte)
	set @sql = @sql + ' and a.DataFineValidità is null and b.DataFineValidità is null'
	--set @sql = @sql + ' and a.Accreditato IN (1,2)'
	
	set @sql = @sql + ' UNION select c.DescrAbb as Ruolo, b.CodiceFiscale as [Codice Fiscale], b.Cognome, b.Nome, unscproduzione.dbo.FormatoData(b.DataNascita) as [Data di Nascita], d.CodiceISTAT as [Istat Comune di Nascita], NULL as [Esperienza di Servizio Civile], NULL as [Corso di formazione]'
	--set @sql = @sql + ' , NULL as [Corso OLP]'
	set @sql = @sql + ' from unscproduzione.dbo.entepersonaleruoli a'
	set @sql = @sql + ' inner join unscproduzione.dbo.entepersonale b on a.IDEntePersonale = b.IDEntePersonale '
	set @sql = @sql + ' inner join unscproduzione.dbo.ruoli c on a.IDRuolo = c.IDRuolo'
	set @sql = @sql + ' left join unscproduzione.dbo.comuni d on b.IDComuneNascita = d.IDComune '
	set @sql = @sql + ' where a.IDRuolo in (14,19) and b.IdEnte = ' + CONVERT(varchar(10),@IdEnte)
	set @sql = @sql + ' and a.DataFineValidità is null and b.DataFineValidità is null'
	set @sql = @sql + ' and a.accreditato=1'
	
	set @sql = @sql + ' UNION select c.DescrAbb as Ruolo, b.CodiceFiscale as [Codice Fiscale], b.Cognome, b.Nome, unscproduzione.dbo.FormatoData(b.DataNascita) as [Data di Nascita], d.CodiceISTAT as [Istat Comune di Nascita], case convert(varchar(50),isnull(EsperienzaServizioCivile,0)) when ''0'' then '''' else convert(varchar(50),isnull(EsperienzaServizioCivile,0)) end as [Esperienza di Servizio Civile], case convert(varchar(50),isnull(Corso,0)) when ''0'' then '''' else convert(varchar(50),isnull(Corso,0))  end as [Corso di formazione]'
	--set @sql = @sql + ' , NULL as [Corso OLP]'
	set @sql = @sql + ' from unscproduzione.dbo.entepersonaleruoli a'
	set @sql = @sql + ' inner join unscproduzione.dbo.entepersonale b on a.IDEntePersonale = b.IDEntePersonale '
	set @sql = @sql + ' inner join unscproduzione.dbo.ruoli c on a.IDRuolo = c.IDRuolo'
	set @sql = @sql + ' left join unscproduzione.dbo.comuni d on b.IDComuneNascita = d.IDComune '
	set @sql = @sql + ' where a.IDRuolo in (2) and b.IdEnte = ' + CONVERT(varchar(10),@IdEnte)
	set @sql = @sql + ' and a.DataFineValidità is null and b.DataFineValidità is null'
	set @sql = @sql + ' and a.accreditato=1'
		
	
	set @sql = @sql + ' ORDER BY  Ruolo,[Codice Fiscale]'


	--PRINT @SQL
	select @comandobcp = 'bcp "'+@sql+'" queryout \\Appl\modhelios$\ExportToSCU\' + @nomefile + ' -c -t; -T -CRAW -S' + @@servername
	
	exec master..xp_cmdshell @comandobcp

		--upload
		set @sql = 'UPDATE Accreditamento_Export_CSV 
						SET FileName_Risorse = ''' + @nomefile + ''', BinData_Risorse = CAST(bulkcolumn AS VARBINARY(MAX)) 
					FROM OPENROWSET(BULK ''\\Appl\modhelios$\ExportToSCU\' + @nomefile + ''' ,SINGLE_BLOB ) AS x 
					WHERE IdEnte = ' + convert(varchar,@IdEnte)
		EXEC (@SQL) 


	return @@rowcount
END





GO
