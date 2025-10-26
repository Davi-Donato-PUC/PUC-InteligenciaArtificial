import numpy as np
import numpy as np
import pyqtgraph as pg
from PyQt5.QtWidgets import QApplication
import sys
from PyQt5.QtCore import QTimer


TERRENOS_CORES = {
    'M': (107, 79, 29),    # Montanha
    'A': (43, 108, 176),   # Água
    'N': (224, 247, 255),  # Neve
    'L': (252, 111, 3),  # Neve
    'F': (34, 139, 34),    # Floresta
    'D': (225, 193, 110),  # Deserto
    'R': (128, 128, 128),  # Rochoso
    '.': (240, 240, 240),  # Livre
    'I': (0, 255, 0),      # Início
    'Z': (0, 0, 255),      # Fim
}

EVENTOS_CARACTERES = [
    '1','2','3','4','5','6','7','8','9','0',
    'B','C','E','G','H','J',
]

INICIO_FIM_CARACTERES = ['I', 'Z']

def desenhar_mapa_pyqtgraph(arquivo_mapa, rota, start, end, eventos, ordem, velocidade_ms=50, runas=[], custoTotal=0):
    with open(arquivo_mapa, 'r', encoding='utf-8') as f:
        grid = [list(line.rstrip('\n')) for line in f.readlines()]

    rows, cols = len(grid), len(grid[0])
    img = np.zeros((rows, cols, 3), dtype=np.uint8)

    # Preenche mapa base
    for r in range(rows):
        for c in range(cols):
            ch = grid[r][c]
            if ch in TERRENOS_CORES:
                img[r, c] = TERRENOS_CORES[ch]
            elif ch in EVENTOS_CARACTERES:
                img[r, c] = (180, 0, 255)
            else:
                img[r, c] = (255, 255, 255)

    # Matriz de contagem de passagens
    contagem_passos = np.zeros((rows, cols), dtype=int)

    app = QApplication(sys.argv)
    win = pg.GraphicsLayoutWidget(title="Mapa com Rota - PyQtGraph")
    win.resize(900, 700)

    view = win.addViewBox(lockAspect=True)
    view.setRange(pg.QtCore.QRectF(0, 0, cols, rows))

    img_rot = np.rot90(img, k=-1)
    img_item = pg.ImageItem(img_rot)
    view.addItem(img_item)

    # --- Texto dos eventos ---
    font = 'Impact'
    cor_texto = (0, 0, 0)

    for k, v in eventos.items():
        x, y = v
        txt = pg.TextItem(k, color=cor_texto, anchor=(0.5, 0.5))
        txt.setFont([font, 16, 'black'])
        txt.setPos(x + 0.5, (rows - 1 - y) + 0.5)
        view.addItem(txt)




    # Início
    txt = pg.TextItem('I', color='black', anchor=(0.5, 0.5))
    txt.setFont([font, 20, 'black'])
    x, y = start
    txt.setPos(x + 0.5, (rows - 1 - y) + 0.5)
    view.addItem(txt)

    # Fim
    txt = pg.TextItem('Z', color='black', anchor=(0.5, 0.5))
    txt.setFont([font, 20, 'black'])
    x, y = end
    txt.setPos(x + 0.5, (rows - 1 - y) + 0.5)
    view.addItem(txt)

    # Ordem no topo
    a = 0
    for c in ordem:
        a += 10
        txt = pg.TextItem(c, color='white', anchor=(0.5, 0.5))
        txt.setFont([font, 30, 'black'])
        txt.setPos(a, -20)
        view.addItem(txt)


    a = 0
    for k, v in runas.items():
        a += 20
        txt = pg.TextItem(f'{k} {v}', color='white', anchor=(0.5, 0.5))
        txt.setFont([font, 30, 'black'])
        txt.setPos(a, -40)
        view.addItem(txt)


    txt = pg.TextItem(f'Custo total: {custoTotal}', color='white', anchor=(0.5, 0.5))
    txt.setFont([font, 30, 'black'])
    txt.setPos(0, -60)
    view.addItem(txt)


    # --- ANIMAÇÃOo ---
    rota_index = [0]
    cor_base = np.array([255, 62, 48])

    def atualizar_rota():
        if rota_index[0] < len(rota):
            x, y = rota[rota_index[0]]
            contagem_passos[y, x] += 1

            fator = 0.6 ** (contagem_passos[y, x] - 1)
            cor = (cor_base * fator).clip(0, 255).astype(np.uint8)
            img[y, x] = cor

            # Atualiza imagem rotacionada
            img_rot = np.rot90(img, k=-1)
            img_item.setImage(img_rot, autoLevels=False)

            rota_index[0] += 1
        else:
            timer.stop()

    timer = QTimer()
    timer.timeout.connect(atualizar_rota)
    timer.start(velocidade_ms)

    win.show()
    sys.exit(app.exec_())












