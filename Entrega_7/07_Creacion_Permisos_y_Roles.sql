USE master
GO

CREATE LOGIN admin_general WITH PASSWORD = 'AdmGen123!';
CREATE LOGIN admin_bancario WITH PASSWORD = 'AdmBan123!';
CREATE LOGIN admin_operativo WITH PASSWORD = 'AdmOpe123!';
CREATE LOGIN sistemas WITH PASSWORD = 'Sist123!';
GO
  

USE Com5600G08;
GO

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
GRANT EXECUTE ON gestion.sp_modificar_Unidad_Funcional TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_administrativo_general;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_administrativo_general;
GRANT EXECUTE ON gestion.ReportePagosOrdinarios TO rol_administrativo_general;
GRANT EXECUTE ON gestion.TopMorosos TO rol_administrativo_general;
--[FALTA AGREGAR REPORTE 1 Y 2],[CAMBIARLE NOMBRE A LOS REPORTES, QUE EMPIECEN CON sp_reporte_(que hace)]

--PERMISOS PARA ADMINISTRATIVO BANCARIO
GRANT EXECUTE ON gestion.sp_importar_pagos TO rol_administrativo_bancario;
--alguno mas se considera info bancaria?
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.ReportePagosOrdinarios TO rol_administrativo_bancario;
GRANT EXECUTE ON gestion.TopMorosos TO rol_administrativo_bancario;
--[FALTA AGREGAR REPORTE 1 Y 2],[CAMBIARLE NOMBRE A LOS REPORTES, QUE EMPIECEN CON sp_reporte_(que hace)]

--PERMISOS PARA ADMINISTRATIVO OPERATIVO
GRANT EXECUTE ON gestion.sp_modificar_Unidad_Funcional TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.ReportePagosOrdinarios TO rol_administrativo_operativo;
GRANT EXECUTE ON gestion.TopMorosos TO rol_administrativo_operativo;
--[FALTA AGREGAR REPORTE 1 Y 2],[CAMBIARLE NOMBRE A LOS REPORTES, QUE EMPIECEN CON sp_reporte_(que hace)]

--PERMISOS PARA SISTEMAS
GRANT EXECUTE ON gestion.sp_reporte_recaudacion_por_procedencia TO rol_sistemas;
GRANT EXECUTE ON gestion.sp_reporte_mayores_ingresos_gastos_xml TO rol_sistemas;
GRANT EXECUTE ON gestion.ReportePagosOrdinarios TO rol_sistemas;
GRANT EXECUTE ON gestion.TopMorosos TO rol_sistemas;
--[FALTA AGREGAR REPORTE 1 Y 2],[CAMBIARLE NOMBRE A LOS REPORTES, QUE EMPIECEN CON sp_reporte_(que hace)]


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