USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_INVIAEMAIL_CSV_GRADUATORIEVOLONTARI]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_INVIAEMAIL_CSV_GRADUATORIEVOLONTARI]
	@CODICEENTE 	VARCHAR(10),
	@CSVContent		VARCHAR(MAX),
	@username		varchar(10),
	@CF				varchar(20),
	@MSGFinale		varchar(1000),
	@RETURN			varchar(500) output
 AS
BEGIN

DECLARE
	@OGGETTO		VARCHAR(300)='',
	@TESTO			varchar(max)='',
	@mailDestinat	varchar(1000)='',
	@COPIACARBONE	varchar(1000)='',
	@COPIACARBONEN  varchar(1000)='',
	@attachFile		varchar(255)='',
	@rc				INT,
	@Cmd			varchar(1000),
	@localDateTime  varchar(30),
	@denominazione	varchar(100)=''

begin try

	select @denominazione=isnull(denominazione,'') from enti where CodiceRegione=@CODICEENTE

	set @localDateTime = convert(varchar,getdate(), 110)+'_'+convert(varchar,getdate(), 108)  --mm-dd-yyyy 
	set @localDateTime = replace (@localDateTime, ':','')

	if @@SERVERNAME in ('SQLSUSCN','SQLUNSCNEW')
	begin
		set @attachFile = 'd:\ALLEGATI_TRASMISSIONE_GRADUATORIE\GraduatoriaVolontari_'+ @CODICEENTE + '_'+ @localDateTime +'.csv'
		set @mailDestinat ='heliosweb@serviziocivile.it'
--		set @COPIACARBONE = 'alinmihai.lefter@eng.it'
	end
	else
	begin
		set @attachFile = 'd:\ALLEGATI_TRASMISSIONE_GRADUATORIE\GraduatoriaVolontari_'+ @CODICEENTE + '_'+ @localDateTime +'.csv'
		set @mailDestinat ='berardino.chirico@eng.it'
	end

	SET @OGGETTO = 'Caricamento graduatorie volontari Ente ['+ @codiceEnte + '] - [' + @denominazione + ']'

	SET @TESTO =
'In data ' + convert(varchar,getdate(), 103)+' '+convert(varchar,getdate(), 108) + ','+
' l''utente con username <B>'+@username+'</B> e Codice Fiscale <B>'+@CF+'</B>, per conto dell''ente <B>' +@CODICEENTE + '</B>,'+
' ha caricato con successo il file CSV allegato, contenente le graduatorie dei volontari, ottenendo il seguente messaggio a video: </BR></BR>'+
'<B>'+ @MSGFinale+'</B>'


--	set @Cmd = 'echo ' +  @CSVContent + ' > '+ @attachFile 

	insert GraduatorieEntità_CSV_Documenti (CSVData, CodiceEnte, DataInserimento) 
	values (@CSVContent, @CODICEENTE, GETDATE())

	declare @id varchar(5) = SCOPE_IDENTITY()

	SET @Cmd = 'bcp "SELECT CSVData FROM '+db_name()+'.dbo.GraduatorieEntità_CSV_Documenti where id='+@id+'" queryout "'+@attachFile+'" -T -c -C RAW '

--	print @cmd

	execute ..xp_CmdShell  @Cmd

	EXEC @RC = dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = @mailDestinat,
		@subject = @OGGETTO,
		@copy_recipients = @COPIACARBONE,
		@blind_copy_recipients = @COPIACARBONEN,
		@body = @TESTO,
		@body_format = 'HTML',
		@file_attachments = @attachFile

--	delete from GraduatorieEntità_CSV_Documenti where id=@id

	set @RETURN ='OK'
	return 0

end try
begin catch
	set @RETURN = 'Si e'' verificato un errore nell''invio della email: ' + ERROR_MESSAGE( ) 
	return 1
end catch

/*
TEST

declare @msg varchar(1000)
execute SP_INVIAEMAIL_CSV_GRADUATORIEVOLONTARI 'TEST','TEST', 'TEST','TEST','TEST',@msg output
select @msg
*/

END
GO
