USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_19112024_ASSEMBLEA_LOMBARDIA]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_19112024_ASSEMBLEA_LOMBARDIA]

AS
DECLARE
			-- variabili obbligatorie
            @OGGETTO						VARCHAR(500),
            @TESTO							VARCHAR(8000),
            @TESTOAPPO						VARCHAR(8000),
            @MAIL							VARCHAR(500),
            @RETURN							BIT,
			@gruppo							INT
            
      SET @OGGETTO='Non mancare all''Assemblea Regionale del Servizio Civile Universale!'

      SET @TESTO =
'
<p>Gentile operatrice, gentile operatore volontario,<br/>
con la presente ti ricordiamo che domani, 20 novembre 2024, la Rappresentanza degli operatori volontari della regione Lombardia ha organizzato un''assemblea Regionale degli Operatori Volontari del Servizio Civile, che si terrà presso <b>l''Auditorium Gaber, Piazza Duca D''Aosta 2, Milano, dalle ore 10:00 alle ore 13:00, con accredito previsto a partire dalle ore 9:00</b>.</p>
<p>Il programma dell''Assemblea prevede:</p>
<ul>
	<li>saluti istituzionali e della Rappresentanza;</li>
	<li>presentazione della procedura di rinnovo della Rappresentanza, dei candidati e dei loro programmi;</li>
	<li>sessione di domande e risposte;</li>
</ul>
<p>L''assemblea rappresenta un''occasione preziosa per rafforzare il legame tra gli operatori, ampliare la rete di contatti e dare voce alle tue idee. Non perdere questa opportunità di crescita e partecipazione!</p>
<p>La partecipazione è volontaria e le ore di assemblea sono da considerarsi come servizio svolto.</p>
<p>
È previsto il rimborso delle spese di viaggio, con le modalità indicate nell''allegato C della Circolare di indizione della procedura elettorale pubblicata in data 18 settembre 2024 e consultabile su<br/>
<a href="https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/" title="Vai alla pagina delle elezioni">https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/</a>.
</p>
<p><b>!! Per confermare la tua presenza scrivi semplicemente "Partecipo" al seguente indirizzo <a href="mailto:serviziocivile@regione.lombardia.it" title="Scrivi alla Regione Lombardia">serviziocivile@regione.lombardia.it</a> !!</b></p>
<p>Per ulteriori informazioni puoi scrivere a:</p>
<ul>
	<li><a href="mailto:serviziocivile@regione.lombardia.it" title="Scrivi alla Regione Lombardia">serviziocivile@regione.lombardia.it</a></li>
	<li><a href="mailto:rappresentanzasc.lombardia@gmail.com" title="Scrivi alla Rappresentanza della Regione Lombardia">rappresentanzasc.lombardia@gmail.com</a></li>
</ul>
<p>Augurandoci che tu possa partecipare, ti auguriamo buon lavoro.<br/><br/>
Cordialmente</p>

<p style="line-height:100%">
La Commissione elettorale<br/>
<b>Dipartimento delle politiche giovanili e del Servizio civile</b>
</p>
<p style="line-height:100%;font-size: 0.8em"><b><i>Ufficio per il Servizio Civile Universale</i></b><br/>
<i>Via della Ferratella in Laterano, 51</i><br/>
<i>00184 Roma</i><br/>
<i>commissioneelettorale@governo.it</i><br/>
<a href="https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/" title="Vai alla pagina delle elezioni"></i>Elezioni della Rappresentanza</i></a><br/>
<a href="https://www.politichegiovanili.gov.it/normativa/decreto-direttoriale/decreto_1724_2024_commelettorale/" title="Vai al decreto di istituzione della Commissione elettorale"><i>Commissione elettorale</i></a><br/><br/><br/>
</p>
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
			from [unscproduzione].[dbo].[_Mail_Commissione_19112024_Assemblea_Lombardia]
			--where gruppo = @gruppo -- produzione
			order by 1
      
	  OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN

		-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
		EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Locandina_Assemblea.png'
        FETCH NEXT FROM MYCUR INTO @MAIL

      END
CLOSE MYCUR
DEALLOCATE MYCUR

--produzione
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
--EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Locandina_Assemblea.png'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;commissionelettorale@serviziocivile.it;serviziocivile@regione.lombardia.it;rappresentanzasc.lombardia@gmail.com','','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Locandina_Assemblea.png'

GO
