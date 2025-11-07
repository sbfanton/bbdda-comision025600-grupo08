USE Com5600G08
GO

/*DATOS PERSONALES: 
tabla persona: nro_doc, nombre, apellido, email, telefono
tabla Cuenta_Bancaria_Asociada_uf:cbu_cvu, listo
pago: cbu_cvu_origen listo
*/
--tablas originales
SELECT TOP 10 * FROM gestion.persona
SELECT TOP 10 * FROM gestion.Cuenta_Bancaria_Asociada_uf
SELECT TOP 10 * FROM gestion.pago


-------------Agregamos nueva columna---
ALTER TABLE gestion.Cuenta_Bancaria_Asociada_UF
ADD cbu_cvu_Cifrado VARBINARY(256);
GO
------------------------------------------------------------
-- 1) Agregar columna SAL (para poder seguir descifrando)
------------------------------------------------------------
ALTER TABLE gestion.Cuenta_Bancaria_Asociada_UF
ADD cbu_cvu_Sal VARBINARY(MAX);
go
UPDATE gestion.Cuenta_Bancaria_Asociada_UF
SET cbu_cvu_Sal = CONVERT(varbinary, cbu_cvu);
go
------------------------------------------------------------
-- 2) Agregar columna HASH (para joins)
------------------------------------------------------------
ALTER TABLE gestion.Cuenta_Bancaria_Asociada_UF
ADD cbu_cvu_Hash VARBINARY(32);
go
UPDATE gestion.Cuenta_Bancaria_Asociada_UF
SET cbu_cvu_Hash = HASHBYTES('SHA2_256', cbu_cvu);
go

-------------para el PAGO------------
ALTER TABLE gestion.Pago
ADD cbu_cvu_origen_Cifrado VARBINARY(MAX) NULL;
GO
------------------------------------------------------------
-- 3) Agregar HASH y SAL a la tabla Pago
------------------------------------------------------------
ALTER TABLE gestion.Pago
ADD cbu_cvu_origen_Hash VARBINARY(32);
GO
UPDATE gestion.Pago
SET cbu_cvu_origen_Hash = HASHBYTES('SHA2_256', cbu_cvu_origen);
GO
ALTER TABLE gestion.Pago
ADD cbu_cvu_origen_Sal VARBINARY(MAX);
GO
UPDATE gestion.Pago
SET cbu_cvu_origen_Sal = CONVERT(varbinary, cbu_cvu_origen);
GO

--------------------para PERSONA------------
ALTER TABLE gestion.Persona
ADD nro_doc_Cifrado VARBINARY(MAX) NULL,
    nombre_Cifrado VARBINARY(MAX) NULL,
    apellido_Cifrado VARBINARY(MAX) NULL,
    email_Cifrado VARBINARY(MAX) NULL,
    telefono_Cifrado VARBINARY(MAX) NULL;
GO

------------------------------------------------------------
-- 4) Agregar HASH y SAL a la tabla Persona
------------------------------------------------------------
ALTER TABLE gestion.Persona
ADD nro_doc_Hash VARBINARY(32),
    nombre_Hash VARBINARY(32),
    apellido_Hash VARBINARY(32),
    email_Hash VARBINARY(32),
    telefono_Hash VARBINARY(32),
    nro_doc_Sal VARBINARY(MAX),
    nombre_Sal VARBINARY(MAX),
    apellido_Sal VARBINARY(MAX),
    email_Sal VARBINARY(MAX),
    telefono_Sal VARBINARY(MAX);
GO

UPDATE gestion.Persona
SET nro_doc_Hash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(50), nro_doc)),
    nombre_Hash = HASHBYTES('SHA2_256', nombre),
    apellido_Hash = HASHBYTES('SHA2_256', apellido),
    email_Hash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(200), email)),
    telefono_Hash = HASHBYTES('SHA2_256', telefono),
    nro_doc_Sal = CONVERT(varbinary, nro_doc),
    nombre_Sal = CONVERT(varbinary, nombre),
    apellido_Sal = CONVERT(varbinary, apellido),
    email_Sal = CONVERT(varbinary, email),
    telefono_Sal = CONVERT(varbinary, telefono);
GO


--SPs para cifrar
CREATE OR ALTER PROCEDURE gestion.sp_encriptar_cuentas_bancarias
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    UPDATE gestion.Cuenta_Bancaria_Asociada_UF
    SET cbu_cvu_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            CONVERT(VARCHAR(50), cbu_cvu_Sal), -- convierto la sal a string (valor original)
            1,
            cbu_cvu_Sal
        )
    WHERE cbu_cvu_Cifrado IS NULL;
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_encriptar_cbu_pago
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    UPDATE gestion.Pago
    SET cbu_cvu_origen_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            CONVERT(VARCHAR(50), cbu_cvu_origen_Sal),
            1,
            cbu_cvu_origen_Sal
        )
    WHERE cbu_cvu_origen_Cifrado IS NULL;
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_encriptar_persona
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'QuieroMiPanDanes';

    UPDATE gestion.Persona
    SET 
        -- nro_doc lo tratamos como texto para encriptarlo de forma segura
        nro_doc_Cifrado   = EncryptByPassPhrase(@FraseClave, CAST(nro_doc AS NVARCHAR(50))),
        nombre_Cifrado    = EncryptByPassPhrase(@FraseClave, nombre),
        apellido_Cifrado  = EncryptByPassPhrase(@FraseClave, apellido),
        email_Cifrado     = EncryptByPassPhrase(@FraseClave, email),
        telefono_Cifrado  = EncryptByPassPhrase(@FraseClave, telefono)
    WHERE nro_doc_Cifrado IS NULL;
