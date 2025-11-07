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

    --traemos pagos junto con la estructura proporcional del prorrateo
    ;WITH PagosConProporcion AS (
        SELECT 
            p.id_unidad_funcional,
            p.id_consorcio_unidad_funcional AS id_consorcio,
            p.fecha,
            p.importe AS ImportePago,
            pr.monto_ordinarias,
            pr.monto_extraordinarias,
            (pr.monto_ordinarias + pr.monto_extraordinarias) AS TotalExpensaMes
        FROM gestion.Pago p
        INNER JOIN gestion.Prorrateo pr 
            ON pr.id_unidad_funcional = p.id_unidad_funcional
            AND pr.id_consorcio_unidad_funcional = p.id_consorcio_unidad_funcional
        INNER JOIN gestion.Expensa e
            ON e.id = pr.id_expensa
        WHERE YEAR(p.fecha) = @anioActual
          AND MONTH(p.fecha) BETWEEN @mesInicio AND @mesFin
          AND (@idConsorcio IS NULL OR p.id_consorcio_unidad_funcional = @idConsorcio)
    ),

    -- Se calcula cuanto del pago fue Ordinario y cuanto Extraordinario
    PagosClasificados AS (
        SELECT
            id_consorcio,
            DATEPART(YEAR, fecha) AS Anio,
            DATEPART(WEEK, fecha) AS Semana,
            CASE 
                WHEN TotalExpensaMes > 0 
                    THEN ImportePago * (monto_ordinarias / TotalExpensaMes)
                ELSE 0
            END AS PagoOrdinario,
            CASE 
                WHEN TotalExpensaMes > 0 
                    THEN ImportePago * (monto_extraordinarias / TotalExpensaMes)
                ELSE 0
            END AS PagoExtraordinario,
            ImportePago AS PagoTotal
        FROM PagosConProporcion
    ),

    --Se agrupa por semana
    RecaudacionSemanal AS (
        SELECT 
            id_consorcio,
            Anio,
            Semana,
            SUM(PagoOrdinario) AS TotalOrdinario,
            SUM(PagoExtraordinario) AS TotalExtraordinario,
            SUM(PagoTotal) AS TotalSemanal
        FROM PagosClasificados
        GROUP BY id_consorcio, Anio, Semana
    )

    SELECT 
        id_consorcio,
        Anio,
        Semana,
		CAST(TotalOrdinario AS DECIMAL(18,2)) AS Monto_Ordinario,
		CAST(TotalExtraordinario AS DECIMAL(18,2)) AS Monto_Extraordinario,
		CAST(TotalSemanal AS DECIMAL(18,2)) AS Total_Semanal,
		CAST(AVG(TotalSemanal) OVER (PARTITION BY id_consorcio) AS DECIMAL(18,2)) AS Promedio_Periodo,
		CAST(SUM(TotalSemanal) OVER (
				PARTITION BY id_consorcio 
				ORDER BY Anio, Semana
			) AS DECIMAL(18,2)) AS Acumulado_Progresivo
    FROM RecaudacionSemanal
    ORDER BY id_consorcio, Anio, Semana;

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
            SUM(p.importe) AS Total -- ?
        FROM gestion.Pago p
        INNER JOIN gestion.Unidad_Funcional uf 
            ON uf.id = p.id_unidad_funcional 
           AND uf.id_consorcio = p.id_consorcio_unidad_funcional
        WHERE YEAR(p.fecha) = @anio
          AND (@idConsorcio IS NULL OR uf.id_consorcio = @idConsorcio)
          AND (@idUnidadFuncional IS NULL OR uf.id = @idUnidadFuncional)
        GROUP BY uf.id_consorcio, uf.id, uf.piso, uf.depto, MONTH(p.fecha) -- ?
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
   @idConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    --Pagos por UF y mes
    ;WITH PagosMesUF AS (
        SELECT
            uf.id_consorcio,
            p.id_unidad_funcional,
            YEAR(p.fecha) AS Anio,
            MONTH(p.fecha) AS Mes,
            SUM(p.importe) AS PagosMes
        FROM gestion.Pago p
        INNER JOIN gestion.Unidad_Funcional uf
            ON uf.id = p.id_unidad_funcional
           AND uf.id_consorcio = p.id_consorcio_unidad_funcional
        WHERE YEAR(p.fecha) BETWEEN @anioInicio AND @anioFin
          AND uf.id_consorcio = @idConsorcio
        GROUP BY uf.id_consorcio, p.id_unidad_funcional, YEAR(p.fecha), MONTH(p.fecha)
    ),

    --Prorrateo mensual por UF (montos de expensa del mes)
    ProrrateoMesUF AS (
        SELECT
            e.id_consorcio,
            e.anio,
            e.mes,
            pr.id_unidad_funcional,
            pr.monto_ordinarias,
            pr.monto_extraordinarias,
            pr.interes_mora,
            (pr.monto_ordinarias + pr.monto_extraordinarias + pr.interes_mora) AS TotalExpensaUF
        FROM gestion.Expensa e
        INNER JOIN gestion.Prorrateo pr
            ON pr.id_expensa = e.id
        WHERE e.anio BETWEEN @anioInicio AND @anioFin
          AND (@idConsorcio IS NULL OR e.id_consorcio = @idConsorcio)
    ),

    --Uno pagos + prorrateo + calculo proporcional
    Distribucion AS (
        SELECT
            p.id_consorcio,
            p.Anio,
            p.Mes,
            CASE 
                WHEN pr.TotalExpensaUF > 0 
                    THEN p.PagosMes / pr.TotalExpensaUF 
                ELSE 0 
            END AS ProporcionPagada,
            pr.monto_ordinarias,
            pr.monto_extraordinarias
        FROM ProrrateoMesUF pr
        LEFT JOIN PagosMesUF p
            ON p.id_consorcio = pr.id_consorcio
           AND p.id_unidad_funcional = pr.id_unidad_funcional
           AND p.Anio = pr.anio
           AND p.Mes = pr.mes
    ),

    --Recaudación proporcional mensual total del consorcio
    RecaudacionMensual AS (
        SELECT
            id_consorcio,
            Anio,
            Mes,
            SUM(ProporcionPagada * monto_ordinarias) AS Ordinario,
            SUM(ProporcionPagada * monto_extraordinarias) AS Extraordinario
        FROM Distribucion
        GROUP BY id_consorcio, Anio, Mes
    )

    /*PIVOT*/
    SELECT 
        CONCAT(Mes, '/', Anio) AS Periodo,
        CAST(ISNULL([Ordinario], 0) AS DECIMAL(18,2)) AS Ordinario,
        CAST(ISNULL([Extraordinario], 0) AS DECIMAL(18,2)) AS Extraordinario
    FROM (
        SELECT
            Anio,
            Mes,
            'Ordinario' AS Tipo,
            Ordinario AS Importe
        FROM RecaudacionMensual
        UNION ALL
        SELECT
            Anio,
            Mes,
            'Extraordinario',
            Extraordinario
        FROM RecaudacionMensual
    ) AS src
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario],[Extraordinario])
    ) AS pvt
	WHERE Anio IS NOT NULL AND Mes IS NOT NULL
    ORDER BY Anio, Mes;

