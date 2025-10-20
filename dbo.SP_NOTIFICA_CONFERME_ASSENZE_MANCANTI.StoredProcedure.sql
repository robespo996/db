USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_NOTIFICA_CONFERME_ASSENZE_MANCANTI]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_NOTIFICA_CONFERME_ASSENZE_MANCANTI]
--CREATA IL:	 03/03/2014 
--REALIZZATA DA: DANILO SPAGNULO
--FUNZIONALITA': INVIA MAIL AL SERVIZIO AMMINISTRAZIONE E BILANCIO CON L'ELENCO DEGLI ENTI CHE NON HANNO
--				 EFFETTUATO LA CONFERMA MENSILE DELLE ASSENZE/PRESENZE 

AS

declare @CONTA AS INT,
		@OGGETTO AS VARCHAR(1000),
		@MESSAGGIO AS VARCHAR(MAX),
		@IDENTE AS INT,
		@CODICEENTE AS VARCHAR(100),
		@ENTE AS VARCHAR(250),
		@PREFISSO AS VARCHAR(100),
		@TELEFONO AS VARCHAR(100),
		@EMAIL AS VARCHAR(255),
		@EMAILCERTIFICATA AS VARCHAR(255)

declare @annorif int
declare @meserif int

IF MONTH(GETDATE()) = 1
	BEGIN
		SET @annorif =  YEAR(getdate())-1
		SET @meserif = 12
	END
ELSE
	BEGIN
		SET @annorif =  YEAR(getdate())
		SET @meserif = month(getdate())-1
	END

SET @CONTA = 0
SET @OGGETTO = 'HELIOS - AVVISO ELENCO ENTI SENZA CONFERMA MENSILE'

SET @MESSAGGIO = '<FONT face="Verdana" size="4" Color="Red">
		 <B>ELENCO ENTI PER I QUALI NON RISULTANO ANCORA CONFERMATE LE ASSENZE/PRESENZE SUL SISTEMA HELIOS:</B></FONT><br><br>
		 <FONT face="Verdana" size="4"><br><br>
		<TABLE CellPadding=3 CellSpacing=3 Border=1 Width="600"><TR><TD><B>Codice</B></TD><TD><B>Ente</B></TD><TD><B>Prefisso</B></TD><TD align="center"><B>Telefono</B></TD><TD align="center"><B>Email</B></TD><TD align="center"><B>Email Certificata</B></TD></TR>'

DECLARE MYCUR CURSOR LOCAL FOR
	select a.idente, a.codiceregione as CodiceEnte, a.denominazione as Ente, a.prefissotelefonorichiestaregistrazione as prefisso, a.telefonorichiestaregistrazione as telefono, a.email, a.emailcertificata from
	(select ENTI.* from NOTIFICA_GESTIONE_ASSENZE_ENTI INNER JOIN ENTI ON NOTIFICA_GESTIONE_ASSENZE_ENTI.IDENTE = ENTI.IDENTE
		where year(datanotifica) =year(getdate()) and month(datanotifica) = month(getdate())) as a
	LEFT JOIN
	(select * from dbo.EntiConfermaAssenze 
		where anno = @annorif and mese = @meserif) as b
	ON A.IDENTE = B.IDENTE
	WHERE B.IDENTE IS NULL
	
OPEN MYCUR
FETCH NEXT FROM MYCUR INTO @IDENTE, @CODICEENTE, @ENTE, @PREFISSO, @TELEFONO, @EMAIL, @EMAILCERTIFICATA
WHILE @@Fetch_status = 0
BEGIN
	SET @CONTA = @CONTA+1
	SET @MESSAGGIO = @MESSAGGIO + 
			'<TR>
			<TD>' + @CODICEENTE + '</TD>
			<TD>' + @ENTE + '</TD>
			<TD>' + @PREFISSO + '</TD>
			<TD align="center">' + @TELEFONO + '</TD>
			<TD align="center">' + @EMAIL + '</TD>
			<TD align="center">' + @EMAILCERTIFICATA + '</TD>
			</TR>'	
	FETCH NEXT FROM MYCUR INTO @IDENTE, @CODICEENTE, @ENTE, @PREFISSO, @TELEFONO, @EMAIL, @EMAILCERTIFICATA
END

SET @MESSAGGIO = @MESSAGGIO + '</TABLE></FONT>'

CLOSE MYCUR
DEALLOCATE MYCUR

IF @CONTA>0
	EXEC  dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = 'amministrazione@serviziocivile.it', -- EMAIL DESTINATARIO formazione@serviziocivile.it
		@subject			= @OGGETTO,
		@copy_recipients = '',
		@blind_copy_recipients = 'heliosweb@serviziocivile.it', --COPIA CABONE NASCOSTA heliosweb@serviziocivile.it
		@body = @MESSAGGIO,
		@body_format = 'HTML'
GO
