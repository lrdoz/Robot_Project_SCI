breed [ walls wall]
walls-own [first-end second-end]

to setup
  ca
  reset-ticks
  set-default-shape walls "line"
  crt 1 [ setxy 4 0]
  ask turtles [facexy 0 0]

  ;;color all cones in radius blue by default
  let dist 10
  let angle 30
  ask turtles [ ask patches in-cone dist angle [set pcolor blue]]

  ;; place a wall down...the line of sight is blocked (keyword: line)
  create-walls 1 [ setxy 0 0 ]
  ;;This is an interpretation of a wall. Two points that define the edges.
  ask wall 1 [set size 10]
  ask wall 1 [set first-end (list 0 (size / 2))]
  ask wall 1 [set second-end (list 0 (-1 * size / 2))]
  ;;my wall is vertical. You can do trig above and below to adjust for not vert lines.
  ask wall 1 [ set heading 0]
  ask wall 1 [set color hsb  216 50 100] ;;pretty blue =)

  ask turtle 0 [ ask in-sight dist angle [ set pcolor green]]
end

;;a turtle can see a patch if the line from the patch to the turtle isn't intersected by a wall.
to-report in-sight [dist angle]
  let turtle-x xcor
  let turtle-y ycor
  report patches in-cone dist angle with 
  [
    not any? walls with [intersects [pxcor] of myself [pycor] of myself turtle-x turtle-y  ;; line 1
                                   (first first-end) (last first-end) (first second-end) (last second-end)] ;; line 2
  ]
end
;; See http://stackoverflow.com/questions/3838329/how-can-i-check-if-two-segments-intersect
;;counter clockwise method (doesn't consider colinearity)
to-report counter-clockwise [x1 y1 x2 y2 x3 y3]
  ;;returns true if triplet creates counter clockwise angle (uses slopes)
  ;(C.y-A.y) * (B.x-A.x) > (B.y-A.y) * (C.x-A.x)
  report (y3 - y1) * (x2 - x1) > (y2 - y1) * (x3 - x1)
end

to-report intersects [x1 y1 x2 y2 x3 y3 x4 y4]
  ;;line 1: x1 y1 x2 y2
  ;;line 2: x3 y3 x4 y4
  ;;DANGER: Doesn't work for colinear segments!!!
  ;ccw(A,C,D) != ccw(B,C,D) and ccw(A,B,C) != ccw(A,B,D)
  report (counter-clockwise x1 y1 x3 y3 x4 y4) != (counter-clockwise x2 y2 x3 y3 x4 y4)
  and (counter-clockwise x1 y1 x2 y2 x3 y3) != (counter-clockwise x1 y1 x2 y2 x4 y4)
end