END
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
    

/* Reporte 5 con API
Obtenga los 3 (tres) propietarios con mayor morosidad. Presente informacion de contacto y
DNI de los propietarios para que la administracion los pueda contactar o remitir el tramite al
estudio juridico.
*/
CREATE OR ALTER PROCEDURE gestion.sp_reporte_top_morosos
    @IdConsorcio INT = NULL,
    @TopCantidad INT = 3,
    @DeudaMinima DECIMAL(18,2) = 0,
    @DeudaMaxima DECIMAL(18,2) = -1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @url NVARCHAR(256) = 'https://open.er-api.com/v6/latest/USD' 
    DECLARE @Object INT 
    DECLARE @json TABLE(respuesta NVARCHAR(MAX)) 
    DECLARE @respuesta NVARCHAR(MAX) -- Crear objeto HTTP 

    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT 
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE' 
    EXEC sp_OAMethod @Object, 'SEND' 
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT -- Guardar la respuesta JSON en la tabla 

    INSERT @json 
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT' -- Extraer la respuesta a una variable 

    SELECT @respuesta = respuesta FROM @json 
    DECLARE @usd_to_ars FLOAT = JSON_VALUE(@respuesta, '$.rates.ARS') -- Obtener cotización

    ;WITH Morosidad AS (
        SELECT 
            per.id,
            uf.id_consorcio,
            pro.deuda,
            per.nro_doc_Cifrado,
            per.nombre_Cifrado,
            per.apellido_Cifrado,
            per.telefono_Cifrado
        FROM gestion.Persona per
        JOIN gestion.Unidad_Funcional_Persona ufp 
            ON per.id = ufp.id_persona
        JOIN gestion.Unidad_Funcional uf 
            ON uf.id = ufp.id_unidad_funcional
            AND uf.id_consorcio = ufp.id_consorcio_unidad_funcional
        LEFT JOIN gestion.Prorrateo pro ON pro.id_unidad_funcional = uf.id
    )
    SELECT TOP (@TopCantidad)
        m.nro_doc AS documento,
        m.nombre + ', ' + m.apellido AS nombre_completo,
        m.telefono,
        m.deuda,
        CAST(ROUND(m.deuda / @usd_to_ars, 2) AS DECIMAL(10,2)) AS deuda_usd
    FROM Morosidad m
    WHERE (@IdConsorcio IS NULL OR m.id_consorcio = @IdConsorcio)
      AND m.deuda > @DeudaMinima
      AND (@DeudaMaxima < 0 OR m.deuda <= @DeudaMaxima)
    ORDER BY m.deuda DESC
    FOR XML PATH('TopMorosos'), ROOT('Morosidad');
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

