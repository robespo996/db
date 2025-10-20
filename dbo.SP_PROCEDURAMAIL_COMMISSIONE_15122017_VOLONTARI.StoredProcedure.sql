USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_15122017_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_15122017_VOLONTARI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICE       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Elezioni rappresentanza 2018'
      SET @TESTO =
'<p>Il 15 dicembre 2017 sono indette le elezioni della rappresentanza dei volontari di servizio civile.
<br/>Al riguardo, si trasmette in allegato la comunicazione del Capo Dipartimento della Gioventù e del Servizio Civile Nazionale.
<br/>
<br/>La Commissione Elettorale
<br/>
<br/>Presidenza del Consiglio dei Ministri 
<br/>Dipartimento della Gioventù e del Servizio Civile Nazionale
<br/>Via della Ferratella in Laterano, 51 - 00184 Roma Tel. 06.67794027 - 06.67794303
<br/>commissioneelettorale@serviziocivile.it
</p>'




      DECLARE MYCUR CURSOR LOCAL FOR
            select CodiceVolontario,EMAIL from [unscproduzione].[dbo].[_Mail_Commissione_15122017_Volontari] 
			where gruppo = 10
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            set @oggetto = 'Elezioni rappresentanza 2018 - ' + @CODICE
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Lettera_Volontari_indizione.pdf'
            FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','afranze@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Lettera_Volontari_indizione.pdf'







GO
