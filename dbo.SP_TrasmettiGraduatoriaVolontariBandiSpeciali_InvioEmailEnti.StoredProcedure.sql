USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_TrasmettiGraduatoriaVolontariBandiSpeciali_InvioEmailEnti]    Script Date: 14/10/2025 12:36:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_TrasmettiGraduatoriaVolontariBandiSpeciali_InvioEmailEnti]
		@IDENTE 		INT,
		@idProgetto    VARCHAR(20),
		@RETURN			varchar(200) output
 AS
DECLARE
	@OGGETTO		VARCHAR(200)='',
	@TESTO			varchar(max)='',
	@dbname			varchar(1000),
	@mailDestinat	varchar(1000)='',
	@COPIACARBONE	varchar(1000)='',
	@COPIACARBONEN  varchar(1000)='',
	@codiceEnte		varchar(10)='',
	@denomEnte		varchar(100)='',
	@codprogetto	varchar(20)='',
	@titolo			varchar(100)='',
	@localPath		varchar(200)='',
	@funcPosition	varchar(50),
	@rc				INT

begin try

	select 
		@codiceEnte=isnull(codiceregione ,''), 
		@mailDestinat=Email,
		@denomEnte=Denominazione
	from Enti where idente=@idEnte

	if isnull(@codiceEnte,'')=''
	begin
		RAISERROR ('Non e'' stato trovato alcun Ente',15,1)
	end

	select @codprogetto=isnull(CodiceEnte,''), @titolo=titolo from attivit‡ where IdAttivit‡=@IdProgetto
	if @codprogetto='' 
	begin
		RAISERROR ('Il Codice progetto non e'' valorizzato',15,1)
	end

	set @DBNAME=db_name()

	if @@SERVERNAME in ('SQLSUSCN','SQLSUSCNEW')
	begin  -- PRODUZIONE
		set @localPath = 'd:\ALLEGATI_TRASMISSIONE_GRADUATORIE\'
		set @dbname='unscproduzione.dbo.TrasmissioneGraduatorieDocumentiBandiSpeciali'
--		set @mailDestinat ='berardino.chirico@eng.it'
--		set @COPIACARBONE = 'alinmihai.lefter@eng.it'
		set @COPIACARBONEN = '' --'heliosweb@serviziocivile.it'
		set @funcPosition='unscproduzione.dbo.'
	end
	else
	begin
