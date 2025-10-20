USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_26112024_ASSEMBLEA_LAZIO]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_26112024_ASSEMBLEA_LAZIO]

AS
DECLARE
			-- variabili obbligatorie
            @OGGETTO						VARCHAR(500),
            @TESTO							VARCHAR(8000),
            @TESTOAPPO						VARCHAR(8000),
            @MAIL							VARCHAR(500),
            @RETURN							BIT,
			@gruppo							INT
            
      SET @OGGETTO='Invito della Rappresentanza Lazio di Servizio civile universale all''assemblea locale di Novembre'

      SET @TESTO =
'
<p>Gentili operatrici, gentili operatori,</p>
<p>in occasione delle elezioni dei Delegati regionali degli operatori volontari del Servizio civile universale, che si terranno dal 2 al 11 dicembre 2024 alle ore 15:00 sulla piattaforma <a href="https://evol.serviziocivile.it/" title="Vai al sito delle elezioni dei volontari online">EVOL (Elezioni volontari online)</a>, la Rappresentanza degli Operatori Volontari della Regione Lazio ha organizzato un’assemblea online in data <b>28 novembre 2024 dalle ore 15:00 alle 17:00</b>.</p>
<p>La partecipazione è volontaria e le ore di assemblea sono da considerarsi come servizio svolto.</p>
<p>Il programma dell''Assemblea prevede:
<ol>
	<li>saluti della Rappresentanza;</li>
	<li>presentazione della procedura elettiva e dei programmi dei candidati;</li>
	<li>sessione di domande e risposte;</li>
	<li>varie ed eventuali.</li>
</ol>
</p>
<p>Per partecipare è necessario prima registrarsi utilizzando il seguente <i>link</i> e inserendo nome e cognome:</p>
<p><a href="https://events.teams.microsoft.com/event/fcacbc80-f936-47bc-a991-51f5030a298e@3e90938b-8b27-4762-b4e8-006a8127a119" title="Vai al link dell''assemblea">https://events.teams.microsoft.com/event/fcacbc80-f936-47bc-a991-51f5030a298e@3e90938b-8b27-4762-b4e8-006a8127a119</a></p>
<p>Partecipate numerosi e contribuite alla crescita del Servizio civile universale !</p>
<p>Per qualsiasi informazione, <b>puoi contattare i tuoi rappresentanti</b> all''indirizzo: <b><a href="mailto:delegazionelazioserviziocivile@gmail.com" title="Scrivi ai rappresentanti della Regione Lazio">delegazionelazioserviziocivile@gmail.com</a></b></p>

<br/><br/>
<p style="line-height:100%">
La Commissione elettorale<br/>
<b>Dipartimento per le Politiche giovanili e il Servizio civile universale</b>
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
	  -- select isnull(max(gruppo),0)+1 from _mail_gruppi_inviati_comm -- check collaudo

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  -- COMMENTA in modo da non aggiornare
	  --insert into _mail_gruppi_inviati_comm (gruppo) values (@gruppo) -- PRODUZIONE

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct 
				 email
			from [unscproduzione].[dbo]._Mail_Commissione_26112024_Assemblea_Lazio
			--where gruppo = @gruppo -- produzione
			order by 1
      
	  OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN

		-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
		EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Locandina_Presentazione_dei_candidati_a_Delegato_Regionale_Lazio.jpeg'
        FETCH NEXT FROM MYCUR INTO @MAIL

      END
CLOSE MYCUR
DEALLOCATE MYCUR

--produzione
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
--EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Locandina_Presentazione_dei_candidati_a_Delegato_Regionale_Lazio.jpeg'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;commissionelettorale@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Locandina_Presentazione_dei_candidati_a_Delegato_Regionale_Lazio.jpeg'

GO
