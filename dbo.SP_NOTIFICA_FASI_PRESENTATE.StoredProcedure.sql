USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_NOTIFICA_FASI_PRESENTATE]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Realizzata da:	Vincenzo Mottola
Creata il:		26/05/2022	
Data Ultima Modifica:	--
Funzionalità: 	NOTIFICA agli utenti DIPARTIMENTO tutte le FASI PRESENTATE ancora non notificate
*/

ALTER PROCEDURE [dbo].[SP_NOTIFICA_FASI_PRESENTATE]

AS
BEGIN TRY
	
	-- PARAMETRI CONFIGURAZIONE
	DECLARE @tmpPath varchar(100)		='D:\\EXPORT_NOTIFICHE_FASI_PRESENTATE\\'			-- path salvataggio temporaneo allegato
	--DECLARE @email varchar(8000)		='heliosweb@serviziocivile.it'					-- destinatari email
	DECLARE @email varchar(8000)		='mtraggi@serviziocivile.it;salfei@serviziocivile.it;heliosweb@serviziocivile.it'	-- destinatari email
	DECLARE @OGGETTO varchar(200)		='NOTIFICA FASI PRESENTATE'											-- oggetto email
	DECLARE @messaggiocc varchar(max) 	='NOTIFICA FASI PRESENTATE'											-- testo email
	
	-- controllo quanti gg sono passati da ultima notifica
	-- recupero parametro configurazione
	
	DECLARE @giorno INT = DATEPART(WEEKDAY, GETDATE());

    -- Controlla che il giorno sia LUN (1), MER (3) o VEN (5)
    IF @giorno NOT IN (1, 3, 5)
	
	
	
	/*declare @gg int
	select @gg = convert(int,valore) from configurazioni where parametro = 'NOTIF_FASI_PRESENTATE'

	DECLARE @DataUltimaNotifica datetime
	select @DataUltimaNotifica=max(DataNotifica) from NotificheFasiPresentate

	if datediff (DD,@DataUltimaNotifica,getdate())<@gg	-- NON SONO PASSATI I GIORNI PREVISTI*/---modifica raggi non più ogni 7 gg
		return

