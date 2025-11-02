
USE Com5600G08
GO

---------------------------------
		/*TESTING*/
---------------------------------

-----------UF LOTE-------------

select TOP 20* from Com5600G08.gestion.Unidad_Funcional

---------MODIFICACIONES-----------

--porcentaje fuera del rango
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = NULL,
@depto = NULL,@porcentaje = 101,@superficie_m2 = 2,@tiene_cochera =1,@tiene_baulera = 0;
GO
--UF no encontrada(ya sea por id_uf o id_consorcio)
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = 'PB',
@depto = 'A',@porcentaje = 1,@superficie_m2 = 2,@tiene_cochera =1,@tiene_baulera = 0;
GO
--superficie fuera de rango
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = 'PB',
@depto = 'A',@porcentaje = 1,@superficie_m2 = -1,@tiene_cochera =1,@tiene_baulera = 0;
GO
--piso y depto con caracteres no validos
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = '/B',
@depto = 'A',@porcentaje = 1,@superficie_m2 = 2,@tiene_cochera =1,@tiene_baulera = 0;
GO
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = 'PB',
@depto = '*',@porcentaje = 1,@superficie_m2 = 2,@tiene_cochera =1,@tiene_baulera = 0;
GO
--caso exitoso
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = 'PB',
@depto = 'A',@porcentaje = 1,@superficie_m2 = 2,@tiene_cochera =1,@tiene_baulera = 0;
GO
-----------BAJAS--------------

-- UF asociada a personas
EXEC gestion.sp_eliminar_Unidad_Funcional @id = 1, @id_consorcio = 4;
GO -- Esperado: Error "existen Persona-UF asociados."

-- UF no existe
EXEC gestion.sp_eliminar_Unidad_Funcional @id = 1000, @id_consorcio = 4;
GO -- Esperado: Error "Unidad_Funcional no existe"

-- Caso exitoso (sin relaciones): ejecutar despues de eliminar UF_Persona
EXEC gestion.sp_eliminar_Unidad_Funcional @id = 10, @id_consorcio = 4;
GO
----------------------------
------UF_PERSONA LOTE----------

select top 20* from Com5600G08.gestion.Unidad_Funcional_Persona

----------ALTAS---------------
-- UF inexistente
EXEC gestion.sp_alta_Unidad_Funcional_Persona 
    @id_unidad_funcional = 999, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 12345678,
    @fecha_desde = '2023-01-01', @fecha_hasta = NULL, @es_inquilino = 0;
GO
-- Persona inexistente
EXEC gestion.sp_alta_Unidad_Funcional_Persona 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 99999999,
    @fecha_desde = '2023-01-01', @fecha_hasta = NULL, @es_inquilino = 1;
GO
-- Relación duplicada
EXEC gestion.sp_alta_Unidad_Funcional_Persona 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 29256383,
    @fecha_desde = '2023-01-01', @fecha_hasta = NULL, @es_inquilino = 1;
GO
-- Caso exitoso
EXEC gestion.sp_alta_Unidad_Funcional_Persona 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 27250604,
    @fecha_desde = '2024-01-01', @fecha_hasta = NULL, @es_inquilino = 0;
GO

----------MODIFICACIONES---------------

-- No existe la relación uf_persona
EXEC gestion.sp_modificar_Unidad_Funcional_Persona
    @id_unidad_funcional = 999, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 29256383,
    @fecha_desde = '2024-01-01', @fecha_hasta = NULL, @es_inquilino = 1;
GO
-- Caso exitoso
EXEC gestion.sp_modificar_Unidad_Funcional_Persona
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 29256383,
    @fecha_desde = '2024-01-01', @fecha_hasta = NULL, @es_inquilino = 1;
GO
----------BAJAS---------------

