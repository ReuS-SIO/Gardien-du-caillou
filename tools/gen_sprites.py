"""
Générateur de sprites pixel art pour Gardiens du Caillou.
Usage :  python tools/gen_sprites.py
Produit les PNG dans assets/sprites/ à partir de dessins ASCII, plus une planche
de contrôle assets/sprites/_preview.png (agrandie x4) pour vérifier le rendu.
Chaque lettre correspond à une couleur de la palette du sprite, '.' = transparent.
Les sprites regardent vers la droite.
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

GENERATED = []


def merge(*ps):
    d = {}
    for p in ps:
        d.update(p)
    return d


def save(name, rows, pal):
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    h = len(rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c == ".":
                continue
            if c not in pal:
                raise KeyError(f"{name}: couleur inconnue '{c}' ligne {y} col {x}")
            px[x, y] = pal[c] + (255,)
    img.save(os.path.join(OUT, name + ".png"))
    GENERATED.append((name, img))
    print(f"-> {name:16s} {w:3d} x {h}")


# ---------------------------------------------------------------- palettes
OUTLINE = {"o": (24, 18, 14)}

TOX = {  # mutations communes
    "V": (168, 82, 220),   # violet toxique
    "v": (120, 50, 170),   # violet sombre
    "F": (128, 250, 90),   # vert fluo
    "f": (80, 190, 60),    # vert fluo sombre
    "Y": (250, 232, 70),   # jaune radioactif
    "E": (255, 70, 60),    # œil rouge
    "e": (255, 236, 90),   # œil jaune lumineux
    "n": (30, 24, 34),     # pupille / contour sombre mutant
}

# ================================================================ JOUEUR (24 x 32)
P_PLAYER = merge(OUTLINE, {
    "h": (54, 34, 22), "H": (88, 58, 34),        # cheveux bruns bouclés
    "s": (198, 142, 98), "S": (160, 108, 72),    # peau
    "e": (22, 16, 12),                           # yeux
    "g": (100, 120, 60), "G": (68, 86, 42), "L": (128, 150, 80),   # chemise verte
    "p": (112, 88, 60), "P": (84, 64, 42),       # sac / bretelles
    "k": (72, 56, 40), "K": (50, 38, 28),        # short
    "b": (60, 42, 30), "B": (94, 68, 46),        # bottes
    "w": (130, 92, 54), "W": (162, 120, 72),     # bois de la lance
    "m": (204, 210, 216), "M": (132, 140, 152),  # pointe
    "r": (204, 50, 44),                          # ruban rouge
})

# corps commun (lignes 0-21), les jambes varient selon la pose
PLAYER_TOP = [
    "....................mm..",
    "....................mM..",
    ".....ohhhho.........mM..",
    "....ohhHhhhho.......Ww..",
    "...ohhHHhhhhho......Ww..",
    "...ohhhhhhhhho......Ww..",
    "...ohsshhhhhho......Ww..",
    "...oSsssssssSo......Ww..",
    "...oSsesssesSo......Ww..",
    "....osssssso........Ww..",
    "....oSsssSSo........Ww..",
    ".....oSSSo.........rWw..",
    "....oLggggLo.......rWw..",
    "...oLgggpgggLo.....oWw..",
    "..oLggggpggggo....osWw..",
    "..osoGggPgggGso...osWw..",
    "..oso.GggggggG.o.oSoWw..",
    "..oSo.GGggggGG.oSSo.Ww..",
    "..oo..oGGGGGGo.oo...Ww..",
    "......okkkkkko......Ww..",
    "......okkkkkko......Ww..",
    "......oKkkkkKo......Ww..",
]
LEGS_IDLE = [
    "......okko.kko......Ww..",
    "......oko..oko......Ww..",
    ".....oSso..oSso.....Ww..",
    ".....oSso..oSso.....Ww..",
    ".....osso..osso.....Ww..",
    ".....obbo..obbo.....Ww..",
    ".....oBbo..oBbo.....Ww..",
    "....obbbo..obbbo....Ww..",
    "....oooo...oooo.....Ww..",
    "....................oo..",
]
LEGS_RUN_0 = [
    "......okko.kko......Ww..",
    ".....oko....oko.....Ww..",
    "....oSso....oSso....Ww..",
    "...oSso......oSso...Ww..",
    "..osso........osso..Ww..",
    "..obbo........obbo..Ww..",
    ".oBbo..........oBbo.Ww..",
    ".obbbo........obbbo.Ww..",
    ".oooo..........oooo.Ww..",
    "....................oo..",
]
LEGS_RUN_1 = [
    "......okkokko.......Ww..",
    "......okkokko.......Ww..",
    "......oSsoSso.......Ww..",
    "......oSsoSso.......Ww..",
    "......ossosso.......Ww..",
    "......obbobbo.......Ww..",
    ".....oBbooBbo.......Ww..",
    "....obbbo.obbbo.....Ww..",
    "....oooo..oooo......Ww..",
    "....................oo..",
]
LEGS_JUMP = [
    "......okko.kko......Ww..",
    ".....oko....oko.....Ww..",
    "....oSso....oSso....Ww..",
    "....oSso.....oSso...Ww..",
    "...osso.......osso..Ww..",
    "...obbo........obbo.Ww..",
    "..oBbo.........oBbo.Ww..",
    "..obbbo.........oooo.Ww.",
    "..oooo..............Ww..",
    "....................oo..",
]
# attaque : lance tendue horizontalement vers la droite (36 de large)
PLAYER_ATTACK = [
    ".....ohhhho.........................",
    "....ohhHhhhho.......................",
    "...ohhHHhhhhho......................",
    "...ohhhhhhhhho......................",
    "...ohsshhhhhho......................",
    "...oSsssssssSo......................",
    "...oSsesssesSo......................",
    "....osssssso........................",
    "....oSsssSSo........................",
    ".....oSSSo..........................",
    "....oLggggLo........................",
    "...oLgggpgggLo......................",
    "..oLggggpggggoooo...................",
    "..osoGggPgggGgssSo..................",
    "..oso.GggggggGoSSoorrWwwwwwwwwwwwwwwwwwMmm",
    "..oSo.GGggggGG.ooo..r...............",
    "..oo..oGGGGGGo......................",
    "......okkkkkko......................",
    "......okkkkkko......................",
    "......oKkkkkKo......................",
    "......okko.kko......................",
    "......oko..oko......................",
    ".....oSso..oSso.....................",
    ".....oSso..oSso.....................",
    ".....osso..osso.....................",
    ".....obbo..obbo.....................",
    ".....oBbo..oBbo.....................",
    "....obbbo..obbbo....................",
    "....oooo...oooo.....................",
]
# lancer : bras levé en arrière, lance toujours en main (le javelot est un projectile séparé)
PLAYER_THROW = [
    "................mm......",
    "................mM......",
    ".....ohhhho.....Ww......",
    "....ohhHhhhho...Ww......",
    "...ohhHHhhhhho..Ww......",
    "...ohhhhhhhhho..Ww......",
    "...ohsshhhhhho..Ww......",
    "...oSsssssssSo..Ww......",
    "...oSsesssesSo..Ww......",
    "....osssssso....Ww......",
    "....oSsssSSo...oWw......",
    ".....oSSSo....osWw......",
    "....oLggggLo..osWw......",
    "...oLgggpgggLoosWw......",
    "..oLggggpggggGSoWw......",
    "..osoGggPgggGGooWw......",
    "..oso.GggggggG..Ww......",
    "..oSo.GGggggGG..Ww......",
    "..oo..oGGGGGGo..Ww......",
    "......okkkkkko..Ww......",
    "......okkkkkko..Ww......",
    "......oKkkkkKo..Ww......",
    "......okko.kko..Ww......",
    ".....oko....oko.Ww......",
    "....oSso....oSsoWw......",
    "...oSso......oSsWw......",
    "..osso........osWw......",
    "..obbo........obWw......",
    ".oBbo..........oWw......",
    ".obbbo........obWw......",
    ".oooo..........oWw......",
    "................oo......",
]

save("player_idle", PLAYER_TOP + LEGS_IDLE, P_PLAYER)
save("player_run_0", PLAYER_TOP + LEGS_RUN_0, P_PLAYER)
save("player_run_1", PLAYER_TOP + LEGS_RUN_1, P_PLAYER)
save("player_jump", PLAYER_TOP + LEGS_JUMP, P_PLAYER)
save("player_attack", PLAYER_ATTACK, P_PLAYER)
save("player_throw", PLAYER_THROW, P_PLAYER)

# javelot lancé (24 x 5)
save("javelin", [
    "..r.....................",
    ".rWwwwwwwwwwwwwwwwwwMmm.",
    "rrWwwwwwwwwwwwwwwwwwMmmm",
    ".rWwwwwwwwwwwwwwwwwwMmm.",
    "..r.....................",
], P_PLAYER)

# ================================================================ ENNEMIS
# Gecko mutant (30 x 13) : vert naturel, taches violettes, œil luisant
P_GECKO = merge(OUTLINE, TOX, {
    "g": (98, 148, 62), "G": (62, 102, 42), "l": (140, 188, 92), "b": (196, 204, 138),
})
save("enemy_gecko", [
    "......................ooooo...",
    ".....................ogllggo..",
    ".....................oglgneGo.",
    "........oooooooooooooogggggoo.",
    ".......oglllggglllgggllggggo..",
    "oo....oggggVVgggggVVggggGGo...",
    "oggooogggglgggggVgggggggGo....",
    ".ogggggGgggggggglggggGGo......",
    "..ooooGGGbbbbbbbbbGGGo........",
    "......oGooGbbbbbGoGGo.........",
    ".....oGo..oGGGGo.oGo..........",
    "....oo....oo..oo..oo..........",
], P_GECKO)

# Crabe mutant (30 x 16) : crabe de palétuvier rouge-brun, cristaux toxiques sur la carapace
P_CRAB = merge(OUTLINE, TOX, {
    "c": (152, 72, 52), "C": (196, 104, 74), "d": (104, 46, 36), "l": (124, 62, 46),
})
save("enemy_crab", [
    "...oo.........o....o.........oo.",
    "..occo........oe...oe.......occo",
    ".occCco.......oo...oo......ocCco",
    ".occco...ooooooooooooooo...occco",
    "..oco...oCCcccccccccccCCo...oco.",
    "..oo...oCccFFcccccVVcccccCo..oo.",
    "..o...oCcccFccccccVcccccccCo..o.",
    "..o..oCcccccccVcccccccFFccccCo.o",
    "..oooCccccccccVcccccccFcccccCooo",
    "....oCcccccccccccccccccccccccCo.",
    ".....odddddddddddddddddddddddo..",
    "......ooolooolooolooolooolooo...",
    ".....ol..ol..ol..ol..ol..ol.....",
    "....ol..ol...ol..ol...ol..ol....",
    "...oo..oo....oo..oo....oo..oo...",
], P_CRAB)

# Roussette mutante (32 x 15) : chauve-souris frugivore brune, membranes veinées de violet
P_BAT = merge(OUTLINE, TOX, {
    "f": (122, 82, 50), "F": (154, 108, 70), "w": (62, 42, 62), "W": (92, 62, 92), "m": (240, 236, 230),
})
save("enemy_bat", [
    "oo............................oo",
    "owoo..........................oowo",
    "owWwoo......................oowWwo",
    ".owWWwoo........oooo......oowWWwo.",
    ".owWWWVwoo.....offffo...oowVWWWwo.",
    "..owWWWWVwoo..oFfffffo.oowVWWWWwo.",
    "..owWWWWWWVwooofEffEfoowVWWWWWWwo.",
    "...owWWWWWWWwoofffffffowWWWWWWwo..",
    "....oowWWWWWwoofmfffmfowWWWWwoo...",
    "......oowWWWWwoFfffffFwWWWwoo.....",
    "........oowWWWofffffffoWwoo.......",
    "..........oowWoFfffffFoWo.........",
    "............oo.offfffo.o..........",
    "................ofFfo.............",
    ".................ooo..............",
], P_BAT)

# Cochon sauvage mutant (32 x 18) : sanglier brun sombre, défenses, excroissances violettes
P_BOAR = merge(OUTLINE, TOX, {
    "b": (82, 58, 42), "B": (112, 82, 58), "l": (142, 108, 76), "m": (232, 226, 210), "k": (40, 30, 24),
})
save("enemy_boar", [
    "..........oooooooooo............",
    "........ooBBBBBBBBBBoo..........",
    ".......oBBlBBBBBBBBBBBoo........",
    "......oBBlBBVVBBBBBBBBBBo.......",
    ".....oBBBBBBVBBBBBBBBBBBBoo.....",
    "....oBBBBBBBBBBBBBBVBBBBBBBo....",
    "...oBBbBBBBBBBBBBBBBBBBBnEBBo...",
    "..oBBbbBBBBBBBBBBBBBBBBBBBBBoo..",
    "..obbbbbbbBBBBBBBBBBBBBbbbbbbbo.",
    "..obbbbbbbbbbbbbbbbbbbbbbbbbbbmo",
    "..obbbbbbbbbbbbbbbbbbbbbbbbbmmo.",
    "...obbbbbbbbbbbbbbbbbbbbbbbbbo..",
    "....obbbbbbbbbbbbbbbbbbbbbbbo...",
    ".....obbbooobbbbbbbboobbbbbo....",
    ".....obbo..obbo...obbo.obbo.....",
    ".....obbo..obbo...obbo.obbo.....",
    ".....okko..okko...okko.okko.....",
    ".....oooo..oooo...oooo.oooo.....",
], P_BOAR)

# ================================================================ BOSS (≈ 48 x 32)
# Zone 1 - Cagou colossal : oiseau gris-bleu à huppe, plumes contaminées, œil rouge
P_CAGOU = merge(OUTLINE, TOX, {
    "g": (150, 160, 172), "G": (104, 116, 132), "l": (192, 198, 206), "c": (226, 228, 236),
    "y": (232, 172, 62), "k": (170, 120, 40),
})
save("boss_cagou", [
    "....................occo........................",
    "...................occcco.......................",
    "..................occcoco.......................",
    ".................ocoo.o.........................",
    "................olllo...........................",
    "...............ollllllo.........................",
    "..............ollgnEllo.........................",
    ".............ollllllllokkkyyy...................",
    "............ollgggggglloooooyy..................",
    "...........ollggggggggllo.......................",
    "...........olggggggggggggoooooooo...............",
    "...........olggggggggggggggggggggoooo...........",
    "...........olgggFgggggggggggggggggggggoo........",
    "...........olggFFFggggggggggFFgggggggggggo......",
    "...........olggggFgggggggggFFFFgggggggggggo.....",
    "............olggggggggVVgggggFggggggggggggo.....",
    "............olgggggggVVVVggggggggggggggggggo....",
    ".............olggggggggVVggggggggGGGGGggggggo...",
    ".............olggggggggggggggggGGGGGGGGGgggggo..",
    "..............olggggggggggggGGGGGGGGGGGGGGgggo..",
    "...............olgggggggggGGGGGGGGGGGGGGGGGGgo..",
    "................olggggggGGGGGGGGGGGGGGGGGGGGo...",
    ".................ollgggGGGGGGGGGGGGGGGGGGGGo....",
    "..................ooolGGGGGGGGGGGGGGGGGGGoo.....",
    ".....................oooooGGGGGGGGoooooooo......",
    "..........................oyyyyyo...............",
    "..........................oyyoyyo...............",
    "..........................oyyoyyo...............",
    "..........................oyyoyyo...............",
    "........................oyyyyoyyyyo.............",
    ".......................oyyyyyoyyyyyo............",
    ".......................ooooooooooooo............",
], P_CAGOU)

# Zone 2 - Crabe de cocotier titanesque : bleu-violet, cristaux verts
P_BIGCRAB = merge(OUTLINE, TOX, {
    "c": (72, 82, 164), "C": (104, 114, 204), "d": (46, 52, 112), "l": (60, 66, 140),
})
save("boss_crab", [
    ".....oo................o..........o................oo.....",
    "....occco..............oe.........oe..............occco...",
    "...occCcco.............oo.........oo.............occCcco..",
    "...occCcco.........ooooooooooooooooooooooo.......occCcco..",
    "...occcco.........oCCCccccccccccccccccccCCo.......occcco..",
    "....occo.........oCccccFFcccccccccccVVccccCo.......occo...",
    "....oco.........oCcccccFFFccccccccccVVVcccccCo......oco...",
    "....oo.........oCcccccccFccccccccccccVccccccccCo.....oo...",
    "....o.........oCccccccccccccccccccccccccccccccccCo....o...",
    "....o........oCcccFFccccccccccVVcccccccccccFFFcccCo...o...",
    "....o........oCccFFFccccccccccVVVcccccccccFFFFcccCo...o...",
    "....oo.......oCcccFcccccccccccccVcccccccccccFccccCo..oo...",
    ".....ooo.....oCcccccccccccccccccccccccccccccccccccCoooo....",
    ".......ooooooCcccccccccccccccccccccccccccccccccccCoo.......",
    ".............oCcccccccccccccccccccccccccccccccccCo.........",
    "..............oCcccccccccccccccccccccccccccccccCo..........",
    "...............odddddddddddddddddddddddddddddddo...........",
    "................oooolooooolooooolooooolooooooo.............",
    "...............ol...ol....ol....ol....ol..ol...............",
    "..............ol...ol....ol......ol....ol..ol..............",
    ".............ol...ol....ol........ol....ol..ol.............",
    "............oo...oo....oo..........oo....oo..oo............",
], P_BIGCRAB)

# Zone 3 - Tricot rayé abyssal : serpent marin rayé noir et blanc-bleu, bave jaune
P_SNAKE = merge(OUTLINE, TOX, {
    "W": (204, 216, 228), "w": (160, 176, 196), "k": (34, 38, 62), "K": (58, 62, 92),
})
save("boss_snake", [
    "......................................oooooo....",
    ".....................................oWWWWWWo...",
    "....................................oWWnEWWWWo..",
    "....................................oWWWWWWWWo..",
    "....................................okkkkkkkko..",
    "....................................oWWWWWWWo...",
    ".....................................oWWYYWo....",
    ".....................................okkkkko....",
    "......................................oWWWo.....",
    ".......................oooooo.........oWWWo.....",
    "....................oooWWWWWWooo......okkko.....",
    "..................ooWWWWkkkkWWWWoo....oWWWo.....",
    ".................oWWWkkkWWWWkkkWWWo...oWWWo.....",
    "................oWkkkWWWWWWWWWWkkkWo..okkko.....",
    "...............oWWWWWWWWkkkkWWWWWWWWo.oWWWo.....",
    "..........ooooWWkkkWWWWWkkkkWWWWWkkkWooWWWo.....",
    "........ooWWWWWWkkkWWWWWWWWWWWWWWkkkWWWWkkko....",
    "......ooWWWkkkWWWWWWWWkkkkWWWWWWWWWWWWWWWWWo....",
    ".....oWWWWWkkkWWWWWWWWkkkkWWWWWWWkkkWWWWWWo.....",
    "....oWkkkWWWWWWWkkkkWWWWWWWWkkkWWkkkWWWWWo......",
    "....oWkkkWWWWWWWkkkkWWWWWWWWkkkWWWWWWWWWo.......",
    "....oWWWWWWWkkkWWWWWWWWkkkWWWWWWWWWWWWo.........",
    ".....oWWWWWWkkkWWWWWWWWkkkWWWWWWWwwwoo..........",
    "......owwwwwwwwwwwwwwwwwwwwwwwwwwoo.............",
    ".......ooooooooooooooooooooooooooo..............",
], P_SNAKE)

# Zone 4 - Cerf rusa irradié : cerf brun, bois luisant de vert
P_DEER = merge(OUTLINE, TOX, {
    "b": (132, 96, 62), "B": (162, 126, 86), "d": (92, 64, 42), "l": (196, 170, 130), "k": (46, 34, 26),
})
save("boss_deer", [
    ".....oF...oF.oF...oF............................",
    "....oFF..oFF.oFF..oFF...........................",
    "....oFFoooFF.oFFoooFF...........................",
    ".....oFFFFo...oFFFFo............................",
    "......oFFo.....oFFo.............................",
    ".......oFFo...oFFo..............................",
    "........oFFoooFFo...............................",
    ".........oFFFFFo................................",
    "..........obbbo.................................",
    ".........obbbbbo................................",
    "........obbnEbbbo...............................",
    "........obbbbbbbbo..............................",
    "........obbbbllbbbo.............................",
    ".........obbbbllbbo.............................",
    ".........obbbbbbbboooooooooooooooooo............",
    ".........obbbbbbbbBBBBBBBBBBBBBBBBBBoo..........",
    "..........obbbbbbBBBBVVBBBBBBBBBBBBBBBo.........",
    "..........obbbbbBBBBBVVVBBBBBBBBVVBBBBBo........",
    "...........obbbbbbbbbbbbbbbbbbbbbVbbbbbo........",
    "...........obbbbbbbbbbbbbbbbbbbbbbbbbbbbo.......",
    "............odbbbbbbbbbbbbbbbbbbbbbbbbbbo.......",
    "............odbbbbbbbbbbbbbbbbbbbbbbbbbo........",
    ".............oddddddddddddddddddddddddo.........",
    ".............odddoooddddddddddoooddddo..........",
    ".............oddo..oddo....oddo..oddo...........",
    ".............oddo..oddo....oddo..oddo...........",
    ".............oddo..oddo....oddo..oddo...........",
    ".............oddo..oddo....oddo..oddo...........",
    ".............okko..okko....okko..okko...........",
    ".............oooo..oooo....oooo..oooo...........",
], P_DEER)

# Zone 5 - Roussette alpha : chauve-souris géante, membranes veinées, crocs
save("boss_bat", [
    "oo..............................................oo",
    "owoo..........................................oowo",
    "owWwoo......................................oowWwo",
    ".owWWwoo..................................oowWWwo.",
    ".owWWWVwoo..............................oowVWWWwo.",
    "..owWWWWVwoo..........oooooo..........oowVWWWWwo..",
    "..owWWWWWVVwoo.......offffffo.......oowVVWWWWWwo..",
    "...owWWWWWWWVwoo....oFffffffFo....oowVWWWWWWWwo...",
    "...owWWWWWWWWWwoo..ofFffffffFfo..oowWWWWWWWWWwo...",
    "....owWWWWWWWWWWwooofffnEffnEfffooowWWWWWWWWWwo....",
    "....owWWWWWWWWWWWwoofffffffffffffoowWWWWWWWWWWwo....",
    ".....owWWWWWWVWWWwooffffffffffffoowWWWVWWWWWWwo.....",
    "......owWWWWWVVWWwoofmfffffffmffoowWWVVWWWWWwo......",
    ".......oowWWWWWWWwooffffffffffffoowWWWWWWWwoo.......",
    ".........oowWWWWWwoofFffffffffFfoowWWWWWwoo.........",
    "...........oowWWWwooofffffffffFfoowWWWwoo...........",
    ".............oowWWwoofffffffffffoowWWwoo.............",
    "...............oowWwoFfffffffffFowWwoo...............",
    ".................oowoofffffffffoowoo.................",
    "...................oo.oFfffffffFo.oo.................",
    "......................ofFfffffFfo....................",
    ".......................offfffffo.....................",
    "........................oFfffFo......................",
    ".........................offfo.......................",
    "..........................ooo........................",
], P_BAT)

# ================================================================ TUILES ET DÉCOR
P_TILE = merge(OUTLINE, {
    "g": (110, 160, 60), "G": (80, 120, 45), "d": (150, 100, 60), "D": (120, 78, 46), "r": (90, 60, 40),
})
save("tile_ground", [
    "gGggGgggGggGgggG",
    "GgggGgGggGgggGgg",
    "oddddddddddddddo",
    "dDddddDdddddDddd",
    "ddddDdddddrdddDd",
    "dDdddddDddddddDd",
    "ddddrdddddDddddd",
    "dDddddddddddDddd",
    "ddddddDdddrddddd",
    "dDdddddddDdddddd",
    "ddrdddDddddddDdd",
    "dDddddddddddDddd",
    "ddddDddddrdddddd",
    "dDdddddddddddDdd",
    "ddddddDddDdddddd",
    "oooooooooooooooo",
], P_TILE)

save("tile_platform", [
    "gGggGgggGggGgggG",
    "GgggGgGggGgggGgg",
    "oddddDddddDdddDo",
    "oDdddddDddddddDo",
    "oddDddddddrddddo",
    ".oooooooooooooo.",
], P_TILE)

save("rock", [
    "....oooooooo....",
    "..ooRRRRRRRRoo..",
    ".oRRrrRRRRRrRRo.",
    "oRRrRRRRRrRRRRRo",
    "oRRRRRRrRRRRRrRo",
    "oRrRRRRRRRRrRRRo",
    "oRRRRrRRRRRRRRRo",
    ".oRRRRRRrRRRRRo.",
    "..ooRRRRRRRRoo..",
    "....oooooooo....",
], {"R": (130, 125, 120), "r": (100, 95, 92), "o": (50, 45, 42)})

save("ore_crystal", [
    ".....oo.....",
    "....oFFo....",
    "...oFYYFo...",
    "..oFYYYYFo..",
    ".oFFYYYYFFo.",
    ".oFFYVVYFFo.",
    "..oFVVVVFo..",
    "...oVVVVo...",
    "....oVVo....",
    ".....oo.....",
], merge(TOX, {"o": (16, 12, 18)}))

save("toxic_drop", [
    "..oo..",
    ".oFFo.",
    "oFFYFo",
    "oFYYFo",
    ".oFFo.",
    "..oo..",
], merge(TOX, {"o": (16, 12, 18)}))

save("hit_spark", [
    "..o..",
    ".oYo.",
    "oYWYo",
    ".oYo.",
    "..o..",
], {"Y": (250, 230, 60), "W": (255, 255, 255), "o": (255, 160, 40)})

# ---------------------------------------------------------------- planche de contrôle
SCALE = 4
PAD = 8
cols = 5
rows_imgs = [GENERATED[i:i + cols] for i in range(0, len(GENERATED), cols)]
cell_w = max(im.width for _, im in GENERATED) * SCALE + PAD
cell_h = max(im.height for _, im in GENERATED) * SCALE + PAD
sheet = Image.new("RGBA", (cols * cell_w, len(rows_imgs) * cell_h), (40, 44, 52, 255))
for r, row in enumerate(rows_imgs):
    for c, (name, im) in enumerate(row):
        big = im.resize((im.width * SCALE, im.height * SCALE), Image.NEAREST)
        sheet.paste(big, (c * cell_w + PAD // 2, r * cell_h + PAD // 2), big)
sheet.save(os.path.join(OUT, "_preview.png"))
print("Planche : assets/sprites/_preview.png")
print("Terminé.")
