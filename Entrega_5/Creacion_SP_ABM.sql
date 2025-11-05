USE Com5600G08
GO
--PROCEDIMIENTOS PARA AMB TIPO_DOCUMENTO
--ALTA
--------------------------------------------------------------------------lucas--------------------------------------------------
CREATE PROCEDURE ALTA_TIPO_DOCUMENTO
	@id_nuevo varchar(5),
	@descripcion_nueva varchar(100)
AS
BEGIN 
	INSERT INTO GESTION.TIPO_DOCUMENTO VALUES (@id_nuevo,@descripcion_nueva)
END

--BAJA
CREATE PROCEDURE BAJA_TIPO_DOCUMENTO 
	@id_baja varchar(5)
AS
BEGIN 
	delete from GESTION.TIPO_DOCUMENTO where tipo_documento.id=@id_baja
END

--MODIFICACION
CREATE PROCEDURE MODIFICACION_TIPO_DOCUMENTO 
	@tipo_doc_modi varchar(100),
	@id_modi varchar(5)
AS
BEGIN 
	update GESTION.TIPO_DOCUMENTO set descripcion = @tipo_doc_modi
	where id = @id_modi
END

--pruebas de las SP
exec alta_tipo_documento 'PAS', 'Pasaporte'
exec baja_tipo_documento 'PAS'
exec MODIFICACION_TIPO_DOCUMENTO 'otro_doc', 'PAS'

SELECT * FROM gestion.Tipo_Documento
-----------------------------------------PERSONA---------------------------------------------------
--ALTA PERSONA
CREATE PROCEDURE ALTA_PERSONA
	@nro_doc int,
	@dni varchar(5),
	@nombre varchar(100),
	@apellido varchar(100),
	@email varchar(150),
	@telefono varchar(30)
AS
BEGIN 
	INSERT INTO GESTION.Persona VALUES (@nro_doc,@dni,@nombre,@apellido,@email,@telefono)
END

--BAJA PERSONA
CREATE PROCEDURE BAJA_PERSONA 
	@NRO_DOC INT
AS
BEGIN 
	delete from GESTION.Persona where PERSONA.nro_doc=@NRO_DOC
END


--------MODIFICACION---------
--EMAIL-- 
CREATE PROCEDURE MODIFICACION_PERSONA_EMAIL
	@NRO_DOC INT,
	@email_modificar varchar(150)
AS
BEGIN 
	update GESTION.Persona set persona.email=@email_modificar
	where persona.nro_doc=@NRO_DOC
END

--TELEFONO--
CREATE PROCEDURE MODIFICACION_PERSONA_TELEFONO
	@NRO_DOC INT,
	@telefono varchar(30)
AS
BEGIN 
	update GESTION.Persona set persona.telefono=@telefono
	where persona.nro_doc=@NRO_DOC
END

exec ALTA_PERSONA 12345678, 'DNI', 'ARMANDO', 'BARRERA', 'X@HOTMAIL.COM', '987654321' 
exec BAJA_PERSONA 12345678
exec MODIFICACION_PERSONA_EMAIL 12345678, 'seymourskinner@gmail.com'
exec MODIFICACION_PERSONA_TELEFONO 12345678, '87654321'

SELECT * FROM GESTION.Persona
where Persona.nro_doc=12345678
-----------------------------------------CONSORCIO---------------------------------------------------
select * from gestion.Consorcio

--ALTA CONSORCIO
CREATE PROCEDURE ALTA_CONSORCIO
	@id int,
	@nombre varchar(100),
	@calle varchar(100),
	@nro int,
	@localidad varchar(100),
	@provincia varchar(100),
	@cuit char(13),
	@razon_social varchar(100),
	@banco varchar(50),
	@cbu_cvu char(22)
AS
BEGIN 
	INSERT INTO GESTION.Consorcio VALUES (@id,@nombre,@calle,@nro,@localidad,@provincia,@cuit,@razon_social,@banco,@cbu_cvu)
END

--BAJA CONSORCIO
CREATE PROCEDURE BAJA_CONSORCIO
	@id INT
AS
BEGIN 
	delete from GESTION.Consorcio where Consorcio.id=@id
END

--MODIFICACION CONSORCIO
CREATE PROCEDURE MODIFICACION_CONSORCIO_NOMBRE
	@id INT,
	@nombre varchar(100)
AS
BEGIN 
	update GESTION.Consorcio set nombre=@nombre
	where Consorcio.id=@id
END
---UBICACION DEL CONSORCIO
CREATE PROCEDURE MODIFICACION_CONSORCIO_UBICACION
	@id INT,
	@calle varchar(100),
	@nro int,
	@localidad varchar(100),
	@provincia varchar(100)
AS
BEGIN 
	update GESTION.Consorcio set calle=@calle, nro=@nro, localidad=@localidad, provincia=@provincia 
	where Consorcio.id=@id
END
---DATOS SOCIALES Y DEL BANCO
CREATE PROCEDURE MODIFICACION_CONSORCIO_social
	@id INT,
	@cuit char(13),
	@razon_social varchar(100),
	@banco varchar(50),
	@cbu_cvu char(22)
AS
BEGIN 
	update GESTION.Consorcio set cuit=@cuit, razon_social=@razon_social, banco=@banco, cbu_cvu=@cbu_cvu 
	where Consorcio.id=@id
END

---PRUEBAS DE LAS SP
select * from gestion.Consorcio
exec ALTA_CONSORCIO 6,'Hola','Corrientes',4321,'Laferrere','Buenos Aires',NULL,NULL,'BANCO PROVINCIA',NULL
EXEC BAJA_CONSORCIO 6
EXEC MODIFICACION_CONSORCIO_NOMBRE 6, 'Armando Barrera'
EXEC MODIFICACION_CONSORCIO_UBICACION 6, 'Belgrano',3250,'Ciudad Aut noma de Buenos Aires','Ciudad Aut noma de Buenos Aires'
exec MODIFICACION_CONSORCIO_social 6,'20-12345678-8','BBVA FRANC S','BANCO SRL','1351324324312345678912'
-----------------------------------------UNIDAD FUNCIONAL---------------------------------------------------
---ALTA UNIDAD FUNCIONAL
CREATE PROCEDURE ALTA_UF
	@id int,
	@id_consorcio int,
	@piso varchar(10),
	@depto varchar(10),
	@porcentaje decimal(5,2),
	@superficie_m2 decimal(7,2),
	@tiene_cochera bit,
	@tiene_baulera bit
AS
BEGIN
	INSERT INTO GESTION.Unidad_Funcional VALUES(@id,@id_consorcio,@piso,@depto,@porcentaje,@superficie_m2,@tiene_cochera,@tiene_baulera)	
END

---PRUEBA ALTA UF
select * from gestion.Unidad_Funcional
where Unidad_Funcional.id=50 and id_consorcio=5

EXEC ALTA_UF 50 , 5, 'PA', 'C', 3.2 ,32.24, 1, 1




delete from gestion.unidad_funcional
where Unidad_Funcional.id=50 and id_consorcio=5
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