-- Relación inexistente
EXEC gestion.sp_eliminar_Unidad_Funcional_Persona 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 12345678;
GO
-- Caso exitoso
EXEC gestion.sp_eliminar_Unidad_Funcional_Persona 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 29256383;
GO
-----------------------------------------
-----CUENTA BANCARIA_UF LOTES-----
select top 20* from Com5600G08.gestion.Cuenta_Bancaria_Asociada_UF

----------ALTAS---------------
-- UF inexistente
EXEC gestion.sp_alta_Cuenta_Bancaria_Asociada_UF 
    @id_unidad_funcional = 999, @id_consorcio_unidad_funcional = 4, @cbu_cvu = '1234567890123456789012';
GO
-- CBU/CVU inválido
EXEC gestion.sp_alta_Cuenta_Bancaria_Asociada_UF 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4, @cbu_cvu = '12345';
GO
-- Duplicado
EXEC gestion.sp_alta_Cuenta_Bancaria_Asociada_UF 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4, @cbu_cvu = '2314407897385040000000';
GO
-- Caso exitoso
EXEC gestion.sp_alta_Cuenta_Bancaria_Asociada_UF 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4, @cbu_cvu = '1111111111111111111111';
GO
----------MODIFICACIONES---------------

-- CBU/CVU viejo inexistente
EXEC gestion.sp_modificar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_viejo = '9999999999999999999999', @cbu_cvu_nuevo = '3333333333333333333333';
GO
-- CBU nuevo inválido
EXEC gestion.sp_modificar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_viejo = '2314407897385040000000', @cbu_cvu_nuevo = '12345';
GO
-- CBU nuevo duplicado
EXEC gestion.sp_modificar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_viejo = '2314407897385040000000', @cbu_cvu_nuevo = '2314407897385040000000';
GO
-- Caso exitoso
EXEC gestion.sp_modificar_Cuenta_Bancaria_Asociada_UF
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_viejo = '1111111111111111111111', @cbu_cvu_nuevo = '9999999999999999999999';
GO
----------BAJAS---------------

-- No existe
EXEC gestion.sp_eliminar_Cuenta_Bancaria_Asociada_UF 
    @id_unidad_funcional = 999, @id_consorcio_unidad_funcional = 4, @cbu_cvu = '9999999999999999999999';
GO
-- Caso exitoso
EXEC gestion.sp_eliminar_Cuenta_Bancaria_Asociada_UF 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4, @cbu_cvu = '9999999999999999999999';
GO
---------------------------------------------
-----PAGO LOTES---------
SELECT top 20* FROM Com5600G08.gestion.Pago WHERE fecha = '2025-11-01'

----------ALTAS---------------
-- CBU/CVU obligatorio
EXEC gestion.sp_alta_Pago 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_origen = NULL , @fecha = '2025-11-01', @importe = 5;
GO

-- Fecha nula
EXEC gestion.sp_alta_Pago 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_origen = '1234567890123456789012', @fecha = NULL, @importe = 1000;
GO

-- Importe <= 0
EXEC gestion.sp_alta_Pago 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_origen = '1234567890123456789012', @fecha = '2024-01-01', @importe = 0;
GO

--UF inexistente
EXEC gestion.sp_alta_Pago 
    @id_unidad_funcional = 999, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_origen = '1234567890123456789012', @fecha = '2024-01-01', @importe = 1000;
GO

--Caso exitoso
EXEC gestion.sp_alta_Pago 
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @cbu_cvu_origen = '1234567890123456789012', @fecha = '2025-11-01', @importe = 1;
GO

--pago no asociado
EXEC gestion.sp_alta_Pago 
@id_unidad_funcional = null, @id_consorcio_unidad_funcional = null,
@cbu_cvu_origen = '1234567890123456789012', @fecha = '2025-11-01', @importe = 1;
GO

----------BAJAS---------------

-- No existe
EXEC gestion.sp_eliminar_Pago @id = 99999;
GO

--Caso exitoso
EXEC gestion.sp_eliminar_Pago @id = 1801;
GO