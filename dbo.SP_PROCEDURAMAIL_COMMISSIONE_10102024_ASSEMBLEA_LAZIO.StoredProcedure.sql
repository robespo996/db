USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_10102024_ASSEMBLEA_LAZIO]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_10102024_ASSEMBLEA_LAZIO]

AS
DECLARE
			-- variabili obbligatorie
            @OGGETTO						VARCHAR(500),
            @TESTO							VARCHAR(8000),
            @TESTOAPPO						VARCHAR(8000),
            @MAIL							VARCHAR(500),
            @RETURN							BIT,
			@gruppo							INT
            
      SET @OGGETTO='Invito Assemblea Rappresentanza Lazio – 15 ottobre 2024'

      SET @TESTO =
'
<p style="line-height:100%">
Gentile operatrice e gentile operatore volontario,<br/>
si trasmette l''invito della Rappresentanza Lazio all''assemblea in oggetto.</br>
</p>

<p style="line-height:100%">
La Commissione elettorale<br/>
<b>Dipartimento delle politiche giovanili e del Servizio civile</b>
</p>

<p style="line-height:100%;font-size: 0.8em"><b><i>Ufficio per il Servizio Civile Universale</i></b><br/>
<i>Via della Ferratella in Laterano, 51</i><br/>
<i>00184 Roma</i><br/>
<i>commissioneelettorale@governo.it</i><br/>
<a href="https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/" title="Vai alla pagina delle elezioni"></i>Elezioni della Rappresentanza</i></a><br/>
<a href="https://www.politichegiovanili.gov.it/normativa/decreto-direttoriale/decreto_1724_2024_commelettorale/" title="Vai al decreto istituzione della commissione elettorale"><i>Commissione elettorale</i></a><br/>
</p>

<p style="text-align:justify; line-height:100%; margin: 0"><br/>
"<b>Alla Vostra cortese attenzione</b><br/><br/>
Gentili,<br/><br/>
vi aspettiamo <b>martedì 15 ottobre dalle 9.30 alle 13.30</b>, all''evento "Assemblea Regionale Giovani e Servizio Civile Lazio" (che si terrà da remoto e in presenza presso il Dipartimento Sport e Politiche Giovanili di Roma Capitale).<br/><br/>
Programma dei lavori:<br/><br/>
<ol>
	<li>Accoglienza e saluti istituzionali;</li>
	<li>Il Ruolo della Rappresentanza (con il contributo speciale del Dottor Francesco Spagnolo);</li>
	<li>Elezioni e Partecipazione;</li>
	<li>Contributo di Enti, Operatori, autorità, Rappresentanti e Delegati;</li>
	<li>Conclusione dei lavori e saluti finali.</li>
</ol>
Inoltre, verrà rilasciato "istantaneamente" a tutti al termine dell''evento un attestato di partecipazione con le attività svolte durante l''Assemblea.<br/><br/>
Per i giovani in Servizio Civile la partecipazione è volontaria ed è un diritto fondamentale e costituisce orario di servizio.<br/><br/>
L’Assemblea può essere seguita da casa o da altro luogo alternativo alla sede di servizio.<br/><br/>
Comunichiamo, di seguito, i link Teams utili per la partecipazione da remoto all''Assemblea Regionale:<br/><br/>
Link 1 - <a href="https://teams.microsoft.com/l/meetup-join/19%3ameeting_MmY0NTE1ZDItNzA3My00MmQxLTk0MWMtOGY1NjZiOWNkY2Jh%40thread.v2/0?context=%7b%22Tid%22%3a%22650e9622-dace-4a1d-8610-cc91a95e22ca%22%2c%22Oid%22%3a%2266ad0c2c-99e4-4de9-8857-fd7ca84c03fa%22%7d" title="Vai al link principale della riunione">https://teams.microsoft.com/l/meetup-join/19%3ameeting_MmY0NTE1ZDItNzA3My00MmQxLTk0MWMtOGY1NjZiOWNkY2Jh%40thread.v2/0?context=%7b%22Tid%22%3a%22650e9622-dace-4a1d-8610-cc91a95e22ca%22%2c%22Oid%22%3a%2266ad0c2c-99e4-4de9-8857-fd7ca84c03fa%22%7d</a>
<br/><br/>
Link 2 - Inseriamo anche il <b>link di riserva</b> (qualora si verifichino problemi con il primo link) - <a href="https://teams.microsoft.com/l/meetup-join/19%3ameeting_ZDNkODdiNzctM2FiMi00ZmZlLWJlZWYtYzliYWMwN2ZhYWQ2%40thread.v2/0?context=%7b%22Tid%22%3a%22650e9622-dace-4a1d-8610-cc91a95e22ca%22%2c%22Oid%22%3a%2266ad0c2c-99e4-4de9-8857-fd7ca84c03fa%22%7d" title="Vai al link alternativo della riunione">https://teams.microsoft.com/l/meetup-join/19%3ameeting_ZDNkODdiNzctM2FiMi00ZmZlLWJlZWYtYzliYWMwN2ZhYWQ2%40thread.v2/0?context=%7b%22Tid%22%3a%22650e9622-dace-4a1d-8610-cc91a95e22ca%22%2c%22Oid%22%3a%2266ad0c2c-99e4-4de9-8857-fd7ca84c03fa%22%7d</a>
<br/><br/>
Cordiali saluti,
</p>
<br/>
<p style="text-align:justify; line-height:100%; margin: 0">
Rappresentanza Lazio del Servizio civile universale<br>
<a href="mailto:delegazionelazioserviziocivile@gmail.com">delegazionelazioserviziocivile@gmail.com</a>"</p>
'
	  -- Legge l'ultimo gruppo inviato (1 se è il primo)
	  -- ATTENZIONE!! Svuotare(TRUNCATE table _mail_gruppi_inviati_comm) prima di fare il primo invio massivo delle e-mail
	  --select @gruppo = isnull(max(gruppo),0)+1 from _mail_gruppi_inviati_comm
	  -- select isnull(max(gruppo),0)+1 from _mail_gruppi_inviati -- check collaudo

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  -- COMMENTA in modo da non aggiornare
	  --insert into _mail_gruppi_inviati_comm (gruppo) values (@gruppo) -- PRODUZIONE

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct 
				 email
			from [unscproduzione].[dbo].[_Mail_Commissione_10102024_Assemblea_Lazio]
			--where gruppo = @gruppo -- produzione
			order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN

			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
			EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\elezioni\Locandina_Assemblea_Regionale_Lazio_GSC.jpeg'
            FETCH NEXT FROM MYCUR INTO @MAIL

      END
CLOSE MYCUR
DEALLOCATE MYCUR

--produzione
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it,commissionelettorale@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\elezioni\Locandina_Assemblea_Regionale_Lazio_GSC.jpeg'
--EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;marsimang@gmail.com','','',@OGGETTO ,@TESTO,'d:\allegati\elezioni\Locandina_Assemblea_Regionale_Lazio_GSC.jpeg'

GO
