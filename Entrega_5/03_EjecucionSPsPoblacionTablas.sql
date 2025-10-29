use Com5600G08
go

----------------------------------------------------

--- Cargamos tablas con datos ---

/*
Para sus pruebas en local, deben reemplazar las rutas a los archivos por las de sus computadoras
*/

----------------------------------------------------

-- Tipo_Documento
EXEC gestion.sp_importar_tipos_documentos;

-- Consorcio
EXEC gestion.sp_importar_consorcios
     @pathConsorcios = N'/var/opt/mssql/pruebas/datos-varios-consorcios.csv',
     @pathProveedores = N'/var/opt/mssql/pruebas/datos-varios-proveedores.csv';

-- Unidad_Funcional
EXEC gestion.sp_importar_unidades_funcionales
     @path = N'/var/opt/mssql/pruebas/UF por consorcio.txt'

-- Persona
-- Unidad_Funcional_Persona
-- Cuenta_Bancaria_Asociada_UF
EXEC gestion.sp_importar_personas
     @pathPersonasDatos = N'/var/opt/mssql/pruebas/Inquilino-propietarios-datos.csv',
     @pathPersonasUF = N'/var/opt/mssql/pruebas/Inquilino-propietarios-UF.csv';

-- Pago
EXEC gestion.sp_importar_pagos
     @path = N'/var/opt/mssql/pruebas/pagos_consorcios.csv';

-- Tipo_Gasto y Proveedor
EXEC gestion.sp_importar_tipos_gastos_y_proveedores
     @path =  N'/var/opt/mssql/pruebas/datos-varios-proveedores.csv';

-- Gasto
DECLARE @json NVARCHAR(MAX)
SELECT @json = BulkColumn FROM OPENROWSET(BULK '/var/opt/mssql/pruebas/Servicios.Servicios.json', SINGLE_CLOB) AS jsonn
--print(@json)
exec gestion.sp_importar_gastos_ordinarios_anio_actual @jsonData = @json
