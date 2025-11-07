USE Com5600G08
GO

--reporte 1

EXEC gestion.sp_reporte_flujo_caja_semanal
    @mesInicio = 4,
    @mesFin = 4,
    @idConsorcio = null;

--reporte 2
EXEC gestion.sp_reporte_recaudacion_mensual_departamento
    @anio = 2025,
    @idConsorcio = 1,
    @idUnidadFuncional = null;

-- Reporte 3
EXEC gestion.sp_reporte_recaudacion_por_procedencia  @anioInicio = 2025, @anioFin = 2025, @idConsorcio = null;

-- Reporte 4 en XML
EXEC gestion.sp_reporte_mayores_ingresos_gastos_xml @id_consorcio = null, @anio_inicio = 2025, @anio_fin = 2025;

--reporte 5
EXEC gestion.sp_reporte_top_morosos;						-- default, top 3
EXEC gestion.sp_reporte_top_morosos 2;						-- consorcio 2
EXEC gestion.sp_reporte_top_morosos null, 100, 0;			-- top 100
EXEC gestion.sp_reporte_top_morosos null, 100, 300000;		-- top 100, minimo 30000 de deuda
EXEC gestion.sp_reporte_top_morosos null, 100, 0, 50000;	-- top 100, maximo 50000 de deuda

--luego de cifrar
EXEC gestion.sp_reporte_top_morosos @FraseClaveCargadaPorUsuario = N'QuieroMiPanDanes';

--reporte 6
EXEC gestion.sp_reporte_pagos_ordinarios;                                   -- default
EXEC gestion.sp_reporte_pagos_ordinarios 2;                                 -- solo el consorcio 2
EXEC gestion.sp_reporte_pagos_ordinarios null, '2024-10-01', '2024-10-31';  -- test con fechas

--generacion de expensas
EXEC gestion.sp_modelo_expensa 1,4,2025;