END
GO

-- Limpiar cifrados para generarlos de nuevo
UPDATE gestion.Persona
SET nro_doc_Cifrado = NULL, nombre_Cifrado = NULL, apellido_Cifrado = NULL, email_Cifrado = NULL, telefono_Cifrado = NULL;

EXEC gestion.sp_encriptar_cuentas_bancarias
EXEC gestion.sp_encriptar_cbu_pago
EXEC gestion.sp_encriptar_persona
	
--vemos el campo cifrado
select top 10* from gestion.Cuenta_Bancaria_Asociada_UF
select top 10* from gestion.Pago
select top 10* from gestion.Persona
GO
	
--deciframos

--SPs para descifrar
--cuenta_bancaria
CREATE OR ALTER PROCEDURE gestion.sp_desencriptar_datos_cbu_cvu
    @FraseClaveCargadaPorUsuario NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FraseClaveCargadaPorUsuario <> 'QuieroMiPanDanes'
    BEGIN
        THROW 50000, 'Frase clave incorrecta. No se realizó la operación de descifrado.', 1;
    END;

    SELECT 
        id_unidad_funcional,
        id_consorcio_unidad_funcional,
        CONVERT(VARCHAR(50), 
            DecryptByPassPhrase(
                @FraseClaveCargadaPorUsuario, 
                cbu_cvu_Cifrado, 
                1, 
                cbu_cvu_Sal 
            )
        ) AS cbu_cvu_desencriptado
    FROM gestion.Cuenta_Bancaria_Asociada_UF;
END
GO

-- Pago
CREATE OR ALTER PROCEDURE gestion.sp_desencriptar_datos_cbu_pago
    @FraseClaveCargadaPorUsuario NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FraseClaveCargadaPorUsuario <> 'QuieroMiPanDanes'
    BEGIN
        THROW 50000, 'Frase clave incorrecta. No se realizó la operación de descifrado.', 1;
    END;

    SELECT 
        id AS id_pago,
        id_unidad_funcional,
        id_consorcio_unidad_funcional,
        CONVERT(VARCHAR(50),
            DecryptByPassPhrase(
                @FraseClaveCargadaPorUsuario,
                cbu_cvu_origen_Cifrado,
                1,
                cbu_cvu_origen_Sal
            )
        ) AS cbu_cvu_origen_desencriptado
    FROM gestion.Pago;
END
GO

--Persona
CREATE OR ALTER PROCEDURE gestion.sp_desencriptar_datos_persona
    @FraseClaveCargadaPorUsuario NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FraseClaveCargadaPorUsuario <> N'QuieroMiPanDanes'
    BEGIN
        THROW 50000, 'Frase clave incorrecta. No se realizó la operación de descifrado.', 1;
    END;

    SELECT 
        id AS id_persona,
        id_tipo_documento,
        -- Se usa NVARCHAR porque el cifrado se hizo con NVARCHAR           ----descomentar solo modifiquemos el sp de importar
        CONVERT(NVARCHAR(50), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, nro_doc_Cifrado/*, 1, nro_doc_Sal*/)) AS nro_doc_desencriptado, 
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, nombre_Cifrado/*,1, nombre_Sal*/)) AS nombre_desencriptado,
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, apellido_Cifrado/*,1, apellido_Sal*/)) AS apellido_desencriptado,
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, email_Cifrado/*,1, email_Sal*/)) AS email_desencriptado,
        CONVERT(VARCHAR(100), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, telefono_Cifrado/*,1, telefono_Sal*/)) AS telefono_desencriptado
    FROM gestion.Persona;
END
GO


--ULTIMO PASO
---borrar columna original de  Cuenta_Bancaria_Asociada_UF
--primero borro constraints asociadas al campo
ALTER TABLE gestion.Cuenta_Bancaria_Asociada_UF
DROP CONSTRAINT cuenta_bancaria_asociada_UF_cbu_cvu_ck;
GO
--borro el campo
ALTER TABLE gestion.Cuenta_Bancaria_Asociada_UF
DROP COLUMN cbu_cvu;
GO

---borrar columna original de  Pago
--primero borro constraints asociadas al campo
ALTER TABLE gestion.Pago
DROP CONSTRAINT pago_cbu_cvu_origen_ck
GO
--borro el campo
ALTER TABLE gestion.Pago
DROP COLUMN cbu_cvu_origen;
GO

---borrar columnas originales de Persona
--primero borro constraints asociadas al campo
ALTER TABLE gestion.Persona
DROP CONSTRAINT persona_tipo_documento_fk, persona_nro_doc_ck, persona_email_ck, persona_telefono_ck, persona_ck_contacto;
GO
-- borro los campos
ALTER TABLE gestion.Persona
DROP COLUMN nro_doc, nombre, apellido, email, telefono;
GO	

	--PRUEBA
EXEC gestion.sp_desencriptar_datos_cbu_cvu
@FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';

EXEC gestion.sp_desencriptar_datos_cbu_pago
@FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';

EXEC gestion.sp_desencriptar_datos_persona
@FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';
GO

-- LO QUE SIGUE:
--MODIFICACIONES DE SP QUE USAN CBU_CVU Y CBU_CVU_ORIGEN Y DATOS DE PERSONAS--


