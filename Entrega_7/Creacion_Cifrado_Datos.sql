USE Com5600G08
GO
--------------------
--DEJO A MODO DE EJEMPLO/GUIA DE LA DIAPO UNIDAD 5, MODIFICAR EN ESTE ARCHIVO
-------------------
  
/*DATOS PERSONALES: 
tabla persona: nro_doc, id_tipo_documento, nombre, apellido, email, telefono
tabla Consorcio:banco
tabla Cuenta_Bancaria_Asociada_uf:cbu_cvu, 
pago: cbu_cvu_origen, importe
*/


-- Agregamos un campo para los datos cifrados, esto no se si es correcto, ya le pregunte a Julio, esperando respuesta
ALTER TABLE gestion.Cuenta_Bancaria_Asociada_UF
ADD cbu_cvu_CifradaFraseClave VARBINARY(256);
GO
  
CREATE OR ALTER PROCEDURE gestion.sp_cifrar_datos_cbu_cvu
AS
BEGIN
    SET NOCOUNT ON;
-- Obtenemos la clave de cifrado. Lo cargaríamos desde otra capa.
	DECLARE @FraseClaveCargadaPorUsuario NVARCHAR(128);
	SET @FraseClaveCargadaPorUsuario = 'QuieroMiPanDanes';

	UPDATE gestion.Cuenta_Bancaria_Asociada_UF
	SET cbu_cvu_CifradaFraseClave =
	EncryptByPassPhrase(@FraseClaveCargadaPorUsuario
	, cbu_cvu, 1, CONVERT(varbinary, cbu_cvu))
END



--desencriptacion
CREATE OR ALTER PROCEDURE gestion.sp_desencriptar_datos_cbu_cvu
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @FraseClaveCargadaPorUsuario NVARCHAR(128);
	SET @FraseClaveCargadaPorUsuario = 'QuieroMiPanDanes';

SELECT 
    id_unidad_funcional,
	id_consorcio_unidad_funcional,
    CONVERT(VARCHAR(50), 
        DecryptByPassPhrase(
            @FraseClaveCargadaPorUsuario, 
            cbu_cvu_CifradaFraseClave, 
            1, 
            CONVERT(varbinary, cbu_cvu)
        )
    ) AS cbu_cvu_desencriptado
FROM gestion.Cuenta_Bancaria_Asociada_UF
END

  --TESTING
--ciframos
EXEC gestion.sp_cifrar_datos_cbu_cvu
--vemos el campo cifrado
select top 10* from gestion.Cuenta_Bancaria_Asociada_UF
--deciframos
EXEC gestion.sp_desencriptar_datos_cbu_cvu
