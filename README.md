# Gardiens du Caillou

Plateformer 2D pixel art de survie par vagues, situé à Kouaoua (Nouvelle-Calédonie).
Moteur : **Godot 4.7** (rendu *Compatibility* pour tourner sur les PC modestes).

## Lancer le jeu

Ouvrir le dossier `gardiend-du-caillou` avec Godot 4.7 et appuyer sur *Lancer* (F5).
En ligne de commande : `Godot.exe --path .`

## Commandes

| Action | Clavier | Manette |
|---|---|---|
| Se déplacer | Q / D ou ← → | Stick gauche / croix |
| Sauter (double saut une fois débloqué) | Espace, Z, ↑ | A |
| Coup de lance (corps à corps) | J, X, clic gauche | X |
| Lancer de javelot (recharge 2 s, transperce 2 mutants) | K, C, clic droit | Y |
| Pause | Échap | Start |

Les touches sont physiques : Q/D fonctionne sur AZERTY comme sur QWERTY.

## Boucle de jeu

1. Le joueur arrive dans une zone fermée (carte de 1920 px, murs invisibles).
2. Cinq vagues de mutants arrivent par les bords. Chaque vague nettoyée donne un **buff mineur** (dégâts, vitesse, PV max ou soin) et rend un quart des PV.
3. Après la 5e vague, le **boss de zone** apparaît (attaque spéciale, phase enragée sous 50 % de PV).
4. Boss vaincu : choix d'une **amélioration permanente** parmi trois, sauvegarde, déblocage de la zone suivante.
5. Mort : réapparition au centre avec PV pleins, la vague ou le boss en cours recommence.

## Zones, mutants et boss

| Zone | Décor | Mutants | Boss |
|---|---|---|---|
| 1 | Forêt sèche de niaoulis | Gecko, cochon sauvage | Cagou colossal (saut écrasant) |
| 2 | Mangrove | Crabe, gecko, roussette | Crabe de cocotier titanesque (appelle des sbires) |
| 3 | Plage | Crabe, roussette, gecko | Tricot rayé abyssal (crache des gouttes toxiques) |
| 4 | Mine de nickel | Cochon, gecko, roussette, crabe | Cerf rusa irradié (charge) |
| 5 | Port de Kouaoua | Tous | Roussette alpha (volante, tempête toxique + sbires) |

La contamination se voit dans les décors : teinte, voile coloré et particules toxiques croissent de zone en zone.

## Structure du projet

```
project.godot            configuration, actions d'entrée, autoload GameState
scenes/
  main_menu.tscn         menu principal (histoire, sauvegarde)
  zone_select.tscn       choix de zone avec déblocage progressif
  game.tscn              scène de jeu (le niveau est construit par game.gd)
  hud.tscn               interface en jeu (PV, javelot, vagues, buffs, boss, pause, améliorations)
  player.tscn / enemy.tscn / boss.tscn
scripts/
  game_state.gd          progression, améliorations, buffs, sauvegarde JSON (user://gardiens_save.json)
  zone_data.gd           données des ennemis, boss, zones, composition des vagues, difficulté
  game.gd                construction de la zone, parallax, vagues, boss, mort/réapparition
  player.gd              déplacement, saut, lance, javelot, PV
  enemy.gd / boss.gd     IA simple (poursuite, saut, charge, vol), étourdissement, attaques spéciales
  javelin.gd / toxic_drop.gd   projectiles
  fx.gd                  petits effets (étincelles, textes flottants)
assets/
  sprites/               PNG générés par tools/gen_sprites.py (+ _preview.png)
  backgrounds/           bandes de décor par zone, découpées depuis bg.png
  ui/                    thème et écran titre
tools/gen_sprites.py     dessine les sprites en ASCII et génère les PNG (python + Pillow)
tests/autotest.tscn      test automatique d'une zone complète
```

## Équilibrage

Les valeurs se règlent dans `scripts/zone_data.gd` (PV, vitesse, dégâts des mutants et boss,
nombre d'ennemis par vague, multiplicateur de difficulté) et `scripts/game_state.gd`
(statistiques de base du joueur, recharge du javelot). Les vitesses des mutants restent
volontairement inférieures à celle du joueur (170 px/s).

## Tests automatiques

```
Godot.exe --headless --path . res://tests/autotest.tscn
GDC_ZONE=3 Godot.exe --headless --path . res://tests/autotest.tscn
```

Le test enchaîne : intro, vague 1, dégâts et invulnérabilité, lancer de javelot, 5 vagues,
boss, mort et réapparition, victoire, choix d'amélioration, sauvegarde et rechargement.
Avec `GDC_SHOTS=<dossier>` et sans `--headless`, il enregistre aussi des captures d'écran.

## Regénérer les sprites

```
pip install pillow
python tools/gen_sprites.py
```

Chaque sprite est un dessin ASCII (une lettre = une couleur de palette, `.` = transparent).