------------de importacion--------------------
---------------------------------------------------------
-- SP IMPORTAR PERSONAS
CREATE OR ALTER PROCEDURE gestion.sp_importar_personas
    @pathPersonasDatos NVARCHAR(4000),
    @pathPersonasUF NVARCHAR(4000),
    @rowTerminatorPersonas NVARCHAR(10) = '\n',
    @rowTerminatorPersonasUF NVARCHAR(10) = '\n',
    @fieldTerminatorPersonas NVARCHAR(10) = ';',
    @fieldTerminatorPersonasUF NVARCHAR(10) = '|'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#tmp_personas') IS NOT NULL DROP TABLE #tmp_personas;
        IF OBJECT_ID('tempdb..#tmp_personas_UF') IS NOT NULL DROP TABLE #tmp_personas_UF;

        CREATE TABLE #tmp_personas (
            nombre NVARCHAR(100),
            apellido NVARCHAR(100),
            dni NVARCHAR(20),
            email_personal NVARCHAR(150),
            telefono_contacto NVARCHAR(30),
            cvu_cbu NVARCHAR(30),
            inquilino NVARCHAR(10)
        );

        DECLARE @sql NVARCHAR(MAX) =
        N'BULK INSERT #tmp_personas FROM ''' + @pathPersonasDatos + ''' WITH (
            FIRSTROW = 2, FIELDTERMINATOR = ''' + @fieldTerminatorPersonas + ''', ROWTERMINATOR = ''' + @rowTerminatorPersonas + ''')';
        EXEC sp_executesql @sql;

        CREATE TABLE #tmp_personas_UF (
            cvu_cbu NVARCHAR(30),
            consorcio NVARCHAR(20),
            uf NVARCHAR(5),
            piso NVARCHAR(5),
            depto NVARCHAR(5)
        );

        DECLARE @sql2 NVARCHAR(MAX) =
        N'BULK INSERT #tmp_personas_UF FROM ''' + @pathPersonasUF + ''' WITH (
            FIRSTROW = 2, FIELDTERMINATOR = ''' + @fieldTerminatorPersonasUF + ''', ROWTERMINATOR = ''' + @rowTerminatorPersonasUF + ''')';
        EXEC sp_executesql @sql2;

        SELECT 
            p.nombre, p.apellido, p.dni, p.email_personal, p.telefono_contacto,
            LTRIM(RTRIM(p.cvu_cbu)) AS cvu_cbu,
            CASE 
                WHEN LTRIM(RTRIM(p.inquilino)) = '1' THEN 1
                WHEN LTRIM(RTRIM(p.inquilino)) = '0' THEN 0
                ELSE NULL 
            END AS inquilino,
            c.id AS id_consorcio,
            r.uf, r.piso, r.depto
        INTO #PersonasUF
        FROM #tmp_personas p
        INNER JOIN #tmp_personas_UF r ON LTRIM(RTRIM(p.cvu_cbu)) = LTRIM(RTRIM(r.cvu_cbu))
        INNER JOIN gestion.Consorcio c ON c.nombre = r.consorcio;

        SELECT 
            p.*,
            ROW_NUMBER() OVER (PARTITION BY p.dni ORDER BY p.apellido) AS dni_rn,
            ROW_NUMBER() OVER (PARTITION BY p.cvu_cbu, p.id_consorcio, p.uf ORDER BY p.id_consorcio) AS cbu_uf_rn
        INTO #PersonasUFConRN 
        FROM #PersonasUF p;

        INSERT INTO gestion.Persona (nro_doc, id_tipo_documento, nombre, apellido, email, telefono)
        SELECT
            CAST(p.dni AS INT),
			'DNI',
            LTRIM(RTRIM(p.nombre)),
			LTRIM(RTRIM(p.apellido)),
            LTRIM(RTRIM(p.email_personal)),
			LTRIM(RTRIM(p.telefono_contacto))
        FROM #PersonasUFConRN p
        WHERE 
		p.dni IS NOT NULL
		AND ISNUMERIC(p.dni) = 1
          AND NOT EXISTS (
                SELECT 1 FROM gestion.Persona per
                WHERE per.nro_doc = CAST(p.dni AS INT)
                  AND per.id_tipo_documento = 'DNI'
          );

        INSERT INTO gestion.Unidad_Funcional_Persona (
            id_unidad_funcional,
			id_consorcio_unidad_funcional,
			id_persona,
            fecha_desde,
			fecha_hasta,
			es_inquilino
        )
        SELECT
            CAST(p.uf AS INT),
			CAST(p.id_consorcio AS INT),
			gp.id,
            NULL,
			NULL,
			CAST(p.inquilino AS BIT)
        FROM #PersonasUFConRN p
        INNER JOIN gestion.Persona gp ON gp.nro_doc = CAST(p.dni AS INT)
        WHERE 
			p.dni IS NOT NULL
            AND p.dni <> ''
			AND ISNUMERIC(p.dni) = 1
			AND NOT EXISTS (
            SELECT 1 FROM gestion.Unidad_Funcional_Persona uf
            WHERE uf.id_persona = gp.id 
              AND uf.id_unidad_funcional = CAST(p.uf AS INT)
              AND uf.id_consorcio_unidad_funcional = CAST(p.id_consorcio AS INT)
        );

        INSERT INTO gestion.Cuenta_Bancaria_Asociada_UF (
            id_unidad_funcional,
			id_consorcio_unidad_funcional,
            cbu_cvu_Cifrado,
			cbu_cvu_Sal,
			cbu_cvu_Hash
        )
        SELECT
            CAST(uf.uf AS INT),
            CAST(uf.id_consorcio AS INT),
            EncryptByPassPhrase(@FraseClave, CAST(uf.cvu_cbu AS VARCHAR(22)), 1, CONVERT(varbinary(50), CAST(uf.cvu_cbu AS VARCHAR(22)))),
            CONVERT(varbinary(50), CAST(uf.cvu_cbu AS VARCHAR(22))),
            HASHBYTES('SHA2_256', CAST(uf.cvu_cbu AS VARCHAR(22)))
        FROM #PersonasUF uf
        WHERE NOT EXISTS (
            SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF x
            WHERE x.id_unidad_funcional = CAST(uf.uf AS INT)
              AND x.id_consorcio_unidad_funcional = CAST(uf.id_consorcio AS INT)
              AND x.cbu_cvu_Hash = HASHBYTES('SHA2_256', CAST(uf.cvu_cbu AS VARCHAR(22)))
        );

        DROP TABLE #PersonasUFConRN;
        DROP TABLE #PersonasUF;
        DROP TABLE #tmp_personas;
        DROP TABLE #tmp_personas_UF;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

---------------------------------------------------------
-- SP IMPORTAR PAGOS 
CREATE OR ALTER PROCEDURE gestion.sp_importar_pagos
    @path NVARCHAR(4000),
    @rowTerminator NVARCHAR(10) = '\n',
    @fieldTerminator NVARCHAR(10) = ','
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#tmp_pagos') IS NOT NULL DROP TABLE #tmp_pagos;

        CREATE TABLE #tmp_pagos (
            id_pago NVARCHAR(10),
            fecha NVARCHAR(20),
            cvu_cbu NVARCHAR(22),
            valor NVARCHAR(50)
        );

        DECLARE @sql NVARCHAR(MAX) =
        N'BULK INSERT #tmp_pagos FROM ''' + @path + ''' WITH (
            FIRSTROW = 2, FIELDTERMINATOR = ''' + @fieldTerminator + ''', ROWTERMINATOR = ''' + @rowTerminator + ''')';
        EXEC sp_executesql @sql;

        DELETE FROM #tmp_pagos
        WHERE id_pago IS NULL OR fecha IS NULL OR cvu_cbu IS NULL OR valor IS NULL;

        ;WITH Pagos_ufs AS (
            SELECT
                CAST(NULLIF(LTRIM(RTRIM(t.id_pago)), '') AS bigint) AS id_pago,
                cba.id_unidad_funcional AS id_uf,
                cba.id_consorcio_unidad_funcional AS id_cons_uf,
                LTRIM(RTRIM(t.cvu_cbu)) AS cbu,
                HASHBYTES('SHA2_256', CAST(LTRIM(RTRIM(t.cvu_cbu)) AS VARCHAR(22))) AS cbu_hash,
                CONVERT(varbinary(50), CAST(LTRIM(RTRIM(t.cvu_cbu)) AS VARCHAR(22))) AS cbu_sal,
                CONVERT(DATETIME, t.fecha, 103) AS FechaConvertida,
                CAST(
				rtrim(
                    ltrim(
						REPLACE(
							REPLACE(
								REPLACE(t.valor, CHAR(13), '')
								, '.', '')
							,'$', ''))) AS DECIMAL(10,2)) AS importe
            FROM #tmp_pagos t
            LEFT JOIN gestion.Cuenta_Bancaria_Asociada_UF cba
                ON HASHBYTES('SHA2_256', CAST(LTRIM(RTRIM(t.cvu_cbu)) AS VARCHAR(22))) = cba.cbu_cvu_Hash
        )
        INSERT INTO gestion.Pago (
            id, id_unidad_funcional,
			id_consorcio_unidad_funcional,
            cbu_cvu_origen_Cifrado,
			cbu_cvu_origen_Sal,
			cbu_cvu_origen_Hash,
            fecha, importe
        )
        SELECT
            p.id_pago,
            p.id_uf,
            p.id_cons_uf,
            EncryptByPassPhrase(@FraseClave, CAST(p.cbu AS VARCHAR(22)), 1, p.cbu_sal),
            p.cbu_sal,
            p.cbu_hash,
            p.FechaConvertida,
            p.importe
        FROM Pagos_ufs p
        WHERE p.id_pago IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM gestion.Pago gp WHERE gp.id = p.id_pago);

        DROP TABLE #tmp_pagos;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_importar_personas --PROBADO
    @pathPersonasDatos NVARCHAR(4000),
    @pathPersonasUF NVARCHAR(4000),
    @rowTerminatorPersonas NVARCHAR(10) = '\n',
    @rowTerminatorPersonasUF NVARCHAR(10) = '\n',
    @fieldTerminatorPersonas NVARCHAR(10) = ';',
    @fieldTerminatorPersonasUF NVARCHAR(10) = '|'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'QuieroMiPanDanes';

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#tmp_personas') IS NOT NULL DROP TABLE #tmp_personas;
        IF OBJECT_ID('tempdb..#tmp_personas_UF') IS NOT NULL DROP TABLE #tmp_personas_UF;

        CREATE TABLE #tmp_personas (
            nombre NVARCHAR(100),
            apellido NVARCHAR(100),
            dni NVARCHAR(20),
            email_personal NVARCHAR(150),
            telefono_contacto NVARCHAR(30),
            cvu_cbu NVARCHAR(30),
            inquilino NVARCHAR(10)
        );

        DECLARE @sql NVARCHAR(MAX) =
        N'BULK INSERT #tmp_personas FROM ''' + @pathPersonasDatos + ''' WITH (
            FIRSTROW = 2, FIELDTERMINATOR = ''' + @fieldTerminatorPersonas + ''', ROWTERMINATOR = ''' + @rowTerminatorPersonas + ''')';
        EXEC sp_executesql @sql;

        CREATE TABLE #tmp_personas_UF (
            cvu_cbu NVARCHAR(30),
            consorcio NVARCHAR(20),
            uf NVARCHAR(5),
            piso NVARCHAR(5),
            depto NVARCHAR(5)
        );

        DECLARE @sql2 NVARCHAR(MAX) =
        N'BULK INSERT #tmp_personas_UF FROM ''' + @pathPersonasUF + ''' WITH (
            FIRSTROW = 2, FIELDTERMINATOR = ''' + @fieldTerminatorPersonasUF + ''', ROWTERMINATOR = ''' + @rowTerminatorPersonasUF + ''')';
        EXEC sp_executesql @sql2;

        SELECT 
            p.nombre, p.apellido, p.dni, p.email_personal, p.telefono_contacto,
            LTRIM(RTRIM(p.cvu_cbu)) AS cvu_cbu,
            CASE 
                WHEN LTRIM(RTRIM(p.inquilino)) = '1' THEN 1
                WHEN LTRIM(RTRIM(p.inquilino)) = '0' THEN 0
                ELSE NULL 
            END AS inquilino,
            c.id AS id_consorcio,
            r.uf, r.piso, r.depto
        INTO #PersonasUF
        FROM #tmp_personas p
        INNER JOIN #tmp_personas_UF r ON LTRIM(RTRIM(p.cvu_cbu)) = LTRIM(RTRIM(r.cvu_cbu))
        INNER JOIN gestion.Consorcio c ON c.nombre = r.consorcio;

        SELECT 
            p.*,
            ROW_NUMBER() OVER (PARTITION BY p.dni ORDER BY p.apellido) AS dni_rn,
            ROW_NUMBER() OVER (PARTITION BY p.cvu_cbu, p.id_consorcio, p.uf ORDER BY p.id_consorcio) AS cbu_uf_rn
        INTO #PersonasUFConRN 
        FROM #PersonasUF p;

       -- INSERTA PERSONA CIFRADA
		INSERT INTO gestion.Persona (
			id_tipo_documento,
			nro_doc_Cifrado, nro_doc_Sal, nro_doc_Hash,
			nombre_Cifrado,  nombre_Sal,
			apellido_Cifrado, apellido_Sal,
			email_Cifrado,   email_Sal,
			telefono_Cifrado, telefono_Sal
		)
		SELECT
			'DNI',
			EncryptByPassPhrase(@FraseClave, CAST(CAST(p.dni AS INT) AS NVARCHAR(50)), 1, CONVERT(varbinary, CAST(p.dni AS INT))),
			CONVERT(varbinary, CAST(p.dni AS INT)),
			HASHBYTES('SHA2_256', CAST(CAST(p.dni AS INT) AS NVARCHAR(50))),

			EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(100), LTRIM(RTRIM(p.nombre))), 1, CONVERT(varbinary(200), CONVERT(VARCHAR(100), LTRIM(RTRIM(p.nombre))))),
			CONVERT(varbinary(200), CONVERT(VARCHAR(100), LTRIM(RTRIM(p.nombre)))),

			EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(100), LTRIM(RTRIM(p.apellido))), 1, CONVERT(varbinary(200), CONVERT(VARCHAR(100), LTRIM(RTRIM(p.apellido))))),
			CONVERT(varbinary(200), CONVERT(VARCHAR(100), LTRIM(RTRIM(p.apellido)))),

			CASE WHEN p.email_personal IS NULL OR LTRIM(RTRIM(p.email_personal)) = '' THEN NULL
				 ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(150), LTRIM(RTRIM(p.email_personal))), 1, CONVERT(varbinary(200), CONVERT(VARCHAR(150), LTRIM(RTRIM(p.email_personal))))) END,
			CASE WHEN p.email_personal IS NULL OR LTRIM(RTRIM(p.email_personal)) = '' THEN NULL
				 ELSE CONVERT(varbinary(200), CONVERT(VARCHAR(150), LTRIM(RTRIM(p.email_personal)))) END,

			CASE WHEN p.telefono_contacto IS NULL OR LTRIM(RTRIM(p.telefono_contacto)) = '' THEN NULL
				 ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(30), LTRIM(RTRIM(p.telefono_contacto))), 1, CONVERT(varbinary(200), CONVERT(VARCHAR(30), LTRIM(RTRIM(p.telefono_contacto))))) END,
			CASE WHEN p.telefono_contacto IS NULL OR LTRIM(RTRIM(p.telefono_contacto)) = '' THEN NULL
				 ELSE CONVERT(varbinary(200), CONVERT(VARCHAR(30), LTRIM(RTRIM(p.telefono_contacto)))) END
		FROM #PersonasUFConRN p
		WHERE p.dni IS NOT NULL
		  AND ISNUMERIC(p.dni) = 1
		  AND NOT EXISTS (
				SELECT 1 FROM gestion.Persona per
				WHERE per.id_tipo_documento = 'DNI'
				  AND per.nro_doc_Hash = HASHBYTES('SHA2_256', CAST(CAST(p.dni AS INT) AS NVARCHAR(50)))
		);

        ---- UF-PERSONA-> usa el hash del DNI ----
        INSERT INTO gestion.Unidad_Funcional_Persona (
            id_unidad_funcional,
            id_consorcio_unidad_funcional,
            id_persona,
            fecha_desde,
            fecha_hasta,
            es_inquilino
        )
        SELECT
            CAST(p.uf AS INT),
            CAST(p.id_consorcio AS INT),
            gp.id,
            NULL,
            NULL,
            CAST(p.inquilino AS BIT)
        FROM #PersonasUFConRN p
        INNER JOIN gestion.Persona gp
            ON gp.id_tipo_documento = 'DNI'
           AND gp.nro_doc_Hash = HASHBYTES('SHA2_256', CAST(CAST(p.dni AS INT) AS NVARCHAR(50)))
        WHERE 
            p.dni IS NOT NULL
            AND p.dni <> ''
            AND ISNUMERIC(p.dni) = 1
            AND NOT EXISTS (
                SELECT 1
                FROM gestion.Unidad_Funcional_Persona uf
                WHERE uf.id_persona = gp.id 
                  AND uf.id_unidad_funcional = CAST(p.uf AS INT)
                  AND uf.id_consorcio_unidad_funcional = CAST(p.id_consorcio AS INT)
        );

        INSERT INTO gestion.Cuenta_Bancaria_Asociada_UF (
            id_unidad_funcional,
            id_consorcio_unidad_funcional,
            cbu_cvu_Cifrado,
            cbu_cvu_Sal,
            cbu_cvu_Hash
        )
        SELECT
            CAST(uf.uf AS INT),
            CAST(uf.id_consorcio AS INT),
            EncryptByPassPhrase(@FraseClave, CAST(uf.cvu_cbu AS VARCHAR(22)), 1, CONVERT(varbinary(50), CAST(uf.cvu_cbu AS VARCHAR(22)))),
            CONVERT(varbinary(50), CAST(uf.cvu_cbu AS VARCHAR(22))),
            HASHBYTES('SHA2_256', CAST(uf.cvu_cbu AS VARCHAR(22)))
        FROM #PersonasUF uf
        WHERE NOT EXISTS (
            SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF x
            WHERE x.id_unidad_funcional = CAST(uf.uf AS INT)
              AND x.id_consorcio_unidad_funcional = CAST(uf.id_consorcio AS INT)
              AND x.cbu_cvu_Hash = HASHBYTES('SHA2_256', CAST(uf.cvu_cbu AS VARCHAR(22)))
        );

        DROP TABLE #PersonasUFConRN;
        DROP TABLE #PersonasUF;
        DROP TABLE #tmp_personas;
        DROP TABLE #tmp_personas_UF;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

------------de abm-----------
CREATE OR ALTER PROCEDURE gestion.sp_alta_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @cbu_cvu CHAR(22)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id_unidad_funcional AND id_consorcio = @id_consorcio_unidad_funcional)
        THROW 50000, 'Unidad_Funcional no existe.', 1;

    IF @cbu_cvu IS NULL OR LEN(@cbu_cvu) <> 22
        THROW 50000, 'CBU/CVU inválido (debe tener 22 dígitos).', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu_Hash = HASHBYTES('SHA2_256', @cbu_cvu)
    )
        THROW 50000, 'La cuenta bancaria ya está asociada a esa UF.', 1;

    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';


    INSERT INTO gestion.Cuenta_Bancaria_Asociada_UF (
        id_unidad_funcional,
        id_consorcio_unidad_funcional,
        cbu_cvu_Cifrado,
        cbu_cvu_Sal,
        cbu_cvu_Hash
    )
    VALUES (
        @id_unidad_funcional,
        @id_consorcio_unidad_funcional,
        EncryptByPassPhrase(@FraseClave, @cbu_cvu, 1, CONVERT(varbinary,@cbu_cvu)),
        CONVERT(varbinary,@cbu_cvu),
        HASHBYTES('SHA2_256', @cbu_cvu)
    );
END --PROBADA
GO

---MODIFICAR CUENTA BANCARIA UF---

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @cbu_cvu_viejo CHAR(22),
    @cbu_cvu_nuevo CHAR(22)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    -- Validaciones mínimas
    IF @cbu_cvu_nuevo IS NULL OR LEN(@cbu_cvu_nuevo) <> 22
        THROW 50000, 'CBU/CVU nuevo inválido (22 dígitos).', 1;

    -- Debe existir el registro con el CBU "viejo" (matcheo por HASH)
    IF NOT EXISTS (
        SELECT 1
        FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu_Hash = HASHBYTES('SHA2_256', @cbu_cvu_viejo)
    )
        THROW 50000, 'Cuenta bancaria original no encontrada.', 1;

    -- Evitar duplicado con el nuevo (por HASH)
    IF EXISTS (
        SELECT 1
        FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu_Hash = HASHBYTES('SHA2_256', @cbu_cvu_nuevo)
    )
        THROW 50000, 'El nuevo CBU/CVU ya existe para esa UF.', 1;

    -- Actualización atómica: recifrado + nueva sal + nuevo hash
    UPDATE gestion.Cuenta_Bancaria_Asociada_UF
    SET
        cbu_cvu_Cifrado = EncryptByPassPhrase(@FraseClave, @cbu_cvu_nuevo, 1, CONVERT(varbinary, @cbu_cvu_nuevo)),
        cbu_cvu_Sal     = CONVERT(varbinary, @cbu_cvu_nuevo),
        cbu_cvu_Hash    = HASHBYTES('SHA2_256', @cbu_cvu_nuevo)
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND cbu_cvu_Hash = HASHBYTES('SHA2_256', @cbu_cvu_viejo);
END --PROBADA
GO

---ELIMINAR CUENTA BANCARIA UF---

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @cbu_cvu CHAR(22)
AS
BEGIN
    SET NOCOUNT ON;

    IF @cbu_cvu IS NULL OR LEN(@cbu_cvu) <> 22
        THROW 50000, 'CBU/CVU inválido (22 dígitos).', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu_Hash = HASHBYTES('SHA2_256', @cbu_cvu)
    )
        THROW 50000, 'Cuenta bancaria asociada a la UF no existe.', 1;

    DELETE FROM gestion.Cuenta_Bancaria_Asociada_UF
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND cbu_cvu_Hash = HASHBYTES('SHA2_256', @cbu_cvu);
END --PROBADA
GO

---INSERTAR PAGO--
CREATE OR ALTER PROCEDURE gestion.sp_alta_Pago
    @id_pago BIGINT,
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @cbu_cvu_origen CHAR(22),
    @fecha DATETIME,
    @importe DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

	IF @id_pago IS NULL
        THROW 50000, 'id_pago es obligatorio.', 1;

    IF @cbu_cvu_origen IS NULL OR LTRIM(RTRIM(@cbu_cvu_origen)) = ''
        THROW 50000, 'CBU/CVU origen obligatorio.', 1;

    IF @fecha IS NULL
        THROW 50000, 'Fecha obligatoria.', 1;

    IF @importe IS NULL OR @importe <= 0
        THROW 50000, 'Importe debe ser mayor a 0.', 1;

    IF @id_unidad_funcional IS NOT NULL OR @id_consorcio_unidad_funcional IS NOT NULL
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional
                      WHERE id = @id_unidad_funcional AND id_consorcio = @id_consorcio_unidad_funcional)
            THROW 50000, 'Unidad_Funcional indicada no existe.', 1;
    END

    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    INSERT INTO gestion.Pago (
        id, id_unidad_funcional, id_consorcio_unidad_funcional,cbu_cvu_origen,
        cbu_cvu_origen_Cifrado, cbu_cvu_origen_Sal, cbu_cvu_origen_Hash,
        fecha, importe
    )
    VALUES (
        @id_pago,
        @id_unidad_funcional,
        @id_consorcio_unidad_funcional,
		@cbu_cvu_origen,
        EncryptByPassPhrase(@FraseClave, @cbu_cvu_origen, 1, CONVERT(varbinary,@cbu_cvu_origen)),
        CONVERT(varbinary,@cbu_cvu_origen),
        HASHBYTES('SHA2_256', @cbu_cvu_origen),
        @fecha,
        @importe
    );
END--PROBADA
GO

CREATE OR ALTER PROCEDURE gestion.sp_reporte_top_morosos
    @FraseClaveCargadaPorUsuario NVARCHAR(128),
    @IdConsorcio INT = NULL,
    @TopCantidad INT = 3,
    @DeudaMinima DECIMAL(18,2) = 0,
    @DeudaMaxima DECIMAL(18,2) = -1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @url NVARCHAR(256) = 'https://open.er-api.com/v6/latest/USD' 
    DECLARE @Object INT 
    DECLARE @json TABLE(respuesta NVARCHAR(MAX)) 
    DECLARE @respuesta NVARCHAR(MAX) -- Crear objeto HTTP 

    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT 
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE' 
    EXEC sp_OAMethod @Object, 'SEND' 
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT -- Guardar la respuesta JSON en la tabla 

    INSERT @json 
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT' -- Extraer la respuesta a una variable 

    SELECT @respuesta = respuesta FROM @json 
    DECLARE @usd_to_ars FLOAT = JSON_VALUE(@respuesta, '$.rates.ARS') 

    ;WITH Morosidad AS (
        SELECT 
            per.id,
            uf.id_consorcio,
            pro.deuda,
            per.nro_doc_Cifrado,
            per.nombre_Cifrado,
            per.apellido_Cifrado,
            per.telefono_Cifrado
        FROM gestion.Persona per
        JOIN gestion.Unidad_Funcional_Persona ufp ON per.id = ufp.id_persona
        JOIN gestion.Unidad_Funcional uf ON uf.id = ufp.id_unidad_funcional
            AND uf.id_consorcio = ufp.id_consorcio_unidad_funcional
        LEFT JOIN gestion.Prorrateo pro ON pro.id_unidad_funcional = uf.id
    )
    SELECT TOP (@TopCantidad)
        CONVERT(NVARCHAR(50), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, m.nro_doc_Cifrado)) AS nro_doc,
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, m.nombre_Cifrado)) + ', ' +
            CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, m.apellido_Cifrado)) AS nombre_y_apellido,
        CONVERT(VARCHAR(100), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, m.telefono_Cifrado)) AS telefono,
        m.deuda,
        CAST(ROUND(m.deuda / @usd_to_ars, 2) AS DECIMAL(10,2)) AS deuda_usd
    FROM Morosidad m
    WHERE (@IdConsorcio IS NULL OR m.id_consorcio = @IdConsorcio)
      AND m.deuda > @DeudaMinima
      AND (@DeudaMaxima < 0 OR m.deuda <= @DeudaMaxima)
    ORDER BY m.deuda DESC
    FOR XML PATH('TopMorosos'), ROOT('Morosidad');
END;
GO

--subir a git amb persona
CREATE OR ALTER PROCEDURE gestion.sp_alta_Persona --sin probar
	@nro_doc INT,
    @id_tipo_documento VARCHAR(5),
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @email VARCHAR(150) = NULL,
    @telefono VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @nro_doc IS NULL OR @nro_doc <= 0
        THROW 50000, 'Nro_doc inválido.', 1;
    IF NOT EXISTS(SELECT 1 FROM gestion.Tipo_Documento WHERE id = @id_tipo_documento)
        THROW 50000, 'Tipo de documento no existe.', 1;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50000, 'Nombre obligatorio.', 1;
    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50000, 'Apellido obligatorio.', 1;

    IF EXISTS(
        SELECT 1
        FROM gestion.Persona
        WHERE id_tipo_documento = @id_tipo_documento
          AND nro_doc_Hash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(50), @nro_doc))
    )
        THROW 50000, 'Ya existe una Persona con ese documento.', 1;

    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

    INSERT INTO gestion.Persona (
        id_tipo_documento,
        nro_doc_Cifrado, nro_doc_Sal, nro_doc_Hash,
        nombre_Cifrado, nombre_Sal,
        apellido_Cifrado, apellido_Sal,
        email_Cifrado, email_Sal,
        telefono_Cifrado, telefono_Sal
    )
    VALUES (
        @id_tipo_documento,
        EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(50), @nro_doc), 1, CONVERT(VARBINARY(50), CONVERT(NVARCHAR(50), @nro_doc))),
        CONVERT(VARBINARY(50), CONVERT(NVARCHAR(50), @nro_doc)),
        HASHBYTES('SHA2_256', CONVERT(NVARCHAR(50), @nro_doc)),

        EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(100), @nombre), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @nombre))),
        CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @nombre)),

        EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(100), @apellido), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @apellido))),
        CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @apellido)),

        CASE WHEN @email IS NULL THEN NULL
             ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(150), @email), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(150), @email))) END,
        CASE WHEN @email IS NULL THEN NULL
             ELSE CONVERT(VARBINARY(200), CONVERT(VARCHAR(150), @email)) END,

        CASE WHEN @telefono IS NULL THEN NULL
             ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(30), @telefono), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(30), @telefono))) END,
        CASE WHEN @telefono IS NULL THEN NULL
             ELSE CONVERT(VARBINARY(200), CONVERT(VARCHAR(30), @telefono)) END
    );
END


CREATE OR ALTER PROCEDURE gestion.sp_modificar_Persona --sin probar
    @id_persona INT,
	@nro_doc INT,
    @id_tipo_documento VARCHAR(5),
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @email VARCHAR(150) = NULL,
    @telefono VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM gestion.Persona WHERE id = @id_persona)
        THROW 50000, 'Persona no encontrada.', 1;

    IF @nro_doc IS NULL OR @nro_doc <= 0
        THROW 50000, 'Nro_doc inválido.', 1;

    IF EXISTS(
        SELECT 1
        FROM gestion.Persona
        WHERE id <> @id_persona
          AND id_tipo_documento = @id_tipo_documento
          AND nro_doc_Hash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(50), @nro_doc))
    )
        THROW 50000, 'Ya existe otra Persona con ese documento.', 1;

    DECLARE @FraseClave NVARCHAR(128) = 'QuieroMiPanDanes';

	UPDATE gestion.Persona
	SET
        id_tipo_documento = @id_tipo_documento,

        nro_doc_Cifrado = EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(50), @nro_doc), 1, CONVERT(VARBINARY(50), CONVERT(NVARCHAR(50), @nro_doc))),
        nro_doc_Sal     = CONVERT(VARBINARY(50), CONVERT(NVARCHAR(50), @nro_doc)),
        nro_doc_Hash    = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(50), @nro_doc)),

        nombre_Cifrado  = EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(100), @nombre), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @nombre))),
        nombre_Sal      = CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @nombre)),

        apellido_Cifrado = EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(100), @apellido), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @apellido))),
        apellido_Sal     = CONVERT(VARBINARY(200), CONVERT(VARCHAR(100), @apellido)),

        email_Cifrado    = CASE WHEN @email IS NULL THEN NULL ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(150), @email), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(150), @email))) END,
        email_Sal        = CASE WHEN @email IS NULL THEN NULL ELSE CONVERT(VARBINARY(200), CONVERT(VARCHAR(150), @email)) END,

        telefono_Cifrado = CASE WHEN @telefono IS NULL THEN NULL ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(30), @telefono), 1, CONVERT(VARBINARY(200), CONVERT(VARCHAR(30), @telefono))) END,
        telefono_Sal     = CASE WHEN @telefono IS NULL THEN NULL ELSE CONVERT(VARBINARY(200), CONVERT(VARCHAR(30), @telefono)) END
	WHERE id = @id_persona;
END
GO
	
-- Creacion Modelo Expensa
CREATE OR ALTER PROCEDURE gestion.sp_modelo_expensa
    @FraseClaveCargadaPorUsuario NVARCHAR(128),
    @id_consorcio INT,
    @mes TINYINT,
    @anio SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC gestion.sp_generar_expensa @id_consorcio, @mes, @anio

    EXEC gestion.sp_generar_prorrateo @id_consorcio, @mes, @anio

    SELECT 
        uf.id as Uf,
        uf.porcentaje AS '%',
        uf.piso + ' ' + uf.depto as 'Piso-Depto',
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, p.nombre_Cifrado)) + ', ' +
            CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, p.apellido_Cifrado)) AS 'Propietario',
        pr.monto_ordinarias AS 'Expensas Ordinarias',
        pr.monto_extraordinarias AS 'Expensas Extraordinarias',
        pr.deuda AS 'Deuda',
        pr.interes_mora AS 'Interés por mora',
        pr.saldo_abonado AS 'Saldo Abonado',
        (pr.monto_ordinarias + pr.monto_extraordinarias + pr.interes_mora) AS 'Total a Pagar'
    FROM gestion.Prorrateo pr
    INNER JOIN gestion.Unidad_Funcional uf 
        ON pr.id_unidad_funcional = uf.id 
        AND pr.id_consorcio_unidad_funcional = uf.id_consorcio
    LEFT JOIN gestion.Unidad_Funcional_Persona ufp 
        ON ufp.id_unidad_funcional = uf.id 
        AND ufp.id_consorcio_unidad_funcional = uf.id_consorcio
    LEFT JOIN gestion.Persona p 
        ON ufp.id_persona = p.id
    WHERE pr.id_expensa IN (
        SELECT id FROM gestion.Expensa 
        WHERE id_consorcio = @id_consorcio AND mes = @mes AND anio = @anio
    )
END



