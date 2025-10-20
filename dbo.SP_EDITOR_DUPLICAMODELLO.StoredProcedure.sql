USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[SP_EDITOR_DUPLICAMODELLO]    Script Date: 14/10/2025 12:36:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_EDITOR_DUPLICAMODELLO]
	@IdModelloTemplate int,
	@NomeLogicoNuovoModello varchar(100),
	@NomeFisicoNuovoModello varchar(100),
	@DescrizioneNuovoModello varchar(255),
	@ESITO VARCHAR(200) OUTPUT
AS
BEGIN
	declare @MYINTEGER int
	select @MYINTEGER = count(*) from editor_modelli where idmodello = @IdModelloTemplate
	
	IF @MYINTEGER = 0
	BEGIN
		SET @ESITO = 'MODELLO TEMPLATE NON ESISTENTE'
		RETURN
	END

	INSERT INTO EDITOR_MODELLI (IDAREA, IDREGIONECOMPETENZA, NOMELOGICO, NOMEFISICO, DESCRIZIONE)
	SELECT IDAREA, IDREGIONECOMPETENZA, @NomeLogicoNuovoModello, @NomeFisicoNuovoModello, @DescrizioneNuovoModello
	FROM EDITOR_MODELLI WHERE IDMODELLO = @IdModelloTemplate
	
	SET @MYINTEGER=@@IDENTITY
	
	INSERT INTO dbo.Editor_ModelliTag (IdModello, IdTag)
	SELECT @MYINTEGER, IdTag 
	FROM dbo.Editor_ModelliTag WHERE IDMODELLO = @IdModelloTemplate
	
	INSERT INTO dbo.Editor_ModelliCompetenze (IdModello, IdRegioneCompetenza, [Path], UsernameProprietario, DataCreazione, PathLocale)
	SELECT @MYINTEGER, IdRegioneCompetenza, [Path], UsernameProprietario, GETDATE(), PathLocale
	FROM dbo.Editor_ModelliCompetenze WHERE IDMODELLO = @IdModelloTemplate		
	
END


GO
