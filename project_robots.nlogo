breed [robots robot]
breed [wastes waste]
breed [buckets bucket]
extensions [array]

globals [ max-dist table-size sleep-var]
patches-own [dist repulsion dist-nuts dist-trees wall robots-know]
robots-own [pocket index goal]


;; récupérer les turtles dans un rayon : turtles in-radius 3

to setup
  __clear-all-and-reset-ticks
  ask patches with [ (abs pxcor = max-pxcor) or (abs pycor = max-pycor) ]
    [ set pcolor black set wall 1 ]


  set table-size ifelse-value ("coop-av-coord" = comportement or "coop-ss-coord" = comportement) [1] [nb-robots]

  ;; Génère des points aléatoire
  if add-wall?[
    ask n-of 100 patches with [ not any? neighbors with [wall = 1]]
    [ set pcolor black set wall 1 ]

    ;; Cherche les points aléatoire et les grossis
    repeat 100
    [ ask one-of patches with [ (wall = 1) and (count neighbors4 with [wall = 1] < 2) ]
      [ask one-of neighbors4 with [ no-wall? ] [ set pcolor black set wall 1 ]]
    ]
  ]
  ;; On stock les listes de vision dans les patches
  ask patches with [no-wall?][
    set robots-know array:from-list n-values table-size [0]
  ]

  ask patches with [wall?][
    set robots-know array:from-list n-values table-size [1]
  ]

  ;; Place les robots
  create-robots nb-robots [ init-robot ]

  ;;Places les déchets
  create-wastes nb-dechets [ init-waste]

  create-buckets nb-buckets [ init-bucket]

  ask robots [move-to one-of buckets]
  propagate
end

to init-robot
  set shape "squirrel"
  set color 36
  set hidden? true
  set index ifelse-value ("coop-av-coord" = comportement or "coop-ss-coord" = comportement) [0] [who]
  set goal nobody
  move-to one-of patches with [no-wall?]
end


to init-waste
  set shape "acorn"
  set color 23
  set hidden? true
  move-to one-of patches with [no-wall?]
end

to init-bucket
  set shape "tree pine"
  set color 61
  set size 2
  set hidden? true
  move-to one-of patches with [no-wall?]
end


to go
  ifelse any? robots [
    ask robots [choose-move]
    propagate
    tick
  ]
  [
    ask patches with [pxcor = (- sleep-var) or pxcor = sleep-var][set pcolor black]
    ask buckets [die]
    ask patch 0 0  [set plabel-color white set plabel "Good Night !" ]
    set sleep-var sleep-var + 1
    tick
  ]
end

to-report voisins
  report ifelse-value neighbors4? [neighbors4] [neighbors]
end

to-report black-sq?
  report pcolor = black
end

to show-label
  ask patches with [no-wall?]
    [ set plabel-color red
      if (show-dist = "dist")
      [set plabel array:item dist (0)]
      if (show-dist = "nuts")
      [set plabel array:item dist-nuts (0)]
      if (show-dist = "trees")
      [set plabel array:item dist-trees (0)]
      if (show-dist = "label")
      [set plabel array:item robots-know (0)]
      if (show-dist = "repulsion")
      [set plabel array:item repulsion (0)]
      if (show-dist = "null")
      [set plabel ""]
  ]
end

to propagate
  ask patches
  ;; ici pour stocker le tableau des cases de chaque agent
  [set dist array:from-list n-values table-size [-1]
    set dist-nuts array:from-list n-values nb-robots [-1]
    set dist-trees array:from-list n-values nb-robots [-1]
    set repulsion array:from-list n-values nb-robots [0]
  ]

  if-else ("coop-av-coord" = comportement or "coop-ss-coord" = comportement) and any? robots
    [ask robots [choose-propagate]]
  [ask robots [choose-propagate]]

  show-label
end

to choose-propagate
  let ind index
  let p patches with [hide-patch? ind]
  propagate-robot p ind

  set p patches with [buckets-patch? ind] ;; c'est ici qu'on doit changer pour le coop/solitaire
  propagate-robot-tree p ind

  ifelse ("coop-av-coord" = comportement)
  [
    ;; Répulsion si on est en phase d'exploration, sinon rien
    if unfinished?
       [
          let friends (robots with [myself != self])
          repulse-propagate friends who
       ]
    set p goal
  ]
  [set p patches with [nuts-patch? ind]] ;; c'est ici qu'on doit changer pour le coop/solitaire

  set ind who
  if (p != nobody) [propagate-robot-nuts p ind]
end

