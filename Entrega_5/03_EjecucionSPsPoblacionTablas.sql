use ConsorciosDB
go

----------------------------------------------------

--- Cargamos tablas con datos ---

----------------------------------------------------

-- Tipo_Documento
EXEC gestion.sp_importar_tipos_documentos;
/*EXEC gestion.sp_importar_tipos_documentos 
     @path = N'/var/opt/mssql/pruebas/consorcios/tipos_documento.csv';
    */

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