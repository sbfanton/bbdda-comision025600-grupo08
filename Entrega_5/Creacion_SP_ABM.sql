USE Com5600G08
GO

--MODIFICAR UNIDAD FUNCIONAL-----

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Unidad_Funcional
    @id INT,
    @id_consorcio INT,
    @piso VARCHAR(10),
    @depto VARCHAR(10),
    @porcentaje DECIMAL(5,2),
    @superficie_m2 DECIMAL(7,2),
    @tiene_cochera BIT = 0,
    @tiene_baulera BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id AND id_consorcio = @id_consorcio)
        THROW 50000, 'Unidad Funcional no encontrada.', 1;

    IF @porcentaje <= 0 OR @porcentaje > 100
        THROW 50000, 'Porcentaje fuera de rango (0,100].', 1;

    IF @superficie_m2 <= 0
        THROW 50000, 'Superficie debe ser > 0.', 1;

	IF @piso LIKE '%[^0-9A-Za-z -]%'
    THROW 50000, 'El valor de piso contiene caracteres no permitidos (solo letras, números, espacios o guiones).', 1;

	IF @depto LIKE '%[^0-9A-Za-z -]%'
    THROW 50000, 'El valor de depto contiene caracteres no permitidos (solo letras, números, espacios o guiones).', 1;

    UPDATE gestion.Unidad_Funcional
    SET piso = @piso,
        depto = @depto,
        porcentaje = @porcentaje,
        superficie_m2 = @superficie_m2,
        tiene_cochera = @tiene_cochera,
        tiene_baulera = @tiene_baulera
    WHERE id = @id AND id_consorcio = @id_consorcio;
END
GO

--ELIMINAR UNIDAD FUNCIONAL----

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Unidad_Funcional
    @id INT,
    @id_consorcio INT
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id AND id_consorcio = @id_consorcio)
        THROW 50000, 'Unidad_Funcional no existe.', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Unidad_Funcional_Persona
        WHERE id_unidad_funcional = @id AND id_consorcio_unidad_funcional = @id_consorcio
    )
        THROW 50000, 'No se puede eliminar Unidad Funcional: existen Persona-UF asociados.', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id AND id_consorcio_unidad_funcional = @id_consorcio
    )
        THROW 50000, 'No se puede eliminar Unidad Funcional: existen Cuentas Bancarias asociadas.', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Pago
        WHERE id_unidad_funcional = @id AND id_consorcio_unidad_funcional = @id_consorcio
    )
        THROW 50000, 'No se puede eliminar Unidad Funcional: existen Pagos asociados.', 1;

    DELETE FROM gestion.Unidad_Funcional WHERE id = @id AND id_consorcio = @id_consorcio;
END
GO

--------------------------------------------------------------------------------
-- Unidad_Funcional_Persona 
--(PK: id_unidad_funcional, id_consorcio_unidad_funcional, id_tipo_doc_persona, nro_doc_persona)
--------------------------------------------------------------------------------

---INSERTAR UF_PERSONA----

CREATE OR ALTER PROCEDURE gestion.sp_alta_Unidad_Funcional_Persona
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @id_tipo_doc_persona VARCHAR(5),
    @nro_doc_persona INT,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @es_inquilino BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id_unidad_funcional AND id_consorcio = @id_consorcio_unidad_funcional)
        THROW 50000, 'Unidad_Funcional no existe.', 1;

    IF NOT EXISTS(SELECT 1 FROM gestion.Persona WHERE nro_doc = @nro_doc_persona AND id_tipo_documento = @id_tipo_doc_persona)
        THROW 50000, 'Persona no existe.', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Unidad_Funcional_Persona
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND id_tipo_doc_persona = @id_tipo_doc_persona
          AND nro_doc_persona = @nro_doc_persona
    )
        THROW 50000, 'La relación Unidad_Funcional_Persona ya existe.', 1;

   /* IF @fecha_desde IS NOT NULL AND @fecha_hasta IS NOT NULL AND @fecha_desde > @fecha_hasta
        THROW 50000, 'fecha_desde no puede ser mayor que fecha_hasta.', 1;*/

    INSERT INTO gestion.Unidad_Funcional_Persona
    (id_unidad_funcional, id_consorcio_unidad_funcional, id_tipo_doc_persona, nro_doc_persona, fecha_desde, fecha_hasta, es_inquilino)
    VALUES (@id_unidad_funcional, @id_consorcio_unidad_funcional, @id_tipo_doc_persona, @nro_doc_persona, @fecha_desde, @fecha_hasta, @es_inquilino);
END
GO

