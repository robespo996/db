USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_COMP_ESTRAI_ELENCO_ENTI_CONFERME_ASSENZE_MANCANTI]    Script Date: 14/10/2025 12:36:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
Name:             SP_COMP_ESTRAI_ELENCO_ENTI_CONFERME_ASSENZE_MANCANTI
Author:           Berardino Chirico
Type:             Stored procedure 
Create date:      29/01/2024
Change history    29/01/2024 - MEV-2023-00021 - Miglioramenti paghe
                  15/11/2025 - MEV-2023-00035 - Miglioramenti paghe

Description:      Estrae la lista di enti che ancora devono confermare le assenze/presenze dei VVOO per uno specifico mese.
                  Le assenze/presenze devono essere confermate entro il 10 del mese successivo al mese a cui si riferiscono
				  La lista è composta dagli enti che non hanno un'occorrenza, relativa all'anno/mese a cui si riferiscono, 
				  nella tabella EntiConfermaAssenze.

Parameters:       annoRif: Anno del periodo a cui si riferiscono le assenze/presenze
                  meseRif: Mese del periodo a cui si riferiscono le assenze/presenze
				  maxGiorno

*/

ALTER PROCEDURE [dbo].[SP_COMP_ESTRAI_ELENCO_ENTI_CONFERME_ASSENZE_MANCANTI]
	@annorif int,
	@meserif int,
	@maxgiorno int
AS

declare @annonotifica int,
        @mesenotifica int

if isnull(@annorif,0) * isnull(@meserif,0) = 0
BEGIN
	IF MONTH(GETDATE()) = 1
	BEGIN
		SET @annorif =  YEAR(getdate())-1
		SET @meserif = 12
	END
	ELSE
	BEGIN
		SET @annorif = YEAR(getdate())
		SET @meserif = month(getdate())-1
	END
END

set @annonotifica=@annorif
set @mesenotifica=@meserif+1

if @meserif=12
begin
   set @annonotifica=@annorif+1
   set @mesenotifica=1
end
else
begin
   set @annonotifica=@annorif
   set @mesenotifica=@meserif+1
end

if isnull(@maxgiorno,1)<0 set @maxgiorno=31

/*
print '@annorif '+convert(varchar,@annorif)
print '@meserif '+convert(varchar,@meserif)
print '@maxgiorno '+convert(varchar,@maxgiorno)
print '@annonotifica '+convert(varchar,@annonotifica)
print '@mesenotifica '+convert(varchar,@mesenotifica)
*/

declare @temp1 table (
	idEnte int,
	dataNotifica datetime
)


declare @TempDestinationTable table (
	idEnte int,
	dateNotifica varchar(1000)
)


insert into @temp1
select distinct * from (
	select IdEnte, datanotifica from NOTIFICA_GESTIONE_ASSENZE_ENTI  
		where year(datanotifica)=@annonotifica and month(datanotifica)=@mesenotifica and ((anno is null) or (mese is null))
	UNION
	select IdEnte, datanotifica from NOTIFICA_GESTIONE_ASSENZE_ENTI  
		where isnull(anno,0)=@annorif and isnull(mese,0)=@meserif
) t


/*
select * from @temp1 where IdEnte=51117
select * from NOTIFICA_GESTIONE_ASSENZE_ENTI where IdEnte=51117
*/

insert into @TempDestinationTable
select p.idente,
STUFF((
SELECT ' ' + convert(varchar,innerTable.datanotifica,103) + '_' +convert(varchar,innerTable.datanotifica,108)
FROM @temp1 AS innerTable
WHERE innerTable.idente = p.idente-- and year(datanotifica)=@annonotifica and  month(datanotifica)=@mesenotifica
FOR XML PATH('')
),1,1,'') AS datenotifica
--into #TempDestinationTable
from  @temp1 p
/*
(
select * from NOTIFICA_GESTIONE_ASSENZE_ENTI  
where year(datanotifica)=@annonotifica and month(datanotifica)=@mesenotifica and (isnull(anno,0) * isnull(mese,0)) = 0
UNION
select * from NOTIFICA_GESTIONE_ASSENZE_ENTI  
where anno=@annonotifica and mese=@mesenotifica
) p
*/
group by p.idente

/*
update @TempDestinationTable set datenotifica = ltrim(rtrim(datenotifica))
update @TempDestinationTable set datenotifica = replace(datenotifica,' ','<BR>')
update @TempDestinationTable set datenotifica = replace(datenotifica,'_',' ')
update @TempDestinationTable set datenotifica = '<SPAN>'+datenotifica+'</SPAN>'
*/
update @TempDestinationTable set datenotifica = 
	'<SPAN>' +
	REPLACE(
		REPLACE(
			ltrim(rtrim(datenotifica))
			,' ','<BR>'
		)
		,'_',' '
	)
	+'</SPAN>'


select 
a.idente, a.codiceregione as CodiceEnte, a.denominazione as Ente, 
a.prefissotelefonorichiestaregistrazione + ' ' + a.telefonorichiestaregistrazione as telefono, 
a.email, a.emailcertificata
,datenotifica
,b.DataConferma
from
	(select enti.*,TDT.datenotifica from @TempDestinationTable TDT
	   INNER JOIN enti with (nolock) ON TDT.IDENTE = ENTI.IDENTE
) as a
	   LEFT outer JOIN (select * from dbo.EntiConfermaAssenze with (nolock) where anno = @annorif and mese = @meserif) as b
	ON A.IDENTE = B.IDENTE
	WHERE (B.IDENTE IS NULL or day(dataconferma)>@maxgiorno)
order by a.idente asc


/*
test 
--insert into NOTIFICA_GESTIONE_ASSENZE_ENTI values(51117, 'XENTRA GIOVANI APS', 'xentragiovani@gmail.com', getdate(),10,2023)
execute SP_COMP_ESTRAI_ELENCO_ENTI_CONFERME_ASSENZE_MANCANTI 2024,12,0

select * from NOTIFICA_GESTIONE_ASSENZE_ENTI where IdEnte=51117

select * from NOTIFICA_GESTIONE_ASSENZE_ENTI order by idnotifica desc
*/
GO
