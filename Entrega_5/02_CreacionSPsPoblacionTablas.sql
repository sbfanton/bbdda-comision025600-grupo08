use ConsorciosDB
go

----------------------------------------------------
----------------------------------------------------

-- Tipo_Documento

create or alter procedure gestion.sp_importar_tipos_documentos 
AS 
BEGIN
    insert into gestion.Tipo_Documento (id, descripcion) values 
    ('DNI',  'Documento Nacional de Identidad'),
    ('LC',   'Libreta Cívica'),
    ('LE',   'Libreta de Enrolamiento'),
    ('PAS',  'Pasaporte'),
    ('CI',   'Cédula de Identidad'),
    ('CUIL', 'Código Único de Identificación Laboral'),
    ('CUIT', 'Código Único de Identificación Tributaria');
END
go

----------------------------------------------------
----------------------------------------------------

-- Consorcios (con generacion aleatoria de datos faltantes)

CREATE OR ALTER PROCEDURE gestion.sp_importar_consorcios
    @path NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#ConsorcioOrigen') IS NOT NULL DROP TABLE #ConsorcioOrigen;

    CREATE TABLE #ConsorcioOrigen (
        Consorcio VARCHAR(50),
        NombreConsorcio VARCHAR(100),
        Domicilio VARCHAR(150),
        CantUnidades int,
        MtsTotales int
    );

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #ConsorcioOrigen
        FROM ''' + @path + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n''
        );';
    EXEC sp_executesql @sql;

   ALTER TABLE #ConsorcioOrigen
    ADD 
        calle VARCHAR(100),
        nro INT,
        localidad VARCHAR(100),
        provincia VARCHAR(100),
        cuit CHAR(13),
        razon_social VARCHAR(100),
        banco VARCHAR(50),
        cbu_cvu CHAR(22);

   UPDATE #ConsorcioOrigen
    SET 
        nro = TRY_CAST(REVERSE(LEFT(REVERSE(Domicilio), CHARINDEX(' ', REVERSE(Domicilio)) - 1)) AS INT),
        calle = RTRIM(LEFT(Domicilio, LEN(Domicilio) - CHARINDEX(' ', REVERSE(Domicilio))))
    WHERE Domicilio IS NOT NULL;

    -- Generamos localidad, provincia y razon social ficticia
    UPDATE #ConsorcioOrigen
    SET 
        localidad = 'Ciudad Autónoma de Buenos Aires',
        provincia = 'Ciudad Autónoma de Buenos Aires',
        razon_social = NombreConsorcio + ' S.A.';

    ;
    
    -- Generamos CUITs aleatorios 
    WITH CUITS AS (
        SELECT 
            NombreConsorcio,
            cuit = '30-' + 
                   RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR(8)), 8) + 
                   '-' + CAST(ABS(CHECKSUM(NEWID())) % 10 AS VARCHAR(1))
        FROM #ConsorcioOrigen
    )
    UPDATE c
    SET c.cuit = cu.cuit
    FROM #ConsorcioOrigen c
    JOIN CUITS cu ON c.NombreConsorcio = cu.NombreConsorcio;

    -- Generamos bancos aleatorios
    UPDATE #ConsorcioOrigen
    SET banco =
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Banco Nación'
            WHEN 1 THEN 'Banco Galicia'
            WHEN 2 THEN 'Banco BBVA'
            ELSE 'Banco Santander'
        END

    -- Generamos CBUs aleatorios
    UPDATE #ConsorcioOrigen
    SET cbu_cvu = RIGHT('0000000000000000000000' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(22)), 22)

   
    INSERT INTO gestion.Consorcio (nombre, calle, nro, localidad, provincia, cuit, razon_social, banco, cbu_cvu)
    SELECT 
        NombreConsorcio,
        calle,
        nro,
        localidad,
        provincia,
        cuit,
        razon_social,
        banco,
        cbu_cvu
    FROM #ConsorcioOrigen o
    WHERE NOT EXISTS (
        SELECT 1 FROM gestion.Consorcio c WHERE c.nombre = o.NombreConsorcio
    )

    drop table #ConsorcioOrigen

    PRINT 'Carga completada correctamente.'
END
GO

----------------------------------------------------
----------------------------------------------------

-- Unidad_Funcional

CREATE OR ALTER PROCEDURE gestion.sp_importar_unidades_funcionales
    @path NVARCHAR(4000) 
AS
BEGIN
    SET NOCOUNT ON;

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
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n''
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

    DROP TABLE #tmp_unidades
END
GO

----------------------------------------------------
----------------------------------------------------

-- Persona

CREATE OR ALTER PROCEDURE gestion.sp_importar_personas
    @path NVARCHAR(4000) 
AS
BEGIN
    SET NOCOUNT ON;
   
   IF OBJECT_ID('tempdb..#tmp_personas') IS NOT NULL DROP TABLE #tmp_personas;

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
        FROM ''' + @path + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n''
        );';
    EXEC sp_executesql @sql;


    INSERT INTO gestion.Persona (
        nro_doc,
        id_tipo_documento,
        nombre,
        apellido,
        email,
        telefono
    )
    SELECT
        CAST(dni AS INT) AS nro_doc,
        'DNI' AS id_tipo_documento,
        LTRIM(RTRIM(nombre)) AS nombre,
        LTRIM(RTRIM(apellido)) AS apellido,
        LTRIM(RTRIM(email_personal)) AS email,
        LTRIM(RTRIM(telefono_contacto)) AS telefono
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY dni ORDER BY nombre) AS rn
        FROM #tmp_personas
    ) t
    WHERE rn = 1  -- Para evitar repeticiones
    AND dni IS NOT NULL
    AND dni <> ''
    AND ISNUMERIC(dni) = 1
    AND NOT EXISTS (
        SELECT 1
        FROM gestion.Persona p
        WHERE p.nro_doc = CAST(t.dni AS INT)
            AND p.id_tipo_documento = 'DNI'
    );

    DROP TABLE #tmp_personas;
