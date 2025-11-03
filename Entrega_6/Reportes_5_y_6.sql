USE Com5600G08;
Go

/* Reporte 5
Obtenga los 3 (tres) propietarios con mayor morosidad. Presente informaci�n de contacto y
DNI de los propietarios para que la administraci�n los pueda contactar o remitir el tr�mite al
estudio jur�dico.
*/
GO
CREATE OR ALTER PROCEDURE gestion.sp_reporte_top_morosos
    @IdConsorcio INT = NULL,            -- filtra por consorcio (opcional)
    @TopCantidad INT = 3,               -- cantidad de morosos a mostrar
    @DeudaMinima DECIMAL(18,2) = 0,     -- filtra morosos con deuda mayor a este valor
    @DeudaMaxima DECIMAL(18,2) = -1     -- filtra morosos con deuda menor a este valor, -1 para que no se considere
AS
BEGIN
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
            ON per.nro_doc = ufp.nro_doc_persona 
            AND per.id_tipo_documento = ufp.id_tipo_doc_persona
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
        deuda
    FROM Morosidad
    WHERE (@IdConsorcio IS NULL OR id_consorcio = @IdConsorcio)
      AND deuda > @DeudaMinima
      AND (@DeudaMaxima < 0 OR deuda <= @DeudaMaxima)
    ORDER BY deuda DESC
    FOR XML PATH('Moroso'), ROOT('TopMorosos');
END;
GO

EXEC gestion.sp_reporte_top_morosos;
EXEC gestion.sp_reporte_top_morosos null, 100, 0;
EXEC gestion.sp_reporte_top_morosos null, 100, 0, 33000000;



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

EXEC gestion.sp_reporte_pagos_ordinarios;