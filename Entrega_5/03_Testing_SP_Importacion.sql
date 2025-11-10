/*

- Materia: Bases de Datos Aplicadas

- Comisión: 02-5600 - Viernes Tarde

- Fecha: 7/11/2025

- Grupo: 8

- Integrantes:
Cazal, Leila Abigail - 42023980
Fanton, Sol Belén - 38789602
Castro, Ezequiel Alejandro - 45239803
Grance Zenteno, Lucas Rodrigo - 43406784

- Enunciado:

*** Entrega 5 ***
(...)
El código fuente no debe incluir referencias hardcodeadas a nombres o ubicaciones de archivo. Esto debe permitirse ser provisto por parámetro en la invocación. En el código de ejemplo se verá dónde el grupo decidió ubicar los archivos, pero si cambia el entorno de ejecución debería adaptarse sin modificar el fuente (sí obviamente el script de testing).
(...)

En este archivo, se encuentran los scripts para realizar la ejecución de los SPs de importación antes generados.
La ruta de los archivos, que se recibe por parámetro en cada SP, se DEBE cambiar por la correspondiente a la ubicación de los archivos en su PC.

*/

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
go

-- Consorcio
EXEC gestion.sp_importar_consorcios
     @pathConsorcios = N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/datos-varios-consorcios.csv';
go

EXEC gestion.sp_importar_consorcios
     @pathConsorcios = N'/var/opt/mssql/pruebas/datos-varios-consorcios.csv';
go

    
-- Unidad_Funcional
EXEC gestion.sp_importar_unidades_funcionales
     @path = N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/UF por consorcio.txt'
GO 

EXEC gestion.sp_importar_unidades_funcionales
     @path = N'/var/opt/mssql/pruebas/UF por consorcio.txt'
GO 

-- Persona
-- Unidad_Funcional_Persona
-- Cuenta_Bancaria_Asociada_UF
EXEC gestion.sp_importar_personas
     @pathPersonasDatos = N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/Inquilino-propietarios-datos.csv',
     @pathPersonasUF = N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/Inquilino-propietarios-UF.csv';
go

EXEC gestion.sp_importar_personas
     @pathPersonasDatos = N'/var/opt/mssql/pruebas/Inquilino-propietarios-datos.csv',
     @pathPersonasUF = N'/var/opt/mssql/pruebas/Inquilino-propietarios-UF.csv';
go
    
-- Pago
EXEC gestion.sp_importar_pagos
     @path = N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/pagos_consorcios.csv';
go

EXEC gestion.sp_importar_pagos
     @path = N'/var/opt/mssql/pruebas/pagos_consorcios.csv';
go
    
-- Tipos gastos ordinarios y proveedores
EXEC gestion.sp_importar_tipos_gastos_y_proveedores
     @path =  N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/datos-varios-proveedores.csv',
    @rowTerminator = '\r';
go

EXEC gestion.sp_importar_tipos_gastos_y_proveedores
     @path =  N'/var/opt/mssql/pruebas/datos-varios-proveedores.csv',
    @rowTerminator = '\r';
go
   
-- Tipos gastos extraordinarios y proveedores
EXEC gestion.sp_importar_tipos_gastos_y_proveedores
     @path =  N'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/extraordinario.csv', @extraordinarios = 1;
go

EXEC gestion.sp_importar_tipos_gastos_y_proveedores
     @path =  N'/var/opt/mssql/pruebas/extraordinario.csv', @extraordinarios = 1;
go
    
-- Gastos ordinarios
DECLARE @json NVARCHAR(MAX)
SELECT @json = BulkColumn FROM OPENROWSET(BULK 'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/Servicios.Servicios.json', SINGLE_CLOB) AS jsonn
--print(@json)
exec gestion.sp_importar_gastos_ordinarios_anio_actual @jsonData = @json
go

DECLARE @json NVARCHAR(MAX)
SELECT @json = BulkColumn FROM OPENROWSET(BULK '/var/opt/mssql/pruebas/Servicios.Servicios.json', SINGLE_CLOB) AS jsonn
--print(@json)
exec gestion.sp_importar_gastos_ordinarios_anio_actual @jsonData = @json
go

-- Gastos extraordinarios
DECLARE @json2 NVARCHAR(MAX)
SELECT @json2 = BulkColumn FROM OPENROWSET(BULK 'C:\Users\yo\Documents\A-Main\Universidad\Base de Datos Aplicadas\bbdda-comision025600-grupo08\Material_TP\Miel\Consorcio/Servicios.ServiciosExtraordinarios.json', SINGLE_CLOB) AS jsonn
--print(@json2)
exec gestion.sp_importar_gastos_extraordinarios_anio_actual @jsonData = @json2
go

DECLARE @json2 NVARCHAR(MAX)
SELECT @json2 = BulkColumn FROM OPENROWSET(BULK '/var/opt/mssql/pruebas/Servicios.ServiciosExtraordinarios.json', SINGLE_CLOB) AS jsonn
--print(@json2)
exec gestion.sp_importar_gastos_extraordinarios_anio_actual @jsonData = @json2
go

-- Expensa
declare @id_consorcio int = 1
declare @mes tinyint = 4
declare @anio smallint = 2025

while @id_consorcio <= 5
begin
    declare @m tinyint = @mes;
    
    while @m <= 6
    begin
        print concat('Ejecutando sp_generar_expensa para consorcio ', @id_consorcio, ', mes ', @m, ', año ', @anio)

        exec gestion.sp_generar_expensa
            @id_consorcio = @id_consorcio,
            @mes = @m,
            @anio = @anio

        set @m += 1
    end

    set @id_consorcio += 1
end
go

-- Prorrateo
declare @id_consorcio int = 1
declare @mes tinyint = 4
declare @anio smallint = 2025

while @id_consorcio <= 5
begin
    declare @m tinyint = @mes;
    
    while @m <= 6
    begin
        print concat('Ejecutando sp_generar_prorrateo para consorcio ', @id_consorcio, ', mes ', @m, ', año ', @anio)

        exec gestion.sp_generar_prorrateo
            @id_consorcio = @id_consorcio,
            @mes = @m,
            @anio = @anio

        set @m += 1
    end

    set @id_consorcio += 1
end
go

-- Modelo Expensa
EXEC gestion.sp_modelo_expensa @FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes', -- CIFRADO
    @id_consorcio = 1,
    @mes = 5,
    @anio = 2025;
    
EXEC gestion.sp_modelo_expensa @id_consorcio = 1, @mes = 5, @anio = 2025; -- SIN CIFRAR
