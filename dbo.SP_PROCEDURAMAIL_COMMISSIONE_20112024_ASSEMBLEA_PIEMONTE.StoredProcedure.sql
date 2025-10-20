USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_20112024_ASSEMBLEA_PIEMONTE]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_20112024_ASSEMBLEA_PIEMONTE]

AS
DECLARE
			-- variabili obbligatorie
            @OGGETTO						VARCHAR(500),
            @TESTO							VARCHAR(8000),
            @TESTOAPPO						VARCHAR(8000),
            @MAIL							VARCHAR(500),
            @RETURN							BIT,
			@gruppo							INT
            
      SET @OGGETTO='Invito della Rappresentanza Piemonte di Servizio civile universale alle assemblee locali di Novembre'

      SET @TESTO =
'
<p>Gentili operatrici, gentili operatori,</p>
<p>in occasione delle elezioni dei Delegati regionali degli operatori volontari del Servizio civile universale, previste dal 2 al 11 dicembre alle ore 15:00 2024 sulla piattaforma <a href="https://evol.serviziocivile.it/" title="Vai al sito delle elezioni dei volontari online">EVOL (Elezioni volontari online)</a>, trasmettiamo in allegato l''invito della Rappresentanza degli Operatori Volontari della Regione Piemonte.</p>
<p>La partecipazione è volontaria e le ore di assemblea sono da considerarsi come servizio svolto.</p>
<p>È previsto il rimborso delle spese di viaggio, con le modalità indicate nell''allegato C della Circolare di indizione della procedura elettorale pubblicata in data 18 settembre 2024 e consultabile su 
<a href="https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/" title="Vai alla pagina delle elezioni">https://www.politichegiovanili.gov.it/servizio-civile/operatori-volontari/elezioni/</a>.
</p>
<p>Per qualsiasi informazione, <b>puoi contattare i tuoi rappresentanti</b> all''indirizzo: <b><a href="mailto:volontariscpiemonte@gmail.com" title="Scrivi ai rappresentanti del Piemonte">volontariscpiemonte@gmail.com</a></b></p>
<p>Cordialmente</p>

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
			from [unscproduzione].[dbo].[_Mail_Commissione_20112024_Assemblea_Piemonte]
			--where gruppo = @gruppo -- produzione
			order by 1
      
	  OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN

		-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
		EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Invito_Assemblea_Servizio_Civile_Piemonte.pdf'
        FETCH NEXT FROM MYCUR INTO @MAIL

      END
CLOSE MYCUR
DEALLOCATE MYCUR

--produzione
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
--EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Invito_Assemblea_Servizio_Civile_Piemonte.pdf'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;commissionelettorale@serviziocivile.it;','','',@OGGETTO ,@TESTO,'d:\allegati\ELEZIONI\Invito_Assemblea_Servizio_Civile_Piemonte.pdf'

GO
