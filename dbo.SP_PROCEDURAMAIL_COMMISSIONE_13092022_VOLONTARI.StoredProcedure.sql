USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_13092022_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_13092022_VOLONTARI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Indizione delle elezioni per la Rappresentanza degli operatori volontari del Servizio civile universale'
      SET @TESTO =
'<p>Si trasmette la lettera con la quale il Capo del Dipartimento per le Politiche giovanili e il Servizio civile universale comunica l''indizione delle elezioni per la rappresentanza degli operatori volontari del servizio civile universale.<p>
 <br/>
<p>Distinti saluti.</p>
<p>La Commissione Elettorale</p>
<p>commissioneelettorale@serviziocivile.it</p>'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codicevolontario,EMAIL from [unscproduzione].[dbo].[_Mail_Commissione_13092022_Volontari] where gruppo=0
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
           EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI_SCU] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Lettera Volontari_12set2022-signed.pdf'
           FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI_SCU] '','','informatica@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Lettera Volontari_12set2022-signed.pdf'





GO
