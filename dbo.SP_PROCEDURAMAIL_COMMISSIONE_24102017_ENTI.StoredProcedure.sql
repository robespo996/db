USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_24102017_ENTI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_24102017_ENTI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICE       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Assemblea Regionale Puglia del 6 novembre 2017'
      SET @TESTO =
'<p>Si trasmette in allegato, su richiesta della Rappresentanza Regionale della Puglia, la Convocazione dell’Assemblea regionale che si terrà il   6 novembre p.v. alle ore 09:30 presso
<br/>
<br/><strong>CENTRO POLIFUNZIONALE PER GLI STUDENTI” (Ex Palazzo delle Poste)
<br/>Università degli studi di Bari “Aldo Moro” 
<br/>Piazza Cesare Battisti n. 1, Bari</strong></p>
<br/>
<p>Gli Enti in indirizzo sono pregati di dare massima diffusione tra i Volontari in servizio dell’evento </p>
<p>Cordialmente</p>
<p>Presidenza Del consiglio dei Ministri
<br/>Dipartimento della gioventù e del servizio civile nazionale
<br/>Commissione Elettorale</p>'



      DECLARE MYCUR CURSOR LOCAL FOR
            select CodiceRegione,EMAIL from [unscproduzione].[dbo].[_Mail_Commissione_24102017_Enti]
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Convocazione_Programma_Assemblea_Volontari_Regione_PUGLIA.pdf;d:\allegati\Locandina_Assemblea_Regionale_6-11-17.jpg'
            FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','afranze@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Convocazione_Programma_Assemblea_Volontari_Regione_PUGLIA.pdf;d:\allegati\Locandina_Assemblea_Regionale_6-11-17.jpg'







GO
