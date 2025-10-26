import itertools
from time import sleep
from buscaAEstrela import *

def melhorRota_Permutacao(grid, start, end, eventos:dict):
    eventosE = list(eventos.keys())
    #eventosE = eventosE[:4] + ['2']
    print(eventosE)

    melhorCusto = float('inf')
    melhorOrdem = None
    melhorCaminhoInteiro = []


    ID = 0
    for perm in itertools.permutations(eventosE):  # Para cada permutação
        if ID == 100 : break

        ordem = ['I'] + list(perm) + ['Z']
        pontos = [start] + [eventos[e] for e in perm] + [end]
        custoTotal = 0
        caminhoTotal = []

        
        for i in range(len(ordem) - 1) : # Para cada evento

            caminho, custo = aEstrela(grid, pontos[i], pontos[i+1])
            custoTotal += custo

            if i == 0: caminhoTotal.extend(caminho)
            else:      caminhoTotal.extend(caminho[1:])

        if  custoTotal < melhorCusto:
            melhorCusto = custoTotal
            melhorOrdem = ordem
            melhorCaminhoInteiro = caminhoTotal

        ID+=1
        print(ID)


    return melhorOrdem, melhorCaminhoInteiro, melhorCusto



import random
import math

def melhorRota_SimulatedAnnealing(grid, start, end, eventos: dict, temp_inicial=10_000, temp_final=0.1, resfriamento=0.99):
    eventosE = list(eventos.keys())
    random.shuffle(eventosE)
    ordem_atual = ['I'] + eventosE + ['Z']
    pontos_atual = [start] + [eventos[e] for e in eventosE] + [end]

    custo_cache = {}

    def calcula_custo(ordem, pontos):
        custo = 0
        for i in range(len(pontos) - 1):
            par = (pontos[i], pontos[i+1])
            if par not in custo_cache:
                _, c = aEstrela(grid, pontos[i], pontos[i+1])
                custo_cache[par] = c
            custo += custo_cache[par]
        return custo

    custo_atual = calcula_custo(ordem_atual, pontos_atual)
    melhor_ordem = ordem_atual[:]
    melhor_pontos = pontos_atual[:]
    melhor_custo = custo_atual

    temperatura = temp_inicial
    ii = 0
    while temperatura > temp_final:
        i, j = random.sample(range(1, len(eventosE)+1), 2)  # evita I e Z
        nova_ordem = ordem_atual[:]
        nova_ordem[i], nova_ordem[j] = nova_ordem[j], nova_ordem[i]
        nova_pontos = [start] + [eventos[e] for e in nova_ordem[1:-1]] + [end]

        novo_custo = calcula_custo(nova_ordem, nova_pontos)
        delta = novo_custo - custo_atual

        if delta < 0 or random.random() < math.exp(-delta / temperatura):
            ordem_atual = nova_ordem
            pontos_atual = nova_pontos
            custo_atual = novo_custo

            if novo_custo < melhor_custo:
                melhor_custo = novo_custo
                melhor_ordem = nova_ordem[:]
                melhor_pontos = nova_pontos[:]

        temperatura *= resfriamento
        ii += 1
        #print(ii)

    caminho_total = []
    for i in range(len(melhor_pontos) - 1):
        caminho, _ = aEstrela(grid, melhor_pontos[i], melhor_pontos[i+1])
        if i == 0:
            caminho_total.extend(caminho)
        else:
            caminho_total.extend(caminho[1:])

    return melhor_ordem, caminho_total, melhor_custo










