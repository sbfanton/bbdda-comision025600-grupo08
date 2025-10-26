import pandas as pd

# Lista de tipos de documento
tipos_documento = ['DNI', 'LC', 'LE', 'PAS', 'CI', 'CUIL', 'CUIT']
descripcion = ['Documento Nacional de Identidad',
               'Libreta Civica',
               'Libreta de Enrolamiento',
               'Pasaporte',
               'Cedula de Identidad',
               'Codigo Unico de Identificacion Laboral',
               'Codigo Unico de Identificacion Tributaria']

df = pd.DataFrame({
    'id': tipos_documento, 
    'descripcion': descripcion
})


# Guardar en CSV
df.to_csv('tipos_documento.csv', index=False, encoding='utf-8')