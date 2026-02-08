# INF1771_Wumpus_Prolog_Python

Pedro Arduini - 2110132

Davi Donato - 2320399

Marcella Maia - 2520570

VIDEO APRESENTAÇÃO: https://drive.google.com/file/d/1r7bgexj1N5qIjaKyogRvKtri3lrtVwxc/view?usp=drivesdk

Main: gmap.py

Warning - swipl module is currently compatible with swi-prolog 8.4.3 download here  https://www.swi-prolog.org/download/stable/bin/swipl-8.4.3-1.x64.exe.envelope

## Lógica do Agente

O agente utiliza um sistema de decisão baseado em prioridades para navegar pelo mapa de forma segura e eficiente.

### Sistema de Prioridades

As ações são executadas seguindo uma ordem de prioridade:

1. **Retornar ao início**: Quando 3+ ouros são coletados, o agente planeja um caminho seguro até (1,1) para finalizar o jogo
2. **Coletar itens**: Pega ouro quando detectado e poções quando energia ≤ 50
3. **Executar plano**: Continua seguindo um plano de ações previamente calculado
4. **Exploração local**: Anda para células seguras não visitadas à frente, evitando morcegos conhecidos
5. **Busca de novas áreas**: Usa A* para encontrar e explorar células seguras distantes
6. **Fronteiras de perigo**: Explora fronteiras de monstros/poços/morcegos apenas quando necessário

### Segurança e Evitação de Perigos

- **Células seguras**: Apenas células visitadas sem perigos ou células não visitadas sem indícios de brisa/passos são consideradas seguras
- **Evitação de morcegos**: O agente evita células conhecidas como morcegos quando há alternativas seguras, prevenindo teletransportes indesejados
- **Pathfinding A***: Usa algoritmo A* para encontrar caminhos seguros, evitando morcegos conhecidos quando possível

### Finalização do Jogo

O jogo termina automaticamente quando o agente retorna a (1,1) com 3 ou mais ouros coletados, garantindo uma conclusão bem-sucedida da missão.

Mapa Fácil
![Mapa Fácil](mapa-facil.png)

Mapa Médio
![Mapa Médio](mapa-medio.png)

Mapa Difícil
![Mapa Difícil](mapa-dificil.png)
