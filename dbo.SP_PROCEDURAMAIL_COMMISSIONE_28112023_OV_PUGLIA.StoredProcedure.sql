USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_28112023_OV_PUGLIA]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_28112023_OV_PUGLIA]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Servizio civile universale - Assemblea regionale Puglia – Elezioni 2023 presentazione candidati – 7/12  dalle ore 10 alle 12:30'
      SET @TESTO =
'<p>
Gentili Operatori Volontari,<br /><br />
con la presente vi informiamo che, la Delegazione Puglia, in vista delle elezioni dei delegati regionali che si terranno dall''11 dicembre al 15 dicembre 2023, ha organizzato, per <b><i>giovedì 7 dicembre dalle ore 10 alle 12:30, l''Assemblea regionale di presentazione dei candidati e delle candidate alla carica di Delegato/a regionale in modalità telematica su Piattaforma Teams</i></b>.
</p>
<p>
Sarà occasione gradita per presentare agli operatori volontari le proposte dei candidati e per incentivare la partecipazione alla tornata elettorale fissata per i giorni sopra menzionati.
<br /><br />
A  moderare l''incontro ci sarà la Delegazione attualmente in carica.
</p>
<p>
All''incontro potranno partecipare tutti gli operatori volontari attualmente in servizio in Puglia.<br /><br />
Si ricorda che il giorno di partecipazione è considerato a tutti gli effetti un giorno di servizio svolto ai sensi dell''Allegato B <i>''Linee guida in materia di Rappresentanza degli operatori volontari di Servizio Civile Universale''</i>.<br /><br />
Si allega link per partecipare all''assemblea e la locandina dell''evento.<br />
<hr>
<p style="font-size: 18px">Riunione di Microsoft Teams<br />
<span style="font-size: 14px">Partecipa da computer, app per dispositivi mobili o dispositivo della stanza<span><br />
<a href="https://teams.microsoft.com/l/meetup-join/19%3ameeting_N2FiZjdkNzktMzEwYy00ZjVmLWJlMTAtNjBlZTFlNTRjM2Vh%40thread.v2/0?context=%7b%22Tid%22%3a%223e90938b-8b27-4762-b4e8-006a8127a119%22%2c%22Oid%22%3a%2231dd599b-2438-4297-b095-4014cd0b268c%22%7d">Fai clic qui per partecipare alla riunione</a><br />
ID riunione: 362 425 141 242<br />
Passcode: bejQcn<br />
<a href="https://www.microsoft.com/en-us/microsoft-teams/download-app">Scarica Teams</a>|<a href="https://www.microsoft.com/microsoft-teams/join-a-meeting">Partecipa sul Web<br /></a><br />
Si auspica ampia partecipazione.
<br/><br/><br/>
<p>Delegazione Puglia - Rappresentanza Volontari Servizio Civile</p>
<p>Indirizzo mail: rappresentanzascn.puglia@gmail.com<br/>
Facebook: Servizio Civile-Delegazione Puglia<br/>
Instagram: servizio_civile_puglia
</p>
'

      DECLARE MYCUR CURSOR LOCAL FOR
            select distinct EMAIL from [unscproduzione].[dbo].[_mail_commissione_28112023_ov_puglia_EVOL] order by 1
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
           EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Locandina_Assemblea_Puglia.png'
           FETCH NEXT FROM MYCUR INTO @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','commissioneelettorale@serviziocivile.it;sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Locandina_Assemblea_Puglia.png'





GO
