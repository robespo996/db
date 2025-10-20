USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_01032017_ENTI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_01032017_ENTI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICE       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Comunicazione Assemblea Regionale'
      SET @TESTO =
'<p>Si trasmette su richiesta della Rappresentanza Regionale SC Friuli Venezia Giulia, il programma relativo all’assemblea regionale che si terrà il 13 marzo p.v.<p>
 <br/>
<p>Distinti saluti.</p>
<p>La Commissione Elettorale</p>
<p>commissioneelettorale@serviziocivile.it</p>'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codiceregione,EMAIL from [unscproduzione].[dbo].[_Mail_Commissione_01032017_Enti]
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Programma_Assemblea_regionale_FVG_13_marzo_2017.pdf'
            FETCH NEXT FROM MYCUR INTO @CODICE, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','mpetracca@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Programma_Assemblea_regionale_FVG_13_marzo_2017.pdf'






GO
