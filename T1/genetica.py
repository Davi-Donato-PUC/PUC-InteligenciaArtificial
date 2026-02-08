import random
from presets import *

# --- FITNESS ---
def calcularFitness(cromossomo) -> float :
    eventsRunas = [[] for _ in range(16)]
    eventsDiffs = []
    apagado = cromossomo[25]
    a = cromossomo[apagado]
    cromossomo[apagado] = -1
    for ID, E in enumerate(cromossomo[:25]) :
        if E == -1 : continue
        eventsRunas[E].append((ID)//5)
    
    cromossomo[apagado] = a
    for IDE, event in enumerate(eventsRunas) :
        somaRuna = 0
        for runa in event:
            somaRuna += RUNAS_PODER[runa]
        eventsDiffs.append(EVENTOS_DIFICULDADE[IDE] / somaRuna)

    return sum(eventsDiffs)


# --- CROSSOVER ---
def crossover(C1: list, C2: list):
    F1 = C1[:]
    F2 = C2[:]

    for I in range(0, 24):
        A1 = F1[F1[25]]
        G = F1[I]
        QG = F1[:25].count(F1[I])
        QA = F1[:25].count(A1)
        if QG > 1 and ((A1 != G) or (A1 == G and (F1[25] == I or QA > 2)))   :
            F1[I] = C2[I]

    for I in range(0, 24):
        A2 = F2[F2[25]]
        G = F2[I]
        QG = F2[:25].count(F2[I])
        QA = F2[:25].count(A2)
        if QG > 1 and ((A2 != G) or (A2 == G and (F2[25] == I or QA > 2)))  :
            F2[I] = C1[I]

    if F1[:25].count(F1[C2[25]]) > 1:
        F1[25] = C2[25]
    if F2[:25].count(F2[C1[25]]) > 1:
        F2[25] = C1[25]

    return F1, F2


def criarCromossomo() -> list :
    eventosBase : list = [i for i in range(16)]
    eventosMais : list = [random.randint(0, 15) for _ in range(9)]
    cromossomo = eventosBase + eventosMais 
    random.shuffle(cromossomo)
    while True :
        apagado = random.randint(0, 24)
        if cromossomo.count(cromossomo[apagado]) > 1 :
            cromossomo += [apagado]
            break
    return cromossomo


def selecao_torneio(populacao, tamanho=3):
    """Seleciona o melhor de 'tamanho' indivíduos aleatórios."""
    candidatos = random.sample(populacao, tamanho)
    candidatos.sort(key=calcularFitness)
    return candidatos[0]


def diversidade(populacao):
    """Mede a diversidade média da população (diferenças entre genes)."""
    base = populacao[0]
    total = 0
    for c in populacao[1:]:
        dif = sum(1 for a, b in zip(base, c) if a != b)
        total += dif
    return total / (len(populacao)-1)


def mutacao_adaptativa(C):
    """Mutação que respeita o formato do cromossomo."""
    while True:
        i1, i2 = random.sample(range(25), 2)
        apagado = C[25]
        # evita trocar com o apagado
        if i1 != apagado and i2 != apagado and C[i1] != C[apagado]  :
            C[i1], C[i2] = C[i2], C[i1]
            break

def getListRunasEventos(cromossomo) :
    eventsRunas = [[] for _ in range(16)]
    apagado = cromossomo[25]
    a = cromossomo[apagado]
    cromossomo[apagado] = -1
    for ID, E in enumerate(cromossomo[:25]) :
        if E == -1 : continue
        eventsRunas[E].append((ID)//5)
    cromossomo[apagado] = a
    return eventsRunas

def genetica(tamanhoPopulacao=100, geracoes=1000, taxaMutacao=0.4):
    populacao = [criarCromossomo() for _ in range(tamanhoPopulacao)]
    populacao.sort(key=calcularFitness)
    melhorGlobal = populacao[0]

    for g in range(geracoes):
        novaPopulacao = [populacao[0]]  # elitismo leve (guarda o melhor)

        div = diversidade(populacao)
        if   div < 5 : taxaMutacao = 0.8  # mais mutação se estiver tudo igual
        elif div > 15: taxaMutacao = 0.3  # menos se estiver bem distribuído

        # --- reprodução ---
        while len(novaPopulacao) < tamanhoPopulacao * 0.8:
            pai1 = selecao_torneio(populacao)
            pai2 = selecao_torneio(populacao)
            f1, f2 = crossover(pai1, pai2)

            if random.random() < taxaMutacao:
                mutacao_adaptativa(f1)
            if random.random() < taxaMutacao:
                mutacao_adaptativa(f2)

            novaPopulacao.append(f1)
            if len(novaPopulacao) < tamanhoPopulacao:
                novaPopulacao.append(f2)

        # --- reinserção de novos indivíduos aleatórios ---
        novos_aleatorios = [criarCromossomo() for _ in range(int(tamanhoPopulacao * 0.2))]
        populacao = novaPopulacao + novos_aleatorios

        # --- seleção dos melhores para a próxima geração ---
        populacao.sort(key=calcularFitness)
        populacao = populacao[:tamanhoPopulacao]

        # --- guarda o melhor global ---
        if calcularFitness(populacao[0]) < calcularFitness(melhorGlobal):
            melhorGlobal = populacao[0]


    return melhorGlobal, calcularFitness(melhorGlobal), getListRunasEventos(melhorGlobal)




