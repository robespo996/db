USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_FIRMA_DIGITALE_CONTRATTI_INVIAEMAIL_CSV_FIRMATARI]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_FIRMA_DIGITALE_CONTRATTI_INVIAEMAIL_CSV_FIRMATARI]
	@CODICEENTE 	     VARCHAR(10),
	@idBando		     int,
	@datainizioservizio  varchar(10),
	@esito				 int output,
	@outMessage		     varchar(500) output
 AS
BEGIN

DECLARE
	@OGGETTO		 VARCHAR(300)='',
	@TESTO			 varchar(max)='',
	@mailDestinat	 varchar(1000)='',
	@COPIACARBONE	 varchar(1000)='',
	@COPIACARBONEN   varchar(1000)='',
	@attachFile		 varchar(255)='',
	@rc				 INT,
	@Cmd			 varchar(1000),
	@DataCaricamento varchar(30),
	@denominazione	 varchar(100),
	
	@CSVContent		 VARCHAR(MAX)=null,
	@idEnte          int,
	@username		 varchar(10),
	@CF				 varchar(20),
	@id				 varchar(5),
	@emailEnte		 varchar(255)

begin try

	select 
		@denominazione=isnull(denominazione,''), 
		@idEnte=idente,
		@emailEnte=email
	from enti where CodiceRegione=@CODICEENTE


	if not exists (select 1 from FirmaDigitaleCOntratti_DelegheFirmatariEnti_CSV_Documenti
		where IdBando=@idBando and idEnte=@idEnte and dataInizioServizio=@datainizioservizio)
	BEGIN
		set @esito=0
		set @outMessage='File CSV non trovato'
		return
	END

	select top 1 
		@CSVContent=csvdata, 
		@id=IdDocumentoCSV,
		@DataCaricamento=DataCaricamento
	from FirmaDigitaleCOntratti_DelegheFirmatariEnti_CSV_Documenti
	where IdBando=@idBando and idEnte=@idEnte and dataInizioServizio=@datainizioservizio
	order by DataCaricamento desc

	if isnull(@CSVContent,'')=''
	BEGIN
		set @esito=0
		set @outMessage='File CSV non valido'
		return
	END

--	set @localDateTime = convert(varchar,getdate(), 110)+'_'+convert(varchar,getdate(), 108)  --mm-dd-yyyy 
--	set @localDateTime = replace (@localDateTime, ':','')

--	set @attachFile = 'ContrattiDigitali_ListaDelegatiFirmatari_' + @CODICEENTE + '_' + @DataCaricamento + '.csv'

	select @attachFile=nomeFileCSV from 
		dbo.FN_FIRMA_DIGITALE_CONTRATTI_GET_LISTA_CSV_CARICATI(@idbando,@CODICEENTE,@datainizioservizio)

	if @@SERVERNAME in ('SQLSUSCN','SQLUNSCNEW ')
	begin
		set @attachFile = 'd:\ALLEGATI_FIRMA_DIGITALE_CONTRATTI\' + @attachFile
		set @mailDestinat = @emailEnte
--		set @mailDestinat ='berardino.chirico@eng.it'
		set @COPIACARBONE ='heliosweb@serviziocivile.it'
	end
	else
	begin
		set @attachFile = 'd:\ALLEGATI_FIRMA_DIGITALE_CONTRATTI\' + @attachFile
		set @mailDestinat ='berardino.chirico@eng.it'
		set @COPIACARBONE = 'alinmihai.lefter@eng.it'
	end

	SET @OGGETTO = 'Caricamento Delegati Firmatari Contratti Digitali - Ente ['+ @codiceEnte + '] - [' + @denominazione + ']'

	SET @TESTO =
'Gentile utente,</BR>
Il caricamento del file csv contenente l''indicazione del firmatario dell''attestazione di cui all''art. 16, comma 2, del d.lgs. 40/2017 è andato a buon fine.
</BR>
È possibile verificare il contenuto del documento visualizzando il file allegato.
</BR>
Si rammenta che, ai fini del perfezionamento del processo di comunicazione del soggetto firmatario, è necessario scaricare il file disponibile al seguente link:</BR>

<a href="https://www.politichegiovanili.gov.it/media/grpktyui/dichiarazione_via_pec.docx">
https://www.politichegiovanili.gov.it/media/grpktyui/dichiarazione_via_pec.docx
</a>
</BR>
Il documento deve essere compilato, sottoscritto dal legale rappresentante dell''ente referente del progetto – anche in caso di coprogettazione - e trasmesso all''indirizzo di posta elettronica certificata del Dipartimento, utilizzando l''oggettario <B>“SU00XXX_ATTESTA#DIGIT"</B>.</BR>
Si rammenta che, in caso di mancata ricezione della comunicazione a mezzo pec entro il 6 luglio 2025, l''attestazione della data di inizio del servizio deve essere resa dal rappresentante legale dell''ente titolare del progetto. In caso di coprogettazione, l''attestazione viene resa dal rappresentante legale dell''ente accreditato titolare della specifica sede nell''ambito del progetto.</BR>'

/*
'In data ' + convert(varchar,getdate(), 103)+' '+convert(varchar,getdate(), 108) + ','+
' l''utente con username <B>'+@username+'</B> e Codice Fiscale <B>'+@CF+'</B>, per conto dell''ente <B>' +@CODICEENTE + '</B>,'+
' ha caricato con successo il file CSV allegato, contenente le graduatorie dei volontari, ottenendo il seguente messaggio a video: </BR></BR>'
*/

	SET @Cmd = 'bcp "SELECT CSVData FROM '+db_name()+'.dbo.FirmaDigitaleCOntratti_DelegheFirmatariEnti_CSV_Documenti '+
	' where idDocumentoCSV='+@id+'" queryout "'+@attachFile+'" -T -c -C RAW '

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

	set @outMessage ='OK'
	return 1

end try
begin catch
	set @outMessage = 'Si e'' verificato un errore nell''invio della email: ' + ERROR_MESSAGE( ) 
	return 0
end catch

END
GO
