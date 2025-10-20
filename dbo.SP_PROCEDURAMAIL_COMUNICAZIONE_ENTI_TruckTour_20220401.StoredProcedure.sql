USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMUNICAZIONE_ENTI_TruckTour_20220401]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMUNICAZIONE_ENTI_TruckTour_20220401]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO            VARCHAR(max),
			@TESTOAPPO        VARCHAR(8000),
            @MAIL             NVARCHAR(200),
			@COGNOME          NVARCHAR(200),
			@NOME             NVARCHAR(200),
			@GENERE           CHAR,
            --@CODICEvolontario       VARCHAR(50),
            @RETURN           BIT,
            @gruppo           INT

      SET @OGGETTO='Campagna informativa NEet-Working tour'
      SET @TESTO =
'<div><p>Buongiorno<br/><br/>
desidero informarvi che sta per prendere il via il <strong>NEet-Working tour</strong> organizzato dal Dipartimento per le Politiche Giovanili e il Servizio civile Universale della Presidenza del Consiglio dei Ministri e dall''Agenzia Nazionale per i Giovani. E'' una campagna informativa, itinerante e partecipativa che animerà, nella prima fase,  11 comuni di Nord Centro e Sud Italia nel periodo compreso tra aprile e maggio 2022.
<br/><br/>
E'' un''occasione nuova e diversa per raccontare le opportunità messe in campo dal Governo e dall''Europa per le nuove generazioni e, al tempo stesso, fornire ai giovani esempi e modelli positivi da seguire, promuovendo momenti di ascolto e confronto attraverso gli strumenti più vicini al loro linguaggio.
<br/><br/>
Nell''Anno europeo dei giovani, il <strong>NEet-Working tour</strong> sarà una campagna per la comunicazione e la divulgazione di politiche ed azioni positive volte a favorire la partecipazione e l''inclusione sociale dei giovani, con particolare riferimento ai giovani NEET così come previsto nel Piano Neet adottato dai Ministri Dadone e Orlando il 19 gennaio 2022 https://www.politichegiovanili.gov.it/comunicazione/news/2022/1/firma-piano-neet/.
<br/><br/>
La campagna farà tappa nelle seguenti città:
<table style="width:30em">
	<tr>
		<td style="width:20%">11 aprile</td>
		<td>Torino</td>
	</tr>
	<tr>
		<td style="width:20%">11-12 aprile</td>
		<td>Alessandria</td>
	</tr>
	<tr>
		<td style="width:20%">20-21 aprile</td>
		<td>Genova</td>
	</tr>
	<tr>
		<td style="width:20%">22-23 aprile</td>
		<td>Brescia</td>
	</tr>
	<tr>
		<td style="width:20%">26-27 aprile</td>
		<td>Lucca</td>
	</tr>
	<tr>
		<td style="width:20%">28-29 aprile</td>
		<td>Chieti</td>
	</tr>
	<tr>
		<td style="width:20%">4-5 maggio</td>
		<td>Roma</td>
	</tr>
	<tr>
		<td style="width:20%">6-7 maggio</td>
		<td>Napoli</td>
	</tr>
	<tr>
		<td style="width:20%">10-11 maggio</td>
		<td>Matera</td>
	</tr>
	<tr>
		<td style="width:20%">13-14 maggio</td>
		<td>Brindisi</td>
	</tr>
	<tr>
		<td style="width:20%">17-18 maggio</td>
		<td>Cosenza</td>
	</tr>
	<tr>
		<td style="width:20%">21-23 maggio</td>
		<td>Palermo</td>
	</tr>
</table>
Per ogni tappa sarà allestito uno spazio "villaggio" informativo al centro del quale sarà collocato il Truck. Lateralmente saranno disposti stand, postazioni mobili e led videowall. L''allestimento mobile durerà due giorni per ogni comune individuato, occupando, in accordo con le amministrazioni coinvolte, una piazza/area abitualmente frequentata dai giovani.
<br/><br/>
Il Dipartimento sarà felice di accogliere nel villaggio del Truck gli operatori volontari del Servizio Civile del Suo ente per illustrare le opportunità e i progetti attualmente offerti ai giovani tra cui segnalo:
<ul>
	<li>la Carta giovani nazionale;</li>
	<li>il Portale giovani2030;</li>
	<li>le iniziative dell’Anno Europeo dei Giovani;</li>
	<li>il supporto personalizzato per la redazione di un curriculum vitae;</li>
	<li>la presentazione di un’app che permette di acquisire degli Open Badge da inserire nel proprio C.V. realizzata dalla fondazione Vodafone;</li>
	<li>progetti Erasmus e Corpo europeo di solidarietà;</li>
	<li>iniziative di Anpal e Garanzia Giovani.</li>
</ul>
Nel corso della giornata alcuni volontari, da voi segnalati,  saranno coinvolti in prima persona con interviste su ANGradio e testimonianze per raccontare la propria esperienza nel realizzare il progetto al quale hanno aderito.
<br/><br/>
<p>Per pianificare al meglio la partecipazione dei volontari contattare:
<table style="width:50em;">
	<tr>
		<td style="width:20%">Roberto Andreani</td>
		<td style="width:15%">392 0200576</td>
		<td>
			<a href="mailto:randreani@serviziocivile.it">randreani@serviziocivile.it</a> - <a href="mailto:comunicazione@serviziocivile.it">comunicazione@serviziocivile.it</a>
		</td>
	</tr>
	<tr>
		<td style="width:20%">Laura Pochesci</td>
		<td style="width:15%">349 6995418</td>
		<td><a href="mailto:lpochesci@serviziocivile.it">lpochesci@serviziocivile.it</a></td>
	</tr>
	<tr>
		<td style="width:20%">Roberta Borzi</td>
		<td style="width:15%">338 9231025</td>
		<td><a href="mailto:rborzi@serviziocivile.it">rborzi@serviziocivile.it</a></td>
	</tr>
</table>
</div>
<br/><br/>
Ringrazio in anticipo per la collaborazione.
<br/><br/>
Cons. Marco De Giorgi
</p>
</div>'

		  DECLARE MYCUR CURSOR LOCAL FOR
				select distinct EMAIL from _Mail_Comunicazione_Enti_TruckTour_20220401
				order by email
		  OPEN MYCUR
		  FETCH NEXT FROM MYCUR INTO @MAIL
		  WHILE @@Fetch_status = 0
		  BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\NEeT_Working_tour.pdf'
			
			FETCH NEXT FROM MYCUR INTO @MAIL
	      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
--EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\NEeT_Working_tour.pdf'
EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','','sviluppo@serviziocivile.it;comunicazione@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\NEeT_Working_tour.pdf'
GO