---MODIFICAR UF_PERSONA---

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Unidad_Funcional_Persona
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @id_tipo_doc_persona VARCHAR(5),
    @nro_doc_persona INT,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @es_inquilino BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(
        SELECT 1 FROM gestion.Unidad_Funcional_Persona
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND id_tipo_doc_persona = @id_tipo_doc_persona
          AND nro_doc_persona = @nro_doc_persona
    )
        THROW 50000, 'Unidad_Funcional_Persona no encontrada.', 1;

    /*IF @fecha_desde IS NOT NULL AND @fecha_hasta IS NOT NULL AND @fecha_desde > @fecha_hasta
        THROW 50000, 'fecha_desde no puede ser mayor que fecha_hasta.', 1;*/

    UPDATE gestion.Unidad_Funcional_Persona
    SET fecha_desde = @fecha_desde,
        fecha_hasta = @fecha_hasta,
        es_inquilino = @es_inquilino
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND id_tipo_doc_persona = @id_tipo_doc_persona
      AND nro_doc_persona = @nro_doc_persona;
END
GO

----ELIMINAR UF_PERSONA----

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Unidad_Funcional_Persona
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @id_tipo_doc_persona VARCHAR(5),
    @nro_doc_persona INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 
        FROM gestion.Unidad_Funcional_Persona
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND id_tipo_doc_persona = @id_tipo_doc_persona
          AND nro_doc_persona = @nro_doc_persona
    )
	THROW 50000, 'Unidad_Funcional_Persona no encontrada.', 1;

    DELETE FROM gestion.Unidad_Funcional_Persona
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND id_tipo_doc_persona = @id_tipo_doc_persona
      AND nro_doc_persona = @nro_doc_persona;
END
GO

--------------------------------------------------------------------------------
-- Cuenta_Bancaria_Asociada_UF 
--(PK: id_unidad_funcional, id_consorcio_unidad_funcional, cbu_cvu)
--------------------------------------------------------------------------------

---INSERTAR CUENTA BANCARIA UF----
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
          AND cbu_cvu = @cbu_cvu
    )
        THROW 50000, 'La cuenta bancaria ya está asociada a esa UF.', 1;

    INSERT INTO gestion.Cuenta_Bancaria_Asociada_UF (id_unidad_funcional, id_consorcio_unidad_funcional, cbu_cvu)
    VALUES (@id_unidad_funcional, @id_consorcio_unidad_funcional, @cbu_cvu);
END
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

    IF NOT EXISTS(
        SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu = @cbu_cvu_viejo
    )
        THROW 50000, 'Cuenta bancaria original no encontrada.', 1;

    IF @cbu_cvu_nuevo IS NULL OR LEN(@cbu_cvu_nuevo) <> 22
        THROW 50000, 'CBU/CVU nuevo inválido (22 dígitos).', 1;

    -- evitar duplicado con el nuevo
    IF EXISTS(
        SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu = @cbu_cvu_nuevo
    )
        THROW 50000, 'El nuevo CBU/CVU ya existe para esa UF.', 1;

    UPDATE gestion.Cuenta_Bancaria_Asociada_UF
    SET cbu_cvu = @cbu_cvu_nuevo
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND cbu_cvu = @cbu_cvu_viejo;
END
GO

---ELIMINAR CUENTA BANCARIA UF---

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @cbu_cvu CHAR(22)
AS
BEGIN
    SET NOCOUNT ON;

	 IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id_unidad_funcional AND id_consorcio = @id_consorcio_unidad_funcional)
        THROW 50000, 'Unidad_Funcional no existe.', 1;

	 IF @cbu_cvu IS NULL OR LEN(@cbu_cvu) <> 22
        THROW 50000, 'CBU/CVU nuevo inválido (22 dígitos).', 1;

    IF NOT EXISTS(
        SELECT 1 FROM gestion.Cuenta_Bancaria_Asociada_UF
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND cbu_cvu = @cbu_cvu
    )
        THROW 50000, 'Cuenta bancaria asociada a la Unidad Funcional no existe.', 1;

    DELETE FROM gestion.Cuenta_Bancaria_Asociada_UF
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND cbu_cvu = @cbu_cvu;
END
GO

--------------------------------------------------------------------------------
-- Pago (id identity)
--------------------------------------------------------------------------------

---INSERTAR PAGO--
CREATE OR ALTER PROCEDURE gestion.sp_alta_Pago
    @id_unidad_funcional INT = NULL,
    @id_consorcio_unidad_funcional INT = NULL,
    @cbu_cvu_origen CHAR(22),
    @fecha DATETIME,
    @importe DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

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

    INSERT INTO gestion.Pago (id_unidad_funcional, id_consorcio_unidad_funcional, cbu_cvu_origen, fecha, importe)
    VALUES (@id_unidad_funcional, @id_consorcio_unidad_funcional, @cbu_cvu_origen, @fecha, @importe);
END
GO

---ELIMINAR PAGO---

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Pago
    @id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Pago WHERE id = @id)
        THROW 50000, 'No existe el pago especificado.', 1;
	--es correcto eliminar el pago asi nomas? o tengo que crear una tabla de auditoria? eso va en el der?
    DELETE FROM gestion.Pago WHERE id = @id;
END
GO