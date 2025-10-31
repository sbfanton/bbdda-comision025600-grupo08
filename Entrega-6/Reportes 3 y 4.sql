
/*Reporte 3: Presente un cuadro cruzado con la recaudación total desagregada según su procedencia 
(ordinario, extraordinario, etc.) según el periodo. */

CREATE OR ALTER PROCEDURE gestion.sp_reporte_recaudacion_por_procedencia
   @anioInicio INT,
    @anioFin INT,
    @idConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CONCAT(Mes, '/', Anio) AS Periodo,
        ISNULL([Ordinario], 0) AS Ordinario,
        ISNULL([Extraordinario], 0) AS Extraordinario
    FROM (
        SELECT 
            YEAR(p.fecha) AS Anio,
            MONTH(p.fecha) AS Mes,
            CASE 
                WHEN tg.es_extraordinario = 1 THEN 'Extraordinario'
                ELSE 'Ordinario'
            END AS TipoGasto,
            SUM(p.importe) AS TotalRecaudado
        FROM gestion.Pago p
        INNER JOIN gestion.Unidad_Funcional uf 
            ON uf.id = p.id_unidad_funcional 
				AND uf.id_consorcio = p.id_consorcio_unidad_funcional
        LEFT JOIN gestion.Gasto g 
            ON g.id_consorcio = uf.id_consorcio
        LEFT JOIN gestion.Tipo_Gasto tg 
            ON tg.id = g.id_tipo_gasto
        WHERE YEAR(p.fecha) BETWEEN @anioInicio AND @anioFin
          AND (@idConsorcio IS NULL OR uf.id_consorcio = @idConsorcio)
        GROUP BY YEAR(p.fecha), MONTH(p.fecha), tg.es_extraordinario
    ) AS src
    PIVOT (
        SUM(TotalRecaudado)
        FOR TipoGasto IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Anio, Mes;
END;
GO


/*reporte 4: Incluye xml
Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.
*/

CREATE OR ALTER PROCEDURE gestion.sp_reporte_mayores_ingresos_gastos_xml
	@id_consorcio INT = NULL,
	@anio_inicio SMALLINT = NULL,
	@anio_fin SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Top 5 ingresos
    SELECT TOP 5
        YEAR(p.fecha) AS Anio,
        MONTH(p.fecha) AS Mes,
        SUM(p.importe) AS Ingreso
    FROM gestion.Pago p
    LEFT JOIN gestion.Unidad_Funcional uf
        ON p.id_unidad_funcional = uf.id
    WHERE (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
      AND (@anio_inicio IS NULL OR YEAR(p.fecha) >= @anio_inicio)
      AND (@anio_fin IS NULL OR YEAR(p.fecha) <= @anio_fin)
    GROUP BY YEAR(p.fecha), MONTH(p.fecha)
    ORDER BY SUM(p.importe) DESC
	FOR XML PATH('Ingreso'), ROOT('TopIngresos');

    -- Top 5 gastos
    SELECT TOP 5
        g.anio AS Anio,
        g.mes AS Mes,
        SUM(g.importe) AS Gasto
    FROM gestion.Gasto g
    WHERE (@id_consorcio IS NULL OR g.id_consorcio = @id_consorcio)
      AND (@anio_inicio IS NULL OR g.anio >= @anio_inicio)
      AND (@anio_fin IS NULL OR g.anio <= @anio_fin)
    GROUP BY g.anio, g.mes
    ORDER BY SUM(g.importe) DESC
	FOR XML PATH('Gasto'), ROOT('TopGastos');
END;
GO

--TESTS

-- Reporte 3
EXEC  gestion.sp_reporte_recaudacion_por_procedencia  @anioInicio = 2025, @anioFin = 2025, @idConsorcio = 1;

-- Reporte 4
EXEC gestion.sp_reporte_mayores_ingresos_gastos_xml @id_consorcio = null, @anio_inicio = 2023, @anio_fin = 2025;