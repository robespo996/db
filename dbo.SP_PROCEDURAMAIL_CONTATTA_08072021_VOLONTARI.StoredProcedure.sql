USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_CONTATTA_08072021_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_CONTATTA_08072021_VOLONTARI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO            VARCHAR(8000),
			@TESTOAPPO        VARCHAR(8000),
            @MAIL             NVARCHAR(200),
			@COGNOME          NVARCHAR(200),
			@NOME             NVARCHAR(200),
			@GENERE           CHAR,
            @CODICEvolontario       VARCHAR(50),
            @RETURN           BIT,
            @gruppo           INT

      SET @OGGETTO='Consultazione su giovani e cibo'
      SET @TESTO =
'<p>Care Volontarie e cari Volontari,<p>
<p>
desideriamo informarvi che nei giorni scorsi, la Ministra per Politiche Giovanili, on. Fabiana Dadone, con il supporto del Dipartimento per le Politiche Giovanili ed il Servizio Civile Universale e dell''Agenzia Nazionale Giovani, ha lanciato una consultazione pubblica su cinque temi: l''accesso ad alimenti nutrienti e sicuri per tutti, il consumo sostenibile, la produzione con impatto positivo sull''ambiente, i mezzi di sussistenza e uguaglianza e la resilienza.
<br/><br/>
Il modo in cui produciamo, distribuiamo e consumiamo il cibo ha un impatto enorme sulla sostenibilità del pianeta. Molti non hanno accesso a quantità adeguate di alimenti a causa della mancanza delle risorse necessarie, determinate dai continui cambiamenti climatici a cui il pianeta è esposto. È necessario interrogarsi e trovare soluzioni innovative per garantire che il cibo sia accessibile, sufficiente, sicuro e sostenibile.
<br/><br/>
ln quest''ottica la Ministra ritiene fondamentale che questa riflessione avvenga a partire dalle giovani generazioni, considerando essenziale coinvolgere le Operatrici e gli Operatori volontari del Servizio Civile Universale impegnati presso gli Enti di Servizio Civile in programmi di intervento e in progetti che contribuiscono al raggiungimento degli Obiettivi dell''Agenda 2030 per lo Sviluppo Sostenibile.
<br/><br/>
Le iniziative ONU del Forum Mondiale sull''Alimentazione (World Food Forum) e del Summit sui sistemi alimentari (UN''s Food Systems Summit - UNFSS) rappresentano occasioni preziose per un vostro coinvolgimento attivo. L''esito della consultazione sarà infatti il contributo dell''Italia ad un più ampio processo al quale, in questi mesi, stanno lavorando cittadini, organizzazioni pubbliche e private di tutto il mondo e che culminerà nell''evento organizzato dal WFF a Roma dal 1° al 5 ottobre 2021, con la partecipazione di rappresentanti dei Governi e dei vertici delle Nazioni Unite.
<br/><br/>
Di qui l''invito a voi per partecipare alla consultazione che è raggiungibile sul sito Giovani2030 all''indirizzo: https://giovani2030.it/iniziativa/wff-survey/. Già dal 14 luglio estrarremo un primo report basato anche sulle vostre idee.
<br/><br/>
Vi ringraziamo in anticipo e confidiamo molto sulla vostra partecipazione.
<br/><br/>
<strong>Il Capo del Dipartimento per le Politiche
<br/>
Giovanili e il Servizio Civile Universale
</strong>
<br/>
<i>Cons. Marco De Giorgi</i>
<br/><br/>
<strong>La Presidente della Consulta Nazionale per il
<br/>
Servizio Civile
</strong>
<br/>
<i>Feliciana Farnese</i>
<p/>
'


      DECLARE MYCUR CURSOR LOCAL FOR
            select top 4000 codicevolontario,EMAIL,gruppo from [unscproduzione].[dbo]._Mail_Contatta_08072021_VOLONTARI
			where gruppo > 0
			order by gruppo, codicevolontario
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL, @gruppo
      WHILE @@Fetch_status = 0
      BEGIN
          
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
			--PRINT 'VOLONTARIO: ' + @codicevolontario + ' ' + @mail + ' (' + convert(varchar, @gruppo) + ')'
            EXEC @RETURN = [SP_INVIO_MAIL_CONTATTA] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Nota_Capo_Dipartimento.pdf;d:\allegati\Nota_Ministro_Dadone.pdf'
            FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL, @gruppo
      END
CLOSE MYCUR
DEALLOCATE MYCUR

			-- Aggiorna il gruppo appena inviato
			UPDATE [unscproduzione].[dbo]._Mail_Contatta_08072021_VOLONTARI
			   SET gruppo = 0
			 WHERE gruppo = @gruppo
			PRINT 'AGGIORNATO GRUPPO: ' + convert(varchar, @gruppo)


SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_CONTATTA] '','','sviluppo@serviziocivile.it;comunicazione@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Nota_Capo_Dipartimento.pdf;d:\allegati\Nota_Ministro_Dadone.pdf'










GO
