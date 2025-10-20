USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_MAIL_DATI_VOLONTARI_ESTERI]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_MAIL_DATI_VOLONTARI_ESTERI]

@ESITO INT = 0 Output
AS
/*CREATA DA DANILO SPAGNULO IL 19/12/2013*/
DECLARE
		@DataElaborazione varchar(100),
		@NVolEsteri int,
		@NVolEsteriAttivi int,
		@NVolEsteriRinuncia int,
		@NVolEsteriInterruzione int,
		@OGGETTO			VARCHAR(200),
		@MESSAGGIO			VARCHAR(MAX),
		@MESSAGGIOCC		VARCHAR(4000)
		
select @NVolEsteri=count(identità) from entità where isnull(idcategoriaentità,1) <>1
select @NVolEsteriAttivi=count(identità) from entità where isnull(idcategoriaentità,1) <>1 and idstatoentità in (3,4,5)
select @NVolEsteriRinuncia=count(identità) from entità where isnull(idcategoriaentità,1) <>1 and idstatoentità=4
select @NVolEsteriInterruzione=count(identità) from entità where isnull(idcategoriaentità,1) <>1 and idstatoentità=5

insert into DatiVolontariEsteri Values (getdate(),@NVolEsteri,@NVolEsteriAttivi,@NVolEsteriRinuncia,@NVolEsteriInterruzione)

SET @OGGETTO = 'HELIOS - DATI VOLONTARI ESTERI'
SET @MESSAGGIO = '<FONT face="Verdana" size="4" Color="Red">
		 <B>STATO DOMANDE REGISTRATE SUL SISTEMA HELIOS RELATIVE AI VOLONTARI ESTERI </B></FONT><br><br>
		 <FONT face="Verdana" size="4"><br><br>
		
		<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD align="center"><B>Data Elaborazione</B></TD><TD align="center"><B>Domande Ricevute</B></TD><TD align="center"><B>Volontari Attivati</B></TD><TD align="center"><B>Chiusure Iniziali</B></TD><TD align="center"><B>Chiusi Durante il Servizio</B></TD></TR>'


	DECLARE MYCUR CURSOR LOCAL FOR
			SELECT dbo.formatodata(DataElaborazione) + ' ' + convert(varchar,datepart(hour,dataelaborazione)) + ':' + convert(varchar,datepart(minute,dataelaborazione)) as DataElab , NVolEsteri, NvolEsteriAttivi, NVolEsteriRinuncia, NVolEsteriInterruzione from DatiVolontariEsteri order by DataElaborazione asc
			
	OPEN MYCUR
	FETCH NEXT FROM MYCUR INTO @DataElaborazione, @NVolEsteri, @NVolEsteriAttivi, @NVolEsteriRinuncia, @NVolEsteriInterruzione
	WHILE @@Fetch_status = 0
	BEGIN
		SET @MESSAGGIO = @MESSAGGIO + 
				'<TR>
				<TD align="center">' + @DataElaborazione + '</TD>
				<TD align="right">' + convert(varchar,@NVolEsteri) + '</TD>
				<TD align="right">' + convert(varchar,@NVolEsteriAttivi) + '</TD>
				<TD align="right">' + convert(varchar,@NVolEsteriRinuncia) + '</TD>
				<TD align="right">' + convert(varchar,@NVolEsteriInterruzione) + '</TD>
				</TR>'	
		
		FETCH NEXT FROM MYCUR INTO @DataElaborazione, @NVolEsteri, @NVolEsteriAttivi, @NVolEsteriRinuncia, @NVolEsteriInterruzione
	END
	SET @MESSAGGIO = @MESSAGGIO + '</TABLE></FONT>'
CLOSE MYCUR
DEALLOCATE MYCUR


	EXEC  dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = 'rdecicco@serviziocivile.it', -- EMAIL DESTINATARIO formazione@serviziocivile.it
		@subject			= @OGGETTO,
		@copy_recipients = '',
		@blind_copy_recipients = 'heliosweb@serviziocivile.it;fpetracca@serviziocivile.it', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
		@body = @MESSAGGIO,
		@body_format = 'HTML'


GO
