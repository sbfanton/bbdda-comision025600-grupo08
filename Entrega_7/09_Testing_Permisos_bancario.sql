/*

- Materia: Bases de Datos Aplicadas

- Comisión: 02-5600 - Viernes Tarde

- Fecha: 7/11/2025

- Grupo: 8

- Integrantes:
Cazal, Leila Abigail - 42023980
Fanton, Sol Belén - 38789602
Castro, Ezequiel Alejandro - 45239803
Grance Zenteno, Lucas Rodrigo - 43406784

- Enunciado:
*** Entrega 7 -Requisitos de seguridad *** 
Asigne los roles correspondientes para poder cumplir con este requisito, según el área a la cual pertenece.
Rol: Administrativo Bancario - Acciones: Importación de información bancaria, Generación de reportes (...)

Este archivo corresponde al testing del rol Administrativo Bancario

*/


use Com5600G08

--'admin_bancario';
--no
EXEC gestion.sp_modificar_Unidad_Funcional @id = 1,@id_consorcio = 4,@piso = 'PB',
@depto = 'A',@porcentaje = 1,@superficie_m2 = 2,@tiene_cochera =1,@tiene_baulera = 0;


EXEC gestion.sp_importar_pagos
     @path = N'C:\Consorcios\pagos_consorcios.csv'; --si


EXEC gestion.sp_reporte_recaudacion_por_procedencia 
@anioInicio = 2025, @anioFin = 2025, @idConsorcio = 1;--si

EXEC gestion.sp_reporte_top_morosos --consulta
EXEC gestion.sp_reporte_pagos_ordinarios --si

EXEC gestion.sp_eliminar_Unidad_Funcional_Persona --no
    @id_unidad_funcional = 1, @id_consorcio_unidad_funcional = 4,
    @id_tipo_doc_persona = 'DNI', @nro_doc_persona = 29256383;

EXEC gestion.sp_modificar_Consorcio 
@id = 999, @nombre = 'Consorcio Editado', @calle = 'Belgrano', @nro = 250, @localidad = 'Morón', @provincia = 'Buenos Aires';
--no

