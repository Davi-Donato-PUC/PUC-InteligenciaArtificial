#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gerador de mapas aleatórios para o jogo Pitfall Harry
Gera mapas 12x12 com as quantidades especificadas:
- 2 inimigos de dano 20 (D)
- 2 inimigos de dano 50 (d)
- 8 poços/obstáculos (P)
- 3 pedras de ouro (O)
- 4 inimigos de teletransporte (T)
- 3 powerups de energia (U)
"""

import random
import sys

def generate_map(filename='mapa.pl'):
    """
    Gera um mapa aleatório 12x12 com as quantidades especificadas
    """
    SIZE_X = 12
    SIZE_Y = 12
    
    # Inicializa o mapa com células vazias
    mapa = [['' for _ in range(SIZE_X)] for _ in range(SIZE_Y)]
    
    # Lista de posições disponíveis (excluindo [1,1] que é a posição inicial)
    available_positions = []
    for x in range(1, SIZE_X + 1):
        for y in range(1, SIZE_Y + 1):
            if not (x == 1 and y == 1):
                available_positions.append((x, y))
    
    # Embaralha as posições disponíveis
    random.shuffle(available_positions)
    
    # Quantidades especificadas
    quantities = {
        'D': 2,  # Inimigos pequenos (dano 20)
        'd': 2,  # Inimigos grandes (dano 50)
        'P': 8,  # Poços
        'O': 3,  # Ouros
        'T': 4,  # Morcegos (teletransporte)
        'U': 3   # Powerups de energia
    }
    
    # Coloca os elementos no mapa
    pos_idx = 0
    for element, count in quantities.items():
        for _ in range(count):
            if pos_idx < len(available_positions):
                x, y = available_positions[pos_idx]
                mapa[y - 1][x - 1] = element
                pos_idx += 1
    
    # Escreve o arquivo Prolog
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(":-dynamic tile/3.\n")
        f.write("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n")
        f.write("%% Definição do mapa\n")
        f.write("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n")
        f.write(f"map_size({SIZE_X},{SIZE_Y}).\n\n")
        
        # Escreve os tiles (note que Y vai de 12 para 1, pois o sistema usa Y invertido)
        for y in range(SIZE_Y, 0, -1):
            for x in range(1, SIZE_X + 1):
                content = mapa[y - 1][x - 1]
                f.write(f"tile({x},{y},'{content}').\n")
    
    print(f"Mapa gerado e salvo em {filename}")
    print(f"Elementos colocados:")
    for element, count in quantities.items():
        print(f"  {element}: {count}")
    
    return mapa

if __name__ == '__main__':
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        filename = 'mapa.pl'
    
    generate_map(filename)

