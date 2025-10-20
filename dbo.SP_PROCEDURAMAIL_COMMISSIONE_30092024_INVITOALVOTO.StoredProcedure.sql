USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_30092024_INVITOALVOTO]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_30092024_INVITOALVOTO]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT,
			@gruppo					INT
            
      SET @OGGETTO='Indizione delle elezioni per la Rappresentanza degli operatori volontari del Servizio civile universale'
      SET @TESTO =
'<p style="font-size: 1em">
Care operatrici volontarie, cari operatori volontari, 
<br/><br/>
si trasmette l''invito del capo Dipartimento delle politiche giovanili e del Servizio civile universale a partecipare attivamente all''elezione della Rappresentanza degli operatori del Servizio civile universale. I termini e le modalità per partecipare sono disponibili sul sito del dipartimento 
<br/><br/>
A seguire il testo dell''invito e in allegato la lettera a firma del capo Dipartimento.
<br/><br/>
Siate numerosi!
<br/><br/>
Commissione elettorale
</p>
<p style="font-size: 1em"><strong>Dipartimento delle politiche giovanili e del Servizio civile</strong></p>
<p style="font-size: 0.8em">
<strong>Ufficio per il Servizio civile universale</strong><br/>
Via della Ferratella in Laterano, 51 - 00184 ROMA<br/>
<i>commissioneelettorale@governo.it</i><br/>
<i><a href="https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/" title="Vai alla pagina delle Elezioni della Rappresentanza">Elezioni della Rappresentanza</a></i><br/>
<i><a href="https://www.politichegiovanili.gov.it/normativa/decreto-direttoriale/decreto_1724_2024_commelettorale/" title="Apri il decreto di nomina della Commissione Elettorale">Commissione elettorale</a></i>
</p>
<br/><br/><br/>
------------------------
<p  style="font-size: 0.8em">
Care operatrici volontarie, cari operatori volontari,<br/><br/>
come sapete il Decreto legislativo 6 marzo 2017, n. 40, ha istituzionalizzato la Rappresentanza degli operatori volontari del Servizio civile universale.<br/><br/>
La Rappresentanza ha l''obiettivo di garantire il confronto costante degli operatori volontari in servizio con la Presidenza del Consiglio dei ministri ed è proprio grazie a questo istituto che tutti gli operatori volontari possono prendere parte attivamente e concretamente allo sviluppo del nostro Servizio civile universale.<br/><br/>
Per questo ritengo sia importante assicurare la più ampia partecipazione alla procedura elettorale, che ha preso avvio il 18 settembre, sia attraverso la presentazione delle candidature al ruolo di delegato sia attraverso la partecipazione al voto da remoto La procedura, completamente digitalizzata, è accessibile dal sito internet <a href="https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/" title="Vai alla pagina delle Elezioni della Rappresentanza">https://politichegiovanili.gov.it</a>, alla voce "Elezioni", dove troverete tutte le informazioni relative alle operazioni di voto.<br/><br/> 
Nel ringraziarvi per l''attenzione e nel salutarvi, mi auguro che tutti voi vorrete esercitare con convinzione ed entusiasmo il vostro diritto di voto e che sarete in tanti a scegliere di candidarvi per contribuire a far crescere il Servizio civile universale.<br/><br/>
Michele Sciscioli
</p>
'

	  -- Legge l'ultimo gruppo inviato (1 se è il primo)
	  -- ATTENZIONE!! Svuotare(TRUNCATE table _mail_gruppi_inviati) prima di fare il primo invio massivo delle e-mail
	  select @gruppo = isnull(max(gruppo),0)+1 from _mail_gruppi_inviati

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  insert into _mail_gruppi_inviati (gruppo) values (@gruppo)

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct EMAIL 
			from [unscproduzione].[dbo].[_mail_commissione_30092024_INVITOALVOTO] 
			WHERE gruppo = @gruppo
			order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
           EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\ALLEGATI\ELEZIONI\Lettera_indizione_OV_2024.pdf'
           FETCH NEXT FROM MYCUR INTO @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','commissionelettorale@serviziocivile.it;sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\ALLEGATI\ELEZIONI\Lettera_indizione_OV_2024.pdf'

GO
