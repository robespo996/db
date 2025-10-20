USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_GG_PRIMOCONTROLLOVOLONTARI_NEET]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_GG_PRIMOCONTROLLOVOLONTARI_NEET]
AS

IF EXISTS(select * from entit‡controlliNEET where data_elaborazione_controlli is null)
BEGIN
	SELECT 'IMPOSSIBILE GENERARE IL FILE. ESISTONO GIA'' DEI VOLONTARI IN ATTESA DI RISCONTRO' AS ANOMALIA
	RETURN
END

declare @data_richiesta_elaborazione datetime
declare @data_richiesta_elaborazionetxt as varchar(100)
declare @nomefile varchar(100)

set @nomefile = 'ElencoVolontariGG_NEET'

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
insert into dbo.entit‡controlliNEET(identit‡,data_richiesta_elaborazione,CF)
SELECT A.IDENTIT‡,@data_richiesta_elaborazione, a.codicefiscale FROM ENTIT‡ A 
INNER JOIN GraduatorieEntit‡ GE ON A.IDEntit‡ = GE.IdEntit‡
INNER JOIN Attivit‡SediAssegnazione ASA ON GE.IdAttivit‡SedeAssegnazione = ASA.IDAttivit‡SedeAssegnazione
INNER JOIN ATTIVIT‡ B ON ASA.IDAttivit‡ = B.IDAttivit‡
INNER JOIN PROGRAMMI ON B.IdProgramma = PROGRAMMI.IdProgramma
inner join TipiGG c on Programmi.IdTipoGG = c.IdTipoGG
WHERE
 B.IDTIPOPROGETTO = 4 --progetto gg NEET
	and
	 c.Descrizione like '%neet%'
	and  
	 ASA.StatoGraduatoria = 2 --volontario su graduatoria presentata non valutata
UNION --PER GRADUATORIE CONFERMATE DA RICONTROLLARE
SELECT A.IDENTIT‡,@data_richiesta_elaborazione, a.codicefiscale FROM ENTIT‡ A 
INNER JOIN GraduatorieEntit‡ GE ON A.IDEntit‡ = GE.IdEntit‡
INNER JOIN Attivit‡SediAssegnazione ASA ON GE.IdAttivit‡SedeAssegnazione = ASA.IDAttivit‡SedeAssegnazione
INNER JOIN ATTIVIT‡ B ON ASA.IDAttivit‡ = B.IDAttivit‡
INNER JOIN PROGRAMMI ON B.IdProgramma = PROGRAMMI.IdProgramma
inner join TipiGG c on Programmi.IdTipoGG = c.IdTipoGG
WHERE
 B.IDTIPOPROGETTO = 4 --progetto gg NEET
	and
	 c.Descrizione like '%neet%'
	and  
	 ASA.StatoGraduatoria = 3 --graduatoria CONFERMATA
	and 
	 GE.Stato = 1 --IDONEO
	and
	 GE.Ammesso <> 1 --NON SELEZIONATO
	and 
	 a.IDStatoEntit‡ = 1 --REGISTRATO
	AND
	 ASA.IDAttivit‡SedeAssegnazione IN (SELECT IdAttivit‡SedeAssegnazione FROM Attivit‡SediAssegnazioneForzaControlloGG WHERE Lavorato = 0)

--MARCO LE FORZATURE COME LAVORATE
UPDATE Attivit‡SediAssegnazioneForzaControlloGG SET LAVORATO = 1 WHERE Lavorato = 0

--intestazioni
set @sql = 'select	''[CODICE_FISCALE]'''
--dati
set @sql = @sql + ' UNION select CF from ' + DB_NAME() + '.dbo.entit‡controlliNEET where data_richiesta_elaborazione=''' + @data_richiesta_elaborazionetxt + ''''

set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,'/','')
set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,':','')
set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,' ','_')
set @data_richiesta_elaborazionetxt = ltrim(rtrim(@data_richiesta_elaborazionetxt))
set @nomefile = @nomefile + '_' + @data_richiesta_elaborazionetxt + '.csv'

select @comandobcp = 'bcp "'+@sql+'" queryout D:\EXPORT_VOLONTARI_NEET\' + @nomefile + ' -c -t; -T -S' + @@servername
--print @comandobcp
exec master..xp_cmdshell @comandobcp





GO
