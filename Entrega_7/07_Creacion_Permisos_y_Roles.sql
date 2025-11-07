/*=============================================================
    LIMPIEZA Y CREACIÓN DE LOGINS, USUARIOS, ROLES Y PERMISOS
=============================================================*/
USE master;
GO
------------------------------------------------------------
-- ELIMINAR ROLES DE SERVIDOR Y MIEMBROS (SI EXISTEN)
------------------------------------------------------------
DECLARE @serverRoles TABLE (name SYSNAME)
INSERT INTO @serverRoles VALUES
('rol_administrativo_general'),
('rol_administrativo_bancario'),
('rol_administrativo_operativo'),
('rol_sistemas')

-- Quitar miembros de roles existentes
DECLARE @dropMembers NVARCHAR(MAX) = (
    SELECT STRING_AGG(
        'ALTER SERVER ROLE [' + sp1.name + '] DROP MEMBER [' + sp2.name + '];',
        CHAR(10)
    )
    FROM sys.server_role_members rm
    JOIN sys.server_principals sp1 ON rm.role_principal_id = sp1.principal_id
    JOIN sys.server_principals sp2 ON rm.member_principal_id = sp2.principal_id
    WHERE sp1.name IN (SELECT name FROM @serverRoles)
)

IF @dropMembers IS NOT NULL
    EXEC sys.sp_executesql @dropMembers

-- Ahora eliminar los roles
DECLARE @dropRoles NVARCHAR(MAX) = (
    SELECT STRING_AGG(
        'DROP SERVER ROLE [' + name + '];',
        CHAR(10)
    )
    FROM @serverRoles
    WHERE name IN (SELECT name FROM sys.server_principals)
)

IF @dropRoles IS NOT NULL
    EXEC sys.sp_executesql @dropRoles
GO


------------------------------------------------------------
-- ELIMINAR LOGINS SI EXISTEN
------------------------------------------------------------
DECLARE @logins TABLE (name SYSNAME)
INSERT INTO @logins VALUES
('admin_general'),
('admin_bancario'),
('admin_operativo'),
('sistemas')

