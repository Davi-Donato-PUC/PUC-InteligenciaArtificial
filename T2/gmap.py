################################################
import pygame
import sys, time, random
from pyswip import Prolog, Functor, Variable, Query

import pathlib
current_path = str(pathlib.Path().resolve())

elapsed_time = 0
auto_play_tempo = 0.3  # Tempo entre ações automáticas (em segundos)
auto_play = False # Desligado por padrão (pressione A para ligar)
show_map = False  # Pressione M para mostrar mapa real
debug_mode = True  # Mostrar mensagens de debug no console

scale = 60
size_x = 12
size_y = 12
width = size_x * scale  #Largura Janela
height = size_y * scale #Altura Janela

player_pos = (1,1,'norte')
energia = 0
pontuacao = 0


mapa=[['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','',''],
      ['','','','','','','','','','','','']]

visitados = []
certezas = []

pl_file = (current_path + '\\main.pl').replace('\\','/')
prolog = Prolog()
prolog.consult(pl_file)

last_action = ""

def decisao():
    """Consulta o Prolog para decidir próxima ação"""
    acao = ""    
    
    try:
        acoes = list(prolog.query("executa_acao(X)"))
        if len(acoes) > 0:
            acao = acoes[0]['X']
            if debug_mode and acao != 'fim_jogo':
                print(f"[AI] Decisão: {acao} | Pos: {player_pos} | E:{energia} P:{pontuacao}")
    except Exception as e:
        print(f"[ERRO] Falha ao consultar ação: {e}")
        acao = ""

    return acao


def exec_prolog(a):
    """Executa uma ação no Prolog"""
    global last_action
    if a != "":
        try:
            list(prolog.query(a))
            if debug_mode and a not in ["atualiza_obs", "verifica_player"]:
                print(f"[EXEC] {a}")
        except Exception as e:
            print(f"[ERRO] Falha ao executar '{a}': {e}")
    last_action = a

def update_prolog():
    global player_pos, mapa, energia, pontuacao,visitados, show_map

    list(prolog.query("atualiza_obs, verifica_player"))

    x = Variable()
    y = Variable()
    visitado = Functor("visitado", 2)
    visitado_query = Query(visitado(x,y))
    visitados.clear()
    while visitado_query.nextSolution():
        visitados.append((x.value,y.value))
    visitado_query.closeQuery()

    x = Variable()
    y = Variable()
    certeza = Functor("certeza", 2)
    certeza_query = Query(certeza(x,y))
    certezas.clear()
    while certeza_query.nextSolution():
        certezas.append((x.value,y.value))
    certeza_query.closeQuery()
        
    if show_map:    
        x = Variable()
        y = Variable()
        z = Variable()    
        tile = Functor("tile", 3)
        tile_query = Query(tile(x,y,z))
        while tile_query.nextSolution():
            mapa[y.get_value()-1][x.get_value()-1] = str(z.value)
        tile_query.closeQuery()

    else:

        y = 0
        for j in mapa:
            x = 0
            for i in j:
                mapa[y][x] = ''
                x  += 1
            y +=  1

        x = Variable()
        y = Variable()
        z = Variable()    
        memory = Functor("memory", 3)
        memory_query = Query(memory(x,y,z))
        while memory_query.nextSolution():
            for s in z.value:
                
                if str(s) == 'brisa':
                    mapa[y.get_value()-1][x.get_value()-1] += 'P'
                elif str(s) == 'flash':
                    mapa[y.get_value()-1][x.get_value()-1] += 'F'
                elif str(s) == 'passos':
                    mapa[y.get_value()-1][x.get_value()-1] += 'D'
                elif str(s) == 'reflexo':
                    mapa[y.get_value()-1][x.get_value()-1] += 'U'
                elif str(s) == 'brilho':
                    mapa[y.get_value()-1][x.get_value()-1] += 'O'
            
        memory_query.closeQuery()

    x = Variable()
    y = Variable()
    z = Variable()

    posicao = Functor("posicao", 3)
    position_query = Query(posicao(x,y,z))
    position_query.nextSolution()
    player_pos = (x.value,y.value,str(z.value))
    position_query.closeQuery()

    x = Variable()
    energia = Functor("energia", 1)
    energia_query = Query(energia(x))
    energia_query.nextSolution()
    energia = x.value
    energia_query.closeQuery()

    x = Variable()
    pontuacao = Functor("pontuacao", 1)
    pontuacao_query = Query(pontuacao(x))
    pontuacao_query.nextSolution()
    pontuacao = x.value
    pontuacao_query.closeQuery()

    #print(mapa)
    #print(player_pos)


