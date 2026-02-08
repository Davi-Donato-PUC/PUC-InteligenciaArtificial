
:-dynamic posicao/3.
:-dynamic memory/3.
:-dynamic visitado/2.
:-dynamic certeza/2.
:-dynamic energia/1.
:-dynamic pontuacao/1.
:-dynamic saiu_inicio/0.
:-dynamic jogo_terminado/0.
:-dynamic seguro/2.
:-dynamic direcoes_testadas/1.
:-dynamic perigoso/3.
:-dynamic plano/1.
:-dynamic pilha_backtrack/1.
:-dynamic turnos_consecutivos/1.
:-dynamic historico_posicoes/1.  % Rastro de últimas N posições para detectar loops
:-dynamic blocked/2.  % Posições bloqueadas para A*
:-dynamic ouro/1.  % Contador de ouro coletado

:-discontiguous executa_acao/1.

:-consult('mapa.pl').

delete([], _, []).
delete([Elem|Tail], Del, Result) :-
    (   \+ Elem \= Del
    ->  delete(Tail, Del, Result)
    ;   Result = [Elem|Rest],
        delete(Tail, Del, Rest)
    ).
	


reset_game :- retractall(memory(_,_,_)), 
		retractall(visitado(_,_)), 
		retractall(certeza(_,_)),
		retractall(energia(_)),
		retractall(pontuacao(_)),
		retractall(posicao(_,_,_)),
		retractall(saiu_inicio),
		retractall(jogo_terminado),
		retractall(seguro(_,_)),
		retractall(perigoso(_,_,_)),
		retractall(plano(_)),
		retractall(pilha_backtrack(_)),
		retractall(turnos_consecutivos(_)),
		retractall(historico_posicoes(_)),
		retractall(blocked(_,_)),
		retractall(ouro(_)),
		retractall(tile(_,_,_)),
		consult('mapa.pl'),
		assert(energia(100)),
		assert(pontuacao(0)),
		assert(posicao(1,1, norte)),
		assert(seguro(1,1)),
		assert(visitado(1,1)),
		assert(historico_posicoes([])),
		assert(certeza(1,1)),
		assert(memory(1,1,[])),
		assert(pilha_backtrack([(1,1)])),
		assert(turnos_consecutivos(0)),
		assert(ouro(0)).


:-reset_game.

