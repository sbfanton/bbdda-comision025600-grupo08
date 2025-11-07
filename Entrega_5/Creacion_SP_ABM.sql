USE Com5600G08
GO
--------------------------------------------------------------------------------
-- Tipo_Documento
--------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE gestion.sp_alta_Tipo_Documento
    @id VARCHAR(5),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF @id IS NULL OR LTRIM(RTRIM(@id)) = ''
        THROW 50000, 'Debe indicar id del tipo de documento.', 1;

    IF EXISTS(SELECT 1 FROM gestion.Tipo_Documento WHERE id = @id)
        THROW 50000, 'Ya existe un Tipo_Documento con ese id.', 1;

    INSERT INTO gestion.Tipo_Documento(id, descripcion)
    VALUES (@id, @descripcion);
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Tipo_Documento
    @id VARCHAR(5),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM gestion.Tipo_Documento WHERE id = @id)
        THROW 50000, 'Tipo_Documento no encontrado.', 1;

    UPDATE gestion.Tipo_Documento
    SET descripcion = @descripcion
    WHERE id = @id;
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Tipo_Documento
    @id VARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(SELECT 1 FROM gestion.Persona WHERE id_tipo_documento = @id)
        THROW 50000, 'No se puede eliminar Tipo_Documento: existen Personas asociadas.', 1;
	IF NOT EXISTS(SELECT 1 FROM gestion.Persona WHERE id_tipo_documento = @id)
        THROW 50000, 'No existen Tipo_Documento.', 1;


    DELETE FROM gestion.Tipo_Documento WHERE id = @id;
END
GO

--------------------------------------------------------------------------------
-- Persona (PK: nro_doc, id_tipo_documento)
--------------------------------------------------------------------------------
--select top 10* from gestion.persona

CREATE OR ALTER PROCEDURE gestion.sp_alta_Persona
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
    IF @id_tipo_documento IS NULL OR LTRIM(RTRIM(@id_tipo_documento)) = ''
        THROW 50000, 'Debe indicar id_tipo_documento.', 1;
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50000, 'Nombre obligatorio.', 1;
    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50000, 'Apellido obligatorio.', 1;

    IF NOT EXISTS(SELECT 1 FROM gestion.Tipo_Documento WHERE id = @id_tipo_documento)
        THROW 50000, 'Tipo de documento no existe.', 1;

    IF EXISTS(SELECT 1 FROM gestion.Persona WHERE nro_doc = @nro_doc AND id_tipo_documento = @id_tipo_documento)
        THROW 50000, 'Ya existe una Persona con ese documento.', 1;

    INSERT INTO gestion.Persona (nro_doc, id_tipo_documento, nombre, apellido, email, telefono)
    VALUES (@nro_doc, @id_tipo_documento, @nombre, @apellido, @email, @telefono);
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Persona
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
        THROW 50000, 'Id de persona no encontrado.', 1;

	IF @nro_doc IS NULL OR @nro_doc <= 0
        THROW 50000, 'Nro_doc inválido.', 1;
    IF @id_tipo_documento IS NULL OR LTRIM(RTRIM(@id_tipo_documento)) = ''
        THROW 50000, 'Debe indicar id_tipo_documento.', 1;
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50000, 'Nombre obligatorio.', 1;
    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50000, 'Apellido obligatorio.', 1;

    IF NOT EXISTS(SELECT 1 FROM gestion.Tipo_Documento WHERE id = @id_tipo_documento)
        THROW 50000, 'Tipo de documento no existe.', 1;

	IF EXISTS(SELECT 1 FROM gestion.Persona 
			  WHERE nro_doc = @nro_doc 
				AND id_tipo_documento = @id_tipo_documento 
				AND id <> @id_persona)
    THROW 50000, 'Ya existe una Persona con ese documento.', 1;

	IF @email IS NOT NULL AND LTRIM(RTRIM(@email)) NOT LIKE '_%@_%._%'
		THROW 50000, 'Email no válido.', 1;
	IF @telefono IS NOT NULL AND LTRIM(RTRIM(@telefono)) LIKE '%[^0-9+ -]%'
		THROW 50000, 'Teléfono no válido.', 1;

	IF (
        (@telefono IS NULL OR LTRIM(RTRIM(@telefono)) = '')
        AND
        (@email IS NULL OR LTRIM(RTRIM(@email)) = '')
	)
		THROW 50000, 'Debe ingresar al menos un teléfono o email.', 1;

	UPDATE gestion.Persona
	SET nro_doc = @nro_doc,
		id_tipo_documento = @id_tipo_documento,
		nombre = @nombre,
		apellido = @apellido,
		email = @email,
		telefono = @telefono
	WHERE id = @id_persona;
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Persona
    @id_persona INT
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 FROM gestion.Persona WHERE id = @id_persona)
        THROW 50000, 'No existen Persona con el ID ingresado.', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Unidad_Funcional_Persona
        WHERE id_persona = @id_persona
    )
        THROW 50000, 'No se puede eliminar Persona: tiene relaciones en Unidad_Funcional_Persona.', 1;

    DELETE FROM gestion.Persona
    WHERE id = @id_persona;
