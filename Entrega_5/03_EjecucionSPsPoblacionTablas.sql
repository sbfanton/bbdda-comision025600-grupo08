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

--AQUI PONGO LAS CONSULTAS PARA LOS REPORTES

--PRUEBAS PARA VER LOS REGISTROS DE LA TABLA -- no usen * solo
select top 10 * from gestion.Consorcio
select top 10 * from gestion.Cuenta_Bancaria_Asociada_UF
select top 10 * from gestion.Gasto
select top 10 * from gestion.Pago
select top 10 * from gestion.Persona
select top 10 * from gestion.Proveedor
select top 10 * from gestion.Tipo_Documento
select * from gestion.Tipo_Gasto
select top 20 * from gestion.Unidad_Funcional
select top 20 * from gestion.Unidad_Funcional_Persona


/*Reporte 1 
Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por 
pagos ordinarios y extraordinarios de cada semana, el promedio en el periodo, y el 
acumulado progresivo. */


--consulta para saber la cantidad de dias del mes dada una fecha
select *, datediff(day, fecha, dateadd(month, 1, fecha)) dia, month(fecha) mes from gestion.Pago

--consulta para saber la cantidad de dias del mes dada una fecha
SELECT fecha, DATEDIFF(WEEK, DATEADD(DAY, 1 - DAY(fecha), fecha), fecha) + 1 AS semana_del_mes from gestion.Pago;

select t.nombre, t.es_extraordinario, g.importe, g.mes from gestion.Gasto g
inner join 
gestion.Tipo_Gasto t
on g.id_tipo_gasto=t.id




/*Reporte 2 
Presente el total de recaudación por mes y departamento en formato de tabla cruzada. */


with recaudacion as(
select  distinct uf.depto, month(p.fecha) as mes, sum(p.importe) over(partition by month(p.fecha)) suma from gestion.Unidad_Funcional UF
inner join
gestion.Pago p on
uf.id=p.id_unidad_funcional
)

--PIVOTE ELIGIENDO LOS DEPTOs
select * from recaudacion
pivot ( sum(recaudacion.suma) for recaudacion.depto in ([A],[B],[C],[D],[E]))
as pivote

/* PIVOTE ELIGIENDO LOS MESES
pivot ( sum(recaudacion.suma) for recaudacion.depto in ([4],[5],[6]))
as pivote
*/
