use Com5600G08
go

----------------------------------------------------
----------------------------------------------------

-- Tipo_Documento

create or alter procedure gestion.sp_importar_tipos_documentos 
AS 
BEGIN
    SET NOCOUNT ON;
/*
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

      BEGIN TRANSACTION;
*/
        INSERT INTO gestion.Tipo_Documento (id, descripcion)
        SELECT v.id, v.descripcion
        FROM (
            VALUES
                ('DNI',  'Documento Nacional de Identidad'),
                ('LC',   'Libreta Cívica'),
                ('LE',   'Libreta de Enrolamiento'),
                ('PAS',  'Pasaporte'),
                ('CI',   'Cédula de Identidad'),
                ('CUIL', 'Código Único de Identificación Laboral'),
                ('CUIT', 'Código Único de Identificación Tributaria')
        ) AS v(id, descripcion)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM gestion.Tipo_Documento td 
            WHERE td.id = v.id
        );
        /*
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
go

----------------------------------------------------
----------------------------------------------------

-- Consorcios (con generacion aleatoria de datos faltantes)

CREATE OR ALTER PROCEDURE gestion.sp_importar_consorcios
    @pathConsorcios NVARCHAR(500),
    @rowTerminatorConsorcios NVARCHAR(10) = '\n',
    @fieldTerminatorConsorcios NVARCHAR(10) = ';'
AS
BEGIN
    SET NOCOUNT ON;
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
        */
        IF OBJECT_ID('tempdb..#ConsorcioOrigen') IS NOT NULL DROP TABLE #ConsorcioOrigen;

        CREATE TABLE #ConsorcioOrigen (
            Consorcio NVARCHAR(50),
            NombreConsorcio NVARCHAR(100),
            Domicilio NVARCHAR(150),
            CantUnidades int,
            MtsTotales int
        );


        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #ConsorcioOrigen
            FROM ''' + @pathConsorcios + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''' + @fieldTerminatorConsorcios + ''',
                ROWTERMINATOR = ''' + @rowTerminatorConsorcios + '''
            );';
        EXEC sp_executesql @sql;

    ALTER TABLE #ConsorcioOrigen
        ADD 
            id int,
            calle VARCHAR(100),
            nro INT,
            localidad VARCHAR(100),
            provincia VARCHAR(100);

        -- Desglosamos el id
        UPDATE #ConsorcioOrigen 
        SET 
            id = TRY_CAST(SUBSTRING(consorcio, CHARINDEX(' ', consorcio) + 1, len(consorcio)) AS INT);

        -- Desglosamos la calle y el nro de la direccion
    UPDATE #ConsorcioOrigen
        SET 
            nro = TRY_CAST(REVERSE(LEFT(REVERSE(Domicilio), CHARINDEX(' ', REVERSE(Domicilio)) - 1)) AS INT),
            calle = RTRIM(LEFT(Domicilio, LEN(Domicilio) - CHARINDEX(' ', REVERSE(Domicilio))))
        WHERE Domicilio IS NOT NULL;

        -- Generamos localidad, provincia y razon social ficticia
        UPDATE #ConsorcioOrigen
        SET 
            localidad = 'Ciudad Autónoma de Buenos Aires',
            provincia = 'Ciudad Autónoma de Buenos Aires';

        ;

        INSERT INTO gestion.Consorcio (id, nombre, calle, nro, localidad, provincia)
        SELECT 
            id, 
            NombreConsorcio,
            calle,
            nro,
            localidad,
            provincia
        FROM #ConsorcioOrigen o
        WHERE NOT EXISTS (
            SELECT 1 FROM gestion.Consorcio c 
            WHERE c.id = o.id
            AND c.nombre = o.NombreConsorcio
        )

        drop table #ConsorcioOrigen

        PRINT 'Carga completada correctamente.'
        /*
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO

----------------------------------------------------
----------------------------------------------------

-- Unidad_Funcional

CREATE OR ALTER PROCEDURE gestion.sp_importar_unidades_funcionales
    @path NVARCHAR(4000) ,
    @rowTerminator NVARCHAR(10) = '\n',
    @fieldTerminator NVARCHAR(10) = '\t'
AS
BEGIN
    SET NOCOUNT ON;
    /*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
*/
        IF OBJECT_ID('tempdb..#tmp_unidades') IS NOT NULL DROP TABLE #tmp_unidades;

        CREATE TABLE #tmp_unidades (
            nombre_consorcio NVARCHAR(100),
            nroUnidadFuncional NVARCHAR(10),
            piso NVARCHAR(10),
            departamento NVARCHAR(10),
            coeficiente NVARCHAR(20),
            m2_unidad_funcional NVARCHAR(20),
            bauleras NVARCHAR(5),
            cochera NVARCHAR(5),
            m2_baulera NVARCHAR(20),
            m2_cochera NVARCHAR(20)
        );

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #tmp_unidades
            FROM ''' + @path + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''' + @fieldTerminator + ''',
                ROWTERMINATOR = ''' + @rowTerminator + '''
            );';
        EXEC sp_executesql @sql;

        INSERT INTO gestion.Unidad_Funcional (
            id,
            id_consorcio,
            piso,
            depto,
            porcentaje,
            superficie_m2,
            tiene_cochera,
            tiene_baulera
        )
        SELECT
            CAST(tmp.nroUnidadFuncional as INT),
            c.id AS id_consorcio,
            LTRIM(RTRIM(tmp.piso)) AS piso,
            LTRIM(RTRIM(tmp.departamento)) AS depto,
            CAST(REPLACE(tmp.coeficiente, ',', '.') AS DECIMAL(5,2)) AS porcentaje,
            CAST(REPLACE(tmp.m2_unidad_funcional, ',', '.') AS DECIMAL(7,2)) AS superficie_m2,
            CASE WHEN UPPER(LTRIM(RTRIM(tmp.cochera))) = 'SI' THEN 1 ELSE 0 END AS tiene_cochera,
            CASE WHEN UPPER(LTRIM(RTRIM(tmp.bauleras))) = 'SI' THEN 1 ELSE 0 END AS tiene_baulera
        FROM #tmp_unidades tmp
        INNER JOIN gestion.Consorcio c
            ON LTRIM(RTRIM(tmp.nombre_consorcio)) = LTRIM(RTRIM(c.nombre))
        WHERE 
            tmp.nroUnidadFuncional IS NOT NULL
            AND tmp.piso IS NOT NULL
            AND tmp.departamento IS NOT NULL
            AND ISNUMERIC(REPLACE(tmp.coeficiente, ',', '.')) = 1
            AND ISNUMERIC(REPLACE(tmp.m2_unidad_funcional, ',', '.')) = 1 
            AND NOT EXISTS (
                select 1 from gestion.Unidad_Funcional u 
                where u.id = tmp.nroUnidadFuncional
                and u.id_consorcio = c.id
            )

        DROP TABLE #tmp_unidades
        /*
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO

----------------------------------------------------
----------------------------------------------------

-- Persona
-- Unidad_Funcional_Persona
-- Cuenta_Bancaria_Asociada_UF

CREATE OR ALTER PROCEDURE gestion.sp_importar_personas
    @pathPersonasDatos NVARCHAR(4000),
    @pathPersonasUF NVARCHAR(4000),
    @rowTerminatorPersonas NVARCHAR(10) = '\n',
    @rowTerminatorPersonasUF NVARCHAR(10) = '\n',
    @fieldTerminatorPersonas NVARCHAR(10) = ';',
    @fieldTerminatorPersonasUF NVARCHAR(10) = '|'
AS
BEGIN
    SET NOCOUNT ON;
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
   */
        IF OBJECT_ID('tempdb..#tmp_personas') IS NOT NULL DROP TABLE #tmp_personas;
        IF OBJECT_ID('tempdb..#tmp_personas_UF') IS NOT NULL DROP TABLE #tmp_personas_UF;

            CREATE TABLE #tmp_personas (
                nombre NVARCHAR(100),
                apellido NVARCHAR(100),
                dni NVARCHAR(20),
                email_personal NVARCHAR(150),
                telefono_contacto NVARCHAR(30),
                cvu_cbu NVARCHAR(30),
                inquilino NVARCHAR(10)
            );

            DECLARE @sql NVARCHAR(MAX);
            SET @sql = N'
                BULK INSERT #tmp_personas
                FROM ''' + @pathPersonasDatos + '''
                WITH (
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ''' + @fieldTerminatorPersonas + ''',
                    ROWTERMINATOR = ''' + @rowTerminatorPersonas + '''
                );';
            EXEC sp_executesql @sql;
        
        CREATE TABLE #tmp_personas_UF (
                cvu_cbu NVARCHAR(30),
                consorcio NVARCHAR(20),
                uf NVARCHAR(5),
                piso NVARCHAR(5),
                depto NVARCHAR(5)
            );

            DECLARE @sql2 NVARCHAR(MAX);
            SET @sql2 = N'
                BULK INSERT #tmp_personas_UF
                FROM ''' + @pathPersonasUF + '''
                WITH (
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ''' + @fieldTerminatorPersonasUF + ''',
                    ROWTERMINATOR = ''' + @rowTerminatorPersonasUF + '''
                );';
            EXEC sp_executesql @sql2;
        
        select 
            p.nombre,
            p.apellido,
            p.dni,
            p.email_personal,
            p.telefono_contacto,
            p.cvu_cbu,
            p.inquilino,
            r.consorcio,
            c.id as id_consorcio,
            r.uf,
            r.piso,
            r.depto
        into #PersonasUF 
        from #tmp_personas p 
        inner join #tmp_personas_UF r on p.cvu_cbu = r.cvu_cbu
        inner join gestion.Consorcio c on c.nombre = r.consorcio
        
        
        
            select 
            p.nombre,
            p.apellido,
            p.dni,
            p.email_personal,
            p.telefono_contacto,
            p.cvu_cbu,
            CASE
                WHEN LTRIM(RTRIM(REPLACE(REPLACE(p.inquilino, CHAR(13), ''), CHAR(10), ''))) = '1' THEN 1
                WHEN LTRIM(RTRIM(REPLACE(REPLACE(p.inquilino, CHAR(13), ''), CHAR(10), ''))) = '0' THEN 0
                ELSE NULL
            END AS inquilino,
            p.consorcio,
            p.id_consorcio,
            p.uf,
            p.piso,
            p.depto,
            ROW_NUMBER() over (partition by p.dni order by p.apellido) as dni_rn,
            ROW_NUMBER() over (partition by p.cvu_cbu, p.consorcio, p.uf order by p.consorcio) as cbu_uf_rn
        into #PersonasUFConRN 
        from #PersonasUF p
        

            -- Insercion en tabla Persona
            INSERT INTO gestion.Persona (
                nro_doc,
                id_tipo_documento,
                nombre,
                apellido,
                email,
                telefono
            )
            SELECT
                CAST(p.dni AS INT) AS nro_doc,
                'DNI' AS id_tipo_documento,
                LTRIM(RTRIM(p.nombre)) AS nombre,
                LTRIM(RTRIM(p.apellido)) AS apellido,
                LTRIM(RTRIM(p.email_personal)) AS email,
                LTRIM(RTRIM(p.telefono_contacto)) AS telefono
            FROM #PersonasUFConRN p
            WHERE 
            p.dni IS NOT NULL
            AND p.dni <> ''
            AND ISNUMERIC(p.dni) = 1
            AND NOT EXISTS (
                SELECT 1
                FROM gestion.Persona per
                WHERE per.nro_doc = CAST(p.dni AS INT)
                    AND per.id_tipo_documento = 'DNI'
            )
        
        
        -- Insercion en tabla Unidad_Funcional_Persona
        insert into gestion.Unidad_Funcional_Persona (
                id_unidad_funcional,
                id_consorcio_unidad_funcional,
                id_persona,
                fecha_desde,
                fecha_hasta,
                es_inquilino
        )   
            SELECT
                CAST(p.uf AS INT) AS id_unidad_funcional,
                CAST(p.id_consorcio AS INT) AS id_consorcio_unidad_funcional,
                gp.id,
                null,
                null,
                CAST(p.inquilino as BIT) as es_inquilino
            FROM #PersonasUFConRN p 
            inner join gestion.Persona gp on gp.nro_doc = CAST(p.dni AS INT) and gp.id_tipo_documento = 'DNI'
            WHERE 
             p.dni IS NOT NULL
            AND p.dni <> ''
            AND ISNUMERIC(p.dni) = 1
            AND NOT EXISTS (
                SELECT 1
                FROM gestion.Unidad_Funcional_Persona uf
                WHERE uf.id_persona = gp.id 
                    AND uf.id_unidad_funcional = CAST(p.uf AS INT)
                    AND uf.id_consorcio_unidad_funcional = CAST(p.id_consorcio AS INT)
            )
        
        
        insert into gestion.Cuenta_Bancaria_Asociada_UF  (
                id_unidad_funcional,
                id_consorcio_unidad_funcional,
                cbu_cvu
        )   
            SELECT
                CAST(p.uf AS INT) AS id_unidad_funcional,
                CAST(p.id_consorcio AS INT) AS id_consorcio_unidad_funcional,
                p.cvu_cbu
            FROM #PersonasUFConRN p
            WHERE NOT EXISTS (
                SELECT 1
                FROM gestion.Cuenta_Bancaria_Asociada_UF uf
                WHERE uf.cbu_cvu = p.cvu_cbu
                    AND uf.id_unidad_funcional = CAST(p.uf AS INT)
                    AND uf.id_consorcio_unidad_funcional = CAST(p.id_consorcio AS INT)
            )
        
        
            DROP TABLE #PersonasUFConRN
            DROP TABLE #PersonasUF
            DROP TABLE #tmp_personas
            DROP TABLE #tmp_personas_UF
            /*
           COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO
----------------------------------------------------
----------------------------------------------------

-- Pago

CREATE OR ALTER PROCEDURE gestion.sp_importar_pagos
    @path NVARCHAR(4000),
    @rowTerminator NVARCHAR(10) = '\n',
    @fieldTerminator NVARCHAR(10) = ','
AS
BEGIN
    SET NOCOUNT ON;
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
   */

        IF OBJECT_ID('tempdb..#tmp_pagos') IS NOT NULL DROP TABLE #tmp_pagos;

        CREATE TABLE #tmp_pagos (
            id_pago NVARCHAR(10),
            fecha NVARCHAR(20),
            cvu_cbu NVARCHAR(22),
            valor NVARCHAR(50)
        );

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #tmp_pagos
            FROM ''' + @path + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''' + @fieldTerminator + ''',
                ROWTERMINATOR = ''' + @rowTerminator + '''
            );';
        EXEC sp_executesql @sql;

        /*
        * -- Pruebas
        SELECT 
            t.valor,
            ASCII(SUBSTRING(t.valor, 1, 1)) AS Char1_ASCII,
            ASCII(SUBSTRING(t.valor, len(t.valor), len(t.valor))) AS Char2_ASCII
        FROM #tmp_pagos t;
        
        select * from #tmp_pagos where cvu_cbu is null;
        */
    
    delete from #tmp_pagos where 
    id_pago is null 
    or fecha is null 
    or cvu_cbu is null 
    or valor is null

        ;with Pagos_ufs as (
            select 
            cast(t.id_pago as bigint) as id_pago,
            cba.id_unidad_funcional as id_uf,
            cba.id_consorcio_unidad_funcional as id_cons_uf,
            t.cvu_cbu as cbu,
            CONVERT(DATETIME, t.fecha, 103) AS FechaConvertida,
            CAST(
                rtrim(
                    ltrim(
                        REPLACE(
                            REPLACE(
                                REPLACE(T.valor, CHAR(13), '')
                            , '.', '')
                        , '$', ''))) AS DECIMAL(10,2)) AS importe
            from #tmp_pagos t 
            left join gestion.Cuenta_Bancaria_Asociada_UF cba
            on t.cvu_cbu = cba.cbu_cvu 
            --where ISDATE(t.fecha) = 1
        )
        insert into gestion.Pago(
            id,
            id_unidad_funcional,
            id_consorcio_unidad_funcional,
            cbu_cvu_origen,
            fecha,
            importe)
        select 
        p.id_pago,
        p.id_uf,
        p.id_cons_uf,
        p.cbu,
        p.FechaConvertida,
        p.importe 
        from Pagos_ufs p 
        where not exists (
            select 1 from gestion.Pago gp 
            where gp.id = p.id_pago 
        );

        drop table #tmp_pagos
        /*
    COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO
   
----------------------------------------------------
----------------------------------------------------

-- Tipo_Gasto
-- Proveedor
CREATE OR ALTER FUNCTION gestion.fn_nombre_tipo_gasto (
    @tipoGasto NVARCHAR(100),
    @proveedor NVARCHAR(100)
)
RETURNS NVARCHAR(200)
AS
BEGIN
    RETURN (
        CASE 
            WHEN LTRIM(RTRIM(UPPER(@tipoGasto))) = 'SERVICIOS PUBLICOS' 
                THEN LTRIM(RTRIM(@tipoGasto)) + N' - ' + LTRIM(RTRIM(@proveedor))
            ELSE LTRIM(RTRIM(@tipoGasto))
        END
    )
END
GO

CREATE OR ALTER PROCEDURE gestion.sp_importar_tipos_gastos_y_proveedores
    @path NVARCHAR(4000),
    @extraordinarios BIT = 0,
    @rowTerminator NVARCHAR(10) = '\n',
    @fieldTerminator NVARCHAR(10) = ';'
AS
BEGIN
    SET NOCOUNT ON;
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
*/
        IF OBJECT_ID('tempdb..#tmp_tipos_gastos') IS NOT NULL DROP TABLE #tmp_tipos_gastos;

        CREATE TABLE #tmp_tipos_gastos (
            tipoGasto NVARCHAR(100),
            proveedor NVARCHAR(100),
            detalle NVARCHAR(100),
            consorcio NVARCHAR(100)
        );

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
            BULK INSERT #tmp_tipos_gastos
            FROM ''' + @path + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''' + @fieldTerminator + ''',
                ROWTERMINATOR = ''' + @rowTerminator + '''
            );'
        EXEC sp_executesql @sql;

        ALTER TABLE #tmp_tipos_gastos 
        ADD es_extraordinario BIT;

        update #tmp_tipos_gastos set es_extraordinario = @extraordinarios
        
        UPDATE #tmp_tipos_gastos
        SET consorcio = RTRIM(REPLACE(REPLACE(consorcio, CHAR(13), ''), CHAR(10), ''))

        INSERT INTO gestion.Tipo_Gasto (nombre, es_extraordinario)
		SELECT DISTINCT 
		    gestion.fn_nombre_tipo_gasto(t.tipoGasto, t.proveedor),
		    t.es_extraordinario
		FROM #tmp_tipos_gastos t
		WHERE NOT EXISTS (
		    SELECT 1 
		    FROM gestion.Tipo_Gasto g
		    WHERE g.nombre = gestion.fn_nombre_tipo_gasto(t.tipoGasto, t.proveedor)
		);

        -- Proveedor
        ;with Prov as (
            select 
            tg.id as id_tipo_gasto,
            c.id as id_consorcio,
            t.proveedor as proveedor, 
            t.detalle as detalle
            from #tmp_tipos_gastos t 
            inner join gestion.Tipo_Gasto tg on gestion.fn_nombre_tipo_gasto(t.tipoGasto, t.proveedor) = tg.nombre 
            inner join gestion.Consorcio c on t.consorcio = c.nombre 
        )
        insert into gestion.Proveedor(id_tipo_gasto, id_consorcio, nombre, detalle) 
        select pr.id_tipo_gasto, pr.id_consorcio, pr.proveedor, pr.detalle from Prov pr
        where not exists (
            select 1 from gestion.Proveedor p
            where p.id_tipo_gasto = pr.id_tipo_gasto 
            and p.id_consorcio = pr.id_consorcio 
        )

        drop table #tmp_tipos_gastos
        /*
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO

----------------------------------------------------
----------------------------------------------------

-- Gasto

-- Funcion para normalizar los importes:
CREATE OR ALTER FUNCTION gestion.fn_normalizar_importe (@valor NVARCHAR(50))
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @resultado DECIMAL(12,2);
    DECLARE @limpio NVARCHAR(50);

    SET @valor = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@valor, '$', ''), '€', ''), ' ', '')));

    SET @limpio = 
        CASE
            WHEN @valor LIKE '%,%.%' THEN 
                REPLACE(@valor, ',', '')

            WHEN @valor LIKE '%.%,%' THEN 
                REPLACE(REPLACE(@valor, '.', ''), ',', '.')

            WHEN @valor LIKE '%,%,%' THEN 
                REPLACE(
                    STUFF(@valor, LEN(@valor) - CHARINDEX(',', REVERSE(@valor)) + 1, 1, '.'),
                    ',', ''
                )

            ELSE @valor
        END

    IF @limpio LIKE '%[^0-9.]%' 
        SET @resultado = NULL
    ELSE
        SET @resultado = TRY_CAST(@limpio AS DECIMAL(12,2))

    RETURN @resultado
END
GO

-- Importar gastos ordinarios
create or alter procedure gestion.sp_importar_gastos_ordinarios_anio_actual
	@jsonData NVARCHAR(MAX)
AS 
BEGIN 
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
*/
	
        IF OBJECT_ID('tempdb..#GastosJson') IS NOT NULL DROP TABLE #GastosJson
        IF OBJECT_ID('tempdb..#Mes') IS NOT NULL DROP TABLE #Mes
        
        declare @anio_actual int = YEAR(GETDATE())
        
        create table #Mes (nro int, mes varchar(20), anio int)
        INSERT INTO #Mes (nro, mes, anio) VALUES
            (1, 'enero', @anio_actual),
            (2, 'febrero', @anio_actual),
            (3, 'marzo', @anio_actual),
            (4, 'abril', @anio_actual),
            (5, 'mayo', @anio_actual),
            (6, 'junio', @anio_actual),
            (7, 'julio', @anio_actual),
            (8, 'agosto', @anio_actual),
            (9, 'septiembre', @anio_actual),
            (10, 'octubre', @anio_actual),
            (11, 'noviembre', @anio_actual),
            (12, 'diciembre', @anio_actual)
        
        SELECT 
            JSON_VALUE(j.value, '$."Nombre del consorcio"') AS NombreConsorcio,
            LTRIM(RTRIM(LOWER(JSON_VALUE(j.value, '$."Mes"')))) AS Mes,
            JSON_VALUE(j.value, '$."BANCARIOS"') AS GastosBancarios,
            JSON_VALUE(j.value, '$."ADMINISTRACION"') AS GastosAdministracion,
            JSON_VALUE(j.value, '$."LIMPIEZA"') AS GastosLimpieza,
            JSON_VALUE(j.value, '$."SEGUROS"') AS GastosSeguros,
            JSON_VALUE(j.value, '$."GASTOS GENERALES"') AS GastosGenerales,
            JSON_VALUE(j.value, '$."SERVICIOS PUBLICOS-Agua"') AS GastosAgua,
            JSON_VALUE(j.value, '$."SERVICIOS PUBLICOS-Luz"') AS GastosLuz
        INTO #GastosJson
        FROM OPENJSON(@jsonData) AS j

        
        ;with GastoMes as (
        select
            c.id as consorcio,
            cast(m.nro as tinyint) as mes,
            cast(m.anio as smallint) as anio,
            g.GastosBancarios,
            g.GastosAdministracion,
            g.GastosLimpieza,
            g.GastosSeguros,
            g.GastosGenerales,
            g.GastosAgua,
            g.GastosLuz
        from #GastosJson g 
        inner join gestion.Consorcio c on g.NombreConsorcio = c.nombre
        inner join #Mes m on g.Mes = m.mes
        )
        INSERT INTO gestion.Gasto (
            id_tipo_gasto, 
            id_consorcio,
            mes,
            anio,
            nro_factura, 
            importe, 
            descripcion, 
            cuotas_totales, 
            nro_cuota)
        SELECT 
            tg.id AS id_tipo_gasto,
            g.consorcio,
            g.mes,
            g.anio,
            null,
            gestion.fn_normalizar_importe(x.importe) AS importe,
            x.tipo_gasto AS descripcion,
            null,
            null
        FROM GastoMes g
        CROSS APPLY (
            VALUES
                ('GASTOS BANCARIOS', g.GastosBancarios),
                ('GASTOS DE ADMINISTRACION', g.GastosAdministracion),
                ('GASTOS DE LIMPIEZA', g.GastosLimpieza),
                ('SEGUROS', g.GastosSeguros),
                ('GASTOS GENERALES', g.GastosGenerales),
                ('SERVICIOS PUBLICOS - AYSA', g.GastosAgua),
                ('SERVICIOS PUBLICOS - EDENOR', g.GastosLuz)
        ) AS x(tipo_gasto, importe)
        INNER JOIN gestion.Tipo_Gasto tg ON tg.nombre = x.tipo_gasto
        WHERE gestion.fn_normalizar_importe(x.importe) IS NOT NULL
        AND gestion.fn_normalizar_importe(x.importe) > 0 
        AND NOT EXISTS (
            select 1 from gestion.Gasto gg
            where gg.mes = g.mes 
            and gg.anio = g.anio 
            and gg.id_consorcio = g.consorcio 
            and gg.id_tipo_gasto = tg.id
        );
        
        drop table #Mes
        drop table #GastosJson
        /*
    COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO

--Importar gastos extraordinarios(de prueba)
create or alter procedure gestion.sp_importar_gastos_extraordinarios_anio_actual
	@jsonData NVARCHAR(MAX)
AS 
BEGIN 
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
        */
        IF OBJECT_ID('tempdb..#GastosJson') IS NOT NULL DROP TABLE #GastosJson
        IF OBJECT_ID('tempdb..#Mes') IS NOT NULL DROP TABLE #Mes
        
        declare @anio_actual int = YEAR(GETDATE())
        
        create table #Mes (nro int, mes varchar(20), anio int)
        INSERT INTO #Mes (nro, mes, anio) VALUES
            (1, 'enero', @anio_actual),
            (2, 'febrero', @anio_actual),
            (3, 'marzo', @anio_actual),
            (4, 'abril', @anio_actual),
            (5, 'mayo', @anio_actual),
            (6, 'junio', @anio_actual),
            (7, 'julio', @anio_actual),
            (8, 'agosto', @anio_actual),
            (9, 'septiembre', @anio_actual),
            (10, 'octubre', @anio_actual),
            (11, 'noviembre', @anio_actual),
            (12, 'diciembre', @anio_actual)
        
        SELECT 
            JSON_VALUE(j.value, '$."Nombre del consorcio"') AS NombreConsorcio,
            LTRIM(RTRIM(LOWER(JSON_VALUE(j.value, '$."Mes"')))) AS Mes,
            JSON_VALUE(j.value, '$."PLOMERIA GENERAL"') AS GastosPlomeriaGeneral,
            JSON_VALUE(j.value, '$."REPARACION ESTRUCTURAL"') AS GastosReparacionEstructural,
            JSON_VALUE(j.value, '$."IMPERMEABILIZACION"') AS GastosImpermeabilizacion,
            JSON_VALUE(j.value, '$."REMODELACION"') AS GastosRemodelacion,
            JSON_VALUE(j.value, '$."INSTALACION DE SIST. SEGURIDAD"') AS GastosInstalacionSeguridad
        INTO #GastosJson
        FROM OPENJSON(@jsonData) AS j
        
        ;with GastoMes as (
        select
            c.id as consorcio,
            cast(m.nro as tinyint) as mes,
            cast(m.anio as smallint) as anio,
            g.GastosPlomeriaGeneral,
            g.GastosReparacionEstructural,
            g.GastosImpermeabilizacion,
            g.GastosRemodelacion,
            g.GastosInstalacionSeguridad
        from #GastosJson g 
        inner join gestion.Consorcio c on g.NombreConsorcio = c.nombre
        inner join #Mes m on g.Mes = m.mes
        )
        INSERT INTO gestion.Gasto (
            id_tipo_gasto, 
            id_consorcio,
            mes,
            anio,
            nro_factura, 
            importe, 
            descripcion, 
            cuotas_totales, 
            nro_cuota)
        SELECT 
            tg.id AS id_tipo_gasto,
            g.consorcio,
            g.mes,
            g.anio,
            null,
            gestion.fn_normalizar_importe(x.importe) AS importe,
            x.tipo_gasto AS descripcion,
            null,
            null
        FROM GastoMes g
        CROSS APPLY (
            VALUES
                ('PLOMERIA GENERAL', g.GastosPlomeriaGeneral),
                ('REPARACION ESTRUCTURAL', g.GastosReparacionEstructural),
                ('IMPERMEABILIZACION', g.GastosImpermeabilizacion),
                ('REMODELACION', g.GastosRemodelacion),
                ('INSTALACION DE SIST. SEGURIDAD', g.GastosInstalacionSeguridad)
        ) AS x(tipo_gasto, importe)
        INNER JOIN gestion.Tipo_Gasto tg ON tg.nombre = x.tipo_gasto
        WHERE gestion.fn_normalizar_importe(x.importe) IS NOT NULL
        AND gestion.fn_normalizar_importe(x.importe) > 0
        AND NOT EXISTS (
            select 1 from gestion.Gasto gg
            where gg.mes = g.mes 
            and gg.anio = g.anio 
            and gg.id_consorcio = g.consorcio
            and gg.id_tipo_gasto = tg.id
        );
        
        drop table #Mes
        drop table #GastosJson
        /*
     COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO


----------------------------------------------------
----------------------------------------------------

-- Tabla Expensa

create or alter procedure gestion.sp_generar_expensa
	@id_consorcio int,
    @mes TINYINT,
    @anio SMALLINT
AS 
BEGIN 
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
*/
        IF @id_consorcio IS NULL
            THROW 50000, 'Debe indicar el consorcio', 1;
        IF @mes IS NULL or @anio IS NULL
            THROW 50000, 'Debe indicar el mes y el año', 1;

        -- Suma de gastos ordinarios
        declare @total_gastos_ordinarios decimal(15,2);
        select 
            @total_gastos_ordinarios = isnull(sum(g.importe), 0)
        from gestion.Gasto g 
        inner join gestion.Tipo_Gasto tg on tg.id = g.id_tipo_gasto
        where g.id_consorcio = @id_consorcio
        and g.mes = @mes
        and g.anio = @anio 
        and tg.es_extraordinario = 0;

        -- Suma de gastos extraordinarios
        declare @total_gastos_extraordinarios decimal(15,2);
        select 
            @total_gastos_extraordinarios = isnull(sum(g.importe), 0)
        from gestion.Gasto g 
        inner join gestion.Tipo_Gasto tg on tg.id = g.id_tipo_gasto
        where g.id_consorcio = @id_consorcio
        and g.mes = @mes
        and g.anio = @anio 
        and tg.es_extraordinario = 1;

        -- Ingresos
        declare @ingresos decimal(15,2);
        select 
            @ingresos = isnull(sum(p.importe), 0)
        from gestion.Pago p 
        where id_consorcio_unidad_funcional = @id_consorcio 
        and year(p.fecha) = @anio
        and month(p.fecha) = @mes;

        delete from gestion.Expensa
        where id_consorcio = @id_consorcio
        and mes = @mes
        and anio = @anio 

        insert into gestion.Expensa(
            id_consorcio,
            mes,
            anio,
            monto_total_ordinarias,
            monto_total_extraordinarias,
            ingresos
        )
        values (
            @id_consorcio,
            @mes,
            @anio,
            @total_gastos_ordinarios,
            @total_gastos_extraordinarios,
            @ingresos
        )