to repulse-propagate [p ind]
  let r repulsion-effect
  while [ (any? p) and (r > 0) ]
    [ ask p [(array:set repulsion ind r)]
      set r r - 1
      set p (patch-set [ voisins with [no-wall? and (array:item repulsion ind < r)]] of p)
    ]
end

;; PROPAGATE
to propagate-robot [p ind]
  let d 0
  while [ any? p ][
    ask p [(array:set dist ind d)]
    set d d + 1
    set p (patch-set [ voisins with [no-wall? and (((array:item dist ind) = -1) or ((array:item dist ind) > d))]] of p)
  ]
end

to propagate-robot-nuts [p ind]
  let d 0
  while [ any? p ][
    ask p [(array:set dist-nuts ind d)]
    set d d + 1
    set p (patch-set [ voisins with [no-wall? and (((array:item dist-nuts ind) = -1) or ((array:item dist-nuts ind) > d))]] of p)
  ]
end

to propagate-robot-tree [p ind]
  let d 0
  while [ any? p ][
    ask p [(array:set dist-trees ind d)]
    set d d + 1
    set p (patch-set [ voisins with [no-wall? and (((array:item dist-trees ind) = -1) or ((array:item dist-trees ind) > d))]] of p)
  ]
end

to choose-move
  set hidden? false
  if-else unfinished? [uncover] [pick-up]
end

to uncover
  let ind index
  let my-index who
  let v (voisins with [no-wall?])

  move-to min-one-of v [(array:item dist ind) + (array:item repulsion  my-index)]

  ask patches in-cone perception 360 with [no-wall? and hide-patch? ind]
    [(array:set robots-know ind 1)
      set pcolor ifelse-value ("coop-av-coord" = comportement or "coop-ss-coord" = comportement)
      [white]
      [scale-color white (sum(array:to-list robots-know)) 0 nb-robots]]
  ;;
  ask patches in-cone perception 360 with [wall?] [set pcolor 32]
  ask buckets in-cone perception 360 with [no-wall?] [set hidden? false (array:set robots-know ind 3)]
  ask wastes in-cone perception 360 with [no-wall? and not dist-neg? ind] [set hidden? false (array:set robots-know ind 2)]
end

to pick-up
  let ind index
  let v (voisins with [no-wall?])

  let p patches with [nuts-patch? ind]

  ;; Si plus de noisette
  ifelse not any? p and goal = nobody
  [
    move-to min-one-of v [(array:item dist-trees ind)]
    sleep-robot
  ]
  [ ;; Si il ne peut plus prendre de noisette on l'envoie sur une pouvelle, sinon on va sur son objectif
    ifelse (pocket < max-nuts)
    [set ind who move-to min-one-of v [(array:item dist-nuts ind)] set ind index];
    [move-to min-one-of v [(array:item dist-trees ind)]]

    consume

    ifelse ("coop-av-coord" = comportement or "coop-ss-coord" = comportement) [
      set p patches with [nuts-patch? ind]
      if (goal = nobody and any? p and "coop-av-coord" = comportement)
      [
        ;;
        set goal n-of 1 (p)
        ;; On reset la case actuel
        ask goal [array:set robots-know ind 1]
      ]

    ]
    [
      ;; Mise à jour des cases si pas en opératif
      ask patches in-cone perception 360 with [nuts-patch? ind]
      [(array:set robots-know ind 1)]
      ask wastes in-cone perception 360 with [no-wall?] [(array:set robots-know ind 2)]
    ]

  ]

end

to sleep-robot
  if any? buckets-here
  [die]
end

to consume
  let ind index
  let tmp nobody

  ;; Si il a un objectif on le récupère
  if goal != nobody[
    set tmp one-of goal
  ]

  ;; Si on est en copération, on regarde si la case actuelle est son objectif, sinon on regarde si il y a une noisette
  let condition ifelse-value not ("coop-av-coord" = comportement)
   [any? wastes-here]
   [tmp = patch-here]

  ;; Si il peut encore porter une noisette, et que la case actuelle comporte une noisette ou est son objectif
  if pocket < max-nuts and condition
  [ set pocket pocket + 1
    ask wastes-here [die]
    ask patch-here [(array:set robots-know ind 1)]
  ]

  ;; Si il est sur un poubelle on le vide
  if pocket >= 1 and any? buckets-here
  [ set pocket 0
    set goal nobody
  ]
end

to-report unfinished?
  let ind index
  let p (patches with [not ((array:item dist ind) = -1)])
  report (any? p)
end

to-report hide-patch? [ind]
  report array:item robots-know ind = 0
end