limpar_plano :- retractall(plano(_)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Controle de Status
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%atualiza pontuacao
atualiza_pontuacao(X):- pontuacao(P), retract(pontuacao(P)), NP is P + X, assert(pontuacao(NP)),!.

%atualiza energia
atualiza_energia(N):- energia(E), retract(energia(E)), NE is E + N, 
					(
					 (NE =<0, assert(energia(0)),posicao(X,Y,_),retract(posicao(_,_,_)), assert(posicao(X,Y,morto)), atualiza_pontuacao(-1000),!);
					 (NE >100, assert(energia(100)),!);
					  (NE >0,assert(energia(NE)),!)
					 ).

%verifica situacao da nova posicao e atualiza energia e pontos
%IMPORTANTE: ordem das regras importa - perigos devem ser verificados primeiro!
verifica_player :- jogo_terminado,!.
%Verifica poço primeiro (morte instantânea)
verifica_player :- posicao(X,Y,_), tile(X,Y,'P'), atualiza_energia(-100), atualiza_pontuacao(-1000), assert(jogo_terminado),!.
%Verifica morcego (teletransporte)
verifica_player :- posicao(X,Y,Z), tile(X,Y,'T'), 
				map_size(SX,SY), random_between(1,SX,NX), random_between(1,SY,NY),
			retract(posicao(X,Y,Z)), assert(posicao(NX,NY,Z)), 
			limpar_plano, 
			% Marca nova posição como visitada e atualiza conhecimento
			assert(visitado(NX,NY)),
			set_real(NX,NY),
			% Reset pilha após teleporte com nova posição
			retract(pilha_backtrack(_)), assert(pilha_backtrack([(NX,NY)])),
			atualiza_obs, verifica_player,!.
%Verifica inimigo grande (dano 50)
verifica_player :- posicao(X,Y,_), tile(X,Y,'d'), atualiza_energia(-50), atualiza_pontuacao(-50),!.
%Verifica inimigo pequeno (dano 20)
verifica_player :- posicao(X,Y,_), tile(X,Y,'D'), atualiza_energia(-20), atualiza_pontuacao(-20),!.
%VERIFICA VITÓRIA: Se está em (1,1) com 3+ ouros, termina o jogo com sucesso
verifica_player :- 
    posicao(1,1,_),
    ouro(Qtd),
    Qtd >= 3,
    \+jogo_terminado,
    assert(jogo_terminado),
    format('[VITÓRIA] Agente retornou ao ponto inicial (1,1) com ~w ouros! Jogo finalizado.~n', [Qtd]),
    !.
%marca que saiu da posição inicial (para possível uso futuro) - SEM CORTE para não impedir outras verificações
verifica_player :- posicao(X,Y,_), (X \= 1; Y \= 1), \+saiu_inicio, assert(saiu_inicio).
%nota: jogo termina quando agente morre OU quando retorna a (1,1) com 3+ ouros
verifica_player.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Comandos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%virar direita (rotação de 270° no sentido horário)
virar_direita :- jogo_terminado,!.
virar_direita :- posicao(X,Y, norte), retract(posicao(_,_,_)), assert(posicao(X, Y, leste)),atualiza_pontuacao(-1),incrementa_turnos,!.
virar_direita :- posicao(X,Y, leste), retract(posicao(_,_,_)), assert(posicao(X, Y, sul)),atualiza_pontuacao(-1),incrementa_turnos,!.
virar_direita :- posicao(X,Y, sul), retract(posicao(_,_,_)), assert(posicao(X, Y, oeste)),atualiza_pontuacao(-1),incrementa_turnos,!.
virar_direita :- posicao(X,Y, oeste), retract(posicao(_,_,_)), assert(posicao(X, Y, norte)),atualiza_pontuacao(-1),incrementa_turnos,!.

%virar esquerda (rotação de 90° no sentido anti-horário)
virar_esquerda :- jogo_terminado,!.
virar_esquerda :- posicao(X,Y, norte), retract(posicao(_,_,_)), assert(posicao(X, Y, oeste)),atualiza_pontuacao(-1),incrementa_turnos,!.
virar_esquerda :- posicao(X,Y, oeste), retract(posicao(_,_,_)), assert(posicao(X, Y, sul)),atualiza_pontuacao(-1),incrementa_turnos,!.
virar_esquerda :- posicao(X,Y, sul), retract(posicao(_,_,_)), assert(posicao(X, Y, leste)),atualiza_pontuacao(-1),incrementa_turnos,!.
virar_esquerda :- posicao(X,Y, leste), retract(posicao(_,_,_)), assert(posicao(X, Y, norte)),atualiza_pontuacao(-1),incrementa_turnos,!.

%andar
andar :- jogo_terminado,!.
andar :- posicao(X,Y,P), P = norte, map_size(_,MAX_Y), Y < MAX_Y, YY is Y + 1, 
         retract(posicao(X,Y,_)), assert(posicao(X, YY, P)), 
		 assert(visitado(X,YY)),
		 atualiza_pilha_backtrack(X,YY),
		 atualiza_historico_posicoes(X,YY),
		 set_real(X,YY),
		 atualiza_pontuacao(-1),
		 reseta_turnos,
		 verifica_player,!.
		 
andar :- posicao(X,Y,P), P = sul,  Y > 1, YY is Y - 1, 
         retract(posicao(X,Y,_)), assert(posicao(X, YY, P)), 
		 assert(visitado(X,YY)),
		 atualiza_pilha_backtrack(X,YY),
		 atualiza_historico_posicoes(X,YY),
		 set_real(X,YY),
		 atualiza_pontuacao(-1),
		 reseta_turnos,
		 verifica_player,!.

andar :- posicao(X,Y,P), P = leste, map_size(MAX_X,_), X < MAX_X, XX is X + 1, 
         retract(posicao(X,Y,_)), assert(posicao(XX, Y, P)), 
		 assert(visitado(XX,Y)),
		 atualiza_pilha_backtrack(XX,Y),
		 atualiza_historico_posicoes(XX,Y),
		 set_real(XX,Y),
		 atualiza_pontuacao(-1),
		 reseta_turnos,
		 verifica_player,!.

andar :- posicao(X,Y,P), P = oeste,  X > 1, XX is X - 1, 
         retract(posicao(X,Y,_)), assert(posicao(XX, Y, P)), 
		 assert(visitado(XX,Y)),
		 atualiza_pilha_backtrack(XX,Y),
		 atualiza_historico_posicoes(XX,Y),
		 set_real(XX,Y),
		 atualiza_pontuacao(-1),
		 reseta_turnos,
		 verifica_player,!.
		 
%andar contra parede (impacto)
andar :- posicao(_X,Y,P), P = norte, map_size(_,MAX_Y), Y >= MAX_Y, atualiza_pontuacao(-1),incrementa_turnos,!.
andar :- posicao(_X,Y,P), P = sul, Y =< 1, atualiza_pontuacao(-1),incrementa_turnos,!.
andar :- posicao(X,_Y,P), P = leste, map_size(MAX_X,_), X >= MAX_X, atualiza_pontuacao(-1),incrementa_turnos,!.
andar :- posicao(X,_Y,P), P = oeste, X =< 1, atualiza_pontuacao(-1),incrementa_turnos,!.
		 
%pegar	
pegar :- jogo_terminado,!.
pegar :- posicao(X,Y,_), tile(X,Y,'O'), retract(tile(X,Y,'O')), assert(tile(X,Y,'')), atualiza_pontuacao(-1), atualiza_pontuacao(1000),set_real(X,Y), reseta_turnos, ouro(Qtd), retract(ouro(Qtd)), QtdNovo is Qtd + 1, assert(ouro(QtdNovo)), verifica_player,!.
pegar :- posicao(X,Y,_), tile(X,Y,'U'), retract(tile(X,Y,'U')), assert(tile(X,Y,'')), atualiza_pontuacao(-1), atualiza_energia(20),set_real(X,Y), reseta_turnos, verifica_player,!.
pegar :- atualiza_pontuacao(-1), reseta_turnos, verifica_player,!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Controle de turnos consecutivos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

incrementa_turnos :- 
	turnos_consecutivos(N), 
	retract(turnos_consecutivos(N)), 
	NN is N + 1, 
	assert(turnos_consecutivos(NN)).

reseta_turnos :- 
	retract(turnos_consecutivos(_)), 
	assert(turnos_consecutivos(0)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Funcoes Auxiliares de navegação e observação
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 
%Define as 4 adjacencias		 
adjacente(X, Y) :- posicao(PX, Y, _), map_size(MAX_X,_),PX < MAX_X, X is PX + 1.  
adjacente(X, Y) :- posicao(PX, Y, _), PX > 1, X is PX - 1.  
adjacente(X, Y) :- posicao(X, PY, _), map_size(_,MAX_Y),PY < MAX_Y, Y is PY + 1.  
adjacente(X, Y) :- posicao(X, PY, _), PY > 1, Y is PY - 1.  

%cria lista com a adjacencias
adjacentes(L) :- findall(Z,(adjacente(X,Y),tile(X,Y,Z)),L).

%define observacoes locais
observacao_loc(brilho,L) :- member('O',L).
observacao_loc(reflexo,L) :- member('U',L).

%define observacoes adjacentes
observacao_adj(brisa,L) :- member('P',L).
observacao_adj(flash,L) :- member('T',L).
observacao_adj(passos,L) :- member('D',L).
observacao_adj(passos,L) :- member('d',L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Tratamento de KB e observações
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%consulta e processa observações
atualiza_obs:-adj_cand_obs(LP), observacoes(LO), iter_pos_list(LP,LO), observacao_certeza, observacao_vazia.

%adjacencias candidatas p/ a observacao (aquelas não visitadas)
adj_cand_obs(L) :- findall((X,Y), (adjacente(X, Y), \+visitado(X,Y)), L).

%cria lista de observacoes
observacoes(X) :- adjacentes(L), findall(Y, observacao_adj(Y,L), X).

%itera posicoes da lista para adicionar observacoes
iter_pos_list([], _) :- !.
iter_pos_list([H|T], LO) :- H=(X,Y), 
							((corrige_observacoes_antigas(X, Y, LO),!);
							adiciona_observacoes(X, Y, LO)),
							iter_pos_list(T, LO).							 

%Corrige observacoes antigas na memoria que ficaram com apenas uma adjacencia
corrige_observacoes_antigas(X, Y, []):- \+certeza(X,Y), memory(X,Y,[]).
corrige_observacoes_antigas(X, Y, LO):-
	\+certeza(X,Y), \+ memory(X,Y,[]), memory(X, Y, LM), intersection(LO, LM, L), 
	retract(memory(X, Y, LM)), assert(memory(X, Y, L)).

%Adiciona observacoes na memoria
adiciona_observacoes(X, Y, _) :- certeza(X,Y),!.
adiciona_observacoes(X, Y, LO) :- \+certeza(X,Y), \+ memory(X,Y,_), assert(memory(X, Y, LO)).

%Quando há apenas uma observação e uma unica posição incerta, deduz que a observação está na casa incerta
%e marca como certeza
%observacao_certeza:- findall((X,Y), (adjacente(X, Y), 
%						((\+visitado(X,Y), \+certeza(X,Y));(certeza(X,Y),memory(X,Y,ZZ),ZZ\=[])),
%						memory(X,Y,Z), Z\=[]), L), ((length(L,1),L=[(XX,YY)], assert(certeza(XX,YY)),!);true).
						
observacao_certeza:- observacao_certeza('brisa'),
						observacao_certeza('flash'),
						observacao_certeza('passos').
						
observacao_certeza(Z):- findall((X,Y), (adjacente(X, Y), 
						((\+visitado(X,Y), \+certeza(X,Y));(certeza(X,Y),memory(X,Y,[Z]))),
						memory(X,Y,[Z])), L), ((length(L,1),L=[(XX,YY)], assert(certeza(XX,YY)),!);true).						

%Quando posição não tem observações
observacao_vazia:- adj_cand_obs(LP), observacao_vazia(LP).
observacao_vazia([]) :- !.
observacao_vazia([H|T]) :- H=(X,Y), ((memory(X,Y,[]), \+certeza(X,Y),assert(certeza(X,Y)),!);true), observacao_vazia(T).

%Quando posicao é visitada, atualiza memoria de posicao com a informação real do mapa 
set_real(X,Y):- ((retract(certeza(X,Y)), assert(certeza(X,Y)),!); assert(certeza(X,Y))), set_real2(X,Y), atualiza_conhecimento(X,Y),!.
set_real2(X,Y):- tile(X,Y,'P'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[brisa])),!);assert(memory(X,Y,[brisa]))),!.
set_real2(X,Y):- tile(X,Y,'O'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[brilho])),!);assert(memory(X,Y,[brilho]))),!.
set_real2(X,Y):- tile(X,Y,'T'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[flash])),!);assert(memory(X,Y,[flash]))),!.
set_real2(X,Y):- ((tile(X,Y,'D'),!); tile(X,Y,'d')), ((retract(memory(X,Y,_)),assert(memory(X,Y,[passos])),!);assert(memory(X,Y,[passos]))),!.
set_real2(X,Y):- tile(X,Y,'U'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[reflexo])),!);assert(memory(X,Y,[reflexo]))),!.
set_real2(X,Y):- tile(X,Y,''), ((retract(memory(X,Y,_)),assert(memory(X,Y,[])),!);assert(memory(X,Y,[]))),!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Conhecimento sobre células seguras/perigosas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

