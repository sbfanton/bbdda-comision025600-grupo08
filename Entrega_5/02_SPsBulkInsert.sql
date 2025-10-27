use ConsorciosDB
go

----------------------------------------------------
----------------------------------------------------

-- Tipo_Documento

create or alter procedure gestion.bulk_insert_tipos_documentos 
	@path nvarchar(500)
AS 
BEGIN
	DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'BULK INSERT gestion.Tipo_Documento
                 FROM ''' + @path + '''
                 WITH (
                     FIRSTROW = 2,
                     FIELDTERMINATOR = '','',
                     ROWTERMINATOR = ''\n''
                 );';

    EXEC sp_executesql @sql;
END

-- Prueba:
EXEC gestion.bulk_insert_tipos_documentos 
     @path = N'/var/opt/mssql/pruebas/consorcios/tipos_documento.csv';

----------------------------------------------------
----------------------------------------------------

-- Consorcios (con generacion de datos faltantes)



CREATE OR ALTER PROCEDURE gestion.bulk_insert_consorcios
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

    ----------------------------------------------------
    -- 2️⃣ Agregar columnas generadas
    ----------------------------------------------------
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

    ----------------------------------------------------
    -- 3️⃣ Separar domicilio (calle / número)
    ----------------------------------------------------
    UPDATE #ConsorcioOrigen
    SET 
        nro = TRY_CAST(REVERSE(LEFT(REVERSE(Domicilio), CHARINDEX(' ', REVERSE(Domicilio)) - 1)) AS INT),
        calle = RTRIM(LEFT(Domicilio, LEN(Domicilio) - CHARINDEX(' ', REVERSE(Domicilio))))
    WHERE Domicilio IS NOT NULL;

    ----------------------------------------------------
    -- 4️⃣ Completar datos fijos
    ----------------------------------------------------
    UPDATE #ConsorcioOrigen
    SET 
        localidad = 'Ciudad Autónoma de Buenos Aires',
        provincia = 'Ciudad Autónoma de Buenos Aires',
        razon_social = NombreConsorcio + ' S.A.';

    ----------------------------------------------------
    -- 5️⃣ Generar CUIT único
    ----------------------------------------------------
    ;
    
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


    ----------------------------------------------------
    -- 6️⃣ Asignar banco aleatorio
    ----------------------------------------------------
    UPDATE #ConsorcioOrigen
    SET banco =
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Banco Nación'
            WHEN 1 THEN 'Banco Galicia'
            WHEN 2 THEN 'Banco BBVA'
            ELSE 'Banco Santander'
        END

    ----------------------------------------------------
    -- 7️⃣ Generar CBU único (22 dígitos)
    ----------------------------------------------------
    UPDATE #ConsorcioOrigen
    SET cbu_cvu = RIGHT('0000000000000000000000' + CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(22)), 22)

   

    ----------------------------------------------------
    -- 8️⃣ Insertar en tabla final (sin duplicar nombres existentes)
    ----------------------------------------------------
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

    PRINT 'Carga completada correctamente.'
END
GO

-- Prueba
EXEC gestion.bulk_insert_tipos_documentos 
     @path = N'/var/opt/mssql/pruebas/consorcios/datos_varios_consorcios.csv';
