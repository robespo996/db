USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_15072020_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_15072020_VOLONTARI]
AS
DECLARE
            @OGGETTO				VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL					VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
			@COGNOME				VARCHAR(255),
			@NOME			        VARCHAR(255),
            @RETURN                 BIT
            
	  
	  SET @OGGETTO='Indizione delle elezioni per la Rappresentanza degli  operatori volontari del Servizio civile universale'
      SET @TESTO =
'<p>Si trasmette la lettera con la quale il Capo del Dipartimento per le Politiche giovanili e il Servizio civile universale comunica l''indizione delle elezioni per la rappresentanza degli operatori volontari del servizio civile universale.</p>' +
'<p>Cordialmente<br/>
La Commissione Elettorale</p>'

      DECLARE MYCUR CURSOR LOCAL FOR
			select codicevolontario,EMAIL from [_Mail_Commissione_15072020_Volontari]
			where gruppo = 9 

		 
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
		    
	   -- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
       EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\Allegati\lettera_rappresentanza_15072020.pdf'  
       
	   FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\Allegati\lettera_rappresentanza_15072020.pdf'





GO
