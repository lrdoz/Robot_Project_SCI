turtles-own [ home-pos ]
patches-own [ pellet-grid? ]  ;; true/false: is a pellet here initially?

breed [ pellets pellet ]
pellets-own [ powerup? ]

breed [ bonuses bonus ]
bonuses-own [ value countdown ]

breed [ pacmans pacman ]
pacmans-own  [ new-heading ]

breed [ ghosts ghost ]
ghosts-own  [ eaten? ]

globals [
  level         ;; current level
  score         ;; your score
  lives         ;; remaining lives
  extra-lives   ;; total number of extra lives you've won
  scared        ;; time until ghosts aren't scared (0 means not scared)
  level-over?   ;; true when a level is complete
  dead?         ;; true when Pac-Man is loses a life
  next-bonus-in ;; time until next bonus is created
  tool which-ghost ;; variables needed to properly load levels 4 and above.
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to new  ;; Observer Button
  clear-all
  set level 1
  load-map
  set score 0
  set lives 3
  set extra-lives 0
  set scared 0
  set level-over? false
  reset-ticks
end

to load-map  ;; Observer Procedure
  ;; Filenames of Level Files
  let maps ["pacmap1.csv" "pacmap2.csv" "pacmap3.csv"
            "pacmap4.csv" "pacmap5.csv"]
  let current-score score
  let current-lives lives
  let current-extra-lives extra-lives
  let current-difficulty difficulty

  ifelse ((level - 1) < length maps)
  [ import-world item (level - 1) maps
    set score current-score
    set lives current-lives
    set extra-lives current-extra-lives
    set difficulty current-difficulty
    set dead? false
    ask pacmans
    [ set home-pos list xcor ycor ]
    ask ghosts
    [ set home-pos list xcor ycor ]
  ]
  [ set level 1
    load-map ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Runtime Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to play  ;; Observer Forever Button
  ;; Only true at this point if you died and are trying to continue
  if dead?
  [ stop ]
  every (1 - difficulty / 10)
  [ move-pacman ]
  every 0.25
  [ update-bonuses ]
  if floor (score / 35000) > extra-lives
  [ set lives lives + 1
    set extra-lives extra-lives + 1 ]
  if dead?
  [ ifelse lives = 0
    [ user-message word "Game Over!\nScore: " score ]
    [ set lives lives - 1
      ifelse lives = 0
      [ user-message "You died!\nNo lives left." ]
      [ ifelse lives = 1
        [ user-message "You died!\nOnly 1 life left." ]
        [ user-message (word "You died!\nOnly " lives " lives left.") ]
      ]
      ask pacmans
      [ setxy (item 0 home-pos) (item 1 home-pos)
        set heading 0
      ]
      ask ghosts
      [ setxy (item 0 home-pos) (item 1 home-pos)
        set heading 0
        set shape "ghost"
      ]
      set dead? false
    ]
    stop
  ]
  if level-over?
  [ user-message word "Level Complete!\nScore: " score  ;; \n means start a new line
    set level level + 1
    load-map
    set level-over? false
    stop ]
  every 1.6 * (1 - difficulty / 10)
  [ move-ghosts ]
  every next-bonus-in
  [ make-bonus ]
  display
end

to move-pacman  ;; Observer Procedure
  ask pacmans
  [ ;; move forward unless blocked by wall
    let old-heading heading
    set heading new-heading
    if [pcolor] of patch-ahead 1 != black
    [ set heading old-heading ]
    if [pcolor] of patch-ahead 1 = black
    [ fd 1 ]
    consume
    ;; Level ends when all pellets are eaten
    if not any? pellets
    [ set level-over? true ]
    ;; Animation
    ifelse shape = "pacman"
    [ set shape "pacman open" ]
    [ set shape "pacman" ]
  ]
end

to consume  ;; Pacman Procedure
  ;; Consume Bonuses
  if any? bonuses-here
  [ set score score + sum [value] of bonuses-here
    ask bonuses-here [ die ] ]

  ;; Consume Pellets
  if any? pellets-here
  [ ifelse [powerup?] of one-of pellets-here
    [ set score score + 500
      set scared 40
      ask ghosts
      [ if not eaten?
        [ set shape "scared" ] ]
    ]
    [ set score score + 100 ]
    ask pellets-here [ die ] ]

  ;; Ghosts
  if any? ghosts-here with [not eaten?]
  [ ifelse scared = 0
    [ set dead? true ]
    [ ask ghosts-here with [not eaten?]
      [ set eaten? true
        set shape "eyes"
        set score score + 500 ]
    ]
  ]
end

to update-bonuses  ;; Observer Procedure
  ask bonuses
  [ set heading heading + 13
    set countdown countdown - 1
    if countdown = 0
    [ die ] ]
end

to move-ghosts  ;; Observer Procedure
  ask ghosts
  [ ifelse eaten?
    [ if [pcolor] of patch-at 0 1 = gray
      [ set eaten? false
        set shape "ghost" ]
      return-home
    ]
    [ choose-heading ]
    fd 1
  ]
  if scared > 0
  [ set scared scared - 1
    ifelse scared < 10 and scared mod 2 = 0
    [ ask ghosts with [not eaten?]
      [ set shape "ghost" ] ]
    [ ask ghosts with [not eaten?]
      [ set shape "scared" ] ]
    if scared = 0
    [ ask ghosts with [not eaten?]
      [ set shape "ghost" ]
    ]
  ]
end

to return-home  ;; Ghosts Procedure
  let dirs clear-headings
  let new-dirs remove opposite heading dirs
  let home-dir 0
  if pcolor != gray
    [ set home-dir towards one-of patches with [pcolor = gray] ]
  let home-path 90 * round (home-dir / 90)

  if length new-dirs = 1
  [ set heading item 0 new-dirs ]
  if length new-dirs > 1
  [ ifelse position home-path new-dirs != false
    [ set heading home-path ]
    [ set heading one-of new-dirs ]
  ]
end

to choose-heading  ;; Ghosts Procedure
  let dirs clear-headings
  let new-dirs remove opposite heading dirs
  let pacman-dir false

  if length dirs = 1
  [ set heading item 0 dirs ]
  if length dirs = 2
  [ ifelse see-pacman item 0 dirs
    [ set pacman-dir item 0 dirs ]
    [ ifelse see-pacman item 1 dirs
      [ set pacman-dir item 1 dirs ]
      [ set heading one-of new-dirs ]
    ]
  ]
  if length dirs = 3
  [ ifelse see-pacman item 0 dirs
    [ set pacman-dir item 0 dirs ]
    [ ifelse see-pacman item 1 dirs
      [ set pacman-dir item 1 dirs ]
      [ ifelse see-pacman item 2 dirs
        [ set pacman-dir item 2 dirs ]
        [ set heading one-of new-dirs ]
      ]
    ]
  ]
  if length dirs = 4
  [ ifelse see-pacman item 0 dirs
    [ set pacman-dir item 0 dirs ]
    [ ifelse see-pacman item 1 dirs
      [ set pacman-dir item 1 dirs ]
      [ ifelse see-pacman item 2 dirs
        [ set pacman-dir item 2 dirs ]
        [ ifelse see-pacman item 3 dirs
          [ set pacman-dir item 3 dirs ]
          [ set heading one-of new-dirs ]
        ]
      ]
    ]
  ]
  if pacman-dir != false
  [ ifelse scared = 0
    [ set heading pacman-dir ]
    [ set dirs remove pacman-dir dirs
      set heading one-of dirs
    ]
  ]
end

to-report clear-headings ;; ghosts procedure
  let dirs []
  if [pcolor] of patch-at 0 1 != blue
  [ set dirs lput 0 dirs ]
  if [pcolor] of patch-at 1 0 != blue
  [ set dirs lput 90 dirs ]
  if [pcolor] of patch-at 0 -1 != blue
  [ set dirs lput 180 dirs ]
  if [pcolor] of patch-at -1 0 != blue
  [ set dirs lput 270 dirs ]
  report dirs
end

to-report opposite [dir]
  ifelse dir < 180
  [ report dir + 180 ]
  [ report dir - 180 ]
end

to-report see-pacman [dir] ;; ghosts procedure
  let saw-pacman? false
  let p patch-here
  while [[pcolor] of p = black]
  [ ask p
    [ if any? pacmans-here
      [ set saw-pacman? true ]
      set p patch-at sin dir cos dir ;; next patch in direction dir
    ]
    ;; stop looking if you loop around the whole world
    if p = patch-here [ report saw-pacman? ]
  ]
  report saw-pacman?
end

to make-bonus ;; Observer Procedure
  ifelse next-bonus-in = 0
  [ set next-bonus-in 10 ]
  [ let bonus-patch one-of patches with [pellet-grid? and
                                                not any? bonuses-here and
                                                not any? pellets-here]
    if bonus-patch != nobody
    [ ask bonus-patch
      [ sprout-bonuses 1
        [ set shape "star"
          set heading 0
          set color one-of base-colors
          set value (random 10 + 1) * 100
          set countdown random 200 + 50 ] ]
      set next-bonus-in 5 + random 10 ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Interface Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-up
  ask pacmans [ set new-heading 0 ]
end

to move-right
  ask pacmans [ set new-heading 90 ]
end

to move-down
  ask pacmans [ set new-heading 180 ]
end

to move-left
  ask pacmans [ set new-heading 270 ]
end


; Copyright 2001 Uri Wilensky.
; See Info tab for full copyright and license.
