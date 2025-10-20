USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_COMP_STORICO_ELABORAZIONI_PAGHE_VOLONTARIO]    Script Date: 14/10/2025 12:36:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_COMP_STORICO_ELABORAZIONI_PAGHE_VOLONTARIO]
   @IdEntità int,
   @dettagli tinyint
AS

if @dettagli>2 set @dettagli=0


begin try
IF OBJECT_ID(N'tempdb..#t', N'U') IS NOT NULL DROP TABLE #t 
IF OBJECT_ID(N'tempdb..#p', N'U') IS NOT NULL DROP TABLE #p 
END TRY  
BEGIN CATCH
END CATCH 


CREATE TABLE #t (idelab varchar(10) not null)
CREATE TABLE #p (DataCreazioneRecord datetime, idpaga VARCHAR(10) not null, annomese varchar(50) null)

declare @identitàs varchar(10)

set @identitàs=convert(varchar,@identità)

insert into #t
select distinct idelaborazione from (
select VecchioIdElaborazione idelaborazione from COMP_StoricoPagheElaborazioni where idpaga in (select idpaga from comp_paghe where identità=@identità)
union
select idelaborazione from comp_paghe where identità=@identità
union
select idelaborazione from COMP_Elaborazione_Scarti where identità=@identità
) t
order by 1 asc

DECLARE @sql nvarchar(MAX);

SELECT 
@sql=COALESCE(@sql+',','')+'['+idelab +'] varchar(1000) null'
FROM #t

set @sql = 'ALTER TABLE #p ADD  ' + @sql +'' 
exec (@sql)

insert into #p ( DataCreazioneRecord,idpaga, annomese) 
	select DataCreazioneRecord,  idpaga, anno_comp+' '+mese_comp 
	   from comp_paghe where identità=@identità

if @dettagli=0
begin
	insert into #p (DataCreazioneRecord,idpaga, annomese)
	  select DataCreazioneRecord,(-1)*idelaborazione, 'X'+t2.Descrizione from COMP_Elaborazione_Scarti t1, COMP_Elaborazione_TipiScarto t2
	  where t1.identità=@identità
	  and t1.IdTipoScarto=t2.IdTipoScarto
end
else
begin
	insert into #p (DataCreazioneRecord,idpaga, annomese) 
	  select DataCreazioneRecord,(-1)*idelaborazione, t2.Descrizione from COMP_Elaborazione_Scarti t1, COMP_Elaborazione_TipiScarto t2
	  where t1.identità=@identità
	  and t1.IdTipoScarto=t2.IdTipoScarto
end



set @sql='update #p set idpaga=idpaga '

SELECT 
@sql=COALESCE(@sql+',','')+'['+idelab  +'] = '''' '
FROM #t

exec (@sql)

--select * from #p

-- Individua tutte le paghe elaborate

set @sql='update #p set idpaga=idpaga '

if @dettagli=0
begin
	SELECT 
	@sql=COALESCE(@sql+',','')+
	   '[' + idelab  +']= case when (select count(*) from comp_paghe r with (nolock) where r.idelaborazione='+ idelab+
	   ' and r.idpaga=#p.idpaga and r.identità='+ @identitàs  +')>0 then ''1'' else '''' end'
	FROM #t