END
GO

--------------------------------------------------------------------------------
-- Consorcio (PK: id)
--------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE gestion.sp_alta_Consorcio
    @id INT,
    @nombre VARCHAR(100),
    @calle VARCHAR(100),
    @nro INT,
    @localidad VARCHAR(100),
    @provincia VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF @id IS NULL
        THROW 50000, 'Id obligatorio.', 1;
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50000, 'Nombre obligatorio.', 1;
    IF @calle IS NULL OR LTRIM(RTRIM(@calle)) = ''
        THROW 50000, 'Calle obligatorio.', 1;
    IF @nro IS NULL OR @nro <= 0
        THROW 50000, 'Nro obligatorio y mayor a 0.', 1;
    IF EXISTS(SELECT 1 FROM gestion.Consorcio WHERE id = @id)
        THROW 50000, 'Ya existe un Consorcio con ese id.', 1;

    INSERT INTO gestion.Consorcio (id, nombre, calle, nro, localidad, provincia)
    VALUES (@id,@nombre,@calle,@nro,@localidad,@provincia);
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Consorcio
    @id INT,
    @nombre VARCHAR(100),
    @calle VARCHAR(100),
    @nro INT,
    @localidad VARCHAR(100),
    @provincia VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM gestion.Consorcio WHERE id = @id)
        THROW 50000, 'Consorcio no encontrado.', 1;

    UPDATE gestion.Consorcio
    SET nombre = @nombre,
        calle = @calle,
        nro = @nro,
        localidad = @localidad,
        provincia = @provincia
    WHERE id = @id;
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Consorcio
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 FROM gestion.Consorcio WHERE id = @id)
    BEGIN
        THROW 50000, 'No existen id consorcio.', 1;
    END

    IF EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id_consorcio = @id)
        THROW 50000, 'No se puede eliminar Consorcio: existen Unidades Funcionales asociadas.', 1;

    IF EXISTS(SELECT 1 FROM gestion.Proveedor WHERE id_consorcio = @id)
        THROW 50000, 'No se puede eliminar Consorcio: existen Proveedores asociados.', 1;

    IF EXISTS(SELECT 1 FROM gestion.Gasto WHERE id_consorcio = @id)
        THROW 50000, 'No se puede eliminar Consorcio: existen Gastos asociados.', 1;

    DELETE FROM gestion.Consorcio WHERE id = @id;
END
GO

--------------------------------------------------------------------------------
-- Unidad_Funcional (PK: id, id_consorcio)
--------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE gestion.sp_alta_Unidad_Funcional
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

    IF @id IS NULL OR @id_consorcio IS NULL
        THROW 50000, 'Id de unidad y id_consorcio obligatorios.', 1;
    IF NOT EXISTS(SELECT 1 FROM gestion.Consorcio WHERE id = @id_consorcio)
        THROW 50000, 'Consorcio no existe.', 1;
    IF EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id AND id_consorcio = @id_consorcio)
        THROW 50000, 'Ya existe la Unidad Funcional en ese Consorcio.', 1;
    IF @porcentaje <= 0 OR @porcentaje > 100
        THROW 50000, 'Porcentaje fuera de rango (0,100].', 1;
    IF @superficie_m2 <= 0
        THROW 50000, 'Superficie debe ser > 0.', 1;

    INSERT INTO gestion.Unidad_Funcional (id, id_consorcio, piso, depto, porcentaje, superficie_m2, tiene_cochera, tiene_baulera)
    VALUES (@id, @id_consorcio, @piso, @depto, @porcentaje, @superficie_m2, @tiene_cochera, @tiene_baulera);
END
GO
	