def load():
    global sys_font, clock, img_wall, img_grass, img_start, img_finish, img_path
    global img_gold,img_health, img_pit, img_bat, img_enemy1, img_enemy2,img_floor
    global bw_img_gold,bw_img_health, bw_img_pit, bw_img_bat, bw_img_enemy1, bw_img_enemy2,bw_img_floor
    global img_player_up, img_player_down, img_player_left, img_player_right, img_tomb

    sys_font = pygame.font.Font(pygame.font.get_default_font(), 20)
    clock = pygame.time.Clock() 

    img_wall = pygame.image.load('wall.jpg')
    #img_wall2_size = (img_wall.get_width()/map_width, img_wall.get_height()/map_height)
    img_wall_size = (width/size_x, height/size_y)
    
    img_wall = pygame.transform.scale(img_wall, img_wall_size)

    
    img_player_up = pygame.image.load('player_up.png')
    img_player_up_size = (width/size_x, height/size_y)
    img_player_up = pygame.transform.scale(img_player_up, img_player_up_size)

    img_player_down = pygame.image.load('player_down.png')
    img_player_down_size = (width/size_x, height/size_y)
    img_player_down = pygame.transform.scale(img_player_down, img_player_down_size)

    img_player_left = pygame.image.load('player_left.png')
    img_player_left_size = (width/size_x, height/size_y)
    img_player_left = pygame.transform.scale(img_player_left, img_player_left_size)

    img_player_right = pygame.image.load('player_right.png')
    img_player_right_size = (width/size_x, height/size_y)
    img_player_right = pygame.transform.scale(img_player_right, img_player_right_size)


    img_tomb = pygame.image.load('tombstone.png')
    img_tomb_size = (width/size_x, height/size_y)
    img_tomb = pygame.transform.scale(img_tomb, img_tomb_size)



    img_grass = pygame.image.load('grass.jpg')
    img_grass_size = (width/size_x, height/size_y)
    img_grass = pygame.transform.scale(img_grass, img_grass_size)

    img_floor = pygame.image.load('floor.png')
    img_floor_size = (width/size_x, height/size_y)
    img_floor = pygame.transform.scale(img_floor, img_floor_size)

    img_gold = pygame.image.load('gold.png')
    img_gold_size = (width/size_x, height/size_y)
    img_gold = pygame.transform.scale(img_gold, img_gold_size)

    img_pit = pygame.image.load('pit.png')
    img_pit_size = (width/size_x, height/size_y)
    img_pit = pygame.transform.scale(img_pit, img_pit_size)

    img_enemy1 = pygame.image.load('enemy1.png')
    img_enemy1_size = (width/size_x, height/size_y)
    img_enemy1 = pygame.transform.scale(img_enemy1, img_enemy1_size)

    img_enemy2 = pygame.image.load('enemy2.png')
    img_enemy2_size = (width/size_x, height/size_y)
    img_enemy2 = pygame.transform.scale(img_enemy2, img_enemy2_size)

    img_bat = pygame.image.load('bat.png')
    img_bat_size = (width/size_x, height/size_y)
    img_bat = pygame.transform.scale(img_bat, img_bat_size)

    img_health = pygame.image.load('health.png')
    img_health_size = (width/size_x, height/size_y)
    img_health = pygame.transform.scale(img_health, img_health_size)    
    
    bw_img_floor = pygame.image.load('bw_floor.png')
    bw_img_floor_size = (width/size_x, height/size_y)
    bw_img_floor = pygame.transform.scale(bw_img_floor, bw_img_floor_size)

    bw_img_gold = pygame.image.load('bw_gold.png')
    bw_img_gold_size = (width/size_x, height/size_y)
    bw_img_gold = pygame.transform.scale(bw_img_gold, bw_img_gold_size)

    bw_img_pit = pygame.image.load('bw_pit.png')
    bw_img_pit_size = (width/size_x, height/size_y)
    bw_img_pit = pygame.transform.scale(bw_img_pit, bw_img_pit_size)

    bw_img_enemy1 = pygame.image.load('bw_enemy1.png')
    bw_img_enemy1_size = (width/size_x, height/size_y)
    bw_img_enemy1 = pygame.transform.scale(bw_img_enemy1, bw_img_enemy1_size)

    bw_img_enemy2 = pygame.image.load('bw_enemy2.png')
    bw_img_enemy2_size = (width/size_x, height/size_y)
    bw_img_enemy2 = pygame.transform.scale(bw_img_enemy2, bw_img_enemy2_size)

    bw_img_bat = pygame.image.load('bw_bat.png')
    bw_img_bat_size = (width/size_x, height/size_y)
    bw_img_bat = pygame.transform.scale(bw_img_bat, bw_img_bat_size)

    bw_img_health = pygame.image.load('bw_health.png')
    bw_img_health_size = (width/size_x, height/size_y)
    bw_img_health = pygame.transform.scale(bw_img_health, bw_img_health_size)  

