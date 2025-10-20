USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_GG_PRIMOCONTROLLOVOLONTARI]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[SP_GG_PRIMOCONTROLLOVOLONTARI]
AS

declare @data_richiesta_elaborazione datetime
declare @data_richiesta_elaborazionetxt as varchar(100)
declare @nomefile varchar(100)

set @nomefile = 'ElencoVolontariGG'

declare @comandobcp varchar(8000)
declare @sql varchar(8000)

set @data_richiesta_elaborazione = getdate()
set @data_richiesta_elaborazionetxt = dbo.formatodata(@data_richiesta_elaborazione) + ' ' 
	+ replicate('0',2-len(convert(varchar,datepart(hour,@data_richiesta_elaborazione)))) + convert(varchar,datepart(hour,@data_richiesta_elaborazione)) 
	+ ':' + replicate('0',2-len(convert(varchar,datepart(minute,@data_richiesta_elaborazione))))+convert(varchar,datepart(minute,@data_richiesta_elaborazione))
	+ ':' + replicate('0',2-len(convert(varchar,datepart(second,@data_richiesta_elaborazione))))+convert(varchar,datepart(second,@data_richiesta_elaborazione))
set @data_richiesta_elaborazione = @data_richiesta_elaborazionetxt

PRINT @data_richiesta_elaborazionetxt

--INSERIMENTO NUOVI VOLONTARI PER PRIMO CONTROLLO 
insert into dbo.entit�controlliMLPS (identit�,data_richiesta_elaborazione,CF)
SELECT A.IDENTIT�,@data_richiesta_elaborazione, a.codicefiscale FROM ENTIT� A 
INNER JOIN ATTIVIT� B ON A.TMPCODICEPROGETTO = B.CODICEENTE
LEFT JOIN dbo.entit�controlliMLPS C ON A.IDENTIT� = C.IDENTIT� and c.data_elaborazione_controlli is null
WHERE
 B.IDTIPOPROGETTO = 4 --progetto gg
	and 
	a.idtipoesitocontrolloMLPS is null --volontario senza esito finale
	and  
	C.IDENTIT� is null --volontario non in attesa di riscontro (in quanto gi� inviato)

--union per ricontrollo volontari con requisiti="In Definizione" per volontari avviati
union
select identit�,@data_richiesta_elaborazione, codicefiscale from entit�
where idtipoesitocontrolloMLPS is not null and isnull(requisiti,'In Definizione') = 'In Definizione' and idstatoentit� in (3,5) 

--union per ricontrollo volontari con requisiti="In Definizione" non avviati ma che fanno riferimento al bando 2� gg 2015 o successivi (franz� 31/03/2016)
union
select identit�,@data_richiesta_elaborazione,codicefiscale from entit� a
inner join attivit� b on a.tmpcodiceprogetto = b.codiceente
inner join bandiattivit� c on b.idbandoattivit� = c.idbandoattivit�
inner join bando d on c.idbando = d.idbando
where idtipoesitocontrolloMLPS is not null and isnull(requisiti,'In Definizione') = 'In Definizione' and idstatoentit� in (1) 
	and d.gruppo >=40

--union 
--select identit�, @data_richiesta_elaborazione ,codicefiscale from entit�
--where idtipoesitocontrolloMLPS is not null and codicefiscale = 'PSTRNN89D63B519N'

---- RICHIESTA DEL 12/08/2015 e il 18/08/2015
---- VOLONTARI IN SERVIZIOO CON REQUISITI IN DEFINIZIONE O VUOTI(IL 18/08/2015)


	-- B.IDTIPOPROGETTO = 4 --progetto gg
	--and a.idstatoentit� = 3
	--and (a.requisiti = 'In Definizione' OR a.requisiti IS NULL)
    
