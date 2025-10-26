import heapq
from presets import *

# Movimentos possíveis: cima, baixo, esquerda, direita
movimentos = [(0,1), (1,0), (0,-1), (-1,0)]


def heuristica(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def aEstrela(mapa, inicio, fim):
    lenX = len(mapa[0])
    lenY = len(mapa)

    filas = []
    heapq.heappush(filas, (0, inicio))
    veio_de = {inicio: None}
    custo_ate_agora = {inicio: 0}

    while filas:
        _, atual = heapq.heappop(filas)

        if atual == fim : break

        for dx, dy in movimentos:
            vizinho = (atual[0] + dx, atual[1] + dy)

            if ( lenX > vizinho[0] >= 0  and lenY > vizinho[1] >= 0 ) : # Verifica se o vizinho é válido
                caractere = mapa[vizinho[1]][vizinho[0]]

                if caractere in EVENTOS_CARACTERES : 
                    novo_custo = custo_ate_agora[atual] + 1
                else : 
                    novo_custo = custo_ate_agora[atual] + TERRENOS_TEMPO[caractere]


                if vizinho not in custo_ate_agora or novo_custo < custo_ate_agora[vizinho]:

                    custo_ate_agora[vizinho] = novo_custo
                    prioridade = novo_custo + heuristica(fim, vizinho)
                    heapq.heappush(filas, (prioridade, vizinho))
                    veio_de[vizinho] = atual


    caminho = []
    atual = fim
    while atual is not None:
        caminho.append(atual)
        atual = veio_de.get(atual)
    caminho.reverse()
    custo_total = custo_ate_agora.get(fim, float('inf'))
    return caminho, custo_total














