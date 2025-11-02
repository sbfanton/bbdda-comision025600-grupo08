-- Creacion de DB y esquema
use master
go

drop database if exists Com5600G08
go

create database Com5600G08 
--collate SQL_Latin1_General_CP1_CI_AS
go

use Com5600G08
go

create schema gestion
go


-- Creacion de Tablas

-- Tabla Tipo_Documento
create table gestion.Tipo_Documento(
	id varchar(5) not null,
    descripcion varchar(100) not null,
    constraint tipo_documento_pk primary key (id),
    constraint tipo_documento_ck_id 
    	check (id in ('DNI', 'LC', 'LE', 'PAS', 'CI', 'CUIL', 'CUIT'))
);
go


-- Tabla Persona 
create table gestion.Persona(
	nro_doc int not null,
	id_tipo_documento varchar(5) not null,
	nombre varchar(100) not null,
	apellido varchar(100) not null,
	email varchar(150),
	telefono varchar(30),
	constraint persona_pk primary key (nro_doc, id_tipo_documento),
	constraint persona_tipo_documento_fk foreign key (id_tipo_documento) 
		references gestion.Tipo_Documento(id),
	constraint persona_nro_doc_ck check (nro_doc > 0),
	constraint persona_email_ck check (email like '_%@_%._%'),
	constraint persona_telefono_ck check (telefono not like '%[^0-9+ -]%'),
	constraint persona_ck_contacto
		check (
		    (telefono is not null and ltrim(rtrim(telefono)) <> '')
		    or
		    (email is not null and ltrim(rtrim(email)) <> '')
		)
);
go

-- Tabla Consorcio
create table gestion.Consorcio (
	id int,
	nombre varchar(100) not null,
	calle varchar(100) not null,
	nro int not null,
	localidad varchar(100) not null,
	provincia varchar(100) not null,
	cuit char(13), -- Puede ser un consorcio que no este inscripto en ARCA
	razon_social varchar(100), -- Puede ser un consorcio que no este inscripto en ARCA
	banco varchar(50),
	cbu_cvu char(22),
	constraint consorcio_pk primary key (id),
	constraint consorcio_nro_dir_ck check (nro > 0),
	constraint consorcio_cuit_ck 
		check (
			cuit IS NULL OR 
			cuit LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
		),
	constraint consorcio_cbu_cvu_ck CHECK (cbu_cvu IS NULL OR (LEN(cbu_cvu) = 22 AND cbu_cvu NOT LIKE '%[^0-9]%')),
);
go


-- Tabla Unidad_Funcional
create table gestion.Unidad_Funcional(
	id int,
	id_consorcio int not null,
	piso varchar(10) not null,
	depto varchar(10) not null,
	porcentaje DECIMAL(5,2) not null,
	superficie_m2 DECIMAL(7,2) not null,
	tiene_cochera BIT NOT NULL DEFAULT 0, -- 1 = sí, 0 = no
    tiene_baulera BIT NOT NULL DEFAULT 0, -- 1 = sí, 0 = no
    constraint unidad_funcional_pk primary key (id, id_consorcio),
    constraint unidad_funcional_consorcio_fk foreign key (id_consorcio) 
    	references gestion.Consorcio(id),
    constraint unidad_funcional_piso_ck check (piso NOT LIKE '%[^0-9A-Za-z -]%'),
    constraint unidad_funcional_depto_ck check (depto NOT LIKE '%[^0-9A-Za-z -]%'),
    constraint unidad_funcional_porcentaje check (porcentaje > 0 AND porcentaje <= 100),
    constraint unidad_funcional_superficie_m2 check (superficie_m2 > 0)
);
go


-- Tabla Unidad_Funcional_Persona
create table gestion.Unidad_Funcional_Persona(
	id_unidad_funcional int not null,
	id_consorcio_unidad_funcional int not null,
	id_tipo_doc_persona varchar(5) not null,
	nro_doc_persona int not null,
	fecha_desde date,
	fecha_hasta date,
	es_inquilino bit not null,
	constraint unidad_funcional_persona_pk primary key 
		(id_unidad_funcional, id_consorcio_unidad_funcional,
		 id_tipo_doc_persona, nro_doc_persona),
	constraint unidad_funcional_persona_fk1 foreign key (id_unidad_funcional, id_consorcio_unidad_funcional) 
		references gestion.Unidad_Funcional(id, id_consorcio),
	constraint unidad_funcional_persona_fk2 foreign key (nro_doc_persona, id_tipo_doc_persona) 
		references gestion.Persona(nro_doc, id_tipo_documento)
);
go