DECLARE @dropLogins NVARCHAR(MAX) = (
    SELECT STRING_AGG('
        IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + name + ''')
            DROP LOGIN [' + name + '];', CHAR(10))
    FROM @logins
)

EXEC sys.sp_executesql @dropLogins
GO

------------------------------------------------------------
-- CREAR LOGINS NUEVOS
------------------------------------------------------------
CREATE LOGIN admin_general WITH PASSWORD = 'AdmGen123!';
CREATE LOGIN admin_bancario WITH PASSWORD = 'AdmBan123!';
CREATE LOGIN admin_operativo WITH PASSWORD = 'AdmOpe123!';
CREATE LOGIN sistemas WITH PASSWORD = 'Sist123!';
GO


------------------------------------------------------------
--CAMBIO DE BASE DE DATOS
------------------------------------------------------------
USE Com5600G08;
GO

------------------------------------------------------------
--ELIMINAR ROLES Y USUARIOS DE BASE DE DATOS
------------------------------------------------------------

-- Roles de base de datos a limpiar
DECLARE @roles TABLE (name SYSNAME)
INSERT INTO @roles VALUES
('rol_administrativo_general'),
('rol_administrativo_bancario'),
('rol_administrativo_operativo'),
('rol_sistemas')

------------------------------------------------------------
--1. Quitar miembros de roles de base de datos
------------------------------------------------------------
DECLARE @dropMembers NVARCHAR(MAX)

SELECT @dropMembers = STRING_AGG(
    'ALTER ROLE [' + dp1.name + '] DROP MEMBER [' + dp2.name + '];',
    CHAR(10)
)
FROM sys.database_role_members drm
JOIN sys.database_principals dp1 ON drm.role_principal_id = dp1.principal_id
JOIN sys.database_principals dp2 ON drm.member_principal_id = dp2.principal_id
WHERE dp1.name IN (SELECT name FROM @roles)

IF @dropMembers IS NOT NULL
    EXEC sys.sp_executesql @dropMembers


------------------------------------------------------------
-- 2. Eliminar roles
------------------------------------------------------------
DECLARE @dropRoles NVARCHAR(MAX)

SELECT @dropRoles = STRING_AGG(
    'DROP ROLE [' + name + '];',
    CHAR(10)
)
FROM @roles
WHERE name IN (SELECT name FROM sys.database_principals)

IF @dropRoles IS NOT NULL
    EXEC sys.sp_executesql @dropRoles


------------------------------------------------------------
-- 3. Eliminar usuarios de la base
------------------------------------------------------------
DECLARE @users TABLE (name SYSNAME)
INSERT INTO @users VALUES
('admin_general'),
('admin_bancario'),
('admin_operativo'),
('sistemas')

DECLARE @dropUsers NVARCHAR(MAX)

SELECT @dropUsers = STRING_AGG(
    'DROP USER [' + name + '];',
    CHAR(10)
)
FROM @users
WHERE name IN (SELECT name FROM sys.database_principals)

IF @dropUsers IS NOT NULL
    EXEC sys.sp_executesql @dropUsers
GO

---EJECUTAR HASTA ACA---


CREATE USER admin_general FOR LOGIN admin_general WITH DEFAULT_SCHEMA= [gestion];
CREATE USER admin_bancario FOR LOGIN admin_bancario WITH DEFAULT_SCHEMA= [gestion];
CREATE USER admin_operativo FOR LOGIN admin_operativo WITH DEFAULT_SCHEMA= [gestion];
CREATE USER sistemas FOR LOGIN sistemas WITH DEFAULT_SCHEMA= [gestion];
GO

CREATE SERVER ROLE rol_administrativo_general;
CREATE SERVER ROLE rol_administrativo_bancario;
CREATE SERVER ROLE rol_administrativo_operativo;
CREATE SERVER ROLE rol_sistemas;

ALTER SERVER ROLE rol_administrativo_general ADD MEMBER admin_general;
ALTER SERVER ROLE rol_administrativo_bancario ADD MEMBER admin_bancario;
ALTER SERVER ROLE bulkadmin ADD MEMBER admin_bancario;
ALTER SERVER ROLE rol_administrativo_operativo ADD MEMBER admin_operativo;
ALTER SERVER ROLE rol_sistemas ADD MEMBER sistemas;

CREATE ROLE rol_administrativo_general;
CREATE ROLE rol_administrativo_bancario;
CREATE ROLE rol_administrativo_operativo;
CREATE ROLE rol_sistemas;

ALTER ROLE rol_administrativo_general ADD MEMBER admin_general;
ALTER ROLE rol_administrativo_bancario ADD MEMBER admin_bancario;
ALTER ROLE rol_administrativo_operativo ADD MEMBER admin_operativo;
ALTER ROLE rol_sistemas ADD MEMBER sistemas;
GO

--PERMISOS PARA ADMINISTRATIVO GENERAL
GRANT EXECUTE ON gestion.sp_alta_Unidad_Funcional TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_modificar_Unidad_Funcional TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_eliminar_Unidad_Funcional TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_reporte_Pagos_Ordinarios TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_reporte_top_morosos TO rol_administrativo_general;


--PERMISOS PARA ADMINISTRATIVO BANCARIO
GRANT EXECUTE ON gestion.sp_importar_pagos TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.sp_reporte_Pagos_Ordinarios TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.sp_reporte_top_morosos TO rol_administrativo_bancario;


--PERMISOS PARA ADMINISTRATIVO OPERATIVO
GRANT EXECUTE ON gestion.sp_modificar_Unidad_Funcional TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_alta_Unidad_Funcional TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_eliminar_Unidad_Funcional TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_reporte_Pagos_Ordinarios TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_reporte_top_morosos TO rol_administrativo_operativo;


--PERMISOS PARA SISTEMAS
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_sistemas;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_sistemas;
GRANT EXECUTE ON gestion.sp_reporte_Pagos_Ordinarios TO rol_sistemas;
GRANT EXECUTE ON gestion.sp_reporte_top_morosos TO rol_sistemas;


--------------------
	/*DETALLES*/
--------------------
-- Ver roles fijos de servidor y usuarios asignados
SELECT SRM.role_principal_id, SP.name AS Role_Name,   
SRM.member_principal_id, SP2.name  AS Member_Name  
FROM sys.server_role_members AS SRM  
JOIN sys.server_principals AS SP  
    ON SRM.Role_principal_id = SP.principal_id  
JOIN sys.server_principals AS SP2   
    ON SRM.member_principal_id = SP2.principal_id  
ORDER BY  SP.name,  SP2.name
--------------------
-- ver roles de la DB y usuarios asignados
SELECT    roles.principal_id                            AS RolePrincipalID
    ,    roles.name                                    AS RolePrincipalName
    ,    database_role_members.member_principal_id    AS MemberPrincipalID
    ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
    ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
    ON database_role_members.member_principal_id = members.principal_id;
--------------------
-- permisos otorgados explicitamente
SELECT
    perms.state_desc AS State,
    permission_name AS [Permission],
    obj.name AS [on Object],
    dp.name AS [to User Name]
FROM sys.database_permissions AS perms
JOIN sys.database_principals AS dp
    ON perms.grantee_principal_id = dp.principal_id
JOIN sys.objects AS obj
    ON perms.major_id = obj.object_id;
--------------------------------------------
