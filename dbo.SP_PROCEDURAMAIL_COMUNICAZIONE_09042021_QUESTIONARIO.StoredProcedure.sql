USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMUNICAZIONE_09042021_QUESTIONARIO]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMUNICAZIONE_09042021_QUESTIONARIO]
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
            --@CODICEvolontario       VARCHAR(50),
            @RETURN           BIT,
            @gruppo           INT

      SET @OGGETTO='"Next generation You" - Le priorità dei giovani per la ripresa dell’Italia'
      SET @TESTO =
'<p>Gentile #GENERE# #COGNOME# #NOME#<p>
<p>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;desidero informarti che fino al 18 aprile è on line il questionario “Next Generation You” con cui la Ministra per le Politiche giovanili, Fabiana Dadone, intende acquisire, direttamente dai giovani, elementi informativi utili a migliorare la progettualità delle azioni del Piano Nazionale di Ripresa e Resilienza dedicate alle nuove generazioni.
<p/>
<p>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Ti chiediamo 10 minuti del tuo tempo per rispondere al questionario, ed esprimerti su progetti che vorremo includere nel PNRR e che sono pensati per i giovani e in particolare: il potenziamento del Servizio civile universale, l’introduzione del Servizio civile digitale e la creazione sul territorio di luoghi, fisici e virtuali, per lo sviluppo creativo, innovativo e produttivo da parte dei giovani.</p>
<p>
<p>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Sarebbe utile avere anche il tuo contributo.
</p>
</p>
<br/>
<p>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<i>cons. Marco De Giorgi</i>
</p>
<br/>
<br/>
<br/>
<br/>
<p>
»        Per compilare il questionario clicca <a href="https://nextgenerationyou.agenziagiovani.it/126484?lang=it" title="Compila il questionario">QUI</a>
</p>
'


		select @gruppo = isnull(max(gruppo),0)+1 from _mail_QUESTIONARIO_09042021_inviate 

		insert _mail_QUESTIONARIO_09042021_inviate
		select top 4000 Nome,Cognome,Email,Sesso,CodiceFiscale,@gruppo 
		from _Mail_Comunicazione_09042021_Questionario
		where CodiceFiscale not in (select CodiceFiscale from _mail_QUESTIONARIO_09042021_inviate) 

		  DECLARE MYCUR CURSOR LOCAL FOR
				select EMAIL, COGNOME, NOME, GENERE from _mail_QUESTIONARIO_09042021_inviate
				where gruppo = @gruppo
		  OPEN MYCUR
		  FETCH NEXT FROM MYCUR INTO @MAIL, @COGNOME, @NOME, @GENERE 
		  WHILE @@Fetch_status = 0
		  BEGIN
            
			SET @TESTOAPPO = @TESTO		-- salvo la stringa con i segnaposti in una variabile di appoggio
			SET @TESTO = REPLACE(@TESTO, '#COGNOME#', UPPER(@COGNOME))
			SET @TESTO = REPLACE(@TESTO, '#NOME#', UPPER(@NOME))
			IF UPPER(@GENERE) = 'M' 
				SET @TESTO = REPLACE(@TESTO, '#GENERE#', 'Operatore volontario')
			ELSE
				SET @TESTO = REPLACE(@TESTO, '#GENERE#', 'Operatore volontario')
			
			--PRINT 'VOLONTARIO: ' + @COGNOME + ' ' + @NOME + ' (' + @MAIL + ')'

			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Lettera del Capo Dipartimento agli operatori volontari.pdf'
			
			SET @TESTO = @TESTOAPPO     -- ripristino la stringa con i segnaposti dalla variabile di appoggio
            
			FETCH NEXT FROM MYCUR INTO @MAIL, @COGNOME, @NOME, @GENERE
	      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','','sviluppo@serviziocivile.it;comunicazione@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Lettera del Capo Dipartimento agli operatori volontari.pdf'










GO