-- Tabla Cuenta_Bancaria_Asociada_UF
create table gestion.Cuenta_Bancaria_Asociada_UF(
	id_unidad_funcional int not null,
	id_consorcio_unidad_funcional int not null,
	cbu_cvu char(22) not null,
	constraint cuenta_bancaria_asociada_UF_pk primary key (id_unidad_funcional, id_consorcio_unidad_funcional, cbu_cvu),
	constraint cuenta_bancaria_asociada_UF_fk foreign key (id_unidad_funcional, id_consorcio_unidad_funcional) 
		references gestion.Unidad_Funcional(id, id_consorcio),
	constraint cuenta_bancaria_asociada_UF_cbu_cvu_ck check (cbu_cvu IS NULL OR (LEN(cbu_cvu) = 22 AND cbu_cvu NOT LIKE '%[^0-9]%'))
);
go

-- Tabla Pago
create table gestion.Pago(
	id bigint /*identity(1,1)*/ not null,
	id_unidad_funcional int null,
	id_consorcio_unidad_funcional int null,
	cbu_cvu_origen char(22) not null,
	fecha datetime not null,
	importe DECIMAL(10,2) NOT NULL,
	constraint pago_pk primary key (id),
	constraint pago_unidad_funcional_fk foreign key (id_unidad_funcional, id_consorcio_unidad_funcional) 
		references gestion.Unidad_Funcional(id, id_consorcio),
	constraint pago_cbu_cvu_origen_ck check (cbu_cvu_origen IS NULL OR (LEN(cbu_cvu_origen) = 22 AND cbu_cvu_origen NOT LIKE '%[^0-9]%')),
	constraint pago_importe_ck check (importe > 0)
);
go


-- Tabla Tipo_Gasto
create table gestion.Tipo_Gasto (
	id int identity(1,1) not null,
	nombre varchar(100) not null,
	es_extraordinario bit not null,
	constraint tipo_gasto_pk primary key (id)
);
go


-- Tabla Proveedor
create table gestion.Proveedor (
	id int identity(1,1) not null,
	id_tipo_gasto int not null,
	id_consorcio int not null,
	nombre varchar(100) not null,
	detalle varchar(200) null,
	constraint proveedor_pk primary key (id),
	constraint proveedor_id_tipo_gasto_fk foreign key (id_tipo_gasto) references gestion.Tipo_Gasto(id),
	constraint proveedor_id_consorcio_fk foreign key (id_consorcio) references gestion.Consorcio(id)
);
go

-- Tabla Gasto
create table gestion.Gasto (
	id INT IDENTITY(1,1),
    id_tipo_gasto INT NOT NULL,
	id_consorcio INT NOT NULL,
    mes TINYINT NOT NULL,
    anio SMALLINT NOT NULL,
    nro_factura VARCHAR(30) NULL, 
    importe DECIMAL(12,2) NOT NULL,
    descripcion VARCHAR(200) NULL,
    cuotas_totales SMALLINT NULL,
    nro_cuota SMALLINT NULL,
    constraint gasto_pk primary key (id),
    CONSTRAINT gasto_tipo_fk FOREIGN KEY (id_tipo_gasto) REFERENCES gestion.Tipo_Gasto(id),
	CONSTRAINT gasto_consorcio_fk FOREIGN KEY (id_consorcio) 
    	REFERENCES gestion.Consorcio(id),
    constraint gasto_mes_ck check (mes BETWEEN 1 AND 12),
    constraint gasto_anio_ck check (anio BETWEEN 2000 AND 2100),
    constraint gasto_nro_factura_ck CHECK (nro_factura NOT LIKE '%[^0-9A-Za-z/-]%'), -- solo números, letras, / o -
    constraint gasto_importe_ck CHECK (importe >= 0),
    constraint gasto_cuotas_totales_ck CHECK (cuotas_totales >= 1),
    constraint gasto_nro_cuota_ck CHECK (nro_cuota >= 1),
    -- si hay nro_cuota debe haber cuotas_totales, y viceversa
    CONSTRAINT gasto_ck_cuotas_coherentes CHECK (
        (cuotas_totales IS NULL AND nro_cuota IS NULL)
        OR (cuotas_totales IS NOT NULL AND nro_cuota IS NOT NULL AND nro_cuota <= cuotas_totales)
    )
);
go