---------------------------------------------------------------------------leila-------------------------------------------------

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
    @id_persona BIGINT,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @es_inquilino BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM gestion.Unidad_Funcional WHERE id = @id_unidad_funcional AND id_consorcio = @id_consorcio_unidad_funcional)
        THROW 50000, 'Unidad_Funcional no existe.', 1;

    IF NOT EXISTS(SELECT 1 FROM gestion.Persona WHERE id = @id_persona)
        THROW 50000, 'Persona no existe.', 1;

    IF EXISTS(
        SELECT 1 FROM gestion.Unidad_Funcional_Persona
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND id_persona = @id_persona
    )
        THROW 50000, 'La relación Unidad_Funcional_Persona ya existe.', 1;

   /* IF @fecha_desde IS NOT NULL AND @fecha_hasta IS NOT NULL AND @fecha_desde > @fecha_hasta
        THROW 50000, 'fecha_desde no puede ser mayor que fecha_hasta.', 1;*/

    INSERT INTO gestion.Unidad_Funcional_Persona
    (id_unidad_funcional, id_consorcio_unidad_funcional, id_persona, fecha_desde, fecha_hasta, es_inquilino)
    VALUES (@id_unidad_funcional, @id_consorcio_unidad_funcional, @id_persona, @fecha_desde, @fecha_hasta, @es_inquilino);
END
GO

---MODIFICAR UF_PERSONA---

CREATE OR ALTER PROCEDURE gestion.sp_modificar_Unidad_Funcional_Persona
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @id_persona bigint,
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
          AND id_persona = @id_persona
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
      AND id_persona = @id_persona;
END
GO

----ELIMINAR UF_PERSONA----

CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Unidad_Funcional_Persona
    @id_unidad_funcional INT,
    @id_consorcio_unidad_funcional INT,
    @id_persona bigint
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 
        FROM gestion.Unidad_Funcional_Persona
        WHERE id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
          AND id_persona = @id_persona
    )
	THROW 50000, 'Unidad_Funcional_Persona no encontrada.', 1;

    DELETE FROM gestion.Unidad_Funcional_Persona
    WHERE id_unidad_funcional = @id_unidad_funcional
      AND id_consorcio_unidad_funcional = @id_consorcio_unidad_funcional
      AND id_persona = @id_persona;
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
	@id_pago BIGINT,
    @id_unidad_funcional INT = NULL,
    @id_consorcio_unidad_funcional INT = NULL,
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

    INSERT INTO gestion.Pago (id, id_unidad_funcional, id_consorcio_unidad_funcional, cbu_cvu_origen, fecha, importe)
    VALUES (@id_pago, @id_unidad_funcional, @id_consorcio_unidad_funcional, @cbu_cvu_origen, @fecha, @importe);
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


---------------------------------------------------------------------------eze-------------------------------------------------
---MODIFICAR PAGO---
CREATE OR ALTER PROCEDURE gestion.sp_modificar_Pago
    @id_pago BIGINT,
    @nuevo_importe DECIMAL(10,2),
    @nueva_fecha DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Pago WHERE id = @id_pago)
        THROW 50000, 'Pago no encontrado.', 1;

    IF @nuevo_importe <= 0
        THROW 50000, 'El importe debe ser mayor a 0.', 1;

    UPDATE gestion.Pago
    SET importe = @nuevo_importe,
        fecha = @nueva_fecha
    WHERE id = @id_pago;
END
GO


--------------------------------------------------------------------------------
-- Tipo_Gasto
-- (PK: id)
--------------------------------------------------------------------------------

---ALTA TIPO GASTO---
CREATE OR ALTER PROCEDURE gestion.sp_alta_Tipo_Gasto
    @nombre VARCHAR(100),
    @es_extraordinario BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50000, 'Debe indicar un nombre.', 1;

    IF EXISTS (SELECT 1 FROM gestion.Tipo_Gasto WHERE nombre = @nombre)
        THROW 50000, 'Ya existe un tipo de gasto con ese nombre.', 1;

    INSERT INTO gestion.Tipo_Gasto (nombre, es_extraordinario)
    VALUES (@nombre, @es_extraordinario);
END
GO

---MODIFICAR TIPO GASTO---
CREATE OR ALTER PROCEDURE gestion.sp_modificar_Tipo_Gasto
    @id_gasto INT,
    @nuevo_nombre VARCHAR(100),
    @nuevo_es_extraordinario BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Tipo_Gasto WHERE id = @id_gasto)
        THROW 50000, 'Tipo de gasto no encontrado.', 1;

    IF EXISTS (SELECT 1 FROM gestion.Tipo_Gasto WHERE nombre = @nuevo_nombre)
        THROW 50000, 'Ya existe un tipo de gasto con ese nombre.', 1;

    UPDATE gestion.Tipo_Gasto
    SET nombre = @nuevo_nombre,
        es_extraordinario = @nuevo_es_extraordinario
    WHERE id = @id_gasto;
END
GO