posicao_valida(X,Y) :- map_size(MAX_X,MAX_Y), between(1,MAX_X,X), between(1,MAX_Y,Y).

vizinho_coord(X,Y,NX,NY) :- NX is X + 1, posicao_valida(NX,Y), NY is Y.
vizinho_coord(X,Y,NX,NY) :- NX is X - 1, posicao_valida(NX,Y), NY is Y.
vizinho_coord(X,Y,NX,NY) :- NY is Y + 1, posicao_valida(X,NY), NX is X.
vizinho_coord(X,Y,NX,NY) :- NY is Y - 1, posicao_valida(X,NY), NX is X.

atualiza_conhecimento(X,Y) :-
	marca_seguro(X,Y),
	(memory(X,Y,Obs) -> processa_observacoes(X,Y,Obs); processa_observacoes(X,Y,[])).

marca_seguro(X,Y) :-
	posicao_valida(X,Y),
	% Não marca como seguro se existe algum perigo conhecido
	\+perigoso(X,Y,_),
	(
		memory(X,Y,M) ->
			\+member(brisa,M),
			\+member(passos,M),
			\+member(flash,M)  % Não marca morcegos como seguros
		;	true
	),
	% Não marca se é morcego conhecido
	\+eh_morcego(X,Y),
	(seguro(X,Y) -> true ; assert(seguro(X,Y))).

processa_observacoes(X,Y,Obs) :-
	% Perigos fatais (poço)
	(member(brisa, Obs) -> marca_perigo(X,Y,brisa) ; limpa_perigo(X,Y,brisa)),
	% Inimigos (passos)
	(member(passos, Obs) -> marca_perigo(X,Y,inimigo) ; limpa_perigo(X,Y,inimigo)),
	% Morcegos apenas evitáveis
	(member(flash, Obs) -> marca_perigo(X,Y,morcego) ; limpa_perigo(X,Y,morcego)),
	% Se não há qualquer indício de perigo fatal, marca adjacentes seguros
	(\+member(brisa,Obs), \+member(passos,Obs) -> marca_adj_seguro(X,Y) ; true).

marca_adj_seguro(X,Y) :-
	findall((NX,NY), vizinho_coord(X,Y,NX,NY), Lista),
	forall(member((NX,NY), Lista), marca_seguro_se_valido(NX,NY)).

% Só marca como seguro se for válido e não tiver sido visitado com perigo
marca_seguro_se_valido(X,Y) :-
	posicao_valida(X,Y),
	\+visitado(X,Y),  % Não sobrescrever células visitadas
	marca_seguro(X,Y).
marca_seguro_se_valido(_,_).  % Falha silenciosamente se inválido

marca_perigo(X,Y,Tipo) :-
	findall((NX,NY), vizinho_coord(X,Y,NX,NY), Lista),
	forall(member((NX,NY), Lista), marca_perigo_celula(NX,NY,Tipo)).

limpa_perigo(X,Y,Tipo) :-
	findall((NX,NY), vizinho_coord(X,Y,NX,NY), Lista),
	forall(member((NX,NY), Lista), retractall(perigoso(NX,NY,Tipo))).

% Marca célula como perigosa APENAS se não for visitada e segura
marca_perigo_celula(X,Y,Tipo) :-
	posicao_valida(X,Y),
	\+visitado(X,Y),  % Não marca visitadas como perigosas
	retractall(seguro(X,Y)),
	(perigoso(X,Y,Tipo) -> true ; assert(perigoso(X,Y,Tipo))).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mostra mapa real
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
show_player(X,Y) :- posicao(X,Y, norte), write('^'),!.
show_player(X,Y) :- posicao(X,Y, oeste), write('<'),!.
show_player(X,Y) :- posicao(X,Y, leste), write('>'),!.
show_player(X,Y) :- posicao(X,Y, sul), write('v'),!.
show_player(X,Y) :- posicao(X,Y, morto), write('+'),!.

%show_position(X,Y) :- show_player(X,Y),!.
show_position(X,Y) :- (show_player(X,Y); write(' ')), tile(X,Y,Z), ((Z='', write(' '));write(Z)),!.

show_map :- map_size(_,MAX_Y), show_map(1,MAX_Y),!.
show_map(X,Y) :- Y >= 1, map_size(MAX_X,_), X =< MAX_X, show_position(X,Y), write(' | '), XX is X + 1, show_map(XX, Y),!.
show_map(X,Y) :- Y >= 1, map_size(X,_),YY is Y - 1, write(Y), nl, show_map(1, YY),!.
show_map(_,0) :- energia(E), pontuacao(P), write('E: '), write(E), write('   P: '), write(P),!.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mostra mapa conhecido
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

show_mem_info(X,Y) :- memory(X,Y,Z), 
		((visitado(X,Y), write('.'),!); (\+certeza(X,Y), write('?'),!); (certeza(X,Y), write('!'))),
		((member(brisa, Z), write('P'));write(' ')),
		((member(flash, Z), write('F'));write(' ')),
		((member(brilho, Z), write('O'));write(' ')),
		((member(passos, Z), write('D'));write(' ')),
		((member(reflexo, Z), write('U'));write(' ')),!.

show_mem_info(X,Y) :- \+memory(X,Y,[]), 
			((visitado(X,Y), write('.'),!); (\+certeza(X,Y), write('?'),!); (certeza(X,Y), write('!'))),
			write('     '),!.		
		
		

show_mem_position(X,Y) :- posicao(X,Y,_), 
		((visitado(X,Y), write('.'),!); (certeza(X,Y), write('!'),!); write(' ')),
		write(' '), show_player(X,Y),
		((memory(X,Y,Z),
		((member(brilho, Z), write('O'));write(' ')),
		((member(passos, Z), write('D'));write(' ')),
		((member(reflexo, Z), write('U'));write(' ')),!);
		(write('   '),!)).

		
show_mem_position(X,Y) :- show_mem_info(X,Y),!.


show_mem :- map_size(_,MAX_Y), show_mem(1,MAX_Y),!.
show_mem(X,Y) :- Y >= 1, map_size(MAX_X,_), X =< MAX_X, show_mem_position(X,Y), write('|'), XX is X + 1, show_mem(XX, Y),!.
show_mem(X,Y) :- Y >= 1, map_size(X,_),YY is Y - 1, write(Y), nl, show_mem(1, YY),!.
show_mem(_,0) :- energia(E), pontuacao(P), write('E: '), write(E), write('   P: '), write(P),!.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Funções auxiliares de navegação (baseadas em ref4.pl)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Gerenciamento de bloqueio A*
add_blocked(X,Y) :- blocked(X,Y), !.
add_blocked(X,Y) :- assertz(blocked(X,Y)).
clear_blocked :- retractall(blocked(_,_)).
not_blocked(X,Y) :- \+ blocked(X,Y).

% Dano máximo do monstro
max_monster_damage(50).

