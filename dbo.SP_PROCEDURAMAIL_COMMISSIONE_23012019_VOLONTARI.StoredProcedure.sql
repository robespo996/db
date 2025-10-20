USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_23012019_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_23012019_VOLONTARI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Comunicazione Delegazione Abruzzo SCN'
      SET @TESTO =
'<p>Si trasmette in allegato, la comunicazione della Delegazione Abruzzo SCN<p>
 <br/>
<p>Cordialmente</p>
<p>La Commissione Elettorale<br/>
Presidenza del Consiglio dei Ministri<br/>
Dipartimento della Gioventù e del Servizio Civile Nazionale<br/>
commissioneelettorale@serviziocivile.it<br/>
tel: 06 6779/4027/4303</p>'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codicevolontario,EMAIL from [unscproduzione].[dbo].[_Mail_Commissione_23012019_Volontari]
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'delegazioneabruzzo.snc@gmail.com','',@OGGETTO ,@TESTO,'d:\allegati\Lettera_ai_Volontari_di_SCN_Abruzzo.pdf'
            FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','mpetracca@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Lettera_ai_Volontari_di_SCN_Abruzzo.pdf'





GO
