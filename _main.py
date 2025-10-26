from presets import *
from utils import * 
from melhorRota import * 
from genetica   import *
from interface import *



def main() : # (X, Y)

    # Aqui eu pego os pontos
    start, end, eventos, grid = encontrarPosicoes('mapa.txt')

    # Decido a melhor rota
    melhorCromossomo, custoEventosRunas, eventosRunas = genetica()
    ordem, caminho, custoCaminho = melhorRota_SimulatedAnnealing(grid, start, end, eventos)

    # Decido as runas usadas em cada evento
    print(melhorCromossomo)

    custoTotal = custoCaminho + custoEventosRunas


    eventosComRunas = {}
    for id, k in enumerate(EVENTOS_CARACTERES) :
        eventosComRunas[k] = eventosRunas[id]
        for ide, e in enumerate(eventosComRunas[k]) :
            eventosComRunas[k][ide] = e +1


    print(ordem)
    print(eventosComRunas)
    for k, v in eventosComRunas.items() : 
        for a in v : 
            print(f'Evento:{k} : {RUNAS[a-1]}')
    print("Custo percurso:", custoCaminho)
    print("Custo runas:", custoEventosRunas)
    print("Custo total:",custoTotal)
    desenhar_mapa_pyqtgraph('mapa.txt', caminho, start, end, eventos, ordem, 25, eventosComRunas, custoTotal)





main()