% Monstro CERTO numa posição
monster_cert_cell(X,Y) :-
    certeza(X,Y),
    memory(X,Y,L),
    member(passos,L).

% Bloco suspeito de monstro
monster_sus_cell(X,Y) :-
    memory(X,Y,L),
    member(passos, L),
    \+ member(flash, L),
    \+ member(brisa, L),
    \+ certeza(X,Y).

% Morcego CERTO numa posição (visitado e confirmado)
bat_cert_cell(X,Y) :-
    certeza(X,Y),
    memory(X,Y,L),
    member(flash, L).

% Bloco suspeito de morcego
bat_sus_cell(X,Y) :-
    memory(X,Y,L),
    member(flash, L),
    \+ member(passos, L),
    \+ member(brisa, L),
    \+ certeza(X,Y).

% Bloco suspeito de poço
pit_sus_cell(X,Y) :-
    memory(X,Y,L),
    member(brisa, L),
    \+ certeza(X,Y).

% Verifica se é um morcego conhecido (certo ou suspeito)
eh_morcego(X,Y) :-
    bat_cert_cell(X,Y), !.
eh_morcego(X,Y) :-
    bat_sus_cell(X,Y), !.

% Verifica se há ao menos um bloco suspeito de monstro
known_monster :-
    monster_sus_cell(X,Y).

% Mapeia cada direção em um delta (DX,DY)
possible_dir(norte, 0,  1).
possible_dir(leste,  1,  0).
possible_dir(sul,    0, -1).
possible_dir(oeste, -1,  0).

% Retorna um index relacionado a direção
dir_index(norte, 0).
dir_index(leste, 1).
dir_index(sul,   2).
dir_index(oeste, 3).

% Seguro(X,Y) é verdade se o agente tem CERTEZA de que (X,Y) é um local seguro
seguro(1,1).

seguro(X,Y) :-
    certeza(X,Y),
    memory(X,Y, []).

% Diz quem é o bloco a frente do agente
proximo(X,Y,norte,  X, Y1) :- Y1 is Y+1.
proximo(X,Y,sul,    X, Y1) :- Y1 is Y-1.
proximo(X,Y,leste,  X1, Y) :- X1 is X+1.
proximo(X,Y,oeste,  X1, Y) :- X1 is X-1.

% Identifica o caso específico: agente preso entre monstros suspeitos e um monstro certo
trapped_monster_dir(DirM) :-
    posicao(X,Y,_),
    possible_dir(DirM,DXM,DYM),
    MX is X+DXM, MY is Y+DYM,
    monster_cert_cell(MX,MY),
    map_size(MAX_X,MAX_Y),
    forall(
      ( possible_dir(Dir2,DX2,DY2),
        Dir2 \= DirM,
        NX is X+DX2, NY is Y+DY2,
        between(1,MAX_X,NX),
        between(1,MAX_Y,NY)
      ),
      (monster_sus_cell(NX,NY))
    ).

% Identifica o caso específico: agente preso entre poços/morcegos suspeitos e um monstro certo
trapped_bat_pit_dir(DirM) :-
    posicao(X,Y,_),
    possible_dir(DirM,DXM,DYM),
    MX is X+DXM, MY is Y+DYM,
    monster_cert_cell(MX,MY),
    map_size(MAX_X,MAX_Y),
    forall(
      ( possible_dir(Dir2,DX2,DY2),
        Dir2 \= DirM,
        NX is X+DX2, NY is Y+DY2,
        between(1,MAX_X,NX),
        between(1,MAX_Y,NY)
      ),
      ( pit_sus_cell(NX,NY)
      ; bat_sus_cell(NX,NY)
      )
    ).

% Informa para qual direção o agente deve virar de acordo para onde ele quer ir
turn_action(DirAtual, DirAlvo, virar_direita) :-
    dir_index(DirAtual, I1),
    dir_index(DirAlvo,  I2),
    D is (I2 - I1 + 4) mod 4,
    D =:= 1, !.

turn_action(DirAtual, DirAlvo, virar_esquerda) :-
    dir_index(DirAtual, I1),
    dir_index(DirAlvo,  I2),
    D is (I2 - I1 + 4) mod 4,
    D =:= 3, !.

% Se for oposto (diferença 2), vira a direita por convenção
turn_action(_DirAtual, _DirAlvo, virar_direita).

% Informa a direção de uma das coordenadas "válidas" (não visitada e sem obstáculo) em relação a um local
% PREFERE DIREÇÕES SEM MORCEGOS CONHECIDOS
valid_direction(X,Y,Dir) :-
    possible_dir(Dir,DX,DY),
    NX is X + DX,
    NY is Y + DY,
    map_size(MAX_X,MAX_Y),
    between(1,MAX_X,NX),
    between(1,MAX_Y,NY),
    memory(NX,NY,Percepts),
    Percepts = [],
    \+ visitado(NX,NY),
    \+eh_morcego(NX,NY),  % PREFERE SEM MORCEGOS
    !.

% FALLBACK: Aceita direção com morcego se não há alternativa
valid_direction(X,Y,Dir) :-
    possible_dir(Dir,DX,DY),
    NX is X + DX,
    NY is Y + DY,
    map_size(MAX_X,MAX_Y),
    between(1,MAX_X,NX),
    between(1,MAX_Y,NY),
    memory(NX,NY,Percepts),
    Percepts = [],
    \+ visitado(NX,NY),
    !.

% Verifica se o bloco tem pelo menos um vizinho não visitado e sem avisos
% PREFERE VIZINHOS SEM MORCEGOS CONHECIDOS
has_safe_frontier(X,Y) :-
    member((DX,DY), [(1,0),(-1,0),(0,1),(0,-1)]),
    NX is X + DX, NY is Y + DY,
    map_size(MAX_X,MAX_Y),
    between(1,MAX_X,NX), between(1,MAX_Y,NY),
    \+ visitado(NX,NY),
    memory(NX,NY,Percepts), Percepts = [],
    \+eh_morcego(NX,NY),  % PREFERE SEM MORCEGOS
    !.

% Verifica se um bloco visitado faz fronteira com um bloco suspeito de monstro
monster_frontier(VX,VY,Dir) :-
    ( visitado(VX,VY) ; posicao(VX,VY,_) ),
    possible_dir(Dir,DX,DY),
    MX is VX+DX,  MY is VY+DY,
    monster_sus_cell(MX,MY),
    seguro(VX,VY).

% Bloco visitado que faz fronteira com um bloco suspeito de morcego
bat_frontier(VX,VY,Dir) :-
    ( visitado(VX,VY) ; posicao(VX,VY,_) ),
    possible_dir(Dir,DX,DY),
    MX is VX+DX, MY is VY+DY,
    bat_sus_cell(MX,MY),
    seguro(VX,VY).

% Bloco visitado que faz fronteira com um bloco suspeito de poço
pit_frontier(VX,VY,Dir) :-
    ( visitado(VX,VY) ; posicao(VX,VY,_) ),
    possible_dir(Dir,DX,DY),
    MX is VX+DX, MY is VY+DY,
    pit_sus_cell(MX,MY),
    seguro(VX,VY).

% Encontra o bloco "aberto" (já visitado) mais próximo de onde o agente está
nearest_open(TX,TY,D) :-
    posicao(X0,Y0,_),
    findall(
     Dist-(VX,VY),
      ( visitado(VX,VY),
        Dist is abs(VX-X0) + abs(VY-Y0),
        has_safe_frontier(VX,VY)
      ),
      Pairs),
    Pairs \= [],
    keysort(Pairs, [D-(TX,TY)|_]).

