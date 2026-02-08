#!/usr/bin/env python

"""GameAI.py: INF1771 GameAI File - Where Decisions are made.
   Versão melhorada: memória, A*, FSM, combate e exploração inteligente.
"""

from Map.Position import Position
from typing import List, Dict, Tuple, Set
from enum import Enum
import heapq
import random

GRID_W = 59
GRID_H = 34

def manhattan(a: Tuple[int,int], b: Tuple[int,int]) -> int:
    return abs(a[0]-b[0]) + abs(a[1]-b[1])

def neighbors4(pos: Tuple[int,int]):
    x,y = pos
    res = []
    if x > 0: res.append((x-1,y))
    if x < GRID_W-1: res.append((x+1,y))
    if y > 0: res.append((x,y-1))
    if y < GRID_H-1: res.append((x,y+1))
    return res

class State(Enum):
    EXPLORING = 1
    RECOVER = 2
    COLLECTING = 3

class Memoria:
    def __init__(self):
        self.safe_positions: Set[Tuple[int,int]] = set()
        self.gold_positions: Set[Tuple[int,int]] = set()
        self.powerup_positions: Set[Tuple[int,int]] = set()
        self.path_to_interest_point: List[Tuple[int,int]] = []
        self.path_index: int = 0
        self.target: Tuple[int,int] = None
        self.number_of_steps_without_gold: int = 0

