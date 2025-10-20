USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_GG_PRIMOCONTROLLOVOLONTARI_DISOCCUPATI_SPOT]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








ALTER PROCEDURE [dbo].[SP_GG_PRIMOCONTROLLOVOLONTARI_DISOCCUPATI_SPOT]
AS

declare @data_richiesta_elaborazione datetime
declare @data_richiesta_elaborazionetxt as varchar(100)
declare @nomefile varchar(100)

set @nomefile = 'ElencoVolontariGG_DISOCCUPATI'

declare @comandobcp varchar(8000)
declare @sql varchar(8000)

set @data_richiesta_elaborazione = getdate()
set @data_richiesta_elaborazionetxt = dbo.formatodata(@data_richiesta_elaborazione) + ' ' 
	+ replicate('0',2-len(convert(varchar,datepart(hour,@data_richiesta_elaborazione)))) + convert(varchar,datepart(hour,@data_richiesta_elaborazione)) 
	+ ':' + replicate('0',2-len(convert(varchar,datepart(minute,@data_richiesta_elaborazione))))+convert(varchar,datepart(minute,@data_richiesta_elaborazione))
	+ ':' + replicate('0',2-len(convert(varchar,datepart(second,@data_richiesta_elaborazione))))+convert(varchar,datepart(second,@data_richiesta_elaborazione))
set @data_richiesta_elaborazione = @data_richiesta_elaborazionetxt

PRINT @data_richiesta_elaborazionetxt

--INSERIMENTO VOLONTARI PER CONTROLLO (VOLONTARI SU GRADUATORIE PRESENTATE NON VALUTATE)
insert into dbo.entit‡controlliDISOCCUPATI(identit‡,data_richiesta_elaborazione,CF)
SELECT A.IDENTIT‡,@data_richiesta_elaborazione, a.codicefiscale FROM ENTIT‡ A 
INNER JOIN GraduatorieEntit‡ GE ON A.IDEntit‡ = GE.IdEntit‡
INNER JOIN Attivit‡SediAssegnazione ASA ON GE.IdAttivit‡SedeAssegnazione = ASA.IDAttivit‡SedeAssegnazione
INNER JOIN ATTIVIT‡ B ON ASA.IDAttivit‡ = B.IDAttivit‡
INNER JOIN PROGRAMMI ON B.IdProgramma = PROGRAMMI.IdProgramma
inner join TipiGG c on Programmi.IdTipoGG = c.IdTipoGG
--inner join DOL_DomandePresentate dol on a.DOL_Id = dol.id
WHERE
 B.IDTIPOPROGETTO = 4 --progetto gg DISOCCUPATI
  AND c.Descrizione like '%DISOCCUPATI%' 
  --and dol.DataPresaInCaricoGaranziaGiovani is not null

--intestazioni
set @sql = 'select	''[CODICE_FISCALE]'''
--dati
set @sql = @sql + ' UNION select CF from ' + DB_NAME() + '.dbo.entit‡controlliDISOCCUPATI where data_richiesta_elaborazione=''' + @data_richiesta_elaborazionetxt + ''''

set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,'/','')
set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,':','')
set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,' ','_')
set @data_richiesta_elaborazionetxt = ltrim(rtrim(@data_richiesta_elaborazionetxt))
set @nomefile = @nomefile + '_' + @data_richiesta_elaborazionetxt + '.csv'

select @comandobcp = 'bcp "'+@sql+'" queryout D:\EXPORT_VOLONTARI_DISOCCUPATI\' + @nomefile + ' -c -t; -T -S' + @@servername
--print @comandobcp
exec master..xp_cmdshell @comandobcp





GO
