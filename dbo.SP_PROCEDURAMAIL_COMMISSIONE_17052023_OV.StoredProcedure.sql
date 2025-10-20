USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_17052023_OV]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_17052023_OV]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT,
			@gruppo					INT
            
      SET @OGGETTO='Assemblea Regione Campania'
      SET @TESTO =
'<p>Su richiesta della delegazione Campania, si trasmette l''invito in allegato.</p>'
	  -- Legge l'ultimo gruppo inviato (1 se è il primo)
	  -- ATTENZIONE!! Svuotare(TRUNCATE table _mail_gruppi_inviati) prima di fare il primo invio massivo delle e-mail
	  select @gruppo = isnull(max(gruppo),0)+1 from _mail_gruppi_inviati

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  insert into _mail_gruppi_inviati (gruppo) values (@gruppo)

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct EMAIL from [unscproduzione].[dbo]._mail_Commissione_17052023_OV
			where gruppo = @gruppo
			order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
          
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Assemblea_Regione_Campania.pdf'
            FETCH NEXT FROM MYCUR INTO @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it;commissionelettorale@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Assemblea_Regione_Campania.pdf'










GO
