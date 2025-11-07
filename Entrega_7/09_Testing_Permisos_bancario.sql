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