------RICHIESTA SPOT DEL 17/07/2015
--SELECT A.IDENTIT�,@data_richiesta_elaborazione, a.codicefiscale FROM ENTIT� A 
--INNER JOIN ATTIVIT� B ON A.TMPCODICEPROGETTO = B.CODICEENTE
--WHERE B.IDTIPOPROGETTO = 4 --progetto gg
--		and a.idstatoentit� = 3
--		and 
--			(		
--					(
--						DATA_REGISTRAZIONE_PORTALE_CLICLAVORO IS NOT NULL AND
--						DATA_REGISTRAZIONE_PORTALE_CLICLAVORO > datadomanda
--					)
--				or (
--						DATA_REGISTRAZIONE_PORTALE_CLICLAVORO IS NULL AND
--						ISNULL(DATA_REGISTRAZIONE,'31/12/2030') > DATADOMANDA
--					)
--				or	(requisiti = 'no')
--				or (requisiti = 'in definizione')
--			)
--UNION
--SELECT IDENTIT�,@data_richiesta_elaborazione,CODICEFISCALE FROM ENTIT� WHERE CODICEFISCALE IN ('BLCSRN86L60A024Z','BNDPQL91H26L628Z','CFRRRT91A09F839Y','CNQCRL93R61F839B','CPTDNC93L17E919W',
--'CRVMHL86E43A509V','CSLFRC94L05F839C','DBRLCU94R03L182M','DGSTSM87B43A662B','DLCRSO90S49A509C',
--'DLDMLN88P58Z112J','DLEFNC87H13L628W','DLLGNN91E49A509V','DNPTRS94M60F839K','DPTLRI93C49F839J',
--'GLTGLN90E53F839X','GRCCST93P60I422Y','GRGFDN95B07I862X','GRNMRC86P25D205I','LMNRSR87L48Z404W',
--'LNGDNL90D05G348N','LRCMSR85T69E472B','LTACST94M50F158F','MCRSNO86E71L049C','MGNMRA93M18M289Q',
--'MLFNTN88L02F839K','MLLDNS94T52A089X','MNFRRT91C48I422G','MNSNNA88R43B963B','MNTFLV92M71F839P',
--'MRTGRL87B42I754S','MSCLSE93E51A479N','MSLVCN87H10D390O','MTPPRD92P08Z611W','NCLGLI95T63C351H',
--'NCLMRA94E54F839M','PLLNRS85T07C351W','PRCMNL95H63F839Q','PRGNDR93L19H501M','RMNFRC93H47E977K',
--'SLMLCU92P09F839Q','SPGGUO90M10F839L','STNCRI91H21H892U','SVNMLN89L56F052U','VRDGDU86P26E131P',
--'VRDLSN91L54D643J','VTTCRI87A18F839A') AND IDTIPOESITOCONTROLLOMLPS IS NOT NULL

--RICHIESTA SPOT PER CONTROLLO MANCANZA REQUISITI A TERMINI QUASI RAGGIUNTI
--WHERE B.IDTIPOPROGETTO = 4 --progetto gg
--	and a.datainizioservizio = '16/03/2015'
--	and a.idstatoentit� = 3
--	and a.requisiti = 'In Definizione'
--	and C.IDENTIT� is null --volontario non in attesa di riscontro (in quanto gi� inviato)
	


--modificato il 16/03/2015 da Danilo
--LEFT JOIN dbo.entit�controlliMLPS C ON A.IDENTIT� = C.IDENTIT�
--WHERE B.IDTIPOPROGETTO = 4 AND C.IDENTIT� IS NULL 

--INSERIMENTO VOLONTARI AVVIATI ANCORA SENZA PRESA IN CARICO
--TODO!

--intestazioni
set @sql = 'select	''CF'',''NOME'',''COGNOME'',''COD_COMUNE'',''COD_GENERE'',''DATA_NASCITA'',''DATA_REGISTRAZIONE'',''DATA_PRESA_IN_CARICO'',''COD_ENTE_PROMOTORE'',''COD_STATO_ADESIONE'',''DATA_STATO_ADESIONE'',''DATA_ELABORAZIONE_FILE'''
--dati
set @sql = @sql + ' UNION select CF, '''', '''', '''', '''', '''', '''', '''', '''','''','''','''' from unscproduzione.dbo.entit�controlliMLPS where data_richiesta_elaborazione=''' + @data_richiesta_elaborazionetxt + ''''

set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,'/','')
set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,':','')
set @data_richiesta_elaborazionetxt = replace(@data_richiesta_elaborazionetxt,' ','_')
set @data_richiesta_elaborazionetxt = ltrim(rtrim(@data_richiesta_elaborazionetxt))
set @nomefile = @nomefile + '_' + @data_richiesta_elaborazionetxt + '.csv'

select @comandobcp = 'bcp "'+@sql+'" queryout D:\EXPORT_VOLONTARI_MLPS\' + @nomefile + ' -c -t; -T -S' + @@servername
--print @comandobcp
exec master..xp_cmdshell @comandobcp






GO
