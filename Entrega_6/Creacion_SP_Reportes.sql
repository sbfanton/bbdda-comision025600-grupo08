USE Com5600G08;
Go

--REPORTE 1 SIN API
/*Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por 
pagos ordinarios y extraordinarios de cada semana, el promedio en el periodo, y el 
acumulado progresivo.*/

CREATE OR ALTER PROCEDURE gestion.sp_reporte_flujo_caja_semanal
   @mesInicio TINYINT,
   @mesFin TINYINT,
   @idConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @anioActual INT = YEAR(GETDATE());

    ;WITH RecaudacionSemanal AS (
        SELECT 
            uf.id_consorcio,
            DATEPART(YEAR, p.fecha) AS Anio,
            DATEPART(WEEK, p.fecha) AS Semana,
            SUM(p.importe) AS TotalPesos
        FROM gestion.Pago p
        INNER JOIN gestion.Unidad_Funcional uf 
            ON uf.id = p.id_unidad_funcional 
           AND uf.id_consorcio = p.id_consorcio_unidad_funcional
        WHERE p.fecha >= DATEFROMPARTS(@anioActual, @mesInicio, 1)
          AND p.fecha <  DATEADD(MONTH, 1, DATEFROMPARTS(@anioActual, @mesFin, 1))
          AND (@idConsorcio IS NULL OR uf.id_consorcio = @idConsorcio)
        GROUP BY uf.id_consorcio, DATEPART(YEAR, p.fecha), DATEPART(WEEK, p.fecha)
    ),
    TipoGastoConsorcio AS (
        SELECT 
            g.id_consorcio,
            MAX(CASE WHEN tg.es_extraordinario = 0 THEN 1 ELSE 0 END) AS TieneOrdinario,
            MAX(CASE WHEN tg.es_extraordinario = 1 THEN 1 ELSE 0 END) AS TieneExtraordinario
        FROM gestion.Gasto g
        INNER JOIN gestion.Tipo_Gasto tg ON tg.id = g.id_tipo_gasto
        WHERE g.anio = @anioActual
          AND g.mes BETWEEN @mesInicio AND @mesFin
          AND (@idConsorcio IS NULL OR g.id_consorcio = @idConsorcio)
        GROUP BY g.id_consorcio
    )
    SELECT 
        r.id_consorcio,
        r.Anio,
        r.Semana,
        CASE WHEN t.TieneOrdinario = 1 THEN r.TotalPesos ELSE 0 END AS Monto_Ordinario,
        CASE WHEN t.TieneExtraordinario = 1 THEN r.TotalPesos ELSE 0 END AS Monto_Extraordinario,
        r.TotalPesos AS Total_Semanal,
        AVG(r.TotalPesos) OVER (PARTITION BY r.id_consorcio) AS Promedio_Periodo,
        SUM(r.TotalPesos) OVER (
            PARTITION BY r.id_consorcio 
            ORDER BY r.Anio, r.Semana
        ) AS Acumulado_Progresivo
    FROM RecaudacionSemanal r
    LEFT JOIN TipoGastoConsorcio t ON t.id_consorcio = r.id_consorcio
    ORDER BY r.id_consorcio, r.Anio, r.Semana;
END;
GO