---ELIMINAR TIPO GASTO---
CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Tipo_Gasto
    @id_gasto INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Tipo_Gasto WHERE id = @id_gasto)
        THROW 50000, 'Tipo de gasto no encontrado.', 1;

    IF EXISTS (SELECT 1 FROM gestion.Gasto WHERE id_tipo_gasto = @id_gasto)
        THROW 50000, 'No se puede eliminar: hay gastos asociados a este tipo.', 1;

    DELETE FROM gestion.Tipo_Gasto WHERE id = @id_gasto;
END
GO


--------------------------------------------------------------------------------
-- Proveedor
-- (PK: id)
--------------------------------------------------------------------------------

---ALTA PROVEEDOR---
CREATE OR ALTER PROCEDURE gestion.sp_alta_Proveedor
    @id_tipo_gasto INT,
    @id_consorcio INT,
    @nombre VARCHAR(100),
    @detalle VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Tipo_Gasto WHERE id = @id_tipo_gasto)
        THROW 50000, 'Tipo de gasto inexistente.', 1;

    IF NOT EXISTS (SELECT 1 FROM gestion.Consorcio WHERE id = @id_consorcio)
        THROW 50000, 'Consorcio inexistente.', 1;

    INSERT INTO gestion.Proveedor (id_tipo_gasto, id_consorcio, nombre, detalle)
    VALUES (@id_tipo_gasto, @id_consorcio, @nombre, @detalle);
END
GO

---MODIFICAR PROVEEDOR---
CREATE OR ALTER PROCEDURE gestion.sp_modificar_Proveedor
    @id_proveedor INT,
    @nuevo_nombre VARCHAR(100),
    @nuevo_detalle VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Proveedor WHERE id = @id_proveedor)
        THROW 50000, 'Proveedor no encontrado.', 1;

    UPDATE gestion.Proveedor
    SET nombre = @nuevo_nombre,
        detalle = @nuevo_detalle
    WHERE id = @id_proveedor;
END
GO

---ELIMINAR PROVEEDOR---
CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Proveedor
    @id_proveedor INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Proveedor WHERE id = @id_proveedor)
        THROW 50000, 'Proveedor no encontrado.', 1;

    DELETE FROM gestion.Proveedor WHERE id = @id_proveedor;
END
GO


--------------------------------------------------------------------------------
-- Gasto
-- (PK: id)
--------------------------------------------------------------------------------

---ALTA GASTO---
CREATE OR ALTER PROCEDURE gestion.sp_alta_Gasto
    @id_tipo_gasto INT,
    @id_consorcio INT,
    @mes TINYINT,
    @anio SMALLINT,
    @nro_factura VARCHAR(30),
    @importe DECIMAL(12,2),
    @descripcion VARCHAR(200),
    @cuotas_totales SMALLINT = NULL,
    @nro_cuota SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Tipo_Gasto WHERE id = @id_tipo_gasto)
        THROW 50000, 'Tipo de gasto inexistente.', 1;

    IF NOT EXISTS (SELECT 1 FROM gestion.Consorcio WHERE id = @id_consorcio)
        THROW 50000, 'Consorcio inexistente.', 1;

    IF @mes NOT BETWEEN 1 AND 12
        THROW 50000, 'Mes inválido (1-12).', 1;

    IF @anio NOT BETWEEN 2000 AND 2100
        THROW 50000, 'Año inválido (2000-2100).', 1;

    IF @importe < 0
        THROW 50000, 'Importe debe ser mayor o igual a 0.', 1;

    INSERT INTO gestion.Gasto (id_tipo_gasto, id_consorcio, mes, anio, nro_factura, importe, descripcion, cuotas_totales, nro_cuota)
    VALUES (@id_tipo_gasto, @id_consorcio, @mes, @anio, @nro_factura, @importe, @descripcion, @cuotas_totales, @nro_cuota);
END
GO

---MODIFICAR GASTO---
CREATE OR ALTER PROCEDURE gestion.sp_modificar_Gasto
    @id_gasto INT,
    @nuevo_importe DECIMAL(12,2),
    @nueva_descripcion VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Gasto WHERE id = @id_gasto)
        THROW 50000, 'Gasto no encontrado.', 1;

    UPDATE gestion.Gasto
    SET importe = @nuevo_importe,
        descripcion = @nueva_descripcion
    WHERE id = @id_gasto;
END
GO

---ELIMINAR GASTO---
CREATE OR ALTER PROCEDURE gestion.sp_eliminar_Gasto
    @id_gasto INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM gestion.Gasto WHERE id = @id_gasto)
        THROW 50000, 'Gasto no encontrado.', 1;

    DELETE FROM gestion.Gasto WHERE id = @id_gasto;
END

GO