def update(dt, screen):
    
    global elapsed_time
    
    elapsed_time += dt
    
    if (elapsed_time / 1000) > auto_play_tempo:
        
        if auto_play and player_pos[2] != 'morto':
            acao = decisao()
            if acao != 'fim_jogo':
                exec_prolog(acao)
                update_prolog()
       
        elapsed_time = 0
        
    

def reset_game():
    """Reinicia o jogo"""
    global player_pos, energia, pontuacao, visitados, certezas
    list(prolog.query("reset_game"))
    update_prolog()

def key_pressed(event):
    
    global show_map, auto_play
    #leitura do teclado
    if event.type == pygame.KEYDOWN:
        
        # Reiniciar jogo (R ou F5)
        if event.key == pygame.K_r or event.key == pygame.K_F5:
            reset_game()
            return
        
        # Alternar auto_play (A)
        if event.key == pygame.K_a:
            auto_play = not auto_play
            exec_prolog("limpar_plano")
            return
        
        if not auto_play and player_pos[2] != 'morto':
            if event.key == pygame.K_LEFT: #tecla esquerda
                exec_prolog("virar_esquerda")
                update_prolog()

            elif event.key == pygame.K_RIGHT: #tecla direita
                exec_prolog("virar_direita")
                update_prolog()

            elif event.key == pygame.K_UP: #tecla  cima
                exec_prolog("andar")
                update_prolog()

            if event.key == pygame.K_SPACE:
                exec_prolog("pegar")
                update_prolog()
    
        if event.key == pygame.K_m:
            show_map = not show_map
            update_prolog()