--		set @localPath = '\\Appl\modhelios$\COLLAUDO\TEST_MEV00014\'
		set @localPath = 'd:\ALLEGATI_TRASMISSIONE_GRADUATORIE\'
		set @dbname='SQLTEST.UnscEngCollaudo.dbo.TrasmissioneGraduatorieDocumentiBandiSpeciali'
		set @mailDestinat ='berardino.chirico@eng.it'
		set @COPIACARBONE = 'alinmihai.lefter@eng.it'
		set @COPIACARBONEN ='' 
		set @funcPosition='TEST_DINO.dbo.'
	end


	declare
	@bcpCommand		varchar(1000),

	@idDocumentoT	varchar(10),
	@bindataT		varbinary(max),
	@dataInserT		datetime,
	@FullFileNameT	varchar(256),
	@dataProtocoT	varchar(20), 
	@codiceProtocT	varchar(20),

	@idDocumentoC	varchar(10),
	@bindataC		varbinary(max),
	@dataInserC		datetime,
	@FullFileNameC	varchar(256),
	@dataProtocoC	varchar(20), 
	@codiceProtocC	varchar(20),

	@attachList		varchar(max)='',
	@dataInserim	datetime


	if not exists (
		select 1
		from TrasmissioneGraduatorieDocumentiBandiSpeciali t1, TrasmissioneGraduatorieDocumentiBandiSpecialiProtocollo t2
		where t1.idDocumento=t2.idDocumento 
		and idente=@idente and IdProgetto=@IdProgetto and TipoDocumento='T')
	begin
		RAISERROR ('Non e'' stata trovata alcuna lettera di trasmissione da notificare',15,1)
	end

	if not exists (
		select 1
		from TrasmissioneGraduatorieDocumentiBandiSpeciali t1, TrasmissioneGraduatorieDocumentiBandiSpecialiProtocollo t2
		where t1.idDocumento=t2.idDocumento 
		and idente=@idente and IdProgetto=@IdProgetto and TipoDocumento='C')
	begin
		RAISERROR ('Non e'' stato trovato alcun Allegato C da notificare',15,1)
	end


	select 
		@idDocumentoT=isnull(t1.iddocumento,-1),
		@FullFileNameT=@localPath+t1.filename,
		@dataInserT = t1.DataInserimento,
		@dataProtocoT=convert(varchar,t2.DataProtocollazione,103),
		@codiceProtocT = t2.CodiceProtocollo,
		@bindataT=bindata
	from TrasmissioneGraduatorieDocumentiBandiSpeciali t1, TrasmissioneGraduatorieDocumentiBandiSpecialiProtocollo t2
	where t1.idDocumento=t2.idDocumento 
	and idente=@idente and IdProgetto=@IdProgetto and TipoDocumento='T'

	if @idDocumentoT=-1
	begin
		RAISERROR ('Non e'' stata trovata alcuna lettera di trasmissione da notificare',15,1)
	end

	select 
		@idDocumentoC=isnull(t1.iddocumento,-1),
		@FullFileNameC=@localPath+t1.filename, 
		@dataInserC = t1.DataInserimento,
		@dataProtocoC=convert(varchar,t2.DataProtocollazione,103),
		@codiceProtocC = t2.CodiceProtocollo,
		@bindataC=bindata 
	from TrasmissioneGraduatorieDocumentiBandiSpeciali t1, TrasmissioneGraduatorieDocumentiBandiSpecialiProtocollo t2
	where t1.idDocumento=t2.idDocumento 
	and idente=@idente and IdProgetto=@IdProgetto and TipoDocumento='C'

	if @idDocumentoC=-1
	begin
		RAISERROR ('Non e'' stato trovato alcun Allegato C) da notificare',15,1)
	end


	CREATE TABLE #temp (msg VARCHAR(max))
	DECLARE @ErrorLevel INT=0
	DECLARE @err AS Nvarchar(MAX)=''

	SET @bcpCommand = 'bcp "SELECT '+@funcPosition+'__base64_decode('+@funcPosition+'__base64_encode(BinData)) FROM '+
		@dbname + ' where idDocumento='+@idDocumentoT+' " queryout "' + @FullFileNameT + '" -T -c -C RAW '

	INSERT #temp
		EXEC @ErrorLevel=master..xp_cmdshell @bcpCommand--, no_output

	if @ErrorLevel<>0
	begin
		SELECT  @err = COALESCE(@err + ' ', '') + '['+isnull(msg,'')+']' FROM #temp
		set @err=@err + '/['+@FullFileNameT+']'
		RAISERROR (@err,15,1)
	end

	SET @bcpCommand = 'bcp "SELECT '+@funcPosition+'__base64_decode('+@funcPosition+'__base64_encode(BinData)) FROM '+
		@dbname + ' where idDocumento='+@idDocumentoC+' " queryout "' + @FullFileNameC + '" -T -c -C RAW '

	INSERT #temp
		EXEC @ErrorLevel=master..xp_cmdshell @bcpCommand--, no_output

	if @ErrorLevel<>0
	begin
		SELECT  @err = COALESCE(@err + ' ', '') + '['+isnull(msg,'')+']' FROM #temp
		set @err=@err + '/['+@FullFileNameT+']'
		RAISERROR (@err,15,1)
	end

	set @attachList = @FullFileNameT + ';'+ @FullFileNameC

	SET @OGGETTO = 
'Trasmissione Graduatorie Ente ['+ @codiceEnte + '] e Allegato C  ñ progetto  ['+@titolo+'] (['+@codprogetto+'])'

	if @dataInserT < @dataInserC
		set @dataInserim=@dataInserT
	else
		set @dataInserim=@dataInserC

	set @codiceProtocT = substring(@codiceProtocT,11,100)
	set @codiceProtocC = substring(@codiceProtocC,11,100)

	SET @TESTO =