--REPORTE 2
/*Presente el total de 
recaudación por mes y departamento en formato de tabla cruzada. 
*/
CREATE OR ALTER PROCEDURE gestion.sp_reporte_recaudacion_mensual_departamento
    @anio INT,
    @idConsorcio INT = NULL,
    @idUnidadFuncional INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH RecaudacionMensual AS (
        SELECT 
            uf.id_consorcio,
            uf.id AS id_unidad_funcional,
            CONCAT(
                'C', uf.id_consorcio,
                '-UF', uf.id,
                '-', uf.piso,
                 uf.depto
            ) AS Departamento,
            MONTH(p.fecha) AS Mes,
            SUM(p.importe) AS Total
        FROM gestion.Pago p
        INNER JOIN gestion.Unidad_Funcional uf 
            ON uf.id = p.id_unidad_funcional 
           AND uf.id_consorcio = p.id_consorcio_unidad_funcional
        WHERE YEAR(p.fecha) = @anio
          AND (@idConsorcio IS NULL OR uf.id_consorcio = @idConsorcio)
          AND (@idUnidadFuncional IS NULL OR uf.id = @idUnidadFuncional)
        GROUP BY uf.id_consorcio, uf.id, uf.piso, uf.depto, MONTH(p.fecha)
    )
    SELECT 
        Departamento,
        ISNULL([1],0) AS Enero,
        ISNULL([2],0) AS Febrero,
        ISNULL([3],0) AS Marzo,
        ISNULL([4],0) AS Abril,
        ISNULL([5],0) AS Mayo,
        ISNULL([6],0) AS Junio,
        ISNULL([7],0) AS Julio,
        ISNULL([8],0) AS Agosto,
        ISNULL([9],0) AS Septiembre,
        ISNULL([10],0) AS Octubre,
        ISNULL([11],0) AS Noviembre,
        ISNULL([12],0) AS Diciembre
    FROM RecaudacionMensual
    PIVOT (
        SUM(Total)
        FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS pvt
    ORDER BY Departamento;
END;
GO
	
/*Reporte 3: Presente un cuadro cruzado con la recaudación total desagregada según su procedencia 
(ordinario, extraordinario, etc.) según el periodo. */

CREATE OR ALTER PROCEDURE gestion.sp_reporte_recaudacion_por_procedencia
   @anioInicio INT,
   @anioFin INT,
   @idConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH RecaudacionMensualConsorcio AS (
        SELECT 
            uf.id_consorcio,
            YEAR(p.fecha) AS Anio,
            MONTH(p.fecha) AS Mes,
            SUM(p.importe) AS importe_total
        FROM gestion.Pago p
        JOIN gestion.Unidad_Funcional uf 
            ON uf.id = p.id_unidad_funcional 
            AND uf.id_consorcio = p.id_consorcio_unidad_funcional
        WHERE YEAR(p.fecha) BETWEEN @anioInicio AND @anioFin
          AND (@idConsorcio IS NULL OR uf.id_consorcio = @idConsorcio)
        GROUP BY uf.id_consorcio, YEAR(p.fecha), MONTH(p.fecha)
    )

    SELECT 
        CONCAT(Mes, '/', Anio) AS Periodo,
        ISNULL([Ordinario], 0) AS Ordinario,
        ISNULL([Extraordinario], 0) AS Extraordinario
    FROM (
        SELECT 
            rmc.Anio,
            rmc.Mes,
            CASE 
                WHEN tg.es_extraordinario = 1 THEN 'Extraordinario'
                ELSE 'Ordinario'
            END AS TipoGasto,
            MAX(rmc.importe_total) AS TotalRecaudado
        FROM RecaudacionMensualConsorcio rmc
        LEFT JOIN gestion.Gasto g 
            ON g.id_consorcio = rmc.id_consorcio
        LEFT JOIN gestion.Tipo_Gasto tg 
            ON tg.id = g.id_tipo_gasto
        GROUP BY rmc.Anio, rmc.Mes, tg.es_extraordinario, rmc.importe_total
    ) AS src
    PIVOT (
        MAX(TotalRecaudado)
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
    

/* Reporte 5
Obtenga los 3 (tres) propietarios con mayor morosidad. Presente informaci�n de contacto y
DNI de los propietarios para que la administraci�n los pueda contactar o remitir el tr�mite al
estudio jur�dico.
*/
CREATE OR ALTER PROCEDURE gestion.sp_reporte_top_morosos
    @IdConsorcio INT = NULL,            -- filtra por consorcio (opcional)
    @TopCantidad INT = 3,               -- cantidad de morosos a mostrar
    @DeudaMinima DECIMAL(18,2) = 0,     -- filtra morosos con deuda mayor a este valor
    @DeudaMaxima DECIMAL(18,2) = -1     -- filtra morosos con deuda menor a este valor, -1 para que no se considere
AS
BEGIN
    --DECLARE @url NVARCHAR(256) = 'https://open.er-api.com/v6/latest/USD'
    DECLARE @url NVARCHAR(256) = 'https://api.bluelytics.com.ar/v2/latest';

    DECLARE @Object INT
    DECLARE @json TABLE(respuesta NVARCHAR(MAX))
    DECLARE @respuesta NVARCHAR(MAX)

    -- Crear objeto HTTP
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'
    EXEC sp_OAMethod @Object, 'SEND'
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT

    -- Guardar la respuesta JSON en la tabla
    INSERT @json
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT'

    -- Extraer la respuesta a una variable
    SELECT @respuesta = respuesta FROM @json

    -- 🔹 Extraer solo el valor del dólar en pesos argentinos (USD → ARS)
    --DECLARE @usd_to_ars FLOAT = JSON_VALUE(@respuesta, '$.rates.ARS')
    DECLARE @usd_to_ars FLOAT = JSON_VALUE(@respuesta, '$.blue.value_avg');
    SET @usd_to_ars = CAST(ROUND(@usd_to_ars, 2) AS DECIMAL(10,2));

    -- 🔹 Si querés la inversa (ARS → USD)
    DECLARE @ars_to_usd FLOAT = ROUND(1 / @usd_to_ars, 6);

    WITH TotalGastos AS (
        SELECT 
            uf.id AS id_unidad_funcional,
            uf.id_consorcio,
            SUM(g.importe * (uf.porcentaje / 100.0)) AS total_gastos
        FROM gestion.Unidad_Funcional uf
        JOIN gestion.Gasto g 
            ON g.id_consorcio = uf.id_consorcio
        GROUP BY uf.id, uf.id_consorcio
    ),
    TotalPagos AS (
        SELECT 
            id_unidad_funcional,
            id_consorcio_unidad_funcional AS id_consorcio,
            SUM(importe) AS total_pagado
        FROM gestion.Pago
        GROUP BY id_unidad_funcional, id_consorcio_unidad_funcional
    ),
    Morosidad AS (
        SELECT 
            per.nro_doc,
            per.id_tipo_documento,
            per.apellido + ', ' + per.nombre AS nombre_completo,
            per.telefono,
            ISNULL(g.total_gastos, 0) AS total_gastos,
            ISNULL(p.total_pagado, 0) AS total_pagado,
            ISNULL(g.total_gastos, 0) - ISNULL(p.total_pagado, 0) AS deuda,
            uf.id_consorcio
        FROM gestion.Persona per
        JOIN gestion.Unidad_Funcional_Persona ufp
            ON per.id = ufp.id_persona
        JOIN gestion.Unidad_Funcional uf
            ON uf.id = ufp.id_unidad_funcional
            AND uf.id_consorcio = ufp.id_consorcio_unidad_funcional
        LEFT JOIN TotalGastos g 
            ON g.id_unidad_funcional = uf.id 
            AND g.id_consorcio = uf.id_consorcio
        LEFT JOIN TotalPagos p 
            ON p.id_unidad_funcional = uf.id 
            AND p.id_consorcio = uf.id_consorcio
    )
    SELECT TOP (@TopCantidad)
        nombre_completo,
        nro_doc,
        telefono,
        total_gastos,
        total_pagado,
        deuda,
        CAST(ROUND(deuda / @usd_to_ars, 2) AS DECIMAL(10,2)) AS deuda_usd
    FROM Morosidad
    WHERE (@IdConsorcio IS NULL OR id_consorcio = @IdConsorcio)
      AND deuda > @DeudaMinima
      AND (@DeudaMaxima < 0 OR deuda <= @DeudaMaxima)
    ORDER BY deuda DESC
    FOR XML PATH('TopMorosos'), ROOT('Morosidad')
END;
GO

EXEC gestion.sp_reporte_top_morosos;


/* Reporte 6
Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de d�as que
pasan entre un pago y el siguiente, para el conjunto examinado.
*/
GO
CREATE OR ALTER PROCEDURE gestion.sp_reporte_pagos_ordinarios
    @IdConsorcio INT = NULL,            -- Filtra por consorcio (opcional)
    @FechaDesde DATE = NULL,            -- Filtra pagos desde esta fecha (opcional)
    @FechaHasta DATE = NULL             -- Filtra pagos hasta esta fecha (opcional)
AS
BEGIN
    WITH PagosOrdinarios AS (
        SELECT DISTINCT 
            p.id, 
            p.id_unidad_funcional, 
            p.fecha
        FROM gestion.Pago p
        JOIN gestion.Unidad_Funcional uf
            ON uf.id = p.id_unidad_funcional
        JOIN gestion.Gasto g
            ON g.id_consorcio = uf.id_consorcio
        JOIN gestion.Tipo_Gasto tg
            ON tg.id = g.id_tipo_gasto
        WHERE tg.es_extraordinario = 0
          AND (@IdConsorcio IS NULL OR uf.id_consorcio = @IdConsorcio)
          AND (@FechaDesde IS NULL OR p.fecha >= @FechaDesde)
          AND (@FechaHasta IS NULL OR p.fecha <= @FechaHasta)
    )
    SELECT
        po.id AS PagoId,
        po.id_unidad_funcional AS UnidadFuncional,
        po.fecha AS FechaDePago,
        LEAD(po.fecha) OVER (PARTITION BY po.id_unidad_funcional ORDER BY po.fecha) AS SiguientePago,
        DATEDIFF(DAY, po.fecha, LEAD(po.fecha) OVER (PARTITION BY po.id_unidad_funcional ORDER BY po.fecha)) AS DiasEntrePagos
    FROM PagosOrdinarios po
    ORDER BY po.id_unidad_funcional, po.fecha;
END;
GO
