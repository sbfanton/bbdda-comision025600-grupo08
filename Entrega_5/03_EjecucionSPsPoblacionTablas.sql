use ConsorciosDB
go

----------------------------------------------------

--- Cargamos tablas con datos ---

----------------------------------------------------

-- Tipo_Documento
EXEC gestion.sp_importar_tipos_documentos;

-- Consorcio
EXEC gestion.sp_importar_consorcios
     @path = N'/var/opt/mssql/pruebas/datos-varios-consorcios.csv';

-- Unidad_Funcional
EXEC gestion.sp_importar_unidades_funcionales
     @path = N'/var/opt/mssql/pruebas/UF por consorcio.txt'

-- Persona
EXEC gestion.sp_importar_personas
     @path = N'/var/opt/mssql/pruebas/Inquilino-propietarios-datos.csv';

-- Unidad_Funcional_Persona
EXEC gestion.sp_asignar_personas_a_unidades
     @path = N'/var/opt/mssql/pruebas/Inquilino-propietarios-datos.csv';

-- Cuenta_Bancaria_Asociada_UF
EXEC gestion.sp_importar_cuentas_bancarias_asociadas_UF
     @path = N'/var/opt/mssql/pruebas/Inquilino-propietarios-datos.csv';

-- Pago
EXEC gestion.sp_importar_pagos
     @path = N'/var/opt/mssql/pruebas/pagos_consorcios.csv';