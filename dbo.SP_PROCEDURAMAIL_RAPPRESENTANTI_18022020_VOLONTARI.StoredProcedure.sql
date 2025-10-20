USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_RAPPRESENTANTI_18022020_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_RAPPRESENTANTI_18022020_VOLONTARI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Servizio Civile 2020'
      SET @TESTO =
'
<p style="margin-bottom: 2em;">Cara volontaria, caro volontario,<p>
<p style="margin-bottom: 2em;">grazie al tuo Servizio e alla tua partecipazione il 2020 può essere un anno di svolta.</p>
<p style="margin-bottom: 2em;">Cogliamo l’occasione per ringraziare chi tra voi si appresta a terminare questo percorso. La vostra missione inizia proprio ora: mettere l''empatia e il senso civico che avete appreso in tutti i vostri rapporti futuri.</p>
<p style="margin-bottom: 2em;">Altri invece stanno iniziando, e a questi i nostri migliori auguri per un''avventura fantastica. Per qualunque esigenza potete fare affidamento su di noi, scrivendoci a <a href=''mailto:rappresentantinazionali@gmail.com''>rappresentantinazionali@gmail.com</a> o alla pagina Facebook (https://www.facebook.com/rappresentanzasc), che vi invitiamo a seguire per rimanere aggiornati sul sistema Servizio Civile e le nostre attività.</p>
<p style="margin-bottom: 2em;">Infine, vogliamo ringraziare chi di voi si è speso a sostenere la nostra petizione per aumentare i fondi per il Servizio Civile (http://chng.it/msZb5vkmwK), così da permettere ad altri di vivere quest’esperienza.</p>
<p style="margin-bottom: 2em;">In forza della vostra attenzione abbiamo incontrato il Ministro competente, l''On. Vincenzo Spadafora, il quale ha auspicato e immaginato per il sistema servizio civile una stabilizzazione della dotazione del Fondo Nazionale che possa permettere di avviare al servizio almeno 40mila volontari circa ogni anno, oltre a mostrarsi fiducioso per l''approvazione del Ddl da lui presentato per 70 milioni aggiuntivi al Fondo per l’anno 2020, tra gli altri ancora in discussione in Parlamento.</p>
<p style="margin-bottom: 2em;">Proprio in Parlamento si sono attivate diverse forze politiche: con un emendamento alla Legge di Bilancio dell''On. Francesca Bonomo è stato ottenuto un aumento del Fondo di 10 milioni aggiuntivi per il 2020.</p>
<p style="margin-bottom: 2em;">Ricordiamo che ad oggi i fondi destinati al Servizio Civile Legge di Bilancio sono, al netto dell''emendamento citato, 149 milioni euro. Permetteranno di avviare poco più di 25.000 operatori volontari a fronte dei circa 40mila avviati oggi, delle relative 85mila domande di partecipazione pervenute e, ancora, a fronte delle quasi100 mila che hanno caratterizzato le scorse annualità</p>
<p style="margin-bottom: 2em;">Per questo è necessario che continuiate a seguire la questione e pretendere dai nostri rappresentanti in Parlamento e dal Governo maggiori investimenti sui giovani. Lo stesso Presidente della Repubblica, Sergio Mattarella, nel suo discorso inaugurale di Padova Capitale Europea del Volontariato 2020 ha ricordato l''immenso valore umano del Servizio Civile ma anche l''insufficienza dei fondi.</p>
<p style="margin-bottom: 2em;">Di seguito/in allegato trovi il documento sottoposto e discusso con il Ministro Spadafora. Per maggiori informazioni sul nostro incontro visita la pagina Facebook: https://www.facebook.com/rappresentanzasc .</p>   
<p style="margin-bottom: 2em;">A proposito di cittadinanza attiva, trovi qui informazioni su come votare al referendum confermativo del 29 marzo 2020: https://www.politichegiovanilieserviziocivile.gov.it/dgscn-news/2020/2/avvisovotoreferendum.aspx </p>
<p style="margin-bottom: 2em;">Grazie di cuore per il vostro servizio.</p>
<p style="margin-bottom: 0em; margin-top: 2em; margin-left: 15em"><strong>Rappresentanza Nazionale operatori volontari del servizio civile universale</strong></p>  
<p style="margin-bottom: 0em; margin-top: 1em; margin-left: 25em"><strong>Feliciana Farnese</strong></p>
<p style="margin-bottom: 0em; margin-top: 0em; margin-left: 25em"><strong>Stefano Neri</strong></p>
<p style="margin-bottom: 0em; margin-top: 0em; margin-left: 25em"><strong>Giovanni Rende</strong></p>
<p style="margin-bottom: 0em; margin-top: 0em; margin-left: 25em"><strong>Michelangelo Vaselli</p>  
'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codicevolontario,EMAIL from [unscproduzione].[dbo].[_Mail_Rappresentanti_18022020_Volontari]
			where gruppo = 9
			--order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
          
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_RAPPRESENTANTIVOLONTARI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\Allegati\7_proposte_per_il_SC_al_Ministro_Spadafora.jpg'
            FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_RAPPRESENTANTIVOLONTARI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\Allegati\7_proposte_per_il_SC_al_Ministro_Spadafora.jpg'







GO