--	BEGIN TRAN
	DECLARE @IdNotificaFasiPresentate INT
	
	-- creo nuovo record master per le notifiche con data da valorizzare
	insert into NotificheFasiPresentate(DataNotifica) VALUES(NULL)
	SET @IdNotificaFasiPresentate=@@IDENTITY

	-- inserisco nella tabella dei dati tutte le fasi che non hanno ancora una notifica
	insert into
		NotificheFasiPresentateDati
	select
		@IdNotificaFasiPresentate,
		ef.IdEnteFase,
		e.IdEnte,
		e.CodiceRegione [CODICE CP/SU],
		e.Denominazione [DENOMINAZIONE ENTE],
		case
			when ef.TipoFase=1 then 'Nuova Iscrizione'
			else cast(ef.IdEnteFase as varchar)
		end Tipo,
		null as Variazioni,
		pd.DataProtocollo
	from 
		entifasi ef
		inner join enti e on ef.idente=e.IDEnte
		left join ProtocolloDomanda pd on pd.IdEnteFase=ef.IdEnteFase and ef.IdEnte=pd.IdEnte
	where 
		ef.stato>2 and ef.tipofase in (1,2) and ef.IdNotificaFasiPresentate is null
	
	if @@rowcount=0										-- NESSUNA FASE DA NOTIFICARE
		GOTO FINE
	
	-- inserisco nelle variazioni le Variazioni Ente Titolare come in SP_ACCREDITAMENTO_ELENCOVARIAZIONI_PADRE
	update
		tt
	set 
		Variazioni='Modifica Ente Titolare'
	from
		NotificheFasiPresentateDati tt
		inner join EntiFasi_Enti efe on efe.IdEnteFase=tt.IdEnteFase
	where 
		len(efe.CodiceEnte)=7 and tt.IdNotificaFasiPresentate=@IdNotificaFasiPresentate
		
	-- inserisco nelle variazioni le Variazioni Enti di Accoglienza come in SP_ACCREDITAMENTO_ELENCOVARIAZIONI_FIGLI
	DECLARE @myIdEnteFase INT,@myVariazioni varchar(max)
	DECLARE MYCUR CURSOR LOCAL FOR
		select IdEnteFase,Variazioni from NotificheFasiPresentateDati tt where tt.IdNotificaFasiPresentate=@IdNotificaFasiPresentate

		OPEN MYCUR
		FETCH NEXT FROM MYCUR INTO @myIdEnteFase,@myVariazioni

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			select @myVariazioni=coalesce(@myVariazioni + ', ' + az,az)
			from
			(
			select case azione
				when 'Nuovo Ente' then 'Iscrizione ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Ente' else 'Enti' end
				when 'Richiesta Modifica' then 'Modifica ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Ente' else 'Enti' end
				else 'Cancellazione ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Ente' else 'Enti' end
			end az
			from EntiFasi_Enti where identefase=@myIdEnteFase and len(codiceente)>7 group by Azione
			) tefe		
			
			update NotificheFasiPresentateDati set Variazioni=@myVariazioni where IdEnteFase=@myIdEnteFase and IdNotificaFasiPresentate=@IdNotificaFasiPresentate
			
			FETCH NEXT FROM MYCUR INTO @myIdEnteFase,@myVariazioni		
		END
		
		CLOSE MYCUR  
		DEALLOCATE MYCUR 	
		
	-- inserisco nelle variazioni le Variazioni Sedi come in SP_ACCREDITAMENTO_ELENCOVARIAZIONI_SEDI
	DECLARE @myIdEnteFase1 INT,@myVariazioni1 varchar(max)
	DECLARE MYCUR1 CURSOR LOCAL FOR
		select IdEnteFase,Variazioni from NotificheFasiPresentateDati tt where tt.IdNotificaFasiPresentate=@IdNotificaFasiPresentate

		OPEN MYCUR1
		FETCH NEXT FROM MYCUR1 INTO @myIdEnteFase1,@myVariazioni1

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			select @myVariazioni1=coalesce(@myVariazioni1 + ', ' + az,az)
			from
			(
			select case azione
				when 'Nuova Sede' then 'Iscrizione ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Sede' else 'Sedi' end
				when 'Richiesta Modifica' then 'Modifica ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Sede' else 'Sedi' end
				else 'Cancellazione ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Sede' else 'Sedi' end
			end az
			from EntiFasi_Sedi efs
			inner join entisediattuazioni b on efs.IdEnteSedeAttuazione = b.IDEnteSedeAttuazione		
			where identefase=@myIdEnteFase1 group by Azione
			) tefe		
			
			update NotificheFasiPresentateDati set Variazioni=@myVariazioni1 where IdEnteFase=@myIdEnteFase1 and IdNotificaFasiPresentate=@IdNotificaFasiPresentate
			
			FETCH NEXT FROM MYCUR1 INTO @myIdEnteFase1,@myVariazioni1		
		END
		
		CLOSE MYCUR1  
		DEALLOCATE MYCUR1 

	-- inserisco nelle variazioni le Variazioni Risorse come in SP_ACCREDITAMENTO_ELENCOVARIAZIONI_RISORSE
	DECLARE @myIdEnteFase2 INT,@myVariazioni2 varchar(max)
	DECLARE MYCUR2 CURSOR LOCAL FOR
		select IdEnteFase,Variazioni from NotificheFasiPresentateDati tt where tt.IdNotificaFasiPresentate=@IdNotificaFasiPresentate

		OPEN MYCUR2
		FETCH NEXT FROM MYCUR2 INTO @myIdEnteFase2,@myVariazioni2

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			select @myVariazioni2=coalesce(@myVariazioni2 + ', ' + az,az)
			from
			(
			select case azione
				when 'Nuovo Ruolo' then 'Iscrizione ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Ruolo' else 'Ruoli' end
				else 'Cancellazione ' + cast(count(*) as varchar) + ' ' + case count(*) when 1 then 'Ruolo' else 'Ruoli' end
			end az
			from 
				(
					select azione from EntiFasi_Risorse where identefase=@myIdEnteFase2
					union all
					select azione from EntiFasi_Personale where identefase=@myIdEnteFase2
				) efs
			group by Azione
			) tefe		
			
			update NotificheFasiPresentateDati set Variazioni=@myVariazioni2 where IdEnteFase=@myIdEnteFase2 and IdNotificaFasiPresentate=@IdNotificaFasiPresentate
			
			FETCH NEXT FROM MYCUR2 INTO @myIdEnteFase2,@myVariazioni2		
		END
		
		CLOSE MYCUR2  
		DEALLOCATE MYCUR2 	

	-- inserisco nelle variazioni le Variazioni Sistemi come in SP_ACCREDITAMENTO_ELENCOVARIAZIONI_RISORSE
	declare @tEntiFasi_EntiSistemi TABLE(		-- attualmente non esiste va simulata chiamando la stored
		[Sistema/Documento] varchar(255) null,
		[Azione] varchar(255) NULL
	)
	
	DECLARE @myIdEnteFase3 INT,@myVariazioni3 varchar(max),@myIdEnte3 int
	DECLARE MYCUR3 CURSOR LOCAL FOR
		select IdEnteFase,Variazioni,IdEnte from NotificheFasiPresentateDati tt where tt.IdNotificaFasiPresentate=@IdNotificaFasiPresentate

		OPEN MYCUR3
		FETCH NEXT FROM MYCUR3 INTO @myIdEnteFase3,@myVariazioni3,@myIdEnte3

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			delete from @tEntiFasi_EntiSistemi
			INSERT INTO @tEntiFasi_EntiSistemi exec [SP_ACCREDITAMENTO_ELENCOVARIAZIONI_SISTEMI] @myIdEnte3,@MyIdEnteFase3
			
			select @myVariazioni3=coalesce(@myVariazioni3 + ', ' + az,az)
			from
			(
			select cast(efs.n as varchar) + 
					case azione when 'Nuovo Inserimento' then case efs.n when 1 then ' inserimento nella ' else ' inserimenti nella ' end
								else case efs.n when 1 then ' modifica alla ' else ' modifiche alla ' end
								--cast(efs.n as varchar) + 'Modifica ' + ' ' + case efs.n when 1 then 'Sistema' else 'Sistemi' end
					end + 'Struttura Organizzativa/Sistemi Funzionali' az
			from 
				(
					select azione,COUNT(*) as N from @tEntiFasi_EntiSistemi group by azione
				) efs
			group by Azione,n
			) tefe		
			
			update NotificheFasiPresentateDati set Variazioni=@myVariazioni3 where IdEnteFase=@myIdEnteFase3 and IdNotificaFasiPresentate=@IdNotificaFasiPresentate
			
			FETCH NEXT FROM MYCUR3 INTO @myIdEnteFase3,@myVariazioni3,@myIdEnte3		
		END
		
		CLOSE MYCUR3  
		DEALLOCATE MYCUR3
		
		--creazione file
		DECLARE @nomefile varchar(100)
		DECLARE @sql varchar(max)
		DECLARE @comandobcp varchar(8000)

		set @nomefile = @tmpPath+CONVERT(VARCHAR,@IdNotificaFasiPresentate) + '_' + REPLACE(DBO.FORMATODATA(getdate()),'/','') + '_NotificaFasiPresentate.xls'
		DECLARE @OLE INT
		DECLARE @FileID INT

		print 'inizio scrittura file'

		EXECUTE sp_OACreate 'Scripting.FileSystemObject', @OLE OUT
		EXECUTE sp_OAMethod @OLE, 'OpenTextFile', @FileID OUT, @nomefile, 8, 1
		EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, '<table cellspacing="0" rules="all" border="1" style="border-collapse:collapse;">'
		--intestazioni
		declare @a as varchar(1000)
		declare @b as varchar(1000)
		declare @c as varchar(1000)
		declare @d as varchar(1000)
		declare @e as varchar(1000)
		declare @f as varchar(1000)
		declare @g as varchar(1000)			
		declare @h as varchar(1000)			-- serve per ordinamento per data protocollo, non inserita in excel	
		declare @stringa as varchar(8000)
		declare @isIntestazione as bit=1	-- la prima riga è l'intestazione

		DECLARE MYCUR3 CURSOR LOCAL FOR
		select * from
		(
			select 'N.' as a,'CODICE CP/SU' as b,'DENOMINAZIONE ENTE' as c,'NUOVA ISCRIZIONE O NUMERO FASE ADEGUAMENTO' as d,'VARIAZIONI (Attività di dettaglio)*' as e,'PRESENTAZIONE ISTANZA (Data PEC)' as f,'PROTOCOLLO' as g,'ordinamento' as h
			UNION ALL SELECT cast(row_number() over(PARTITION BY idnotificafasipresentate order by idnotificafasipresentate) as varchar),nullif([CodiceRegione],'XXXXXXX') ,nullif([Denominazione],''''),nullif([Tipo],''''),nullif([Variazioni],''''),nullif(convert(varchar(10),pd.[DataProtocollo],103),''''),'Prot. Num. ' + nullif(cast([NumeroProtocollo] as varchar),''''),convert(varchar,pd.[DataProtocollo],127)
			FROM NotificheFasiPresentateDati
			left join ProtocolloDomanda pd on pd.IdEnteFase=NotificheFasiPresentateDati.IdEnteFase and NotificheFasiPresentateDati.IdEnte=pd.IdEnte			
			where IdNotificaFasiPresentate= @IdNotificaFasiPresentate
		) t
		order by case when t.h='ordinamento' then 0 else 1 end,t.h

		OPEN MYCUR3
		FETCH NEXT FROM MYCUR3 INTO @a,@b,@c,@d,@e,@f,@g,@h

		WHILE @@FETCH_STATUS = 0
		BEGIN
			if @isIntestazione=1
				EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, '	<tr style="font-weight:bold;">'
			else
				EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, '	</tr><tr>'

			set @isIntestazione=0

			set @stringa='		<td>'+isnull(@a,'')
			set @stringa=@stringa+'</td><td>'+isnull(@b,'')
			set @stringa=@stringa+'</td><td>'+isnull(@c,'')
			set @stringa=@stringa+'</td><td>'+isnull(@d,'')
			set @stringa=@stringa+'</td><td>'+isnull(@e,'')
			set @stringa=@stringa+'</td><td>'+isnull(@f,'')
			set @stringa=@stringa+'</td><td>'+isnull(@g,'')+'</td>'
			
			EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, @stringa

			FETCH NEXT FROM MYCUR3 INTO @a,@b,@c,@d,@e,@f,@g,@h
		END
		--chiusura file
		EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, '	</tr>'
		EXECUTE sp_OAMethod @FileID, 'Write', Null, '</table>'
		EXECUTE sp_OADestroy @FileID
		EXECUTE sp_OADestroy @OLE

		print 'fine scrittura file'

		CLOSE MYCUR3
		DEALLOCATE MYCUR3
		
		--declare @allegato varchar(100)=replace(@nomefile,'\\','\')

		-- INVIO EMAIL	
		EXEC SP_INVIO_MAIL_ALLEGATO 
			'heliosweb@serviziocivile.it', 					--MAIL MITTENTE
			'HELIOSWEB', 									--MITTENTE
			@email, 										-- EMAIL DESTINATARIO
			'',												--@CC, --COPIA CARBONE
			'heliosweb@serviziocivile.it',					--COPIA CARBONE NASCOSTA
			@OGGETTO, 										--OGGETTO
			@messaggiocc, 									--TESTO EMAIL
			@nomefile										--ALLEGATI
		
		print 'allegato=' + @nomefile

		--aggiorno tutte le fasi appena inserite come notificate
		update ef
			set IdNotificaFasiPresentate=@IdNotificaFasiPresentate
		from EntiFasi ef inner join NotificheFasiPresentateDati nfpd on nfpd.IdEnteFase=ef.IdEnteFase
		where nfpd.IdNotificaFasiPresentate=@IdNotificaFasiPresentate

FINE:
		--aggiorno il record master con la data notifica (o tentata notifica se non c'erano fasi da notificare)
		update NotificheFasiPresentate set DataNotifica=getdate() where IdNotificaFasiPresentate=@IdNotificaFasiPresentate

--	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
		PRINT 'ERRORE ' + ERROR_MESSAGE()
	END	
END CATCH
GO