% Encontra o bloco da "fronteira de monstro" (visitado, seguro e adjacente a monstro)
nearest_monster_frontier(TX,TY,Dir,D) :-
    posicao(X0,Y0,_),
    findall( Dist-(VX,VY,Dir1),
             ( monster_frontier(VX,VY,Dir1),
               Dist is abs(VX-X0)+abs(VY-Y0) ),
             Pairs), Pairs \= [],
    keysort(Pairs,[D-(TX,TY,Dir)|_]).

% Encontra o bloco com poção mais próximo
nearest_potion(TX,TY,D) :-
    posicao(X0,Y0,_),
    findall(
      Dist-(PX,PY),
      (
        memory(PX,PY,[reflexo]),
        Dist is abs(PX-X0) + abs(PY-Y0)
      ),
      Pairs), Pairs \= [],
    keysort(Pairs,[D-(TX,TY)|_]).

% Encontra o bat_frontier mais próximo do agente
nearest_bat_frontier(TX,TY,Dir,D) :-
    posicao(X0,Y0,_),
    findall( Dist-(VX,VY,Dir1),
             ( bat_frontier(VX,VY,Dir1),
               Dist is abs(VX-X0)+abs(VY-Y0) ),
             Pairs), Pairs \= [],
    keysort(Pairs,[D-(TX,TY,Dir)|_]).