end
else if @dettagli=1
begin
	SELECT 
		@sql=COALESCE(@sql+',','')+'[' + idelab  +'] = 
		case
		   when (select count(*) from COMP_paghe r with (nolock)
				where r.idelaborazione='+ idelab+' and r.idpaga=#p.idpaga and r.identità='+ @identitàs  +')>0 
			then
(select (''Importo paga: '' + convert(varchar,importo) +''€ ''+char(10)) 
from COMP_paghe with (nolock) where idpaga=#p.idpaga
FOR XML PATH('''') )
			else 
			'''' 
			end'
	FROM #t
end
else if @dettagli=2
begin
	SELECT 
		@sql=COALESCE(@sql+',','')+'[' + idelab  +'] = 
		case
			when (select count(*) from COMP_paghe r with (nolock)
				where r.idelaborazione='+ idelab+' and r.idpaga=#p.idpaga and r.identità='+ @identitàs  +')>0 
			then dbo.FN_COMP_FormattaDescrizionePagheVolontario(#p.idpaga)
			end'
	FROM #t
end

print @sql

	exec (@sql)
--select * from #p

-- Verifica se ci sono paghe riproposte

set @sql='update #p set idpaga=idpaga '

if @dettagli=0
begin
	SELECT
	@sql=COALESCE(@sql+',','')+'[' + idelab  +
	   '] = case when (select count(*) from COMP_StoricoPagheElaborazioni r where r.vecchioidelaborazione='+ idelab+
	   ' and r.idpaga=#p.idpaga)>0 then ''X'' else [' + idelab  +'] end'
	FROM #t
end
else
begin
	SELECT
	@sql=COALESCE(@sql+',','')+'[' + idelab  +
	   '] = case when (select count(*) from COMP_StoricoPagheElaborazioni r where r.vecchioidelaborazione='+ idelab+
	   ' and r.idpaga=#p.idpaga)>0 then ''Riproposta'' else [' + idelab  +'] end'
	FROM #t
end
--print @sql

exec (@sql)


-- Verifica se ci sono paghe in errore non riproposte
set @sql='update #p set idpaga=idpaga '

if @dettagli=0
begin
	SELECT
	@sql=COALESCE(@sql+',','')+'[' + idelab  +'] = case when (select count(*) from comp_paghe r where r.idelaborazione='+ idelab+
	' and r.idpaga=#p.idpaga and r.identità='+ @identitàs  +' and IdStatoPaga in (3,4) )>0 then ''E'' else [' + idelab  +'] end'
	FROM #t
end
else
begin
	SELECT
	@sql=COALESCE(@sql+',','')+
'[' + idelab  +'] = 
case 
	when (select count(*) from comp_paghe r where 
		r.idelaborazione='+ idelab+' 
		and r.idpaga=#p.idpaga 
		and r.identità='+ @identitàs  +' 
		and r.IdStatoPaga in (3,4))>0
    then (
		select ''Importo paga: ''+convert(varchar,importo) +''€_>>''+ statoPaga+''<<'' 
		from comp_paghe r,COMP_StatiPaghe sp 
		where sp.idStatoPaga=r.idStatoPaga
		and r.idpaga=#p.idpaga
	   )  
else [' + idelab  +'] end'
	FROM #t
end

print @sql

exec (@sql)


declare @idpaga varchar(100)
declare @annomese varchar(100)

DECLARE CUR_TEMP CURSOR LOCAL FOR
SELECT idpaga, annomese FROM #p where left(idpaga,1)='-'		
OPEN CUR_TEMP

FETCH NEXT FROM CUR_TEMP INTO @idpaga,@annomese
WHILE @@FETCH_STATUS = 0 
	BEGIN 	

	set @sql='update #p set idpaga='''',annomese='''', ['+replace(@idpaga,'-','')+']=annomese where idpaga='''+@idpaga+''''

--	print @sql

	exec (@sql)

	FETCH NEXT FROM CUR_TEMP INTO @idpaga,@annomese
END
CLOSE CUR_TEMP
DEALLOCATE CUR_TEMP	

--select * from #p order by DataCreazioneRecord asc


set @sql='select 
isnull(convert(varchar, DataCreazioneRecord, 103) + '' '' +convert(varchar, DataCreazioneRecord, 108),'''') [Data creazione],
IDpaga'

SELECT 
@sql=COALESCE(@sql+',','')+
	'[' + idelab  +'] as [Elaborazione_n.' + idelab  +']       '
FROM #t

set @sql=@sql+' from #p order by DataCreazioneRecord asc'

print @sql

exec (@sql)

GO
