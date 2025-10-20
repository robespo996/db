USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_27022024_OV_CALABRIA]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_27022024_OV_CALABRIA]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Servizio civile universale - Convocazione Assemblea Regionale Calabria - 6 marzo 2024 ore 9:30'
      SET @TESTO =
'<p>
Gentili Operatori Volontari,<br/>
con la presente vi informiamo che la Delegazione Calabria ha organizzato per <i><strong>mercoledì 6 marzo 2024, dalle ore 9:30 alle 13:30</strong></i>, l''Assemblea regionale presso la sede della Regione Calabria in <i><strong>Viale Europa, Cittadella Regionale - Località Germaneto, 88100 Catanzaro</strong></i>.
<br/>All''incontro potranno partecipare tutti gli operatori volontari attualmente in servizio in Calabria.
<br/>Si ricorda che il giorno di partecipazione è considerato a tutti gli effetti  servizio svolto ai sensi dell''Allegato B ‘Linee guida in materia di Rappresentanza degli operatori volontari di Servizio Civile Universale’.
<br/><br/>L''evento si terrà in modalità mista, fisica e virtuale. Si allega la locandina con i dettagli dell''incontro e l’apposito collegamento per la conferenza online:
<br/>https://teams.live.com/meet/9411809442553?p=3v9BNWXUpM7Vo7De
<br/><br/><br/>
Delegazione Calabria – Rappresentanza operatori volontari Servizio civile Universale
</p>
'

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct EMAIL from [unscproduzione].[dbo].[_mail_commissione_27022024_ov_Calabria] order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
           EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Programma_assemblea_regionale_Calabria.pdf'
           FETCH NEXT FROM MYCUR INTO @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','commissionelettorale@serviziocivile.it;sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Programma_assemblea_regionale_Calabria.pdf'
--EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Programma_assemblea_regionale_Calabria.pdf'

GO
