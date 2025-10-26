import heapq

# Movimentos possíveis: cima, baixo, esquerda, direita
movimentos = [(0,1), (1,0), (0,-1), (-1,0)]

def heuristica(a, b):
    # Distância de Manhattan
    return abs(a[0] - b[0]) + abs(a[1] - b[1])

def a_estrela(grid, inicio, fim):
    filas = []
    heapq.heappush(filas, (0, inicio))
    veio_de = {inicio: None}
    custo_ate_agora = {inicio: 0}

    while filas:
        _, atual = heapq.heappop(filas)

        if atual == fim:
            break

        for dx, dy in movimentos:
            vizinho = (atual[0] + dx, atual[1] + dy)
            if (0 <= vizinho[0] < len(grid) and
                0 <= vizinho[1] < len(grid[0]) and
                grid[vizinho[0]][vizinho[1]] == 0):

                novo_custo = custo_ate_agora[atual] + 1
                if vizinho not in custo_ate_agora or novo_custo < custo_ate_agora[vizinho]:
                    custo_ate_agora[vizinho] = novo_custo
                    prioridade = novo_custo + heuristica(fim, vizinho)
                    heapq.heappush(filas, (prioridade, vizinho))
                    veio_de[vizinho] = atual
        print(custo_ate_agora)

    # Reconstruir o caminho
    caminho = []
    atual = fim
    while atual is not None:
        caminho.append(atual)
        atual = veio_de.get(atual)
    caminho.reverse()
    return caminho

# Exemplo de uso
grid = [
    [0, 0, 0, 0, 0],
    [1, 1, 0, 1, 0],
    [0, 0, 0, 1, 0],
    [0, 1, 1, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
]

inicio = (0, 0)
fim = (5, 4)

caminho = a_estrela(grid, inicio, fim)
print("Caminho encontrado:")
for p in caminho:
    print(p)













