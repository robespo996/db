USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_CONTROLLO_CAPIENZA_SEDI_SU_VERIFICHE]    Script Date: 14/10/2025 12:36:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Creata da Rocco Macioce il 7 aprile 2011
--Verifica la presenza di almeno un volontario su sedi programmate per le verifiche
--27/10/2011 Richiesta modifica per le solo Verifiche nello stato di "Aperta" e "In Esecuzione"

ALTER PROCEDURE [dbo].[SP_CONTROLLO_CAPIENZA_SEDI_SU_VERIFICHE] 
AS
BEGIN

	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_Appo_SediVerifiche_TMP]') AND type in (N'U'))
	DROP TABLE [dbo].[_Appo_SediVerifiche_TMP]
	
	select g.descrizione as Programmazione,h.statoverifiche as StatoVerifica, c.IDentesedeattuazione as SedeAttuazione,
	e.codiceente as CodiceProgetto,e.titolo as Progetto,f.codiceregione as CodiceEnte,f.denominazione as Ente,
	(v.cognome + ' ' + v.nome) as Verificatore,
	(select count(distinct ae.identit�) from attivit� att with (nolock)
	inner join   attivit�entisediattuazione aesa with (nolock) on att.IDAttivit� =aesa.IDAttivit� 
	inner join attivit�entit� ae with (nolock) on ae.IDAttivit�entesedeattuazione =aesa.IDAttivit�entesedeattuazione 
	inner join entit� e with (nolock) on ae.identit� =e.identit�
	where idstatoentit� =3 and ae.idstatoattivit�entit�=1 
	and ae.IDAttivit�entesedeattuazione=c.IDAttivit�entesedeattuazione) as NVolontari
	--a.idprogrammazione ,a.idverifica,
	into #tmp
	from tverifiche a 
	inner join tverificheassociate b with (nolock) on a.idverifica=b.idverifica
	inner join attivit�entisediattuazione c with (nolock) on b.IDAttivit�entesedeattuazione=c.IDAttivit�entesedeattuazione
	inner join attivit� e with (nolock) on c.idattivit�=e.idattivit�
	inner join enti f with (nolock)on e.identepresentante=f.idente
	inner join tverificheprogrammazione g with (nolock)on g.idprogrammazione=a.idprogrammazione
	inner join tverifichestati h with (nolock)on h.idstatoverifiche=a.idstatoverifica
	inner join tverificheverificatori k with (nolock)on k.idverifica=a.idverifica
	inner join tverificatori v with (nolock)on v.idverificatore=k.idverificatore 
	where g.datafinevalidit�> getdate() and g.idregcompetenza=22
	and e.IDStatoAttivit� = 1 AND e.DataFineAttivit�>getdate() and idstatoverifica in (5,6)

	--drop table #tmp
	select * into _Appo_SediVerifiche_TMP from #tmp where NVolontari=0


	IF EXISTS(select * from _Appo_SediVerifiche_TMP)
		BEGIN
			DECLARE @tableHTML  NVARCHAR(MAX);
			SET @tableHTML =
			N'<H1>Anomalie Capienza Sedi Verifiche</H1>' +
			N'<table border="1">' +
			N'<tr><th>Programmazione</th><th>Stato Verifica</th>' +
			N'<th>Sede Attuazione</th><th>Codice Progetto</th><th>Progetto</th>' +
			N'<th>Codice Ente</th><th>Ente</th>' +
			N'<th>Verificatore</th><th>NVolontari</th></tr>' +
			CAST ( ( SELECT td = Programmazione,       '',
							td = StatoVerifica, '',
							td = SedeAttuazione, '',
							td = CodiceProgetto, '',
							td = Progetto, '',
							td = CodiceEnte, '',
							td = Ente, '',
							td = Verificatore, '',
							td = NVolontari , ''
					  FROM _Appo_SediVerifiche_TMP 
					  FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;

			EXEC  dbo.SSIS_sp_send_dbmail
				@profile_name = 'UNSC',
				@recipients = 'heliosweb@serviziocivile.it',
				@subject    = 'ANOMALIE CAPIENZA SEDI VERIFICHE',
				@body = @tableHTML,
				@body_format = 'HTML'
		END

END


 
GO