END;
GO

----------------------------------------------------
----------------------------------------------------

-- Unidad_Funcional_Persona (relacion entre UFs y personas generada aleatoriamente)

CREATE OR ALTER PROCEDURE gestion.sp_asignar_personas_a_unidades
    @path NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#tmp_personas') IS NOT NULL DROP TABLE #tmp_personas;

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
        FROM ''' + @path + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n''
        );';
    EXEC sp_executesql @sql;

   /*
    * Se usaron las dos consultas de abajo con la tabla temporal
    * creada y el bulk insert realizado fuera del SP ya que se 
    * detectó la presencia de caracter extraño en campo de inquilino 
    * (retorno de carro, representado en ASCII con 13)
    * 
	SELECT 
	    t.inquilino,
	    LEN(t.inquilino) AS LongitudOriginal,
	    LEN(RTRIM(LTRIM(t.inquilino))) AS LongitudSinEspacios
	FROM #tmp_personas t
	           
	           
	 SELECT 
	    t.inquilino,
	    ASCII(SUBSTRING(t.inquilino, 1, 1)) AS Char1_ASCII,
	    ASCII(SUBSTRING(t.inquilino, 2, 1)) AS Char2_ASCII
	FROM #tmp_personas t
    * */
   

    -- Obtenemos listas numeradas de personas y unidades
    ;WITH personas_ordenadas AS (
        SELECT 
            p.nro_doc,
            p.id_tipo_documento,
            CASE WHEN rtrim(ltrim(REPLACE(t.inquilino, CHAR(13), ''))) = '1' THEN 1 ELSE 0 END AS es_inquilino,
            ROW_NUMBER() OVER (ORDER BY p.nro_doc) AS rn
        FROM #tmp_personas t
        INNER JOIN gestion.Persona p
            ON p.nro_doc = CAST(t.dni AS INT)
           AND p.id_tipo_documento = 'DNI'
    ),
    unidades_ordenadas AS (
        SELECT 
            uf.id,
            uf.id_consorcio,
            ROW_NUMBER() OVER (ORDER BY uf.id) AS rn
        FROM gestion.Unidad_Funcional uf
    ),
    cantidades AS (
        SELECT 
            (SELECT COUNT(*) FROM personas_ordenadas) AS cant_personas,
            (SELECT COUNT(*) FROM unidades_ordenadas) AS cant_unidades
    )

    -- Insertar mapeo circular
    INSERT INTO gestion.Unidad_Funcional_Persona (
        id_unidad_funcional,
        id_consorcio_unidad_funcional,
        id_tipo_doc_persona,
        nro_doc_persona,
        fecha_desde,
        fecha_hasta,
        es_inquilino
    )
    SELECT
        u.id,
        u.id_consorcio,
        p.id_tipo_documento,
        p.nro_doc,
        DATEADD(DAY, - ((ABS(CHECKSUM(NEWID())) % 100) * p.rn), GETDATE()),
        NULL,
        p.es_inquilino
    FROM personas_ordenadas p
    CROSS APPLY (
        SELECT 
            uo.id,
            uo.id_consorcio
        FROM unidades_ordenadas uo
        CROSS JOIN cantidades c
        WHERE uo.rn = ((p.rn - 1) % c.cant_unidades) + 1
    ) u
    
    /*
     * Referencia y explicacion del CROSS APPLY:
     * 
     * Para la insercion en la tabla Unidad_Funcional_Persona tenemos tres CTEs:
     * - personas_ordenadas
     * - unidades_ordenadas
     * - cantidades
     * 
     * CROSS APPLY permite aplicar una subconsulta a cada fila de una tabla
     * 
     * En el resultado final,
     * Cada persona se combinará con el resultado de la subconsulta 
     * calculada, que devuelve un id de UF y consorcio.
     * La subconsulta dentro del CROSS APPLY hace un CROSS JOIN con la 
     * tabla cantidades, que es una CTE que obtiene el número total de 
     * personas y unidades.
     * La fórmula ((p.rn - 1) % c.cant_unidades) + 1 asegura que las personas 
     * se asignen de manera circular a las unidades. 
     * La operación de módulo (%) hace que, cuando el número de personas 
     * sea mayor que el de unidades, se empiecen a asignar nuevamente desde 
     * la primera unidad.
     * 
     * Esta asignación cíclica funcionaria asi (suponiendo, por ej, que hay 3 UFs en total):

		Cuando nro fila persona (p.rn) es 1: 
		(1 - 1) % 3 + 1 = 1, entonces la persona 1 se asigna a la UF 1.
		
		Cuando nro fila persona (p.rn) es 2: 
		(2 - 1) % 3 + 1 = 2, entonces la persona 2 se asigna a la UF 2.
		
		Cuando nro fila persona (p.rn) es 3: 
		(3 - 1) % 3 + 1 = 3, entonces la persona 3 se asigna a la UF 3.
		
		Cuando nro fila persona (p.rn) es 4: 
		(4 - 1) % 3 + 1 = 1, entonces la persona 4 se asigna a la UF 1, reiniciando el ciclo.
		
	*/

    DROP TABLE #tmp_personas
END
GO

----------------------------------------------------
----------------------------------------------------

-- Cuenta_Bancaria_Asociada_UF

CREATE OR ALTER PROCEDURE gestion.sp_importar_cuentas_bancarias_asociadas_UF
    @path NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#tmp_personas') IS NOT NULL DROP TABLE #tmp_personas;

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
        FROM ''' + @path + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n''
        );';
    EXEC sp_executesql @sql;
   
   -- Genero aleatoriamente el banco
   /*
   ALTER TABLE #tmp_personas ADD banco VARCHAR(50);
  	UPDATE #tmp_personas
    SET banco =
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Banco Nación'
            WHEN 1 THEN 'Banco Galicia'
            WHEN 2 THEN 'Banco BBVA'
            ELSE 'Banco Santander'
        END
    */
    ------
        
   	    BEGIN TRY
        ;WITH ufs_por_personas AS (
            SELECT 
                ufp.id_unidad_funcional,
                ufp.id_consorcio_unidad_funcional,
                t.cvu_cbu--,
                --t.banco
            FROM #tmp_personas t
            INNER JOIN gestion.Unidad_Funcional_Persona ufp 
                ON ufp.nro_doc_persona = CAST(t.dni AS INT)
                AND ufp.id_tipo_doc_persona = 'DNI'
        ) 
        
        INSERT INTO gestion.Cuenta_Bancaria_Asociada_UF
            (id_unidad_funcional, id_consorcio_unidad_funcional, cbu_cvu, banco)
        SELECT u.id_unidad_funcional,
               u.id_consorcio_unidad_funcional,
               u.cvu_cbu,
               --u.banco
               null
        FROM ufs_por_personas u;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
   DROP TABLE #tmp_personas
END
GO
   
----------------------------------------------------
----------------------------------------------------

-- Pago

CREATE OR ALTER PROCEDURE gestion.sp_importar_pagos
    @path NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

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
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n''
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
        id_unidad_funcional,
        id_consorcio_unidad_funcional,
        cbu_cvu_origen,
        fecha,
	    importe)
    select 
    p.id_uf,
    p.id_cons_uf,
    p.cbu,
    p.FechaConvertida,
    p.importe 
    from Pagos_ufs p;

    drop table #tmp_pagos

END
GO
   
