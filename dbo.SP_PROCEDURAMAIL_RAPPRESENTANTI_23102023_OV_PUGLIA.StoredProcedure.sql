USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_RAPPRESENTANTI_23102023_OV_PUGLIA]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_RAPPRESENTANTI_23102023_OV_PUGLIA]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT,
			@gruppo					INT
            
      SET @OGGETTO='Servizio civile universale - inoltro convocazione Assemblea regionale Puglia - giovedì 26 ottobre 2023'
      SET @TESTO =
'<p>Gentili Operatori Volontari,</p>
<p>con la presente vi informiamo che, la Delegazione Puglia, in vista delle elezioni dei delegati regionali che si terranno dall''11 dicembre al 15 dicembre 2023, ha organizzato, per <strong>giovedì 26 ottobre 2023, un''assemblea tematica sulla Rappresentanza degli operatori volontari in modalità telematica su Piattaforma Teams.</strong></p>
<p>Sarà occasione gradita per formare i volontari riguardo l’intero sistema di rappresentanza degli operatori volontari di Servizio Civile Universale e per informare della possibilità, fino al 3 novembre, di candidarsi come delegato/a regionale ed essere protagonista di questa straordinaria esperienza. </p>
<p>A presenziare l’incontro ci sarà la Delegazione attualmente in carica che potrà rispondere ad eventuali dubbi o perplessità.<br/>L’obiettivo principale è quello di incentivare i volontari a partecipare alla tornata elettorale che avrà luogo nel mese di dicembre come specificato sopra.</p>
<p>All’incontro potranno partecipare tutti gli operatori volontari attualmente in servizio in Puglia.</p>
<p>Si allega link per partecipare all’assemblea e la locandina dell’evento.</p>
<p>Si auspica ampia partecipazione.</p>
<p>La Delegazione Puglia – Rappresentanza operatori volontari Servizio civile Universale</p>
<p style="font-size: 18px">Riunione di Microsoft Teams</p>
<p>Partecipa da computer, app per dispositivi mobili o dispositivo della stanza</p>
<p><a href="https://teams.microsoft.com/l/meetup-join/19%3ameeting_MDc4ZTRhZWMtMWZhZC00YjUxLTk4Y2ItYzZjY2I5MDY0YjFh%40thread.v2/0?context=%7b%22Tid%22%3a%22c6328dc3-afdf-40ce-846d-326eead86d49%22%2c%22Oid%22%3a%228a449827-4a46-4d72-a072-38089a580c2a%22%7d">Fai clic qui per partecipare alla riunione</a></p>
<p>ID riunione: 358 365 590 221</p>
<p>Passcode: RyA6GF</p>
<br/><br/>
<p>Delegazione Puglia - Rappresentanza Volontari Servizio Civile</p>
<p>Indirizzo mail: rappresentanzascn.puglia@gmail.com<br/>
Facebook: Servizio Civile-Delegazione Puglia<br/>
Instagram: servizio_civile_puglia
</p>
'
	  -- Legge l'ultimo gruppo inviato (1 se è il primo)
	  -- ATTENZIONE!! Svuotare(TRUNCATE table _mail_gruppi_inviati) prima di fare il primo invio massivo delle e-mail
	  --select @gruppo = isnull(max(gruppo),0)+1 from _mail_gruppi_inviati

	  -- Scrive il gruppo da inviare nella tabella dei gruppi inviati
	  --insert into _mail_gruppi_inviati (gruppo) values (@gruppo)

      DECLARE MYCUR CURSOR LOCAL FOR
            --select codicevolontario,EMAIL from [unscproduzione].[dbo]._Mail_Rappresentanti_23102023_OV_Puglia
			--where gruppo = @gruppo
			select codicevolontario,EMAIL from [unscproduzione].[dbo]._Mail_Rappresentanti_23102023_OV_Puglia
				where email not in 
				(select recipients
				from msdb.dbo.sysmail_allitems
				where 
				sent_status = 'sent' and
				sent_date > '23-10-2023 21:00' and
				profile_id = 7)
			order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
          
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_RAPPRESENTANTIVOLONTARI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Mi_candido_perche.pdf'
            FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_RAPPRESENTANTIVOLONTARI] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Mi_candido_perche.pdf'





GO