-- MODELO EXPENSA

CREATE OR ALTER PROCEDURE gestion.sp_modelo_expensa
    @id_consorcio INT,
    @mes TINYINT,
    @anio SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC gestion.sp_generar_expensa @id_consorcio, @mes, @anio
    EXEC gestion.sp_generar_prorrateo @id_consorcio, @mes, @anio

    SELECT 
        uf.id as Uf,
        uf.porcentaje AS '%',
        uf.piso + ' ' + uf.depto as 'Piso-Depto',
        p.nombre + ', ' + p.apellido AS 'Propietario',
        pr.monto_ordinarias AS 'Expensas Ordinarias',
        pr.monto_extraordinarias AS 'Expensas Extraordinarias',
        pr.deuda AS 'Deuda',
        pr.interes_mora AS 'Interés por mora',
        pr.saldo_abonado AS 'Saldo Abonado',
        (pr.monto_ordinarias + pr.monto_extraordinarias + pr.interes_mora) AS 'Total a Pagar'
    FROM gestion.Prorrateo pr
    INNER JOIN gestion.Unidad_Funcional uf 
        ON pr.id_unidad_funcional = uf.id 
        AND pr.id_consorcio_unidad_funcional = uf.id_consorcio
    LEFT JOIN gestion.Unidad_Funcional_Persona ufp 
        ON ufp.id_unidad_funcional = uf.id 
        AND ufp.id_consorcio_unidad_funcional = uf.id_consorcio
    LEFT JOIN gestion.Persona p 
        ON ufp.id_persona = p.id
    WHERE pr.id_expensa IN (
        SELECT id FROM gestion.Expensa 
        WHERE id_consorcio = @id_consorcio AND mes = @mes AND anio = @anio
    )
END
