USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_GG_ELENCO_NEET]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_GG_ELENCO_NEET]
--PRODUCE FILE PER ATTIVAZIONE PRESA IN CARICO CENTRALIZZATA
--CANDIDATI SU PROGETTI GG CON TIPOGG "NEET" e domanda con DataPresaInCaricoGaranziaGiovani NON indicata
AS
declare @sql varchar(8000) = '',
		@comandobcp varchar(8000),
		@nomefile varchar(255),
		@NRecordPerFile int = 500,
		@Inizio int = 1,
		@ContaCicli int = 1,
		@NRigheTot int = 0,
		@Gruppo int = 59

declare @Fine int = @NRecordPerFile


--drop table #tmp
select distinct g.CodiceFiscale,g.Email 
into tmpExpNeet
from programmi a
inner join attivit‡ b on a.IdProgramma = b.IdProgramma
inner join TipiGG c on a.IdTipoGG = c.IdTipoGG
--inner join entit‡ d on b.CodiceEnte = d.TMPCodiceProgetto
inner join Attivit‡SediAssegnazione e on b.IDAttivit‡ = e.IDAttivit‡
inner join GraduatorieEntit‡ f on e.IDAttivit‡SedeAssegnazione = f.IdAttivit‡SedeAssegnazione
inner join entit‡ g on f.IdEntit‡ = g.IDEntit‡
inner join DOL_DomandePresentate h on g.DOL_Id = h.id
inner join BandiAttivit‡ i on b.IDBandoAttivit‡ = i.IdBandoAttivit‡
inner join bando l on i.IdBando = l.IDBando 
where c.Descrizione like '%neet%' and h.DataPresaInCaricoGaranziaGiovani is null AND Gruppo = @Gruppo
	

select @NRigheTot = count(*) from tmpExpNeet

while @ContaCicli <= 1+(@NRigheTot/@NRecordPerFile)
BEGIN
	set @nomefile = 'Export_NEET_'  + CONVERT(VARCHAR(10),@Gruppo) + '_' + CONVERT(VARCHAR(10),@ContaCicli) + '.csv'	
	--intestazioni
	--set @sql = 'select	''CODICE_FISCALE'' as CODICE_FISCALE,''EMAIL'' as EMAIL'
	--set @sql = @sql + ' UNION '
	--dati
	set @sql = ''
	set @sql = @sql + 'SELECT nullif([CodiceFiscale],'''') as CODICE_FISCALE, nullif([Email],'''') as EMAIL FROM unscproduzione.dbo.tmpExpNeet  ORDER BY CODICE_FISCALE'
	select @comandobcp = 'bcp "'+@sql+'" queryout \\Appl\modhelios$\SIGMA_FILES\CSV\' + @nomefile + ' -c -t; -T -CRAW -F' + convert(varchar(10),@Inizio) + ' -L' + convert(varchar(10),@Fine)  + ' -S' + @@servername
	exec master..xp_cmdshell @comandobcp
	SET @Inizio = @Inizio + @NRecordPerFile
	SET @Fine = @Fine + @NRecordPerFile
	SET @ContaCicli = @ContaCicli + 1
END
drop table tmpExpNeet
GO
