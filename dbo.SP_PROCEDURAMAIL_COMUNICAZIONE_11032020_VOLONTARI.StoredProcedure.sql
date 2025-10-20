USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_PROCEDURAMAIL_COMUNICAZIONE_11032020_VOLONTARI]    Script Date: 14/10/2025 12:36:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









ALTER PROCEDURE [dbo].[SP_PROCEDURAMAIL_COMUNICAZIONE_11032020_VOLONTARI]
--@gruppo as int
AS
DECLARE
            @OGGETTO          VARCHAR(500),
            @TESTO                  VARCHAR(8000),
            @MAIL             VARCHAR(500),
            @CODICEvolontario       VARCHAR(50),
            @RETURN                 BIT
            
      SET @OGGETTO='#distantimauniti'
      SET @TESTO =
'<p>Care ragazze, cari ragazzi, purtroppo il vostro periodo di servizio civile ha coinciso con l''emergenza Coronavirus, e per questo la maggior parte dei percorsi è stata sospesa. Mi dispiace moltissimo: cercheremo di trovare il modo per recuperare questo tempo e farvi completare il periodo previsto non appena ce ne saranno le condizioni.</p>
<p>So che invece alcuni di voi stanno continuando perché impegnati in Enti che stanno fronteggiando, in modi diversi, l''emergenza: voglio ringraziarvi, vi siamo davvero grati per quanto state facendo in difesa della Patria, incarnando pienamente lo spirito del servizio civile.</p>
<p>A tutti gli altri voglio mandare un messaggio: anche se in pausa, siete parte di una straordinaria squadra della solidarietà che coinvolge migliaia di giovani, in ogni parte del Paese, e che non si ferma mai.
<br>Molti di voi mi hanno scritto, chiedendomi: come possiamo dare il nostro contributo in questi giorni in cui è consigliato stare a casa?
<br>Un modo c''è: nelle ultime ore abbiamo lanciato, insieme a campioni dello sport, la campagna "distanti ma uniti".</p>
<p>Vogliamo far arrivare a tutti due messaggi. Il primo: in questo momento occorre stare a casa ed evitare ogni spostamento non necessario. Il secondo: stare a casa non significa essere soli.
<br>Siamo parte di una comunità unita, anche se per forza di cose in questi giorni dobbiamo stare distanti.
<br>Aiutateci a smentire il luogo comune che, a causa di qualche decina di irresponsabili che postano foto di aperitivi e feste, sta colpendo un''intera generazione. I giovani italiani non sono questo, ed è il momento di dimostrarlo!</p>
<p>Pubblicate anche voi la foto, magari insieme ai vostri consigli su cosa fare mentre si è a casa, coinvolgete i vostri amici in questa catena, facciamo sentire a tutti che si può essere, davvero, distanti ma uniti.</p>
<p><strong>#iorestoacasa</strong> <strong>#distantimauniti</strong></p>
<p><br><br>Vincenzo Spadafora</p>'

      DECLARE MYCUR CURSOR LOCAL FOR
            select codicevolontario,EMAIL from [unscproduzione].[dbo].[_Mail_Comunicazione_11032020_Volontari]
			where gruppo = 9
      OPEN MYCUR
      FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      WHILE @@Fetch_status = 0
      BEGIN
            
			-- L'allegato va messo come ultimo parametro e deve risiedere sul server dove si trova SQL, es: 'd:\allegato.pdf'
            EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','',@MAIL,'','',@OGGETTO ,@TESTO,'d:\allegati\Istruzioni SOCIAL campagna #distantimauniti.pdf'
            FETCH NEXT FROM MYCUR INTO @CODICEvolontario, @MAIL
      END
CLOSE MYCUR
DEALLOCATE MYCUR
SET @OGGETTO = @OGGETTO + ' - CONCLUSIONE INVIO'
EXEC @RETURN = [SP_INVIO_MAIL_COMUNICAZIONE] '','','sviluppo@serviziocivile.it','','',@OGGETTO ,@TESTO,'d:\allegati\Istruzioni SOCIAL campagna #distantimauniti.pdf'









GO
