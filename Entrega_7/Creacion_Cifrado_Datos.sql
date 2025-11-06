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
------------------------------------------------------------
-- Verificacion
------------------------------------------------------------
SELECT TOP 10 *
FROM gestion.Cuenta_Bancaria_Asociada_UF;
go


--------------------para el PAGO------------
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

------------------------------------------------------------
-- Verificacion
------------------------------------------------------------
SELECT TOP 10 *FROM gestion.Pago;
SELECT TOP 10 *FROM gestion.Persona;

--veo que los hash coinciden, me habilita a seguir
select top 10* from gestion.Pago p join gestion.Cuenta_Bancaria_Asociada_UF cuf
on p.cbu_cvu_origen_Hash = cuf.cbu_cvu_Hash
GO


--cifro el cuenta_bancaria_asociada_uf
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

--cifro el pago
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

-- ENCRIPTAR PERSONA ----------------------------------------------------
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

--desencriptacion ESTA SIRVE
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

-- Desencriptar Persona -----------------------------------------------------------
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
        -- Se usa NVARCHAR porque el cifrado se hizo con NVARCHAR
        CONVERT(NVARCHAR(50), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, nro_doc_Cifrado)) AS nro_doc_desencriptado,
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, nombre_Cifrado)) AS nombre_desencriptado,
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, apellido_Cifrado)) AS apellido_desencriptado,
        CONVERT(VARCHAR(200), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, email_Cifrado)) AS email_desencriptado,
        CONVERT(VARCHAR(100), DecryptByPassPhrase(@FraseClaveCargadaPorUsuario, telefono_Cifrado)) AS telefono_desencriptado
    FROM gestion.Persona;
END
GO

EXEC gestion.sp_desencriptar_datos_cbu_cvu
@FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';

EXEC gestion.sp_desencriptar_datos_cbu_pago
@FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';

EXEC gestion.sp_desencriptar_datos_persona
@FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';

-- LO QUE SIGUE:
--MODIFICACIONES DE SP QUE USAN CBU_CVU Y CBU_CVU_ORIGEN--

------------de importacion--------------------
---------------------------------------------------------
-- SP IMPORTAR PERSONAS (con CBU CIFRADO CORRECTO)
---------------------------------------------------------
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
-- SP IMPORTAR PAGOS (con CBU CIFRADO CORRECTO)
---------------------------------------------------------
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

--------------------------------------------------------------------------------
-- Pago (id identity)
--------------------------------------------------------------------------------

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


--MUESTRA EL CBU_CVU EN CUENTA_BANCARIA
SELECT TOP 50
    cbu_cvu_Cifrado,
    CONVERT(VARCHAR(50), DecryptByPassPhrase('QuieroMiPanDanes', cbu_cvu_Cifrado, 1, cbu_cvu_Sal)) AS cbu_descifrado,
    cbu_cvu_Hash
FROM gestion.Cuenta_Bancaria_Asociada_UF
where id_unidad_funcional = 1;

--MUESTRA EL CBU_CVU_origen EN PAGO
SELECT TOP 20
    CONVERT(VARCHAR(50),
        DecryptByPassPhrase('QuieroMiPanDanes', cbu_cvu_origen_Cifrado, 1, cbu_cvu_origen_Sal)
    ) AS cbu_descifrado,
    cbu_cvu_origen_Hash
FROM gestion.Pago
--WHERE fecha = '2025-11-01'


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

------------------------------------------------------------------
--MISMO PROCESO PARA LA TABLA PERSONA
