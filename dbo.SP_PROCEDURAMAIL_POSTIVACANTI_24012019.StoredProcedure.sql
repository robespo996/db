USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_POSTIVACANTI_24012019]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_POSTIVACANTI_24012019]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @IDENTITA       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Comunicazione ai giovani idonei non selezionati – bandi 20 agosto 2018: possibilità di ricoprire posti vacanti in altri progetti'
      SET @TESTO =
'<p>Il 14 gennaio u.s. sono state adottate le "Disposizioni concernenti la disciplina dei rapporti tra enti e operatori volontari del servizio civile universale" che sostituiscono il "Prontuario concernente la disciplina dei rapporti tra enti e volontari del Servizio civile nazionale" del 2015.<p>
<p>Tra le novità introdotte dalle nuove disposizioni, e precisamente all’art. 3, è prevista <strong>la possibilità per i giovani risultati idonei non selezionati, se interessati, di poter essere assegnati in altri progetti che presentano posti vacanti.</strong></p>
<p>Si invitano, pertanto, i giovani idonei non selezionati, se interessati, a contattare gli enti presso cui hanno presentato domanda per conoscere quali enti hanno disponibilità di posti per progetti affini, così da poter essere eventualmente impiegati in altro progetto.</p>
<p>Cordialmente</p>
<p>Presidenza del Consiglio dei Ministri<br/>
Dipartimento della Gioventù e del Servizio Civile Nazionale</p>
<br/>
<br/>
<strong>La presente e-mail è stata generata automaticamente da un indirizzo di posta elettronica di solo invio; si chiede pertanto di non rispondere al messaggio.<strong>' 

      DECLARE MYCUR CURSOR LOCAL FOR
            select identità,EMAIL from [unscproduzione].[dbo].[_Mail_Postivacanti_24012019_Volontari]
			where gruppo = 8
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @IDENTITA, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_POSTIVACANTI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Avviso_ai_volontari_idonei_non_selezionati.pdf'
            FETCH NEXT FROM MYCUR INTO @IDENTITA, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_POSTIVACANTI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Avviso_ai_volontari_idonei_non_selezionati.pdf'





GO
