USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_FIRMA_DIGITALE_CONTRATTI_FINALIZZA_DELEGA_INVIOEMAILENTI]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_FIRMA_DIGITALE_CONTRATTI_FINALIZZA_DELEGA_INVIOEMAILENTI]
		@idEnte int,
		@idDocumentoTrasmissione int,
		@Esito int output,
		@RETURN varchar(500) output
 AS
DECLARE
	@OGGETTO		VARCHAR(200)='',
	@TESTO			varchar(max)='',
	@dbname			varchar(1000),
	@mailDestinat	varchar(1000)='',
	@COPIACARBONE	varchar(1000)='',
	@COPIACARBONEN  varchar(1000)='',
	@CodiceEnte		varchar(10)='',
	@denomEnte		varchar(100)='',
	@codProgramma	varchar(20)='',
	@titolo			varchar(100)='',
	@localPath		varchar(200)='',
	@funcPosition	varchar(50),
	@rc				INT,
	@isTest			TINYINT=1,
	@EntiCoprogr	varchar(max)='',
	@APPEND_EM      varchar(10)='_TEST';

begin try


	if @@SERVERNAME in ('SQLSUSCN','SQLUNSCNEW')
		set @isTest = 0 

	if @isTest=0  --produzione
		set @APPEND_EM=''

	select
		@codiceEnte=isnull(codiceregione ,''), 
		@codiceEnte=isnull(codiceregione ,''), 
		@mailDestinat=Email + @APPEND_EM,
		@denomEnte=Denominazione
	from Enti where idente=@idEnte

	if @codiceEnte=''
	begin
		RAISERROR ('Non è stato trovato alcun Ente',15,1)
	end

	declare
	@bcpCommand		 varchar(1000),

	@idDocumentoCSV  int = -1,
	@dataInser		 datetime,
	@FullFileName	 varchar(256),
	@dataProtoco	 varchar(20), 
	@OraProtoco 	 varchar(20), 
	@codiceProtoc	 varchar(20),
	@dataAvvio		 varchar(20),
	@PROGRAMMA       varchar(30)='',
	@CODICEPROGRAMMA varchar(255)='',
	@attachList		 varchar(max)=''


	/* ERRATA, modificata da Dino il 08/09/2025
	select
		@idDocumentoCSV = t1.IdDocumentoCSV,
		@FullFileName=@localPath + replace(filename,'/','_'),
		@dataInser = DataInserimento,
		@dataProtoco = convert(varchar,DataInserimento,103),
		@OraProtoco = convert(varchar,DataInserimento,108),
		@codiceProtoc = CodiceProtocollo,
		@dataAvvio = convert(varchar, t2.DataInizioServizio, 103)
	from FirmaDigitaleContratti_TrasmissioneDeleghe_Documenti t1,
		FirmaDigitaleContratti_CronologiaDelegheFirmatariEnti_CSV_Documenti t2
	where idDocumento=@idDocumentoTrasmissione
	*/


	select
		@idDocumentoCSV = t1.IdDocumentoCSV,
		@FullFileName=@localPath + replace(filename,'/','_'),
		@dataInser = DataInserimento,
		@dataProtoco = convert(varchar,DataInserimento,103),
		@OraProtoco = convert(varchar,DataInserimento,108),
		@codiceProtoc = CodiceProtocollo,
		@dataAvvio = convert(varchar, t2.DataInizioServizio, 103)
	from FirmaDigitaleContratti_TrasmissioneDeleghe_Documenti t1
		inner join FirmaDigitaleContratti_CronologiaDelegheFirmatariEnti_CSV_Documenti t2 on t1.IdDocumentoCSV=t2.IdCronologiaDocumentoCSV
	where idDocumento=@idDocumentoTrasmissione

	if @IdDocumentoCSV=-1
	begin
		RAISERROR ('Non è stato trovato alcun documento da inviare',15,1)
	end

	declare @EntiCoProgrammanti table (
		idEnte int,
		codiceRegione varchar(100),
		email varchar(255)
	)

	insert into @EntiCoProgrammanti
	select distinct 
		t5.IDEnte,
		t5.CodiceRegione,
		t5.Email
	from VW_FirmaDigitaleContratti_DelegheFirmatariEnti_Dettagli t1
	inner join attività t2 on t1.idAttività=t2.idAttività
	inner join Programmi t3 on t2.IdProgramma = t3.IdProgramma 
	inner join ProgrammiEntiCoprogrammazione t4 on t4.IdProgramma=t3.IdProgramma
	inner join Enti t5 on t5.idente=t4.IdEnte
	where 1=1
	and t1.IdEnte=@idEnte
	and t3.IdProgramma is not null
	and t5.IDEnte<> @idEnte

	SELECT @EntiCoprogr = COALESCE(@EntiCoprogr + ';', '') +  email + @APPEND_EM FROM @EntiCoProgrammanti

	declare @ListaProgrammi table (
		CodiceProgramma varchar(100)
	)

	insert into @ListaProgrammi
	select distinct 
		t3.CodiceProgramma
	from VW_FirmaDigitaleContratti_DelegheFirmatariEnti_Dettagli t1
	inner join attività t2 on t1.idAttività=t2.idAttività
	left outer join Programmi t3 on t2.IdProgramma = t3.IdProgramma 
	where 1=1
	and t3.IdProgramma is not null
	and t1.IdEnte=@idEnte

	declare @ListaProgrammiTXT varchar(max)
	SELECT @ListaProgrammiTXT = COALESCE(@ListaProgrammiTXT + '', '') +  '</BR> - ' + CodiceProgramma FROM @ListaProgrammi

	if @isTest=0  --produzione
	begin
		set @localPath = 'd:\ALLEGATI_TRASMISSIONE_GRADUATORIE\'
		set @dbname=@@SERVERNAME+'.UnscProduzione.dbo.FirmaDigitaleContratti_TrasmissioneDeleghe_Documenti'
		set @mailDestinat =@mailDestinat
		set @COPIACARBONE = @EntiCoprogr
		set @COPIACARBONEN = 'heliosweb@serviziocivile.it'
		set @funcPosition='unscproduzione.dbo.'
	end
	else
	begin
		set @localPath = 'd:\ALLEGATI_TRASMISSIONE_GRADUATORIE\'
		set @dbname=@@SERVERNAME+'.UnscEngCollaudo.dbo.FirmaDigitaleContratti_TrasmissioneDeleghe_Documenti'
		set @mailDestinat =@mailDestinat
		set @COPIACARBONE = @EntiCoprogr
		set @COPIACARBONEN = 'heliosweb@serviziocivile.it;berardino.chirico@eng.it;s.mura@governo.it'
		set @funcPosition='UnscEngCollaudo.dbo.'
	end

	declare @temp table (msg VARCHAR(max))
	DECLARE @ErrorLevel INT=0
	DECLARE @err AS Nvarchar(MAX)=''

	set  @FullFileName = @localPath+@FullFileName

	SET @bcpCommand = 'bcp "SELECT '+@funcPosition+'FN_BASE64_DECODE('+@funcPosition+'FN_BASE64_ENCODE(BinData)) FROM '+
		@dbname + ' where idDocumento='+
		convert(varchar,@idDocumentoTrasmissione)
		+' " queryout "' + @FullFileName + '" -T -c -C RAW '

