% Test script to verify initialization
:-consult('main.pl').

test_init :-
    write('=== TESTE DE INICIALIZAÇÃO ==='), nl,
    write('Testando se (1,1) foi inicializado corretamente...'), nl, nl,
    
    % Verifica posição
    (posicao(X,Y,Dir) -> 
        format('Posição: (~w,~w) Direção: ~w~n', [X,Y,Dir])
    ;   write('ERRO: Posição não definida!')
    ), nl,
    
    % Verifica visitado
    (visitado(1,1) -> 
        write('✓ (1,1) está marcado como visitado~n')
    ;   write('✗ (1,1) NÃO está marcado como visitado~n')
    ), nl,
    
    % Verifica seguro
    (seguro(1,1) -> 
        write('✓ (1,1) está marcado como seguro~n')
    ;   write('✗ (1,1) NÃO está marcado como seguro~n')
    ), nl,
    
    % Verifica memória
    (memory(1,1,M) -> 
        format('✓ Memory(1,1) = ~w~n', [M])
    ;   write('✗ Memory(1,1) não existe~n')
    ), nl,
    
    % Verifica células adjacentes
    write('Células adjacentes:'), nl,
    findall((AX,AY), vizinho_coord(1,1,AX,AY), Adjacentes),
    format('  Posições: ~w~n', [Adjacentes]),
    
    forall(member((AX,AY), Adjacentes),
        (
            (seguro(AX,AY) -> S = '✓ SEGURA' ; S = '✗ não segura'),
            (celula_segura(AX,AY) -> CS = '✓ SEGURA' ; CS = '✗ não segura'),  
            format('  (~w,~w): seguro/2=~w  celula_segura/2=~w~n', [AX,AY,S,CS])
        )
    ), nl,
    
    % Teste de ação
    write('Testando executa_acao:'), nl,
    (executa_acao(Acao) -> 
        format('  Ação decidida: ~w~n', [Acao])
    ;   write('  ERRO: Nenhuma ação retornada!')
    ), nl,
    
    write('=== FIM DO TESTE ==='), nl.

:- test_init, halt.

