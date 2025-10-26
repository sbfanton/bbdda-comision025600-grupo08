use ConsorciosDB
go

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


EXEC gestion.bulk_insert_tipos_documentos 
     @path = N'/var/opt/mssql/pruebas/consorcios/tipos_documento.csv';

-- Persona