class GameAI():

    def __init__(self):
        self.player = Position()
        self.state = "ready"
        self.dir = "north"
        self.score = 0
        self.energy = 0

        # observations & memory
        self.ultimaObservacao = None
        self.perigosas = {}    # (x,y) -> reason
        self.arriscadas = {}   # reserved (not used heavily)
        self.seguras = {}      # reserved (not used heavily)
        self.estado = 'EXPLORE'

        self.memory = Memoria()

        # transient sensors
        self.has_breeze = False
        self.has_flash = False
        self.has_blocked = False
        self.has_blue = False
        self.has_red = False
        self.has_weak = False
        self.has_enemy_near = False
        self.enemy_distance = None
        self.has_hit = False
        self.has_damage = False
        self.visited = set()

    # -----------------------
    # STATUS / POSITIONS
    # -----------------------
    def SetStatus(self, x: int, y: int, dir: str, state: str, score: int, energy: int):
        self.SetPlayerPosition(x, y)
        self.dir = dir.lower()
        self.state = state
        self.score = score
        self.energy = energy

    def GetCurrentObservableAdjacentPositions(self) -> List[Position]:
        return self.GetObservableAdjacentPositions(self.player)

    def GetObservableAdjacentPositions(self, pos):
        ret = []
        ret.append(Position(pos.x - 1, pos.y))
        ret.append(Position(pos.x + 1, pos.y))
        ret.append(Position(pos.x, pos.y - 1))
        ret.append(Position(pos.x, pos.y + 1))
        return ret

    def GetAllAdjacentPositions(self):
        ret = []
        ret.append(Position(self.player.x - 1, self.player.y - 1))
        ret.append(Position(self.player.x, self.player.y - 1))
        ret.append(Position(self.player.x + 1, self.player.y - 1))
        ret.append(Position(self.player.x - 1, self.player.y))
        ret.append(Position(self.player.x + 1, self.player.y))
        ret.append(Position(self.player.x - 1, self.player.y + 1))
        ret.append(Position(self.player.x, self.player.y + 1))
        ret.append(Position(self.player.x + 1, self.player.y + 1))
        return ret

    def NextPositionAhead(self, steps):
        ret = None
        if self.dir == "north":
            ret = Position(self.player.x, self.player.y - steps)
        elif self.dir == "east":
            ret = Position(self.player.x + steps, self.player.y)
        elif self.dir == "south":
            ret = Position(self.player.x, self.player.y + steps)
        elif self.dir == "west":
            ret = Position(self.player.x - steps, self.player.y)
        return ret

    def NextPosition(self):
        return self.NextPositionAhead(1)

    def GetPlayerPosition(self):
        return Position(self.player.x, self.player.y)

    def SetPlayerPosition(self, x:int, y:int):
        self.player.x = x
        self.player.y = y

    # -----------------------
    # Observations handling
    # -----------------------
    def GetObservationsClean(self):
        """Limpa observações temporárias e marca posição atual como visitada e segura."""
        self.ultimaObservacao = None
        self.has_breeze = False
        self.has_flash = False
        self.has_blocked = False
        self.has_blue = False
        self.has_red = False
        self.has_weak = False
        self.has_enemy_near = False
        self.enemy_distance = None
        self.has_hit = False
        self.has_damage = False

        # marca posição atual como segura
        cur = (self.player.x, self.player.y)
        self.memory.safe_positions.add(cur)
        self.visited.add(cur)

    def GetObservations(self, o: List[str]):
        """Processa observações recebidas e atualiza memória/sensores."""
        # reset temporários (we expect GetObservationsClean called before new batch normally)
        for s in o:
            if s == "blocked":
                self.ultimaObservacao = 'blocked'
                self.has_blocked = True
                # mark forward pos as blocked (conservatively)
                fpos = (self.NextPosition().x, self.NextPosition().y)
                self.perigosas[fpos] = 'blocked'
                print(f'blocked {self.player.x} {self.player.y}')

            elif s == "":
                self.ultimaObservacao = 'steps'
                print(f'steps {self.player.x} {self.player.y}')

            elif s == "breeze":
                self.ultimaObservacao = 'breeze'
                self.has_breeze = True
                # marcar adjacentes como perigosos (poço)
                for pos in self.GetCurrentObservableAdjacentPositions():
                    px,py = pos.x, pos.y
                    if 0 <= px < GRID_W and 0 <= py < GRID_H:
                        self.perigosas[(px,py)] = 'poço'
                print(f'breeze {self.player.x} {self.player.y}')

            elif s == "flash":
                self.ultimaObservacao = 'flash'
                self.has_flash = True
                for pos in self.GetCurrentObservableAdjacentPositions():
                    px,py = pos.x, pos.y
                    if 0 <= px < GRID_W and 0 <= py < GRID_H:
                        self.perigosas[(px,py)] = 'teleport'
                print(f'flash {self.player.x} {self.player.y}')

            elif s == "blueLight":
                self.ultimaObservacao = 'blueLight'
                self.has_blue = True
                print(f'blueLight {self.player.x} {self.player.y}')

            elif s == "redLight":
                self.ultimaObservacao = 'redLight'
                self.has_red = True
                print(f'redLight {self.player.x} {self.player.y}')

            elif s == "greenLight":
                self.ultimaObservacao = 'greenLight'
                print(f'greenLight {self.player.x} {self.player.y}')

            elif s == "weakLight":
                self.ultimaObservacao = 'weakLight'
                self.has_weak = True
                print(f'weakLight {self.player.x} {self.player.y}')

            elif s == "damage":
                self.ultimaObservacao = 'damage'
                self.has_damage = True
                print(f'damage {self.player.x} {self.player.y}')

            elif s == "hit":
                self.ultimaObservacao = 'hit'
                self.has_hit = True
                print(f'hit {self.player.x} {self.player.y}')

            elif s.startswith("enemy#"):
                try:
                    steps = int(s.replace("enemy#",""))
                    self.ultimaObservacao = 'enemy'
                    self.has_enemy_near = True
                    self.enemy_distance = steps
                    print(f'enemy {steps} {self.player.x} {self.player.y}')
                except:
                    pass

        # se não há brisa nem flash, marcamos adjacentes como seguros
        if not self.has_breeze and not self.has_flash:
            self.MarkAdjacentSafe(self.GetCurrentObservableAdjacentPositions())

        # update memory about blue/red/weak positions
        cur = (self.player.x, self.player.y)
        if self.has_blue:
            self.memory.gold_positions.add(cur)
            self.memory.safe_positions.add(cur)
            self.memory.number_of_steps_without_gold = 0
        if self.has_red:
            self.memory.powerup_positions.add(cur)
            self.memory.safe_positions.add(cur)

    def MarkAdjacentSafe(self, adj):
        for p in adj:
            if 0 <= p.x < GRID_W and 0 <= p.y < GRID_H:
                self.memory.safe_positions.add((p.x, p.y))

    # -----------------------
    # Movement helpers
    # -----------------------
    def getDirectionTo(self, target: Position) -> str:
        dx = target.x - self.player.x
        dy = target.y - self.player.y
        if dx == 1 and dy == 0: return "east"
        if dx == -1 and dy == 0: return "west"
        if dx == 0 and dy == -1: return "north"
        if dx == 0 and dy == 1: return "south"
        return self.dir

    def getTurnCommand(self, currentDir: str, targetDir: str) -> str:
        ordem = ["north","east","south","west"]
        if currentDir == targetDir: return "andar"
        iAtual = ordem.index(currentDir)
        iDesejada = ordem.index(targetDir)
        diff = (iDesejada - iAtual + 4) % 4
        if diff == 2:
            # prefer virar_direita (like C++ did) rather than andar para trás
            return "virar_direita"
        if diff == 1: return "virar_direita"
        if diff == 3: return "virar_esquerda"
        return "virar_direita"

    # -----------------------
    # A* pathfinding (considera apenas memory.safe_positions)
    # -----------------------
    def a_star(self, start: Tuple[int,int], goal: Tuple[int,int]) -> List[Tuple[int,int]]:
        if start == goal: return []
        # if goal not known safe, we still allow goal if in memory gold/powerup sets
        # but prefer to check: require that intermediate nodes are in safe_positions
        open_heap = []
        heapq.heappush(open_heap, (manhattan(start,goal), 0, start))
        came_from = {}
        gscore = {start: 0}
        closed = set()
        while open_heap:
            _, cost, current = heapq.heappop(open_heap)
            if current == goal:
                path = []
                cur = current
                while cur != start:
                    path.append(cur)
                    cur = came_from[cur]
                path.reverse()
                return path
            if current in closed:
                continue
            closed.add(current)
            for nb in neighbors4(current):
                if nb not in self.memory.safe_positions and nb != goal:
                    continue
                tentative = gscore[current] + 1
                if nb not in gscore or tentative < gscore[nb]:
                    gscore[nb] = tentative
                    priority = tentative + manhattan(nb, goal)
                    heapq.heappush(open_heap,(priority, tentative, nb))
                    came_from[nb] = current
        return []

    def closest_interest_point(self, interest_set: Set[Tuple[int,int]]) -> Tuple[int,int]:
        pos = (self.player.x, self.player.y)
        best = None
        bestd = 10**9
        for p in interest_set:
            d = manhattan(pos,p)
            if d < bestd:
                bestd = d
                best = p
        return best

    # -----------------------
    # High level behaviors
    # -----------------------
    def exploring(self) -> str:
        cur = (self.player.x, self.player.y)
        # mark current as safe
        self.memory.safe_positions.add(cur)
        # blocked -> turn randomly
        if self.has_blocked:
            if random.getrandbits(1):
                return "virar_esquerda"
            else:
                return "virar_direita"

        # If in danger (breeze or flash), try to move to a known safe adjacent cell
        if self.has_breeze or self.has_flash:
            adj = self.GetCurrentObservableAdjacentPositions()
            for p in adj:
                if 0 <= p.x < GRID_W and 0 <= p.y < GRID_H:
                    if (p.x,p.y) in self.memory.safe_positions:
                        # turn to that direction
                        return self.getTurnCommand(self.dir, self.getDirectionTo(p))
            # if no known safe neighbor, prefer to turn to change direction
            if random.random() < 0.5:
                return "virar_direita"
            return "virar_esquerda"

        # small random turns to diversify exploration
        if random.randint(0,29) < 1:
            if random.getrandbits(1):
                return "virar_direita"
            else:
                return "virar_esquerda"

        # otherwise walk forward
        return "andar"

    def backtracking(self) -> str:
        # if no path, revert to exploring
        if not self.memory.path_to_interest_point:
            self.current_state = State.EXPLORING
            return self.exploring()

        # get next pos from path
        if self.memory.path_index >= len(self.memory.path_to_interest_point):
            # reached destination
            if self.current_state == State.COLLECTING:
                self.memory.number_of_steps_without_gold = 0
            self.current_state = State.EXPLORING
            self.memory.path_to_interest_point = []
            self.memory.path_index = 0
            return self.exploring()

        next_pos = self.memory.path_to_interest_point[self.memory.path_index]
        nx, ny = next_pos
        if (self.player.x, self.player.y) == (nx, ny):
            self.memory.path_index += 1
            if self.memory.path_index >= len(self.memory.path_to_interest_point):
                if self.current_state == State.COLLECTING:
                    self.memory.number_of_steps_without_gold = 0
                self.current_state = State.EXPLORING
                self.memory.path_to_interest_point = []
                self.memory.path_index = 0
                return self.exploring()
            next_pos = self.memory.path_to_interest_point[self.memory.path_index]
            nx, ny = next_pos

        target = Position(nx, ny)
        return self.getTurnCommand(self.dir, self.getDirectionTo(target))

    # -----------------------
    # Decision (main)
    # -----------------------
    def GetDecision(self) -> str:
        print(f'Score {self.score}')

        # initialize FSM state variable if not present
        if not hasattr(self, 'current_state'):
            self.current_state = State.EXPLORING

        # Immediate reactions to items on current tile
        cur = (self.player.x, self.player.y)
        if self.has_blue:
            # found gold
            self.memory.gold_positions.add(cur)
            self.memory.safe_positions.add(cur)
            print(f'[LOG] Observação: OURO em {cur}')
            self.memory.number_of_steps_without_gold = 0
            # clear blue flag to avoid repeated picks
            self.has_blue = False
            return "pegar_ouro"

        if self.has_red:
            self.memory.powerup_positions.add(cur)
            self.memory.safe_positions.add(cur)
            print(f'[LOG] Observação: POWERUP em {cur}')
            self.has_red = False
            if self.current_state == State.RECOVER:
                # reached powerup
                self.current_state = State.EXPLORING
                self.memory.path_to_interest_point.clear()
                self.memory.path_index = 0
            return "pegar_powerup"

        # Combat: if enemy near and close enough, shoot; otherwise approach cautiously
        if self.has_enemy_near and (self.enemy_distance is not None):
            if self.enemy_distance <= 3:
                # aggressive short-range behavior
                return "atacar"
            else:
                # approach enemy carefully
                # try moving forward if safe
                f = self.NextPosition()
                fx,fy = f.x, f.y
                if (fx,fy) in self.memory.safe_positions:
                    return "andar"
                # otherwise turn randomly towards some safe direction
                if random.getrandbits(1):
                    return "virar_direita"
                return "virar_esquerda"

        # Energy management: seek powerup if low
        if self.energy < 20 and self.current_state == State.EXPLORING and self.memory.powerup_positions:
            self.current_state = State.RECOVER
            self.memory.target = self.closest_interest_point(self.memory.powerup_positions)
            if self.memory.target:
                start = (self.player.x, self.player.y)
                self.memory.path_to_interest_point = self.a_star(start, self.memory.target)
                self.memory.path_index = 0

        # If starving for gold, go collect
        if self.memory.number_of_steps_without_gold > 150 and self.current_state == State.EXPLORING and self.memory.gold_positions:
            self.current_state = State.COLLECTING
            self.memory.target = self.closest_interest_point(self.memory.gold_positions)
            if self.memory.target:
                start = (self.player.x, self.player.y)
                self.memory.path_to_interest_point = self.a_star(start, self.memory.target)
                self.memory.path_index = 0

        # State dispatch
        if self.current_state == State.EXPLORING:
            print("[LOG] EXPLORING = exploração genérica")
            self.memory.number_of_steps_without_gold += 1
            return self.exploring()

        if self.current_state == State.RECOVER:
            print("[LOG] RECOVER = backtracking para energia")
            return self.backtracking()

        if self.current_state == State.COLLECTING:
            print("[LOG] COLLECTING = backtracking para ouro")
            return self.backtracking()

        # fallback random safe action
        if random.randint(0,7) == 0:
            return "virar_direita"
        return "andar"
