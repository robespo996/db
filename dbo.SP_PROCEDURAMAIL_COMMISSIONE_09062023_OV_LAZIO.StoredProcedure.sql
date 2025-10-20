USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_09062023_OV_LAZIO]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMMISSIONE_09062023_OV_LAZIO]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='Invito assemblea operatori volontari Lazio 12 giugno 2023 - Link riunione online'
      SET @TESTO =
'<p>
Egregi,<br />
in qualità di Rappresentanza degli Operatori Volontari in Servizio Civile del Lazio, 
abbiamo indetto per il giorno odierno lunedì 12 giugno l''Assemblea Regionale degli Operatori Volontari in Servizio Civile, che si svolgerà in presenza e in streaming alle ore 15.30 nella splendida località di Poli in provincia di Roma.
</p><p>
In allegato il programma dell''evento<br />
</p><p>
Invito all’Assemblea Regionale Delegazione Lazio Giovani e Servizio Civile - Poli (RM)<br />
lunedì 12 giugno 2023<br />
15:30 - 18:30 (CET):<br />

https://teams.microsoft.com/l/meetup-join/19%3ameeting_ZjliYzExOWEtMDRmZC00ODRiLTk3ZGUtYmQyMTU2NDcwNzlj%40thread.v2/0?context=%7b%22Tid%22%3a%22650e9622-dace-4a1d-8610-cc91a95e22ca%22%2c%22Oid%22%3a%2266ad0c2c-99e4-4de9-8857-fd7ca84c03fa%22%7d
<br Tocca il link o incollalo in un browser per partecipare.
</p><p>
In questa occasione sarà data anche l''opportunità ad illustri invitati di presenziare all''incontro ed esprimere il proprio prezioso punto di vista istituzionale, tramite interventi mirati sui temi del Servizio Civile e dei giovani del Lazio.
<br />
Alcuni dei Rappresentanti e Delegati Regionali e Nazionali del Servizio Civile (presenti e passati) dirigeranno i loro messaggi ad una platea di Volontari in Servizio-ex Volontari-Autorità-Enti Locali-Enti del Terzo Settore, in modo da estendere a tutti le varie opportunità che il Servizio Civile e la Rappresentanza possono offrire.
<br />
Sperando di fare cosa gradita e auspicando la più fervida partecipazione, sarà nostro piacere dare la possibilità nel corso della manifestazione di intavolare assieme un dibattito costruttivo con i giovani e per i giovani.
 <br />
La partecipazione di Agenzie, Enti ed ospiti istituzionali garantirà certamente un successivo canale preferenziale con il nostro organismo di Rappresentanza nazionale e regionale, in quanto le nostre attenzioni sono rivolte sì ai ragazzi del Servizio Civile ma anche alle Istituzioni pubbliche da sempre al lavoro per i giovani, intessendo un ponte ed uno strumento di supporto ulteriore nell''interlocuzione con i giovani. 
<br />
Certi di una grande partecipazione,<br />
Cordiali Saluti dalla Delegazione Lazio
</p>
'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codicevolontario,EMAIL from [unscproduzione].[dbo].[_mail_commissione_09062023_ov_lazio]
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
           EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\assemblea_lazio.pdf'
           FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_ELEZIONI] '','','commissioneelettorale@serviziocivile.it;sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\assemblea_lazio.pdf'





GO