def draw_screen(screen):
    
    screen.fill((0,0,0))
 
    y = 0
    for j in mapa:
        x = 0
        for i in j:

            if (x+1,12-y) in visitados:
                screen.blit(img_floor, (x * img_floor.get_width(), y * img_floor.get_height()))
            else:
                screen.blit(bw_img_floor, (x * bw_img_floor.get_width(), y * bw_img_floor.get_height()))

            if mapa[11-y][x].find('P') > -1:
                if (x+1,12-y) in certezas:
                    screen.blit(img_pit, (x * img_pit.get_width(), y * img_pit.get_height()))                            
                else:
                    screen.blit(bw_img_pit, (x * bw_img_pit.get_width(), y * bw_img_pit.get_height()))                            

            if mapa[11-y][x].find('F') > -1:
                if (x+1,12-y) in certezas:
                    screen.blit(img_bat, (x * img_bat.get_width(), y * img_bat.get_height()))
                else:
                    screen.blit(bw_img_bat, (x * bw_img_bat.get_width(), y * bw_img_bat.get_height()))

            if mapa[11-y][x].find('D') > -1:
                if (x+1,12-y) in certezas:
                    screen.blit(img_enemy1, (x * img_enemy1.get_width(), y * img_enemy1.get_height()))                                               
                else:
                    screen.blit(bw_img_enemy1, (x * bw_img_enemy1.get_width(), y * bw_img_enemy1.get_height()))                                               
                            
            if mapa[11-y][x].find('d') > -1:
                if (x+1,12-y) in certezas:
                    screen.blit(img_enemy2, (x * img_enemy2.get_width(), y * img_enemy2.get_height()))                                               
                else:
                    screen.blit(bw_img_enemy2, (x * bw_img_enemy2.get_width(), y * bw_img_enemy2.get_height()))                                               

            if mapa[11-y][x].find('U') > -1:
                if (x+1,12-y) in certezas:
                    screen.blit(img_health, (x * img_health.get_width(), y * img_health.get_height()))                               
                else:
                    screen.blit(bw_img_health, (x * bw_img_health.get_width(), y * bw_img_health.get_height()))                               

            if mapa[11-y][x].find('O') > -1:
                if (x+1,12-y) in certezas:
                    screen.blit(img_gold, (x * img_gold.get_width(), y * img_gold.get_height()))                
                else:
                    screen.blit(bw_img_gold, (x * bw_img_gold.get_width(), y * bw_img_gold.get_height()))                
            
            if x == player_pos[0] - 1  and  y == 12 - player_pos[1]:
                if player_pos[2] == 'norte':
                    screen.blit(img_player_up, (x * img_player_up.get_width(), y * img_player_up.get_height()))                                               
                elif player_pos[2] == 'sul':
                    screen.blit(img_player_down, (x * img_player_down.get_width(), y * img_player_down.get_height()))                                               
                elif player_pos[2] == 'leste':
                    screen.blit(img_player_right, (x * img_player_right.get_width(), y * img_player_right.get_height()))                                               
                elif player_pos[2] == 'oeste':
                    screen.blit(img_player_left, (x * img_player_left.get_width(), y * img_player_left.get_height()))                                                                                                           
                else:
                    screen.blit(img_tomb, (x * img_tomb.get_width(), y * img_tomb.get_height()))                                                                                                           
            x  += 1
        y +=  1

    # Linha 1: Pontuação, Última ação, Energia
    t = sys_font.render("Pontos: " + str(pontuacao), False, (255,255,255))
    screen.blit(t, t.get_rect(top = height + 5, left=10))

    # Exibir última ação com cor baseada no tipo
    action_color = (255,255,255)
    if last_action == "andar":
        action_color = (100, 255, 100)
    elif "virar" in str(last_action):
        action_color = (255, 255, 100)
    elif last_action == "pegar":
        action_color = (255, 215, 0)
    
    action_text = f"Ação: {last_action}" if last_action else "Ação: aguardando..."
    t = sys_font.render(action_text, False, action_color)
    screen.blit(t, t.get_rect(top = height + 5, left=width/2-80))
    
    # Energia com cor baseada no nível
    energia_color = (255,255,255)
    if energia > 70:
        energia_color = (100, 255, 100)
    elif energia > 40:
        energia_color = (255, 255, 100)
    else:
        energia_color = (255, 100, 100)
    
    t = sys_font.render("Energia: " + str(energia), False, energia_color)
    screen.blit(t, t.get_rect(top = height + 5, left=width-140))
    
    # Linha 2: Auto play, Controles, Posição
    auto_text = "Auto: ON" if auto_play else "Auto: OFF"
    auto_color = (0, 255, 0) if auto_play else (255, 255, 255)
    t = sys_font.render(auto_text, False, auto_color)
    screen.blit(t, t.get_rect(top = height + 25, left=10))
    
    # Mostrar controles
    controls_text = "R: Reset | A: Auto | M: Mapa | Setas+Espaço: Manual"
    t_small = pygame.font.Font(pygame.font.get_default_font(), 14)
    t = t_small.render(controls_text, False, (180,180,180))
    screen.blit(t, t.get_rect(top = height + 28, left=width/2-160))
    
    # Mostrar células visitadas
    num_visitados = len(visitados)
    t = sys_font.render(f"Visitados: {num_visitados}", False, (200,200,255))
    screen.blit(t, t.get_rect(top = height + 25, left=width-140))

def main_loop(screen):  
    global clock
    running = True
    
    while running:
        for e in pygame.event.get(): 
            if e.type == pygame.QUIT:
                running = False
                break
            
            key_pressed(e)
            
        # Calcula tempo transcorrido desde
        # a última atualização 
        dt = clock.tick()
        
        
        # Atualiza posição dos objetos da tela
        update(dt, screen)
        
        # Desenha objetos na tela 
        draw_screen(screen)

        # Pygame atualiza o seu estado
        pygame.display.update() 


update_prolog()

pygame.init()
pygame.display.set_caption('INF1771 Trabalho 2 - Agente Lógico')
screen = pygame.display.set_mode((width, height+50))
load()

main_loop(screen)
pygame.quit()



