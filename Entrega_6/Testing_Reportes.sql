USE Com5600G08
GO

--reporte 1

--reporte 2

-- Reporte 3
EXEC  gestion.sp_reporte_recaudacion_por_procedencia  @anioInicio = 2025, @anioFin = 2025, @idConsorcio = null;

-- Reporte 4 en XML
EXEC gestion.sp_reporte_mayores_ingresos_gastos_xml @id_consorcio = null, @anio_inicio = 2025, @anio_fin = 2025;

--reporte 5

--reporte 6

