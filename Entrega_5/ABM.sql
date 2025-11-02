use Com5600G08

--PRUEBAS PARA VERIFICAR LOS RESULTADOS DE LAS SPS
SELECT * FROM gestion.Tipo_Documento

SELECT * FROM GESTION.Persona
where Persona.nro_doc=12345678

--PROCEDIMIENTOS PARA AMB TIPO_DOCUMENTO
--ALTA
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

exec ALTA_PERSONA 12345678, 'DNI', 'ARMANDO', 'BARRERA', 'X@HOTMAIL.COM', '987654321' 
exec BAJA_PERSONA 12345678
exec MODIFICACION_PERSONA 12345678, 'seymourskinner@gmail.com'

--MODIFICACION PERSONA (SOLO EMAIL) (SQL DINAMICO???)
CREATE PROCEDURE MODIFICACION_PERSONA 
	@NRO_DOC INT,
	@email_modificar varchar(150)
AS
BEGIN 
	update GESTION.Persona set persona.email=@email_modificar
	where persona.nro_doc=@NRO_DOC
END