--	print @bcpCommand

	INSERT @temp
		EXEC @ErrorLevel=master..xp_cmdshell @bcpCommand--, no_output

	if @ErrorLevel<>0
	begin
		SELECT  @err = COALESCE(@err + ' ', '') + '['+isnull(msg,'')+']' FROM @temp

		set @err=@err + '/['+@FullFileName+']'
		RAISERROR (@err,15,1)
	end

	set @attachList = @FullFileName 

--	print @attachList

	SET @OGGETTO = @codiceEnte + '_ATTESTA#DIGIT#['  + @dataAvvio + ']' 

	set @codiceProtoc = substring(@codiceProtoc,11,100)

	SET @TESTO =
'<P>Gentile Utente, il Dipartimento ha ricevuto sul sistema Helios la trasmissione del PDF allegato, '+ 
'sottoscritto dal legale rappresentante e contenente i nominativi dei firmatari, '+
--'relativi al programma '+ '['+@PROGRAMMA + '] ([' + @CODICEPROGRAMMA +']) '+
'per l''ente ['+ @codiceEnte + '] - [' + @denomEnte + '] '+
'in relazione alla data di avvio del progetto del [' + @dataAvvio + '] e relativi subentri.</BR>'

if @ListaProgrammiTXT<>''
BEGIN
set @TESTO += 
'La comunicazione è stata resa per progetti afferenti ai seguenti programmi di intervento:</BR>'+
@ListaProgrammiTXT+
'</BR>'
END

