
# 'I' : Inicio - Mistwood
# 'Z' : Fim    - Outskirts

# 'M' : Montanha
# 'A' : Agua
# 'N' : Neve
# 'L' : Lava
# 'F' : Floresta
# 'D' : Deserto
# 'R' : Rochoso
# '.' : Livre

TERRENOS_TEMPO = {
    'M' : 50,
    'A' : 20,
    'N' : 15,
    'L' : 15,
    'F' : 10,
    'D' :  8,
    'R' :  5,
    '.' :  1,
    'I' :  1,
    'Z' :  1,
    }


EVENTOS_CARACTERES = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    'B',
    'C',
    'E',
    'G',
    'H',
    'J',
    ]

INICIO_FIM_CARACTERES = [
    'I',
    'Z',

    ]

EVENTOS_DIFICULDADE = [
    55,
    60,
    65,
    70,
    75,
    90,
    95,
    120,
    125,
    130,
    135,
    150,
    155,
    160,
    170,
    180,
    ]

EVENTOS = {
    '1' : 55,
    '2' : 60,
    '3' : 65,
    '4' : 70,
    '5' : 75,
    '6' : 90,
    '7' : 95,
    '8' : 120,
    '9' : 125,
    '0' : 130,
    'B' : 135,
    'C' : 150,
    'E' : 155,
    'G' : 160,
    'H' : 170,
    'J' : 180,
    }


RUNAS = [
    'Godrick',
    'Radahn' ,
    'Morgott',
    'Malenia',
    'Rykard' ,
    ]


RUNAS_PODER = [
    1.6,
    1.4,
    1.3,
    1.2,
    1.0,
    ]

RUNAS_USOS = {
    'Godrick' : 5,
    'Radahn'  : 5,
    'Morgott' : 5,
    'Malenia' : 5,
    'Rykard'  : 5,
    }




# Tempo gasto nos eventos =  Dificuldade do evento / Somatoria das runas usada no evento
# Cada runa pode ser usada 5 vezes no total
# Uma runa ao menos deve restar ao final


