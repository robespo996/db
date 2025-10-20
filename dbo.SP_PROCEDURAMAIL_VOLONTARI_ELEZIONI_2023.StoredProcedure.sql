USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_VOLONTARI_ELEZIONI_2023]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_VOLONTARI_ELEZIONI_2023]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT,
			@gruppo					INT
            
      SET @OGGETTO='Indizione delle elezioni per la Rappresentanza degli operatori volontari del Servizio civile universale - lettera del Capo dipartimento agli operatori volontari'
      SET @TESTO =
'<p>Care operatrici volontarie, cari operatori volontari,</p>
<br>
<p>come sapete il Decreto legislativo 6 marzo 2017, n. 40, ha
istituzionalizzato la Rappresentanza degli operatori volontari del Servizio
civile universale.</p>
<br>
<p>La Rappresentanza ha l’obiettivo di garantire il confronto
costante degli operatori volontari in servizio con la Presidenza del Consiglio
dei ministri ed è proprio grazie a questo istituto, che tutti gli operatori
volontari possono prendere parte attivamente e concretamente allo sviluppo del
nostro Servizio civile universale.</p>
<br>
<p>Per questo ritengo sia importante assicurare la più ampia
partecipazione alle elezioni, che avranno inizio il prossimo 28 settembre con
la presentazione delle candidature per Delegato e si chiuderanno nel mese di
febbraio 2024, con il rinnovo di tutta la Rappresentanza. La partecipazione è
possibile da remoto, attraverso una procedura accessibile dal sito internet <a
href="https://politichegiovanili.gov.it">https://politichegiovanili.gov.it</a> ,
alla voce “Elezioni”, dove troverete anche tutte le informazioni relative alle
operazioni di voto.</p>
<br>
<p>Nel ringraziarvi per l’attenzione e nel salutarvi, mi auguro
che tutti voi vorrete esercitare con convinzione ed entusiasmo il vostro
diritto di voto e che sarete in tanti a scegliere di candidarvi per contribuire
a far crescere il Servizio civile universale.</p>
<br>
<p align=right style="text-align:right">Michele Sciscioli</p>'

	  -- Legge l'ultimo gruppo inviato (1 se è il primo)
	  -- ATTENZIONE!! Svuotare(TRUNCATE table _mail_gruppi_inviati) prima di fare il primo invio massivo delle e-mail
	  select @gruppo = isnull(max(gruppo),0)+1 from _mail_gruppi_inviati

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  insert into _mail_gruppi_inviati (gruppo) values (@gruppo)

      DECLARE MYCUR CURSOR LOCAL FOR
            select codicevolontario,EMAIL from [_Mail_Commissione_21092023_Volontari_DUMP]
where gruppo = 99  --Impostare gruppo uguale a 99 per non estrarre niente dalla select (solo per TEST con e-mail personale)
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
       EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\LetteraVolontari19set2023.pdf'  -- scommenta per inviare
            FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR

SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\LetteraVolontari19set2023.pdf'

GO