set @TESTO += 
'</BR>La trasmissione del documento è avvenuta ' + 
'in data ' + @dataProtoco + ' alle ore '+ @OraProtoco +
' ed è stata protocollata il ' + @dataProtoco + ' con il n.' + @codiceProtoc + '.'
/*
	if @isTest=1
	BEGIN
		set @EntiCoprogr=''

		SELECT  @EntiCoprogr = COALESCE(@EntiCoprogr + ' ', '</BR>') + 
			' [' + convert(varchar,idEnte) + ']'+
			' [' + codiceRegione + ']'+
			' [' +email + '] </BR>'
		FROM @EntiCoProgrammanti

		set @TESTO += '</BR></BR>Lista Enti coprogrammanti:</BR>'+@EntiCoprogr

	END
*/
	print @testo

/*
relativi al programma ['+@titolo+'] (['+@codProgramma + ']) per l''ente ['+@codiceEnte+'] – ['+@denomEnte + ']</p>
<p>La trasmissione delle graduatorie e l’Allegato C sono stati presentati a sistema in data '+
convert(varchar,@dataInserim,103)+ ' e ora '+convert(varchar,@dataInserim,108)+ ' e protocollati il '+ 
@dataProtocoT + ' con protocollo n.'+@codiceProtocT + ' e il ' + 
@dataProtocoC + ' con protocollo n.'+@codiceProtocC + '.</p>'+
'<p>Copia della trasmissione delle graduatorie e dell’Allegato C sono allegate a questa e-mail.</p>'+
'<p>La presente e-mail è stata generata automaticamente da un indirizzo di posta elettronica di solo invio;'+
' si chiede pertanto di non rispondere al messaggio.</p>'
*/

print @mailDestinat
print @COPIACARBONE
print @COPIACARBONEN


	EXEC @RC = dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = @mailDestinat,
		@subject = @OGGETTO,
		@copy_recipients = @COPIACARBONE,
		@blind_copy_recipients = @COPIACARBONEN,
		@body = @TESTO,
		@body_format = 'HTML',
		@file_attachments = @attachList


	-- Memorizza l'invio dell'email

	insert into FirmaDigitaleContratti_TrasmissioneDeleghe_NotificheEmail
	select
		 @idDocumentoTrasmissione
		,getDate()
		,1
		,'OK'
		,@mailDestinat
		,@COPIACARBONE
		,@COPIACARBONEN
		,@OGGETTO
		,@Testo

	set @RETURN ='OK'
	set @Esito=1
end try
begin catch
	declare @err1 varchar(max)

	set @err1 = 'Si e'' verificato un errore nell''invio della email: ' + ERROR_MESSAGE( ) 

	insert into FirmaDigitaleContratti_TrasmissioneDeleghe_NotificheEmail 
	select
		 @idDocumentoTrasmissione
		,getDate()
		,0
		,@err1
		,@mailDestinat
		,@COPIACARBONE
		,@COPIACARBONEN
		,@OGGETTO
		,@Testo

	set @RETURN = 'Si e'' verificato un errore nell''invio della email' 
	set @Esito=0
end catch


GO
