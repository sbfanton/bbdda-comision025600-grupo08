use Com5600G08
go

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



--pendiente para consultar al ticher
with reporte_1 as(
select t.nombre, t.es_extraordinario, g.importe, g.mes, g.anio from gestion.Gasto g
inner join 
gestion.Tipo_Gasto t
on g.id_tipo_gasto=t.id
)

select * from reporte_1




/*Reporte 2 
Presente el total de recaudación por mes y departamento en formato de tabla cruzada. */

create procedure reporte_2
@campo.1 varchar(30)
@campo.2 varchar(30)


--falta poner todo esto en una SP y pensar los 3 parametros de la misma
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
