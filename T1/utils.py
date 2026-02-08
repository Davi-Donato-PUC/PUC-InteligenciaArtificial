


from presets import *

def encontrarPosicoes(filename) : # (X, Y)
    eventos = {}
    start   = (0, 0)
    end     = (0, 0)

    with open(filename) as file :
        GRID = file.readlines()

    for posI, LINHA in enumerate(GRID) :
        GRID[posI] = LINHA.strip('\n')

        for evento in EVENTOS_CARACTERES :
            posJ = LINHA.find(evento)
            if posJ > -1 :
                eventos[evento] = ( posJ, posI )
            
        if LINHA.find('Z') > -1:
            end   = (LINHA.find('Z'), posI)
        if LINHA.find('I') > -1:
            start = (LINHA.find('I'), posI)

    return start, end, eventos, GRID






#['I', '6', 'G', 'C', 'E', '9', 'B', '4', '5', '1', '2', '8', '7', '0', 'J', 'Z']