/*
     COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
    */
END
GO

----------------------------------------------------
----------------------------------------------------

-- Tabla Prorrateo

-- Funcaion para calcular deuda acumulada
CREATE OR ALTER FUNCTION gestion.fn_calcular_deuda_acumulada
(
    @id_unidad_funcional INT,
    @id_consorcio INT,
    @anio SMALLINT,
    @mes TINYINT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @deuda DECIMAL(15,2) = 0
    DECLARE @mes_anterior TINYINT
    DECLARE @anio_anterior SMALLINT

    -- Calcula mes y año anterior
    IF @mes = 1
    BEGIN
        SET @mes_anterior = 12
        SET @anio_anterior = @anio - 1
    END
    ELSE
    BEGIN
        SET @mes_anterior = @mes - 1
        SET @anio_anterior = @anio
    END;

    DECLARE @id_expensa_anterior INT

    SELECT @id_expensa_anterior = e.id
    FROM gestion.Expensa e
    WHERE e.id_consorcio = @id_consorcio
      AND e.mes = @mes_anterior
      AND e.anio = @anio_anterior

    DECLARE @deuda_anterior DECIMAL(15,2) = 0
    DECLARE @monto_ordinarias_anterior DECIMAL(15,2) = 0
    DECLARE @monto_extraordinarias_anterior DECIMAL(15,2) = 0
    DECLARE @interes_mora_mes_anterior DECIMAL(15,2) = 0
    DECLARE @pagos_actuales DECIMAL(15,2) = 0

    -- deuda = (deuda_mes_anterior + expensa_mes_anterior + interes_mora_mes_anterior) - pagos_actuales

    -- deuda y montos del prorrateo anterior
    SELECT 
    @deuda_anterior = isnull(pr.deuda, 0),
    @monto_ordinarias_anterior = isnull(pr.monto_ordinarias, 0),
    @monto_extraordinarias_anterior = isnull(pr.monto_extraordinarias, 0),
    @interes_mora_mes_anterior = isnull(pr.interes_mora, 0)
    FROM gestion.Prorrateo pr
    WHERE pr.id_expensa = @id_expensa_anterior
    AND pr.id_unidad_funcional = @id_unidad_funcional;

    -- pagos del mes actual
    SELECT @pagos_actuales = isnull(sum(p.importe), 0)
    FROM gestion.Pago p
    WHERE p.id_unidad_funcional = @id_unidad_funcional
      AND p.id_consorcio_unidad_funcional = @id_consorcio
      AND year(p.fecha) = @anio
      AND month(p.fecha) = @mes;

    IF @deuda_anterior = 0 
    and @monto_ordinarias_anterior = 0 
    and @monto_extraordinarias_anterior = 0 
    and @interes_mora_mes_anterior = 0
        BEGIN
            SET @deuda = 0
        END
    ELSE   
        BEGIN
            SET @deuda = @deuda_anterior + 
                         @monto_ordinarias_anterior + 
                         @monto_extraordinarias_anterior + 
                         @interes_mora_mes_anterior - 
                         @pagos_actuales;
        END

    RETURN @deuda;
END;
GO



create or alter procedure gestion.sp_generar_prorrateo
	@id_consorcio int,
    @mes TINYINT,
    @anio SMALLINT
AS 
BEGIN 
/*
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

        BEGIN TRANSACTION;
*/
        IF @id_consorcio IS NULL
            THROW 50000, 'Debe indicar el consorcio', 1;
        IF @mes IS NULL or @anio IS NULL
            THROW 50000, 'Debe indicar el mes y el año', 1;

        -- Se busca el id de expensa correspondiente
        declare @id_expensa int;
        select @id_expensa = e.id
        from gestion.Expensa e
        where e.id_consorcio = @id_consorcio
          and e.mes = @mes
          and e.anio = @anio

        if @id_expensa is null
            throw 50001, 'No existe expensa generada para ese consorcio y período', 1;

        delete from gestion.Prorrateo
        where id_expensa = @id_expensa

        ;with ExpensaDistribuida as (
            select 
            uf.id as id_unidad_funcional,
            uf.id_consorcio as id_consorcio_unidad_funcional,
            sum(isnull(p.importe, 0)) as saldo_abonado,
            cast((e.monto_total_ordinarias * uf.porcentaje / 100.0) as decimal(15,2)) as monto_ordinarias,
            cast((e.monto_total_extraordinarias * uf.porcentaje / 100.0) as decimal(15,2)) as monto_extraordinarias,
            gestion.fn_calcular_deuda_acumulada(uf.id, uf.id_consorcio, @anio, @mes) as deuda
            from gestion.Expensa e 
            inner join gestion.Unidad_Funcional uf on uf.id_consorcio = e.id_consorcio
            left join gestion.Pago p 
                on p.id_unidad_funcional = uf.id 
               and p.id_consorcio_unidad_funcional = uf.id_consorcio
               and year(p.fecha) = @anio
               and month(p.fecha) = @mes
            where e.id = @id_expensa 
            and uf.id_consorcio = @id_consorcio 
            group by uf.id, uf.id_consorcio, uf.porcentaje, 
                     e.monto_total_ordinarias, e.monto_total_extraordinarias
        )
         insert into gestion.Prorrateo (
            id_expensa,
            id_unidad_funcional,
            id_consorcio_unidad_funcional,
            saldo_abonado,
            monto_ordinarias,
            monto_extraordinarias,
            deuda,
            interes_mora
        )
        select 
        @id_expensa as id_expensa,
        ed.id_unidad_funcional,
        ed.id_consorcio_unidad_funcional,
        ed.saldo_abonado,
        ed.monto_ordinarias,
        ed.monto_extraordinarias,
        ed.deuda,
        cast(
            case 
                when ed.deuda > 0
                then ed.deuda * 0.05
                else 0
            end
        as decimal(12,2)) as interes_mora
        from ExpensaDistribuida ed
        
/*
     COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        if @@trancount > 0 rollback transaction;
        THROW;
    END CATCH
    */
END
GO


----------------------------------------------------
----------------------------------------------------