% Encontra o pit_frontier mais próximo do agente
nearest_pit_frontier(TX,TY,Dir,D) :-
    posicao(X0,Y0,_),
    findall( Dist-(VX,VY,Dir1),
             ( pit_frontier(VX,VY,Dir1),
               Dist is abs(VX-X0)+abs(VY-Y0) ),
             Pairs), Pairs \= [],
    keysort(Pairs,[D-(TX,TY,Dir)|_]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Planejamento e execução de ações (baseado em ref4.pl)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Não executa ações se o jogo terminou
executa_acao(X) :- jogo_terminado, X = 'fim_jogo', log_decisao(X), !.

% ====================================================================
% PRIORIDADE 1: Se peguei 3 ouros, retornar ao ponto inicial (1,1)
% ====================================================================
executa_acao(Acao) :-
    \+jogo_terminado,
    ouro(Qtd), 
    Qtd >= 3,
    posicao(PX,PY,_),
    (PX \= 1; PY \= 1),  % Ainda não está em (1,1)
    % Verifica se há caminho seguro até (1,1)
    astar_path(PX,PY,1,1,Caminho),
    Caminho \= [],
    converte_caminho_acoes(PX,PY,Caminho,Acoes),
    Acoes = [Acao|Resto],
    (Resto = [] -> true ; assert(plano(Resto))),
    format('[FIM-DE-JOGO] Retornando ao ponto inicial (1,1) com ~w ouros...~n', [Qtd]),
    log_decisao(Acao),
    !.

% Se já está em (1,1) com 3+ ouros, termina o jogo imediatamente
executa_acao('fim_jogo') :-
    \+jogo_terminado,
    posicao(1,1,_),
    ouro(Qtd),
    Qtd >= 3,
    assert(jogo_terminado),
    format('[VITÓRIA] Agente completou a missão! Retornou a (1,1) com ~w ouros. Jogo finalizado!~n', [Qtd]),
    !.

% ====================================================================
% PRIORIDADE 2: Coletar itens na célula atual
% ====================================================================

% Pegar ouro se estiver na célula atual
executa_acao(pegar) :- 
    \+jogo_terminado, 
    posicao(X,Y,_), 
    memory(X,Y,[brilho]),
    log_decisao(pegar),
    !.

% Pegar powerup se energia baixa (≤ 50)
executa_acao(pegar) :- 
    \+jogo_terminado, 
    posicao(X,Y,_), 
    memory(X,Y,[reflexo]),     
    energia(E), 
    E =< 50,
    log_decisao(pegar),
    !.

% ====================================================================
% PRIORIDADE 3: Executar plano existente (se houver)
% ====================================================================

executa_acao(Acao) :-
    \+jogo_terminado,
    plano([Acao|Resto]),
    retract(plano(_)),
    (Resto = [] -> true ; assert(plano(Resto))),
    log_decisao(Acao),
    !.

% ====================================================================
% PRIORIDADE 4: Anda "para frente" se não houver obstáculo e a célula à frente não foi visitada
% EVITA MORCEGOS CONHECIDOS quando possível
% ====================================================================
executa_acao(andar) :-
    \+jogo_terminado,
    posicao(X,Y,Dir),
    proximo(X,Y,Dir,NX,NY),
    memory(NX,NY,Percepts),
    Percepts = [],
    \+ visitado(NX,NY),
    \+eh_morcego(NX,NY),  % EVITA MORCEGOS CONHECIDOS
    log_decisao(andar),
    !.

% FALLBACK: Aceita morcego apenas se não há alternativa segura
executa_acao(andar) :-
    \+jogo_terminado,
    posicao(X,Y,Dir),
    proximo(X,Y,Dir,NX,NY),
    memory(NX,NY,Percepts),
    Percepts = [],
    \+ visitado(NX,NY),
    % Verifica se não há alternativa segura sem morcego
    \+ (
        proximo(X,Y,OutraDir,AltNX,AltNY),
        OutraDir \= Dir,
        memory(AltNX,AltNY,AltPercepts),
        AltPercepts = [],
        \+ visitado(AltNX,AltNY),
        \+eh_morcego(AltNX,AltNY)
    ),
    log_decisao(andar),
    !.

% ====================================================================
% PRIORIDADE 5: Verifica se há algum lugar aberto ao redor do jogador, se sim vira em direção ao lugar
% PREFERE DIREÇÕES SEM MORCEGOS CONHECIDOS
% ====================================================================
executa_acao(X) :-
    \+jogo_terminado,
    posicao(XN,YN,DirAtual),
    % Primeiro tenta encontrar direção sem morcego conhecido
    possible_dir(DirAlvo,DX,DY),
    NX is XN + DX, NY is YN + DY,
    map_size(MAX_X,MAX_Y),
    between(1,MAX_X,NX), between(1,MAX_Y,NY),
    memory(NX,NY,Percepts),
    Percepts = [],
    \+ visitado(NX,NY),
    \+eh_morcego(NX,NY),  % PREFERE SEM MORCEGOS
    valid_direction(XN,YN,DirAlvo),
    turn_action(DirAtual, DirAlvo, X),
    log_decisao(X),
    !.

% FALLBACK: Aceita direção com morcego se não há alternativa
executa_acao(X) :-
    \+jogo_terminado,
    posicao(XN,YN,DirAtual),            
    valid_direction(XN,YN,DirAlvo),     
    turn_action(DirAtual, DirAlvo, X), 
    log_decisao(X),
    !.

% ====================================================================
% PRIORIDADE 6: Procura o nearest_open (bloco aberto mais próximo) e planeja caminho
% ====================================================================
executa_acao(Acao) :-
    \+jogo_terminado,
    posicao(CX, CY, _),
    nearest_open(TX, TY, _),
    not_blocked(TX,TY),
    (CX \= TX ; CY \= TY),
    astar_path(CX,CY,TX,TY,Caminho),
    Caminho \= [],
    converte_caminho_acoes(CX,CY,Caminho,Acoes),
    Acoes = [Acao|Resto],
    (Resto = [] -> true ; assert(plano(Resto))),
    log_decisao(Acao),
    !.

% ====================================================================
% PRIORIDADE 7: Se está encurralado procura passar por monstros com suspeita (garantia de sobrevivência)
% ====================================================================
executa_acao(Acao) :-
    \+jogo_terminado,
    max_monster_damage(MaxD),
    energia(E), E > MaxD,
    nearest_monster_frontier(TX,TY,DirM,_),
    not_blocked(TX,TY),
    posicao(CX,CY,DirNow),
    (   (CX \= TX ; CY \= TY)
    ->  astar_path(CX,CY,TX,TY,Caminho),
        Caminho \= [],
        converte_caminho_acoes(CX,CY,Caminho,AcoesPath),
        AcoesPath = [Acao|RestoPath],
        (RestoPath = [] -> true ; assert(plano(RestoPath))),
        log_decisao(Acao)
    ;   ( DirNow \= DirM
        -> turn_action(DirNow,DirM,Acao),
            log_decisao(Acao)
        ;  Acao = andar,
            log_decisao(andar)
        )
    ),
    !.

% ====================================================================
% PRIORIDADE 8: Energia insuficiente para garantir sobrevivência em avanço a monstros -> procurar poção conhecida
% ====================================================================
executa_acao(Acao) :-
    \+jogo_terminado,
    max_monster_damage(MaxD),
    energia(E), E =< MaxD,
    known_monster,
    nearest_potion(TX,TY,_),
    not_blocked(TX,TY),
    posicao(PX,PY,_),
    astar_path(PX,PY,TX,TY,Caminho),
    Caminho \= [],
    converte_caminho_acoes(PX,PY,Caminho,Acoes),
    Acoes = [Acao|Resto],
    (Resto = [] -> true ; assert(plano(Resto))),
    log_decisao(Acao),
    !.

% ====================================================================
% PRIORIDADE 9: Avançar para o morcego suspeito mais próximo
% APENAS SE NÃO HÁ ALTERNATIVAS SEGURAS SEM MORCEGOS
% ====================================================================
executa_acao(Acao) :-
    \+jogo_terminado,
    % Verifica se há células seguras não visitadas SEM morcegos
    \+ (
        celula_segura(SX,SY),
        \+visitado(SX,SY),
        \+eh_morcego(SX,SY)
    ),
    nearest_bat_frontier(TX,TY,DirB,_),
    not_blocked(TX,TY),
    posicao(CX,CY,DirNow),
    (   (CX \= TX ; CY \= TY)
    ->  astar_path(CX,CY,TX,TY,Caminho),
        Caminho \= [],
        converte_caminho_acoes(CX,CY,Caminho,AcoesPath),
        AcoesPath = [Acao|RestoPath],
        (RestoPath = [] -> true ; assert(plano(RestoPath))),
        log_decisao(Acao)
    ;   ( DirNow \= DirB
        -> turn_action(DirNow,DirB,Acao),
            log_decisao(Acao)
        ;  Acao = andar,
            log_decisao(andar)
        )
    ),
    !.

% ====================================================================
% PRIORIDADE 10: Preso entre monstro(suspeita) e monstro certo
% ====================================================================
executa_acao(andar) :-
    \+jogo_terminado,
    trapped_monster_dir(_DirM),
    log_decisao(andar),
    !.

% ====================================================================
% PRIORIDADE 11: Preso entre poços/morcegos(suspeita) e monstro certo (decisão "ruim" no passo 7)
% ====================================================================
executa_acao(X) :-
    \+jogo_terminado,
    trapped_bat_pit_dir(DirM),
    max_monster_damage(MaxD),
    energia(E),
    E > MaxD,
    posicao(_,_,DirNow),
    ( DirNow \= DirM
    -> turn_action(DirNow,DirM,X),
        log_decisao(X)
    ;  X = andar,
        log_decisao(andar)
    ),
    !.

% ====================================================================
% PRIORIDADE 12: Se nada anterior servir, avança para o poço suspeito mais próximo
% ====================================================================
executa_acao(Acao) :-
    \+jogo_terminado,
    nearest_pit_frontier(TX,TY,DirP,_),
    not_blocked(TX,TY),
    posicao(CX,CY,DirNow),
    (   (CX \= TX ; CY \= TY)
    ->  astar_path(CX,CY,TX,TY,Caminho),
        Caminho \= [],
        converte_caminho_acoes(CX,CY,Caminho,AcoesPath),
        AcoesPath = [Acao|RestoPath],
        (RestoPath = [] -> true ; assert(plano(RestoPath))),
        log_decisao(Acao)
    ;   ( DirNow \= DirP
        -> turn_action(DirNow,DirP,Acao),
            log_decisao(Acao)
        ;  Acao = andar,
            log_decisao(andar)
        )
    ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Funções auxiliares para o planejamento
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calcula nova direção após uma ação de virar
calcular_nova_direcao(norte,virar_direita,leste).
calcular_nova_direcao(leste,virar_direita,sul).
calcular_nova_direcao(sul,virar_direita,oeste).
calcular_nova_direcao(oeste,virar_direita,norte).
calcular_nova_direcao(norte,virar_esquerda,oeste).
calcular_nova_direcao(oeste,virar_esquerda,sul).
calcular_nova_direcao(sul,virar_esquerda,leste).
calcular_nova_direcao(leste,virar_esquerda,norte).

% Verifica se a célula da frente é segura
celula_frente(X,Y,norte,X,NY) :- map_size(_,MAX_Y), Y < MAX_Y, NY is Y + 1.
celula_frente(X,Y,sul,X,NY) :- Y > 1, NY is Y - 1.
celula_frente(X,Y,leste,NX,Y) :- map_size(MAX_X,_), X < MAX_X, NX is X + 1.
celula_frente(X,Y,oeste,NX,Y) :- X > 1, NX is X - 1.

% =======================================================================================
% LÓGICA DE SEGURANÇA BASEADA EM WUMPUS WORLD (First Order Logic)
% =======================================================================================
% Baseado no algoritmo clássico: Russell & Norvig - AIMA + refs
% 
% Regras de Inferência CONSERVADORAS:
% 1. Célula visitada SEM perigos (sem brisa/passos) → SEGURA para caminhar por ela
% 2. Célula NÃO visitada → só é segura se NENHUM vizinho detectou brisa ou passos
% 3. NUNCA considere segura uma célula não visitada adjacente a brisa/passos
% =======================================================================================

% Regra 1: Célula visitada é "segura para estar nela" (já sabemos que não tem poço)
% MAS isso NÃO significa que podemos andar para células ao redor dela se ela tem brisa!
% IMPORTANTE: Não considera segura se é um morcego conhecido (evita teletransporte)
celula_segura(X,Y) :- 
    visitado(X,Y),
    certeza(X,Y),
    memory(X,Y,M),
    \+member(brisa,M),
    \+member(passos,M),  % Não tem passos = sem inimigo conhecido
    \+eh_morcego(X,Y),  % Não é morcego conhecido
    !.

% Regra 2: Célula explicitamente marcada como segura E sem suspeitas
celula_segura(X,Y) :-
    seguro(X,Y),
    \+possivelmente_perigosa(X,Y),
    \+eh_morcego(X,Y),  % Não é morcego conhecido
    ( \+memory(X,Y,M) -> true
    ; \+member(brisa,M), \+member(passos,M)
    ),
    !.

% Regra 3: Célula NÃO visitada - EXTREMAMENTE CONSERVADOR
% Só é segura se TODOS os vizinhos visitados NÃO detectaram brisa nem passos
% E não é suspeita de morcego quando há alternativas seguras
celula_segura(X,Y) :- 
    \+visitado(X,Y),
    posicao_valida(X,Y),
    tem_vizinho_visitado(X,Y),
    nao_ha_brisa_vizinha(X,Y),
    nao_ha_passos_vizinha(X,Y),
    \+possivelmente_perigosa(X,Y),
    \+eh_morcego(X,Y),  % Não é morcego conhecido
    !.

% Célula é possivelmente perigosa se foi marcada pelo sistema de inferência
possivelmente_perigosa(X,Y) :-
    perigoso(X,Y,_),
    !.

% Célula é possivelmente perigosa se está adjacente a observação de perigo
% mas não foi confirmada como segura
possivelmente_perigosa(X,Y) :-
    \+seguro(X,Y),
    vizinho_coord(X,Y,VX,VY),
    visitado(VX,VY),
    memory(VX,VY,M),
    (member(brisa,M); member(passos,M)),
    !.

% Regra 4: Célula com morcego conhecido (evita quando possível)
% Morcegos não são fatais mas quebram planejamento
celula_evitavel(X,Y) :-
    memory(X,Y,M),
    member(flash,M),
    !.

% Verifica se tem pelo menos um vizinho visitado
tem_vizinho_visitado(X,Y) :-
    vizinho_coord(X,Y,VX,VY),
    visitado(VX,VY),
    !.

% Nenhum vizinho visitado detecta BRISA (poços são FATAIS)
nao_ha_brisa_vizinha(X,Y) :-
    \+ (
        vizinho_coord(X,Y,VX,VY),
        visitado(VX,VY),
        memory(VX,VY,M),
        member(brisa,M)
    ).

% Nenhum vizinho visitado detecta PASSOS (inimigos causam dano)
nao_ha_passos_vizinha(X,Y) :-
    \+ (
        vizinho_coord(X,Y,VX,VY),
        visitado(VX,VY),
        memory(VX,VY,M),
        member(passos,M)
    ).

% Verifica se tem adjacente seguro não visitado
tem_adjacente_seguro_nao_visitado(X,Y) :-
    vizinho_coord(X,Y,NX,NY),
    celula_segura(NX,NY),
    \+visitado(NX,NY),!.

% Verifica se tem adjacente seguro não visitado SEM morcego
tem_adjacente_sem_morcego(X,Y) :-
    vizinho_coord(X,Y,NX,NY),
    celula_segura(NX,NY),
    \+visitado(NX,NY),
    \+celula_evitavel(NX,NY),
    !.

% Verifica se existe alguma área sem morcegos no mapa para explorar
existe_area_sem_morcego_no_mapa :-
    celula_segura(X,Y),
    \+visitado(X,Y),
    \+celula_evitavel(X,Y),
    !.

% Atualiza histórico de posições (mantém últimas 10)
atualiza_historico_posicoes(X,Y) :-
    historico_posicoes(Hist),
    retract(historico_posicoes(_)),
    append([(X,Y)], Hist, NovoHist),
    % Mantém apenas as 10 últimas posições
    (length(NovoHist, Len), Len > 10 -> 
        length(NovoHist, L),
        Skip is L - 10,
        length(Prefix, Skip),
        append(Prefix, HistCortado, NovoHist),
        assert(historico_posicoes(HistCortado))
    ;
        assert(historico_posicoes(NovoHist))
    ).

% Detecta se está em loop (visitou mesma posição 3+ vezes recentemente)
em_loop :-
    posicao(X,Y,_),
    historico_posicoes(Hist),
    findall(1, member((X,Y), Hist), Ocorrencias),
    length(Ocorrencias, N),
    N >= 3,
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sistema de Backtracking (Pilha LIFO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Atualiza pilha de backtrack (LIFO - Last In First Out)
% Adiciona posição atual no topo da pilha
atualiza_pilha_backtrack(X,Y) :-
    (pilha_backtrack(Pilha) -> 
        append([(X,Y)], Pilha, NovaPilha),
        retract(pilha_backtrack(_)),
        assert(pilha_backtrack(NovaPilha))
    ; 
        assert(pilha_backtrack([(X,Y)]))
    ).

% Remove posição do topo da pilha (backtrack)
remove_top_pilha(X,Y) :-
    pilha_backtrack([(X,Y)|Resto]),
    retract(pilha_backtrack(_)),
    (Resto = [] -> assert(pilha_backtrack([(X,Y)])) ; assert(pilha_backtrack(Resto))).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% A* Pathfinding Algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Distância Manhattan como heurística
heuristica(X1,Y1,X2,Y2,H) :- 
    H is abs(X1-X2) + abs(Y1-Y2).

% A* principal
astar_path(StartX,StartY,GoalX,GoalY,Path) :-
    astar_search([(0,0,StartX,StartY,[])], GoalX,GoalY,[], PathRev),
    reverse(PathRev, Path).

% Caso base: chegou no objetivo
astar_search([(_,_,X,Y,Path)|_], X,Y, _, [(X,Y)|Path]) :- !.

% Verifica se há perigo FATAL conhecido na célula (brisa/passos, NÃO morcegos)
ha_perigo_conhecido(X,Y) :-
    memory(X,Y,M),
    (member(brisa,M); member(passos,M)),
    !.
ha_perigo_conhecido(X,Y) :-
    perigoso(X,Y,Tipo),
    Tipo \= morcego,
    !.
ha_perigo_conhecido(_,_) :- fail.

% Caso recursivo: expandir nó COM VERIFICAÇÃO EXTRA DE SEGURANÇA
% EVITA MORCEGOS CONHECIDOS quando há alternativas seguras
astar_search([(G,_,X,Y,Path)|Resto], GoalX,GoalY, Visited, FinalPath) :-
    findall(
        (NewG,F,NX,NY,[(X,Y)|Path]),
        (
            vizinho_coord(X,Y,NX,NY),
            celula_segura(NX,NY),
            \+ha_perigo_conhecido(NX,NY),  % VERIFICAÇÃO EXTRA
            not_blocked(NX,NY),  % Verifica se não está bloqueado
            \+eh_morcego(NX,NY),  % EVITA MORCEGOS CONHECIDOS
            \+member((NX,NY),[(X,Y)|Path]),
            \+member((NX,NY),Visited),
            NewG is G + 1,
            heuristica(NX,NY,GoalX,GoalY,H),
            F is NewG + H
        ),
        Vizinhos
    ),
    % Se não encontrou caminho sem morcegos, tenta com morcegos (último recurso)
    (Vizinhos = [] ->
        findall(
            (NewG,F,NX,NY,[(X,Y)|Path]),
            (
                vizinho_coord(X,Y,NX,NY),
                celula_segura(NX,NY),
                \+ha_perigo_conhecido(NX,NY),
                not_blocked(NX,NY),
                \+member((NX,NY),[(X,Y)|Path]),
                \+member((NX,NY),Visited),
                NewG is G + 1,
                heuristica(NX,NY,GoalX,GoalY,H),
                F is NewG + H
            ),
            VizinhosComMorcegos
        ),
        (VizinhosComMorcegos = [] -> 
            merge_sorted([], Resto, NovaFila)
        ;
            merge_sorted(VizinhosComMorcegos, Resto, NovaFila)
        )
    ;
        merge_sorted(Vizinhos, Resto, NovaFila)
    ),
    astar_search(NovaFila, GoalX,GoalY, [(X,Y)|Visited], FinalPath).

% Merge ordenado para fila de prioridade
merge_sorted([], L, L).
merge_sorted(L, [], L).
merge_sorted([(G1,F1,X1,Y1,P1)|R1], [(G2,F2,X2,Y2,P2)|R2], [(G1,F1,X1,Y1,P1)|R]) :-
    F1 =< F2, !,
    merge_sorted(R1, [(G2,F2,X2,Y2,P2)|R2], R).
merge_sorted(L1, [H2|R2], [H2|R]) :-
    merge_sorted(L1, R2, R).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Conversão de caminho para ações
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Converte uma lista de coordenadas em lista de ações (andar/virar)
% Começa da posição e orientação atuais
converte_caminho_acoes(_,_,[],[]) :- !.
converte_caminho_acoes(X,Y,[(X,Y)|Resto],Acoes) :- 
    !,
    converte_caminho_acoes(X,Y,Resto,Acoes).
converte_caminho_acoes(X,Y,[(NX,NY)|Resto],Acoes) :-
    posicao(X,Y,Dir),!,
    direcao_para(X,Y,NX,NY,DirNecessaria),
    acoes_para_direcao(Dir,DirNecessaria,AcoesVirar),
    append(AcoesVirar,[andar],AcoesAqui),
    % Calcula nova direção após as ações
    atualiza_direcao_simulada(Dir,AcoesVirar,NovaDirecao),
    converte_caminho_acoes_dir(NX,NY,NovaDirecao,Resto,AcoesRestantes),
    append(AcoesAqui,AcoesRestantes,Acoes).

% Versão auxiliar que mantém controle da direção simulada
converte_caminho_acoes_dir(_,_,_,[],[]) :- !.
converte_caminho_acoes_dir(X,Y,Dir,[(X,Y)|Resto],Acoes) :- 
    !,
    converte_caminho_acoes_dir(X,Y,Dir,Resto,Acoes).
converte_caminho_acoes_dir(X,Y,Dir,[(NX,NY)|Resto],Acoes) :-
    direcao_para(X,Y,NX,NY,DirNecessaria),
    acoes_para_direcao(Dir,DirNecessaria,AcoesVirar),
    append(AcoesVirar,[andar],AcoesAqui),
    atualiza_direcao_simulada(Dir,AcoesVirar,NovaDirecao),
    converte_caminho_acoes_dir(NX,NY,NovaDirecao,Resto,AcoesRestantes),
    append(AcoesAqui,AcoesRestantes,Acoes).

% Simula mudança de direção após uma sequência de viragens
atualiza_direcao_simulada(Dir,[],Dir) :- !.
atualiza_direcao_simulada(Dir,[virar_direita|Resto],DirFinal) :-
    virar_dir_simulado(Dir,NovaDir),
    atualiza_direcao_simulada(NovaDir,Resto,DirFinal).
atualiza_direcao_simulada(Dir,[virar_esquerda|Resto],DirFinal) :-
    virar_esq_simulado(Dir,NovaDir),
    atualiza_direcao_simulada(NovaDir,Resto,DirFinal).

% Simulação de rotações sem alterar o estado real
virar_dir_simulado(norte,leste).
virar_dir_simulado(leste,sul).
virar_dir_simulado(sul,oeste).
virar_dir_simulado(oeste,norte).

virar_esq_simulado(norte,oeste).
virar_esq_simulado(oeste,sul).
virar_esq_simulado(sul,leste).
virar_esq_simulado(leste,norte).

% Determina direção necessária para ir de (X1,Y1) para (X2,Y2)
direcao_para(X,Y1,X,Y2,norte) :- Y2 > Y1, !.
direcao_para(X,Y1,X,Y2,sul) :- Y2 < Y1, !.
direcao_para(X1,Y,X2,Y,leste) :- X2 > X1, !.
direcao_para(X1,Y,X2,Y,oeste) :- X2 < X1, !.

% Calcula ações necessárias para virar de DirAtual para DirDesejada
acoes_para_direcao(Dir,Dir,[]) :- !.
acoes_para_direcao(norte,leste,[virar_direita]) :- !.
acoes_para_direcao(norte,oeste,[virar_esquerda]) :- !.
acoes_para_direcao(norte,sul,[virar_direita,virar_direita]) :- !.
acoes_para_direcao(leste,sul,[virar_direita]) :- !.
acoes_para_direcao(leste,norte,[virar_esquerda]) :- !.
acoes_para_direcao(leste,oeste,[virar_direita,virar_direita]) :- !.
acoes_para_direcao(sul,oeste,[virar_direita]) :- !.
acoes_para_direcao(sul,leste,[virar_esquerda]) :- !.
acoes_para_direcao(sul,norte,[virar_direita,virar_direita]) :- !.
acoes_para_direcao(oeste,norte,[virar_direita]) :- !.
acoes_para_direcao(oeste,sul,[virar_esquerda]) :- !.
acoes_para_direcao(oeste,leste,[virar_direita,virar_direita]) :- !.

% Escolhe o melhor candidato (mais próximo)
escolhe_melhor_candidato(_PX,_PY,[(X,Y)],X,Y) :- !.
escolhe_melhor_candidato(PX,PY,[(X1,Y1),(X2,Y2)|Resto],MelhorX,MelhorY) :-
    heuristica(PX,PY,X1,Y1,D1),
    heuristica(PX,PY,X2,Y2,D2),
    (D1 =< D2 -> 
        escolhe_melhor_candidato(PX,PY,[(X1,Y1)|Resto],MelhorX,MelhorY)
    ;
        escolhe_melhor_candidato(PX,PY,[(X2,Y2)|Resto],MelhorX,MelhorY)
    ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Debug e diagnóstico
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Mostra status do agente para debug
debug_status :-
    posicao(X,Y,Dir),
    energia(E),
    pontuacao(P),
    findall((SX,SY), celula_segura(SX,SY), Seguras),
    length(Seguras, NumSeguras),
    findall((VX,VY), visitado(VX,VY), Visitadas),
    length(Visitadas, NumVisitadas),
    format('Pos: (~w,~w) Dir: ~w | E: ~w P: ~w | Seguras: ~w Visitadas: ~w~n', 
           [X,Y,Dir,E,P,NumSeguras,NumVisitadas]).

log_decisao(Acao) :-
    posicao(X,Y,Dir),
    energia(E),
    pontuacao(P),
    (plano(PPlano) -> true ; PPlano = []),
    findall((NX,NY,Status,Perigos,Memo),
        (
            vizinho_coord(X,Y,NX,NY),
            status_celula(NX,NY,Status),
            findall(Tipo, perigoso(NX,NY,Tipo), Perigos),
            (memory(NX,NY,Memo) -> true ; Memo = desconhecido)
        ),
        Adj),
    format('[AI-LOG] ação=~w | pos=(~w,~w,~w) | E=~w P=~w~n', [Acao,X,Y,Dir,E,P]),
    format('          plano_atual=~w~n', [PPlano]),
    format('          adjacentes=~w~n', [Adj]),
    !.
log_decisao(_).

status_celula(X,Y,visitado) :- visitado(X,Y), !.
status_celula(X,Y,seguro) :- celula_segura(X,Y), !.
status_celula(X,Y,suspeito) :- possivelmente_perigosa(X,Y), !.
status_celula(_,_,desconhecido).

% Mostra células adjacentes e seu status de segurança
debug_adjacentes :-
    posicao(PX,PY,Dir),
    format('~n=== DEBUG: Posição (~w,~w) direção ~w ===~n', [PX,PY,Dir]),
    findall((X,Y), vizinho_coord(PX,PY,X,Y), Vizinhos),
    format('Vizinhos: ~w~n', [Vizinhos]),
    forall(member((X,Y), Vizinhos),
        (
            (celula_segura(X,Y) -> Status = 'SEGURA' ; Status = 'PERIGOSA'),
            (visitado(X,Y) -> Visit = 'visitado' ; Visit = 'nao_visitado'),
            (memory(X,Y,M) -> Mem = M ; Mem = 'sem_memoria'),
            format('  (~w,~w): ~w ~w mem=~w~n', [X,Y,Status,Visit,Mem])
        )
    ),
    format('===================================~n~n').