'<P>Gentile Utente, il Dipartimento ha ricevuto sul sistema Helios la trasmissione delle graduatorie e l''Allegato C 
relativi al progetto ['+@titolo+'] (['+@codprogetto + ']) per l''ente ['+@codiceEnte+'] ñ ['+@denomEnte + ']</p>
<p>La trasmissione delle graduatorie e líAllegato C sono stati presentati a sistema in data '+
convert(varchar,@dataInserim,103)+ ' e ora '+convert(varchar,@dataInserim,108)+ ' e protocollati il '+ 
@dataProtocoT + ' con protocollo n.'+@codiceProtocT + ' e il ' + 
@dataProtocoC + ' con protocollo n.'+@codiceProtocC + '.</p>'+
'<p>Copia della trasmissione delle graduatorie e dellíAllegato C sono allegate a questa e-mail.</p>'+
'<p>La presente e-mail Ë stata generata automaticamente da un indirizzo di posta elettronica di solo invio;'+
' si chiede pertanto di non rispondere al messaggio.</p>'

	EXEC @RC = dbo.SSIS_sp_send_dbmail
		@profile_name = 'UNSC',
		@recipients = @mailDestinat,
		@subject = @OGGETTO,
		@copy_recipients = @COPIACARBONE,
		@blind_copy_recipients = @COPIACARBONEN,
		@body = @TESTO,
		@body_format = 'HTML',
		@file_attachments = @attachList

	-- Aggiorno la data invio email
	if @rc=0
	begin
		update TrasmissioneGraduatorieDocumentiBandiSpeciali set DataInvioEmail=getDate()
		where iddocumento in (@idDocumentoT,@idDocumentoC)
	end

	-- aggiorno lo stato delle graduatorie

		update attivit‡sediAssegnazione set StatoGraduatoria=2 
		where IDAttivit‡ = @idProgetto



/*

	update attivit‡sediAssegnazione set StatoGraduatoria=2 where IDAttivit‡SedeAssegnazione in (
		SELECT distinct
			asa.IDAttivit‡SedeAssegnazione
		FROM  attivit‡sediAssegnazione ASA with(nolock)
			INNER JOIN attivit‡ with(nolock)  ON attivit‡.IDAttivit‡ = ASA.IDAttivit‡
			inner join GraduatorieEntit‡ GE on ASA.IDAttivit‡SedeAssegnazione=GE.IdAttivit‡SedeAssegnazione
			INNER JOIN Entit‡ with (nolock) on Entit‡.IDEntit‡=GE.identit‡
			INNER JOIN entisediattuazioni with (nolock) ON entit‡.TMPIdSedeAttuazione = entisediattuazioni.IDEnteSedeAttuazione 
			INNER JOIN BandiAttivit‡ with(nolock) ON attivit‡.IDBandoAttivit‡ = BandiAttivit‡.IdBandoAttivit‡
		WHERE --statiattivit‡.idstatoattivit‡ in (1,2)
			attivit‡.IDStatoAttivit‡ in (1,2)
			and IDEntePresentante=@idente
			and programmi.IdEnteProponente=@idente
			and attivit‡.IdProgetto=@IdProgetto
		)
*/

	insert into [TrasmissioneGraduatorieDocumentiBandiSpecialiNotificheEmail] 
	values (
		getDate(),
		@IdEnte,
		@IdProgetto,
		1,
		'OK',
		@mailDestinat,
		@COPIACARBONE,
		@COPIACARBONEN,
		@OGGETTO,
		@Testo)

	set @RETURN ='OK'
	return 0

end try
begin catch
	declare @err1 varchar(max)

	set @err1 = 'Si e'' verificato un errore nell''invio della email: ' + ERROR_MESSAGE( ) 

print @return
	insert into [TrasmissioneGraduatorieDocumentiBandiSpecialiNotificheEmail] values (
		getDate(),
		@IdEnte,
		@IdProgetto,
		0,
		@err1,
		@mailDestinat,
		@COPIACARBONE,
		@COPIACARBONEN,
		@OGGETTO,
		@Testo)

	set @RETURN = 'Si e'' verificato un errore nell''invio della email' 
	return 1
end catch


GO
