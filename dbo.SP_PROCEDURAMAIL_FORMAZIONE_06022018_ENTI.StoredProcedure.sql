USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_FORMAZIONE_06022018_ENTI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_FORMAZIONE_06022018_ENTI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICE       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='AVVISO - Mancato invio allegati formazione'
      SET @TESTO =
'<p>In riferimento a quanto indicato nell’avviso pubblicato sul sito del Dipartimento in data 9/5/2017 (sezione News) si ricorda a tutti gli enti di servizio civile che, ai sensi del nuovo prontuario contenente le caratteristiche e le modalità per la redazione e la presentazione dei progetti di servizio civile nazionale da realizzarsi in Italia e all''estero, nonché i criteri per la selezione e la valutazione degli stessi, approvato con D.M. 5 maggio 2016,  e  del documento di programmazione finanziaria relativo all''impiego delle risorse del Fondo nazionale per il servizio civile per l''anno 2016, per avere diritto all''erogazione del contributo per la formazione generale, a partire dai progetti avviati da settembre 2016, oltre all''invio del Modulo F, devono anche essere  trasmessi, a mezzo pec (dgioventuescn@pec.governo.it ), all''attenzione dei  Servizi Formazione, programmazione, monitoraggio e controllo (ora Servizio Affari Generali e Personale settore Formazione) e Amministrazione e bilancio, i  modelli in allegato, debitamente compilati, di cui  uno per  progetti in Italia e l''altro per i progetti all''estero.
 <p>Da controlli effettuati abbiamo riscontrato che il vs. Ente non ha provveduto al suddetto invio e chiediamo quindi di far pervenire a questo Dipartimento,  all’attenzione dei sopracitati servizi, i modelli in allegato (Allegato N.1 per l’Italia, Allegato N.2 per l’estero), indicando il codice del Modulo F a cui si riferiscono, riportato in basso a sinistra  nel citato Modulo e specificando nell’oggetto: Allegato ad integrazione del Modulo F.
<br>
<br/>Invitiamo gli enti, per il futuro, ad inviare a questo Dipartimento i citati modelli unitamente al Modulo F.
<br/>
<br/>
<br/>Cordialmente
<br/>
<br/>F.  Visicchio
<br/>
<br/>Dott.Francesco Visicchio
<br/>Dirigente
<br/>
<br/>Presidenza del Consiglio dei Ministri 
<br/>Dipartimento della Gioventù e del Servizio Civile Nazionale
<br/>Ufficio Organizzazione e Comunicazione
<br/>Servizio Affari Generali e Personale
<br/>Via della Ferratella in Laterano, 51 - 00184 Roma
<br/>Tel. 06-67793060
<br/>fvisicchio@serviziocivile.it'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codiceregione,EMAIL from [unscproduzione].[dbo].[_Mail_Formazione_06022018_Enti]
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_FORMAZIONE] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\MODELLO_ALLEGATO_1_ ITALIA.docx;d:\allegati\MODELLO__ALLEGATO_2_ ESTERO.docx'
            FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_FORMAZIONE] '','','afranze@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\MODELLO_ALLEGATO_1_ ITALIA.docx;d:\allegati\MODELLO__ALLEGATO_2_ ESTERO.docx'






GO