to-report dist-neg?[ind]
 report (array:item dist ind = -1)
end

to-report discover-patch? [ind]
  report array:item robots-know ind != 0
end

to-report nuts-patch? [ind]
  report array:item robots-know ind = 2
end

to-report buckets-patch? [ind]
  report array:item robots-know ind = 3
end

to-report no-wall?
  report wall != 1
end

to-report wall?
  report wall = 1
end

;;to-report wastes?
;;  report waste > 0
;;end
@#$#@#$#@
GRAPHICS-WINDOW
485
22
1033
571
-1
-1
16.364
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
22
26
88
59
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
25
77
88
110
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
15
334
149
367
neighbors4?
neighbors4?
0
1
-1000

SLIDER
9
228
181
261
perception
perception
1
50
3.0
1
1
NIL
HORIZONTAL

SLIDER
7
182
179
215
nb-robots
nb-robots
1
100
2.0
1
1
NIL
HORIZONTAL

SWITCH
12
383
135
416
add-wall?
add-wall?
0
1
-1000

SLIDER
216
179
388
212
nb-dechets
nb-dechets
0
100
5.0
1
1
NIL
HORIZONTAL

CHOOSER
210
325
348
370
show-dist
show-dist
"dist" "nuts" "trees" "label" "repulsion" "null"
5

PLOT
1325
48
1525
198
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [discover-patch? 0]"

CHOOSER
204
378
355
423
comportement
comportement
"egoiste" "coop-ss-coord" "coop-av-coord"
2

SLIDER
211
273
383
306
repulsion-effect
repulsion-effect
0
100
8.0
1
1
NIL
HORIZONTAL

BUTTON
175
41
302
74
hidde agents
ask wastes [set hidden? true]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
176
85
341
118
not hidden agents
ask wastes [set hidden? false]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
214
229
386
262
max-nuts
max-nuts
1
100
8.0
1
1
NIL
HORIZONTAL

SLIDER
9
270
181
303
nb-buckets
nb-buckets
1
100
4.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

acorn
false
0
Polygon -7500403 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

garbage can
false
0
Polygon -16777216 false false 60 240 66 257 90 285 134 299 164 299 209 284 234 259 240 240
Rectangle -7500403 true true 60 75 240 240
Polygon -7500403 true true 60 238 66 256 90 283 135 298 165 298 210 283 235 256 240 238
Polygon -7500403 true true 60 75 66 57 90 30 135 15 165 15 210 30 235 57 240 75
Polygon -7500403 true true 60 75 66 93 90 120 135 135 165 135 210 120 235 93 240 75
Polygon -16777216 false false 59 75 66 57 89 30 134 15 164 15 209 30 234 56 239 75 235 91 209 120 164 135 134 135 89 120 64 90
Line -16777216 false 210 120 210 285
Line -16777216 false 90 120 90 285
Line -16777216 false 125 131 125 296
Line -16777216 false 65 93 65 258
Line -16777216 false 175 131 175 296
Line -16777216 false 235 93 235 258
Polygon -16777216 false false 112 52 112 66 127 51 162 64 170 87 185 85 192 71 180 54 155 39 127 36

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

squirrel
false
0
Polygon -7500403 true true 87 267 106 290 145 292 157 288 175 292 209 292 207 281 190 276 174 277 156 271 154 261 157 245 151 230 156 221 171 209 214 165 231 171 239 171 263 154 281 137 294 136 297 126 295 119 279 117 241 145 242 128 262 132 282 124 288 108 269 88 247 73 226 72 213 76 208 88 190 112 151 107 119 117 84 139 61 175 57 210 65 231 79 253 65 243 46 187 49 157 82 109 115 93 146 83 202 49 231 13 181 12 142 6 95 30 50 39 12 96 0 162 23 250 68 275
Polygon -16777216 true false 237 85 249 84 255 92 246 95
Line -16777216 false 221 82 213 93
Line -16777216 false 253 119 266 124
Line -16777216 false 278 110 278 116
Line -16777216 false 149 229 135 211
Line -16777216 false 134 211 115 207
Line -16777216 false 117 207 106 211
Line -16777216 false 91 268 131 290
Line -16777216 false 220 82 213 79
Line -16777216 false 286 126 294 128
Line -16777216 false 193 284 206 285

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

tree pine
false
0
Rectangle -6459832 true false 120 225 180 300
Polygon -7500403 true true 150 240 240 270 150 135 60 270
Polygon -7500403 true true 150 75 75 210 150 195 225 210
Polygon -7500403 true true 150 7 90 157 150 142 210 157 150 7

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
