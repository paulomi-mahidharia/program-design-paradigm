;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname screensaver-4) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))

;; Two rectangles move around at a contant velocity in the scene.
;; The user can pause/unpause the rectangles with the space bar.
;; The user can drag the rectangles to a specific position within the canvas.

(require rackunit)
(require "extras.rkt")

(require 2htdp/universe)
(require 2htdp/image)

(provide
 screensaver
 initial-world
 world-after-tick
 world-after-key-event
 world-after-mouse-event
 rect-after-mouse-event
 new-rectangle
 rect-x
 rect-y
 rect-vx
 rect-vy
 rect-selected?
 rect-after-key-event
 world-rects
 rect-pen-down?
 world-paused?)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DATA DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;

(define-struct myrect (x y vx vy selected? mx my pen?))
;;A Rectangle is a
;;(make-myrect NonNegInt NonNegInt Integer Integer Boolean NonNegInt NonNegInt Boolean)
;;INTERPRETATION:
;;x is the x-coordinate(in pixels) and y is the y-coordinate(in pixels)
;;     such that (x,y) represents the center of the rectangle.
;;vx is the velocity of the center of rectangle in x direction and
;;vy is the velocity of the center of rectangle in y direction
;;selected? describes whether or not the rectangle is selected.
;;mx is the x coordinate determined by the mouse pointer
;;my is the y coordinate determined by the mouse pointer
;;    such that (mx,my) represent the point where mouse is pointing.
;;pen? described whether or not the pen is down.

;; template:
;; myrect-fn : Rectangle -> ??
;(define (myrect-fn r)
;  (... (myrect-x r)
;       (myrect-y r)
;       (myrect-vx r)
;       (myrect-vy r)
;       (myrect-selected? r)
;       (myrect-mx r)
;       (myrect-my r)
;       (myrect-pen? r)
;))

;; ListofRectangles

;; A ListOfRectangles (LOR) is either
;; -- empty
;; -- (cons Rectangle LOR)

;; lor-fn : ListOfRectangles -> ??
;; (define (lor-fn lor)
;;   (cond
;;     [(empty? lor) ...]
;;     [else (...
;;             (myrect-fn (first lor))
;;             (lor-fn (rest lor)))]))

(define-struct world (lor lod paused?))
;; A WorldState is a (make-world LOR Boolean)
;; INTERPRETATION: 
;; LOR is a list of rectangles
;; LOD is a list of pen dots
;; paused? describes whether or not the rectangle is paused.

;; template:
;; world-fn : WorldState -> ??
;(define (world-fn w)
;  (... (world-lor w)
;       (world-lod w)
;       (world-paused? w)))

(define-struct pdots (dx dy))
;;A pdots is (NonNegInt NonNegInt)
;INTERPRETATION:
;dx is the x coordinate of the dot
;dy is the y coordinate of the dot

;; template:
;; pdots-fn : Pendots -> ??
;(define (world-fn w)
;  (... (world-lor w)
;       (world-paused? w)))

;; A ListOfDots (LOD) is either
;; -- empty
;; -- (cons Pendots LOD)

;; lod-fn : ListOfDots -> ??
;; (define (lod-fn lod)
;;   (cond
;;     [(empty? lod) ...]
;;     [else (...
;;             (pdots-fn (first lod))
;;             (lod-fn (rest lod)))]))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;CONSTANTS
;;increase/decrease in velocity
(define INC-VEL 2)
(define DEC-VEL -2)
;;deimensions of rectangle
(define RECT-HEIGHT 50)
(define RECT-WIDTH 60)

(define SEL-COLOR "red")
(define UNSEL-COLOR "blue")
(define RECT (rectangle RECT-WIDTH RECT-HEIGHT "outline" UNSEL-COLOR))

(define RECT-CLICKED (rectangle RECT-WIDTH RECT-HEIGHT "outline" SEL-COLOR))
(define PEN-DOT (circle 1 "solid" "black"))
(define CIRCLE-ON-MOUSE (circle 5 "outline" "red"))
(define VEL-FONT 12)

;;Contants to set collide conditions

(define COLLIDE-NORTH-Y (/ RECT-HEIGHT 2))
(define COLLIDE-WEST-X (/ RECT-WIDTH 2))
(define COLLIDE-SOUTH-Y (- 300 COLLIDE-NORTH-Y))
(define COLLIDE-EAST-X (- 400 COLLIDE-WEST-X))

;; dimensions of the canvas
(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 300)
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;; Initial state of the rectangles
(define UNSEL-NEW-RECT (make-myrect (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) 0 0 false 0 0 #f))
(define SEL-NEW-RECT (make-myrect (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) 0 0 true 0 0 #f))
(define SEL-INITIAL-RECT (make-myrect (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) 0 0 true 0 0 #f))

;;Rectangles for testing
(define UNSEL-RECT-AT-CENTER (make-myrect (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2)
                                          5 -6 false 0 0 #f))
(define SEL-RECT-AT-CENTER (make-myrect (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2)
                                        5 -6 true 0 0 #f))
(define UNSEL-RECT-AT-200-150 (make-myrect 200 150 15 -9 false 0 0 #f))
(define SEL-RECT-AT-200-150 (make-myrect 200 150 15 -9 true 0 0 #f))
(define UNSEL-RECT-AT-200-150-PEN-DOWN (make-myrect 200 150 15 -9 true 0 0 #t))
(define SEL-RECT-AT-200-150-AFTER-BUTTON-DOWN (make-myrect 200 150 15 -9 true 205 145 #t))
(define SEL-NEW-RECT-AFTER-DRAG (make-myrect 405 295 0 0 #true 205 145 #f))
(define UNSEL-NEW-RECT-AFTER-BUTTON-UP (make-myrect 405 295 0 0 #false 205 145 #f))
(define SEL-RECT-AT-CENTER-WITH-DEC-VX (make-myrect 200 150 3 -6 #true 0 0 #f))
(define UNSEL-RECT-AT-CENTER-WITH-INC-VX (make-myrect 200 150 7 -6 #false 0 0 #f))
(define UNSEL-RECT-AT-CENTER-WITH-DEC-VY (make-myrect 200 150 5 -8 #false 0 0 #f))

(define SEL-RECT-AT-CENTER-AFTER-LEFT (make-myrect 200 150 -2 0 #true 0 0 #f))
(define SEL-RECT-AT-CENTER-AFTER-RIGHT (make-myrect 200 150 2 0 #true 0 0 #f))
(define SEL-RECT-AT-CENTER-AFTER-UP (make-myrect 200 150 0 -2 #true 0 0 #f))
(define SEL-RECT-AT-CENTER-AFTER-DOWN (make-myrect 200 150 0 2 #true 0 0 #f))
(define SEL-RECT-AT-CENTER-AFTER-BUTTON-DOWN (make-myrect 200 150 5 -6 #true 205 145 #f))

(define RECT-COLLIDING-NORTH (make-myrect 15 COLLIDE-NORTH-Y -12 -20 #false 0 0 #f))
(define RECT-COLLIDING-SOUTH (make-myrect 15 COLLIDE-SOUTH-Y -12 20 #false 0 0 #f))
(define RECT-COLLIDING-EAST (make-myrect COLLIDE-EAST-X 20 12 20 #false 0 0 #f))
(define RECT-COLLIDING-WEST (make-myrect COLLIDE-WEST-X 15 -12 20 #false 0 0 #f))

(define RECT-NOT-COLLIDING-NORTH (make-myrect 15 COLLIDE-NORTH-Y -12 20 #false 0 0 #f))
(define RECT-NOT-COLLIDING-SOUTH (make-myrect 15 COLLIDE-SOUTH-Y -12 -20 #false 0 0 #f))
(define RECT-NOT-COLLIDING-EAST (make-myrect COLLIDE-EAST-X 20 -12 20 #false 0 0 #f))
(define RECT-NOT-COLLIDING-WEST (make-myrect COLLIDE-WEST-X 15 12 20 #false 0 0 #f))

;;;;Rectangles for testing world-to-scene
(define I-UNSEL-RECT-AT-CENTER (overlay (text "(5,-6)" 12 "blue")
                                        (rectangle RECT-WIDTH RECT-HEIGHT "outline" "blue")))
(define I-SEL-RECT-AT-CENTER (overlay (text "(5,-6)" 12 "red")
                                      (rectangle RECT-WIDTH RECT-HEIGHT "outline" "red")))

;;World for testing
(define PAUSED-EMPTY-WORLD (make-world '() '() #true))
(define UNPAUSED-WORLD-WITH-ONE-RECT
  (make-world (cons UNSEL-RECT-AT-CENTER empty) '() false))
(define PAUSED-WORLD-WITH-ONE-RECT
  (make-world (cons UNSEL-RECT-AT-CENTER empty) '() true))
(define PAUSED-WORLD-WITH-ONE-SEL-RECT
  (make-world (cons (make-myrect 200 150 5 -6 #true 205 145 #f) '()) '() #true))
(define PAUSED-WORLD-WITH-ONE-SEL-RECT-AFTER-DRAG
  (make-world (cons (make-myrect 245 165 5 -6 #true 250 160 #f) '()) '() #true))
(define PAUSED-WORLD-WITH-ONE-RECT-AFTER-BUTTON-UP
  (make-world (cons (make-myrect 200 150 5 -6 #false 205 145 #f) '()) '() #true))
(define UNPAUSED-WORLD-WITH-TWO-RECTS
  (make-world (cons UNSEL-RECT-AT-CENTER (cons UNSEL-RECT-AT-200-150 empty)) '() false))

(define UNPAUSED-WORLD-WITH-ONE-RECT-AFTER-TICK
  (make-world (cons (make-myrect 205 144 5 -6 #false 0 0 #f) '()) '() #false))
(define UNPAUSED-WORLD-WITH-TWO-RECTS-AFTER-TICK
  (make-world (cons (make-myrect 205 144 5 -6 #false 0 0 #f)
                    (cons (make-myrect 215 141 15 -9 #false 0 0 #f) '())) '() #false))
(define WORLD-WITH-NEW-RECT (make-world (cons UNSEL-NEW-RECT '()) '() #true))

;; examples KeyEvents for testing
(define PAUSE-KEY-EVENT " ")
(define NON-PAUSE-KEY-EVENT "q")
(define N "n")
(define LEFT "left")
(define RIGHT "right")
(define UP "up")
(define DOWN "down")
(define PEN-DOWN "d")
(define PEN-UP "u")
(define RANDOM-KEY "p")

;;List of rectangles
(define EMPTY-LOR '())
(define LIST-OF-UNSEL-ONE-RECT (cons UNSEL-RECT-AT-CENTER empty))
(define LIST-OF-UNSEL-RECTS (cons UNSEL-RECT-AT-CENTER (cons UNSEL-RECT-AT-200-150 '())))
(define LIST-WITH-ONE-SEL-RECT (cons SEL-RECT-AT-CENTER (cons UNSEL-RECT-AT-200-150 '())))
(define LIST-WITH-ONE-SEL-RECT-AFTER-LEFT
  (cons SEL-RECT-AT-CENTER-WITH-DEC-VX (cons UNSEL-RECT-AT-200-150 '())))
(define LIST-WITH-TWO-SEL-RECT-AFTER-BUTTON-DOWN
  (cons SEL-RECT-AT-CENTER-AFTER-BUTTON-DOWN
        (cons SEL-RECT-AT-200-150-AFTER-BUTTON-DOWN '())))
(define LOD1 (cons (make-pdots 200 150) empty))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN FUNCTION.

;; screensaver : PosReal -> WorldState
;; GIVEN: the speed of the simulation, in seconds/tick
;; EFFECT: runs the simulation, starting with the initial state as
;; specified in the problem set.
;; RETURNS: the final state of the world
(define (screensaver simulation-speed)
  (big-bang (initial-world 5)
            (on-tick world-after-tick simulation-speed)
            (on-key world-after-key-event)
            (on-draw world-to-scene)
            (on-mouse world-after-mouse-event)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initial-world : Any -> WorldState
;; GIVEN: any value (ignored)
;; RETURNS: the initial world specified in the problem set i.e no rectangles 
;; STATEGY: Call simpler functions
;; EXAMPLE:
;;(initial-world 5)=PAUSED-EMPTY-WORLD
(define (initial-world n)
  (make-world
   empty
   empty
   true))
;;TEST:
(begin-for-test
  (check-equal? (initial-world 5)
                PAUSED-EMPTY-WORLD
                "Initialises world with an empty list of rectangles in paused state"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rect-pen-down? : Rectangle -> Boolean
;; GIVEN: a rectangle
;; RETURNS: true if the pen is down for the given rectangle
;; STATEGY: Use template for Rectangle on r
;; EXAMPLE
;; (rect-pen-down? UNSEL-NEW-RECT)=#f
(define (rect-pen-down? r)
  (myrect-pen? r))
(begin-for-test
  (check-equal? (rect-pen-down? UNSEL-NEW-RECT)
                #f
                "Pen is up i.e not selected"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;; world-after-tick : WorldState -> WorldState
;; RETURNS: the world state that should follow the given world state
;; after a tick.
;; STRATEGY: Use template for WorldState on w
;; EXAMPLES:
;; EXAMPLES:
;;(world-after-tick UNPAUSED-WORLD-WITH-ONE-RECT)
;;    =UNPAUSED-WORLD-WITH-ONE-RECT-AFTER-TICK
;;(world-after-tick PAUSED-WORLD-WITH-ONE-RECT)
;;    =PAUSED-WORLD-WITH-ONE-RECT
;;(world-after-tick UNPAUSED-WORLD-WITH-TWO-RECTS)
;;    =UNPAUSED-WORLD-WITH-TWO-RECTS-AFTER-TICK
(define (world-after-tick w)
  (if (world-paused? w)
      w
      (make-world
       (list-rect-after-tick (world-lor w))
       (list-dots-after-tick (world-lor w)(world-lod w))
       (world-paused? w))))
;;TEST:
(begin-for-test
  (check-equal? (world-after-tick UNPAUSED-WORLD-WITH-ONE-RECT)
                UNPAUSED-WORLD-WITH-ONE-RECT-AFTER-TICK
                "The rectangle moves from (200,150) to (205,144)")
  (check-equal? (world-after-tick PAUSED-WORLD-WITH-ONE-RECT)
                PAUSED-WORLD-WITH-ONE-RECT
                "The rectangle does not move as the world is paused")
  (check-equal? (world-after-tick UNPAUSED-WORLD-WITH-TWO-RECTS)
                UNPAUSED-WORLD-WITH-TWO-RECTS-AFTER-TICK))
;........................................................................
;; list-rect-after-tick: ListOfRectangles -> ListOfRectangles
;; GIVEN: a list of rectangles
;; RETURNS: the list of rectangles that follows the given list of rectangles
;; after a tick.
;; STRATEGY: Use template for ListOfRectangles on lst
;; EXAMPLES:
;; (list-rect-after-tick (cons UNSEL-RECT-AT-200-150 (cons UNSEL-RECT-AT-CENTER '())))
;;     =(cons (make-myrect 215 141 15 -9 #false 0 0 #false)
;;            (cons (make-myrect 205 144 5 -6 #false 0 0 #false) '()))
(define (list-rect-after-tick lst)
  (cond
    [(empty? lst) empty]
    [else (cons (rect-after-tick (first lst))
                (list-rect-after-tick (rest lst)))]))
;TEST
(begin-for-test
  (check-equal? (list-rect-after-tick (cons UNSEL-RECT-AT-200-150 (cons UNSEL-RECT-AT-CENTER '())))
                (cons (make-myrect 215 141 15 -9 #false 0 0 #false)
                      (cons (make-myrect 205 144 5 -6 #false 0 0 #false) '()))
                "Both rectangles change their location based on their respective
                 velocities after one tick"))
;.......................................................................
;; list-dot-after-tick: ListOfRectangles ListOfDots -> ListOfDots
;; GIVEN: a list of rectangles and list of dots
;; RETURNS: the list of dots that follows the given list of dots
;; after a tick.
;; STRATEGY: Use template for ListOfRectangles on lst
;; EXAMPLES:
;; (list-dot-after-tick (cons UNSEL-RECT-AT-200-150 '()) empty))=empty
;; (list-dot-after-tick (cons UNSEL-RECT-AT-200-150-PEN-DOWN '()) empty))
;   =(cons (make-pdots 200 150) '())
(define (list-dots-after-tick lor lod)
  (cond
    [(empty? lor) lod]
    [else (list-dots-after-tick (rest lor)
                                (dots-after-tick (first lor) lod))]))
(begin-for-test
  (check-equal? (list-dots-after-tick (cons UNSEL-RECT-AT-200-150 '()) empty)
                empty
                "the rectangle has pen up. So no dots are placed")
  (check-equal? (list-dots-after-tick (cons UNSEL-RECT-AT-200-150-PEN-DOWN '()) empty)
                (cons (make-pdots 200 150) '())
                "The dot is added to the list as for the given rectangle pen is down"))
;;.......................................................................
;; dots-after-tick : Rectangle -> Rectangle
;; Given: a rectangle and a list of dots
;; RETURNS: a list of dots for the given rectangle after a tick
;; STRATEGY: Use template for myrect on r
(define (dots-after-tick r lod)
  (if (myrect-pen? r)
      (cons (make-pdots (myrect-x r) (myrect-y r)) lod)
      lod))
;........................................................................
;; rect-after-tick : Rectangle -> Rectangle
;; Given: rectangle 1
;; RETURNS: the state of the given rectangle 1 after a tick in an unpaused world
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;;(rect-after-tick UNSEL-RECT-AT-CENTER)=(make-myrect 205 144 5 -6 #false 0 0 #false)
;;(rect-after-tick SEL-RECT-AT-CENTER)=SEL-RECT-AT-CENTER
(define (rect-after-tick r)
  (if (myrect-selected? r)
      r
      (make-myrect
       (rect-collides-x? r)
       (rect-collides-y? r)
       (update-rect-vx r)
       (update-rect-vy r)
       (myrect-selected? r)
       0
       0
       (myrect-pen? r))))
;TESTS:
(begin-for-test
  (check-equal? (rect-after-tick UNSEL-RECT-AT-CENTER)
                (make-myrect 205 144 5 -6 #false 0 0 #false)
                "The rectangle moves by the specifies velocity after one tick")
  (check-equal? (rect-after-tick SEL-RECT-AT-CENTER)
                SEL-RECT-AT-CENTER
                "The rectangle is hold by mouse and hence it does not move to next step
                 by the specified velocity"))

;.................................................................................
;; HELPER FUNCTIONS for rect-after-tick
;.................................................................................

;; rect-collides-x? : Rectangle -> NonNegInt
;; GIVEN: a rectangle to be moved at next tick
;; RETURNS: the boundry x-coordinate if the rectangle collides the wall
;;          otherwise the next x-coordinate based on velocity
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;; (rect-collides-x? RECT-COLLIDING-WEST)=COLLIDE-WEST-X
;; (rect-collides-x? RECT-NOT-COLLIDING-WEST)=42
;; (rect-collides-x? RECT-NOT-COLLIDING-EAST)=358
;; (rect-collides-x? RECT-COLLIDING-EAST)=COLLIDE-EAST-X
(define (rect-collides-x? r)
  (cond
    [(<= (+ (myrect-x r) (myrect-vx r)) COLLIDE-WEST-X) COLLIDE-WEST-X]
    [(>= (+ (myrect-x r) (myrect-vx r)) COLLIDE-EAST-X) COLLIDE-EAST-X]
    [else (+ (myrect-x r) (myrect-vx r))]))
;TESTS:
(begin-for-test
  (check-equal? (rect-collides-x? RECT-COLLIDING-WEST)
                COLLIDE-WEST-X
                "The rectangle goes beyond the west wall in next tick. So set
                 x-coordinate to west boundry coordinate")
  (check-equal? (rect-collides-x? RECT-NOT-COLLIDING-WEST)
                42
                "The rectangle does not go beyond the west wall in next tick.
                So set x-coordinate by adding the velocity.")
  (check-equal? (rect-collides-x? RECT-NOT-COLLIDING-EAST)
                358
                "The rectangle does not go beyond the east wall in next tick.
                So set x-coordinate by adding the velocity.")
  (check-equal? (rect-collides-x? RECT-COLLIDING-EAST)
                COLLIDE-EAST-X
                "The rectangle goes beyond the east wall in next tick. So set
                 x-coordinate to east boundry coordinate"))      
;........................................................................
;; rect-collides-y? : Rectangle -> NonNegInt
;; GIVEN: a rectangle to be moved at next tick
;; RETURNS: true if the rectangle collides vertically in y-axis direction
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;; (rect-collides-y? RECT-NOT-COLLIDING-NORTH)=45
;; (rect-collides-y? RECT-COLLIDING-NORTH)=COLLIDE-NORTH-Y
;; (rect-collides-y? RECT-COLLIDING-SOUTH)=COLLIDE-SOUTH-Y
;; (rect-collides-y? RECT-NOT-COLLIDING-SOUTH)=255
(define (rect-collides-y? r)
  (cond
    [(<= (+ (myrect-y r) (myrect-vy r)) COLLIDE-NORTH-Y) COLLIDE-NORTH-Y]
    [(>= (+ (myrect-y r) (myrect-vy r)) COLLIDE-SOUTH-Y) COLLIDE-SOUTH-Y]
    [else (+ (myrect-y r) (myrect-vy r))]))
;TESTS:
(begin-for-test
  (check-equal? (rect-collides-y? RECT-NOT-COLLIDING-NORTH)
                45
                "The rectangle does not go beyond the north wall in next tick.
                So set y-coordinate by adding the velocity.")
  (check-equal? (rect-collides-y? RECT-COLLIDING-NORTH)
                COLLIDE-NORTH-Y
                "The rectangle goes beyond the north wall in next tick. So set
                 y-coordinate to north boundry coordinate")
  (check-equal? (rect-collides-y? RECT-COLLIDING-SOUTH)
                COLLIDE-SOUTH-Y
                "The rectangle goes beyond the south wall in next tick. So set
                 y-coordinate to south boundry coordinate")
  (check-equal? (rect-collides-y? RECT-NOT-COLLIDING-SOUTH)
                255
                "The rectangle does not go beyond the south wall in next tick.
                So set y-coordinate by adding the velocity."))    
;......................................................................
;; update-rect-vx : Rectangle -> Integer
;; Given: a rectangle after the tick
;; RETURNS: the updated velocity of the given rectangle
;;          in the x-axis direction after a tick
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;;(update-rect-vx RECT-COLLIDING-WEST)=12
;;(update-rect-vx RECT-NOT-COLLIDING-WEST)=12
(define (update-rect-vx r)
  (if (or (<= (+ (myrect-x r) (myrect-vx r)) COLLIDE-WEST-X)
          (>= (+ (myrect-x r) (myrect-vx r)) COLLIDE-EAST-X))
      (- 0 (myrect-vx r))
      (myrect-vx r)))
;TESTS:
(begin-for-test
  (check-equal? (update-rect-vx RECT-COLLIDING-WEST)
                12
                "The rectangle collides west wall and hence its x velocity is reversed
                 from -12 to 12")
  (check-equal? (update-rect-vx RECT-NOT-COLLIDING-WEST)
                12
                "The rectangle's x velocity remains same as it does not collide west
                 wall i.e does not change direction"))
;...........................................................................
;; update-rect-vy : Rectangle -> Integer
;; Given: a rectangle after the tick
;; RETURNS: the updated velocity of the given rectangle
;;          in the y-axis direction after a tick
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;;(update-rect-vy RECT-COLLIDING-NORTH)=20
;;(update-rect-vy RECT-NOT-COLLIDING-NORTH)=20
(define (update-rect-vy r)
  (if (or (<= (+ (myrect-y r) (myrect-vy r)) COLLIDE-NORTH-Y)
          (>= (+ (myrect-y r) (myrect-vy r)) COLLIDE-SOUTH-Y)) 
      (- 0 (myrect-vy r))
      (myrect-vy r)))
;TESTS:
(begin-for-test
  (check-equal? (update-rect-vy RECT-COLLIDING-NORTH)
                20
                "The rectangle collides north wall and hence its y velocity is reversed
                 from -20 to 20")
  (check-equal? (update-rect-vy RECT-NOT-COLLIDING-NORTH)
                20
                "The rectangle's y velocity remains same as it does not collide north
                 wall i.e does not change direction"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; world-rects : WorldState -> ListOfRectangles
;; GIVEN: a world state
;; RETURNS: the specified attribute i.e list of rectangles of the WorldState
;; EXAMPLE:
;; (world-rects UNPAUSED-WORLD-WITH-TWO-RECTS)
;; =LIST-OF-UNSEL-RECTS
(define (world-rects w)
  (world-lor w))
;;TEST:
(begin-for-test
  (check-equal? (world-rects UNPAUSED-WORLD-WITH-TWO-RECTS)
                LIST-OF-UNSEL-RECTS
                "Returns the list of rectangles in the given world"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; world-after-key-event : WorldState KeyEvent -> WorldState
;; GIVEN:  a World State and a Keyevent
;; RETURNS: the World State that should follow the given world state
;;          after the given keyevent
;; STRATEGY: Dividing cases for Keyevent on kev
;; EXAMPLES:
;;(world-after-key-event UNPAUSED-WORLD-WITH-ONE-RECT PAUSE-KEY-EVENT)
;;   =PAUSED-WORLD-WITH-ONE-RECT
;;(world-after-key-event UNPAUSED-WORLD-WITH-ONE-RECT NON-PAUSE-KEY-EVENT)
;;   =UNPAUSED-WORLD-WITH-ONE-RECT
;;(world-after-key-event PAUSED-EMPTY-WORLD "n")
;;   =WORLD-WITH-NEW-RECT
(define (world-after-key-event w kev)
  (cond
    [(key=? kev " ") (world-with-paused-toggled w)]
    [(key=? kev N) (create-rect w)]
    [else (make-world (list-after-key-event (world-lor w) kev)
                      (world-lod w)
                      (world-paused? w))]))
(begin-for-test
  (check-equal? (world-after-key-event UNPAUSED-WORLD-WITH-ONE-RECT PAUSE-KEY-EVENT)
                PAUSED-WORLD-WITH-ONE-RECT
                "Unpaused world pauses after a valid key event")
  (check-equal? (world-after-key-event UNPAUSED-WORLD-WITH-ONE-RECT NON-PAUSE-KEY-EVENT)
                UNPAUSED-WORLD-WITH-ONE-RECT
                "Invalid key event makes no changes to the world")
  (check-equal? (world-after-key-event PAUSED-EMPTY-WORLD "n")
                WORLD-WITH-NEW-RECT
                "A new rectangle is created after pressing n key"))
;...............................................................................
;; list-after-key-event : ListOfRectangles Keyevent -> ListOfRectangles
;; GIVEN: a list of rectangles and a keyevent
;; RETURNS: list of rectangles following the given keyevent
;; STRATEGY: Use template for ListOfRectangles on lst
;; EXAMPLE:
;; (list-after-key-event EMPTY-LOR LEFT)=EMPTY-LOR
;; (list-after-key-event LIST-OF-UNSEL-RECTS LEFT)=LIST-OF-UNSEL-RECTS
;; (list-after-key-event LIST-WITH-ONE-SEL-RECT LEFT)=LIST-WITH-ONE-SEL-RECT-AFTER-LEFT
(define (list-after-key-event lst kev)
  (cond
    [(empty? lst) empty]
    [else (cons (rect-after-key-event (first lst) kev)
                (list-after-key-event (rest lst) kev))]))
;TESTS:
(begin-for-test
  (check-equal? (list-after-key-event EMPTY-LOR LEFT)
                EMPTY-LOR
                "Any key event on empty list of rectangles returns empty list of rectangles")
  (check-equal? (list-after-key-event LIST-OF-UNSEL-RECTS LEFT)
                LIST-OF-UNSEL-RECTS
                "No changes made as no rectangle is selected")
  (check-equal? (list-after-key-event LIST-WITH-ONE-SEL-RECT LEFT)
                LIST-WITH-ONE-SEL-RECT-AFTER-LEFT
                "Decreases the vx from 5 to 3 i.e decrease by 2 pixels"))
;............................................................................
;; rect-after-key-event : Rectangle Keyevent -> Rectangle
;; GIVEN: a rectangle and a keyevent
;; RETURNS: rectangle after the given keyevent
;; STRATEGY: Use template for ListOfRectangles on lst
;; EXMAPLES:
;; (rect-after-key-event SEL-INITIAL-RECT LEFT)=SEL-RECT-AT-CENTER-AFTER-LEFT
;; (rect-after-key-event SEL-INITIAL-RECT RIGHT)=SEL-RECT-AT-CENTER-AFTER-RIGHT
;; (rect-after-key-event SEL-INITIAL-RECT UP)=SEL-RECT-AT-CENTER-AFTER-UP
;; (rect-after-key-event SEL-INITIAL-RECT DOWN)=SEL-RECT-AT-CENTER-AFTER-DOWN
;;(rect-after-key-event SEL-INITIAL-RECT RANDOM-KEY)=SEL-INITIAL-RECT
(define (rect-after-key-event r kev)
  (if (myrect-selected? r)
      (cond
        [(key=? kev LEFT) (drift-rect-x r -2)]
        [(key=? kev RIGHT) (drift-rect-x r 2)]
        [(key=? kev UP) (drift-rect-y r -2)]
        [(key=? kev DOWN) (drift-rect-y r 2)]
        [(key=? kev PEN-DOWN) (activate-pen r)]
        [(key=? kev PEN-UP) (deactivate-pen r)]
        [else r])
      r)
  )
;TESTS:
(begin-for-test
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT LEFT)
                SEL-RECT-AT-CENTER-AFTER-LEFT
                "vx decreses by 2 pixels")
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT RIGHT)
                SEL-RECT-AT-CENTER-AFTER-RIGHT
                "vx increses by 2 pixels")
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT UP)
                SEL-RECT-AT-CENTER-AFTER-UP
                "vy decrease by 2 pixels")
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT DOWN)
                SEL-RECT-AT-CENTER-AFTER-DOWN
                "vy increses by 2 pixels")
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT PEN-DOWN)
                (make-myrect 200 150 0 0 #true 0 0 #true)
                "vy increses by 2 pixels")
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT PEN-UP)
                (make-myrect 200 150 0 0 #true 0 0 #false)
                "vy increses by 2 pixels")
  (check-equal? (rect-after-key-event SEL-INITIAL-RECT RANDOM-KEY)
                SEL-INITIAL-RECT
                "Not a valid keyevent and hence no change in velocity"))
;...........................................................................
;...........................................................................
;; world-with-paused-toggled : WorldState -> WorldState
;; GIVEN: a world
;; RETURNS: a world with its paused state toggled
;; STRATEGY: Use template for WorldState on w
;; EXAMPLE: 
;; (world-with-paused-toggled UNPAUSED-WORLD-WITH-ONE-RECT)=PAUSED-WORLD-WITH-ONE-RECT
(define (world-with-paused-toggled w)
  (make-world
   (world-lor w)
   (world-lod w)
   (not (world-paused? w))))
;TEST:
(begin-for-test
  (check-equal? (world-with-paused-toggled UNPAUSED-WORLD-WITH-ONE-RECT)
                PAUSED-WORLD-WITH-ONE-RECT
                "Unpaused world pauses and vice-versa i.e it gets toggles"))
;...........................................................................
;; drift-rect-x : Rectangle Integer -> Rectangle
;; GIVEN: a rectangle in an unpaused state and increased/decreased value
;;        in the velocity of that rectangle in x-axis direction
;; RETURNS: the given rectangle with updated velocity
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLE:
;; (drift-rect-x UNSEL-RECT-AT-CENTER INC-VEL)=UNSEL-RECT-AT-CENTER-WITH-INC-VX
(define (drift-rect-x r v)
  (make-myrect
   (myrect-x r)
   (myrect-y r)
   (+ (myrect-vx r) v)
   (myrect-vy r)
   (myrect-selected? r)
   (myrect-mx r)
   (myrect-my r)
   (myrect-pen? r)))
;TEST:
(begin-for-test
  (check-equal? (drift-rect-x UNSEL-RECT-AT-CENTER INC-VEL)
                UNSEL-RECT-AT-CENTER-WITH-INC-VX
                "the vx increases by 2 pixels"))
;...........................................................................
;; drift-rect-y : Rectangle Integer -> Rectangle
;; GIVEN: a rectangle in an unpaused state and increased/decreased value
;;        in the velocity of that rectangle in y-axis direction
;; RETURNS: the given rectangle with updated velocity
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLE:
;; (drift-rect-x UNSEL-RECT-AT-CENTER DEC-VEL)=UNSEL-RECT-AT-CENTER-WITH-DEC-VY
(define (drift-rect-y r v)
  (make-myrect
   (myrect-x r)
   (myrect-y r)
   (myrect-vx r)
   (+ (myrect-vy r) v)
   (myrect-selected? r)
   (myrect-mx r)
   (myrect-my r)
   (myrect-pen? r)))
;...........................................................................
;; create-rect : WorldState -> WorldState
;; GIVEN: a world 
;; RETURNS: a world with a new rectangle created at the center of the canvas
;;          with (0,0) velocity
;; STRATEGY: Use template for WorldState on w
;; EXAMPLE:
;; (create-rect PAUSED-EMPTY-WORLD)=WORLD-WITH-NEW-RECT
(define (create-rect w)
  (make-world
   (cons UNSEL-NEW-RECT (world-lor w))
   (world-lod w)
   (world-paused? w)))
;;TEST:
(begin-for-test
  (check-equal? (create-rect PAUSED-EMPTY-WORLD)
                WORLD-WITH-NEW-RECT
                "A new stationary rectangle is created at the center of the scene"))
;..........................................................................
;; activate-pen: Rectangle -> Rectangle
;; GIVEN: a rectangle
;; RETURNS: a rectangle with pen down
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLE:
;; (activate-pen UNSEL-NEW-RECT)=(make-myrect 200 150 0 0 #false 0 0 #true)
(define (activate-pen r)
  (make-myrect
   (myrect-x r)
   (myrect-y r)
   (myrect-vx r)
   (myrect-vy r)
   (myrect-selected? r)
   (myrect-mx r)
   (myrect-my r)
   #t))
(begin-for-test
  (check-equal? (activate-pen UNSEL-NEW-RECT)
                (make-myrect 200 150 0 0 #false 0 0 #true)
                "Pen is down"))
;..........................................................................
;; deactivate-pen: Rectangle -> Rectangle
;; GIVEN: a rectangle
;; RETURNS: a rectangle with pen up
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLE:(deactivate-pen UNSEL-NEW-RECT)=(make-myrect 200 150 0 0 #false 0 0 #false)
(define (deactivate-pen r)
  (make-myrect
   (myrect-x r)
   (myrect-y r)
   (myrect-vx r)
   (myrect-vy r)
   (myrect-selected? r)
   (myrect-mx r)
   (myrect-my r)
   #f))
(begin-for-test
  (check-equal? (deactivate-pen UNSEL-NEW-RECT)
                (make-myrect 200 150 0 0 #false 0 0 #false)
                "Pen is up"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; world-after-mouse-event : WorldState NonNegInt NonNegInt MouseEvent -> WorldState
;; GIVEN: A world, the x- and y-coordinates of mouse and the mouse event
;; RETURNS: the world that should follow the given world after the given mouse
;; event.
;; STRATEGY: Use template for WorldState on w
;;EXAMPLES:
;;(world-after-mouse-event PAUSED-WORLD-WITH-ONE-RECT 140 60 "button-down")
;; =PAUSED-WORLD-WITH-ONE-RECT
;;(world-after-mouse-event PAUSED-WORLD-WITH-ONE-RECT 205 145 "button-down")
;; =PAUSED-WORLD-WITH-ONE-SEL-RECT
;;(world-after-mouse-event PAUSED-WORLD-WITH-ONE-SEL-RECT 250 160 "drag")
;; =PAUSED-WORLD-WITH-ONE-SEL-RECT-AFTER-DRAG
;;(world-after-mouse-event PAUSED-WORLD-WITH-ONE-SEL-RECT 205 145 "button-up")
;; =PAUSED-WORLD-WITH-ONE-RECT-AFTER-BUTTON-UP
(define (world-after-mouse-event w mx my mev)
  (make-world
   (list-after-mouse-event (world-lor w) mx my mev)
   (world-lod w)
   (world-paused? w)))
;TESTS:
(begin-for-test
  (check-equal? (world-after-mouse-event PAUSED-WORLD-WITH-ONE-RECT 140 60 "button-down")
                PAUSED-WORLD-WITH-ONE-RECT
                "Button down doesnt happen as the mouse coordinates are outside rectangle")
  (check-equal? (world-after-mouse-event PAUSED-WORLD-WITH-ONE-RECT 205 145 "button-down")
                PAUSED-WORLD-WITH-ONE-SEL-RECT
                "After button down, the rectangle is selected")
  (check-equal? (world-after-mouse-event PAUSED-WORLD-WITH-ONE-SEL-RECT 250 160 "drag")
                PAUSED-WORLD-WITH-ONE-SEL-RECT-AFTER-DRAG
                "The rectangle's center changes to the new location after drag and the mouse
                coordinates are saved")
  (check-equal? (world-after-mouse-event PAUSED-WORLD-WITH-ONE-SEL-RECT 205 145 "button-up")
                PAUSED-WORLD-WITH-ONE-RECT-AFTER-BUTTON-UP
                "the rectangle is now unselected and the mouse coordinates are saved"))
;.........................................................................
;; list-after-mouse-event :
;;     ListOfRectangles NonNegInt NonNegInt MouseEvent -> ListOfRectangles
;; GIVEN: A list of rectangles, the x- and y-coordinates of mouse and the mouse event
;; RETURNS: a list of rectangles after the mouse event
;; STRATEGY: Use template for ListOfRectangles on lst
;; EXAMPLE:
;; (list-after-mouse-event EMPTY-LOR 205 150 "button-up")=EMPTY-LOR
;; (list-after-mouse-event LIST-WITH-ONE-SEL-RECT 205 145 "button-down")
;;    =LIST-WITH-TWO-SEL-RECT-AFTER-BUTTON-DOWN
(define (list-after-mouse-event lst mx my mev)
  (cond
    [(empty? lst) empty]
    [else (cons (rect-after-mouse-event (first lst) mx my mev)
                (list-after-mouse-event (rest lst) mx my mev))]))

;..........................................................................
;; rect-after-mouse-event : Rectangle NonNegInt NonNegInt MouseEvent -> Rectangle
;; GIVEN: A rectangle, the x- and y-coordinates of mouse and the mouse event
;; RETURNS: a rectangles after the mouse event
;; STRATEGY: Dividing into cases based on MouseEvent
;; EXAMPLES:
;; (rect-after-mouse-event UNSEL-RECT-AT-CENTER 205 145 "move")=UNSEL-RECT-AT-CENTER
;; (rect-after-mouse-event UNSEL-RECT-AT-CENTER 205 145 "button-down")
;;       =SEL-RECT-AT-CENTER-AFTER-BUTTON-DOWN
(define (rect-after-mouse-event r mx my mev)
  (cond
    [(mouse=? mev "button-down") (rect-after-button-down r mx my)]
    [(mouse=? mev "drag") (rect-after-drag r mx my)]
    [(mouse=? mev "button-up") (rect-after-button-up r mx my)]
    [else r]))
(begin-for-test
  (check-equal? (rect-after-mouse-event UNSEL-RECT-AT-CENTER 205 145 "move")
                UNSEL-RECT-AT-CENTER
                "Invalid mouse event leaves the rectangle unchanged")
  (check-equal? (rect-after-mouse-event UNSEL-RECT-AT-CENTER 205 145 "button-down")
                SEL-RECT-AT-CENTER-AFTER-BUTTON-DOWN
                "selects the rectangle after button bown and stores mouse coordinates"))

;..........................................................................
;; rect-after-button-down : myrect Integer Integer -> myrect
;; GIVEN: a rectangle and x and y coordinates of mouse
;; RETURNS: the rectangle following a button-down at the given location.
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES: see tests below
(define (rect-after-button-down r mx my)
  (if (and (in-rect? r mx my) (not (myrect-selected? r))) 
      (make-myrect (myrect-x r)
                   (myrect-y r)
                   (myrect-vx r)
                   (myrect-vy r)
                   true
                   mx
                   my
                   (myrect-pen? r))
      r))
;TESTS:
(begin-for-test
  (check-equal? (rect-after-button-down UNSEL-RECT-AT-CENTER 250 60)
                UNSEL-RECT-AT-CENTER
                "The mouse coordinates are no inside the rectangle, hence no changes are made")
  (check-equal? (rect-after-button-down UNSEL-RECT-AT-CENTER 205 145)
                SEL-RECT-AT-CENTER-AFTER-BUTTON-DOWN
                "The rectangle gets selected after button-down and mouse coordinates
                 are saved"))
;.....................................................................
;; rect-after-drag : Rectangle NonNegInt NonNegInt -> Rectangle
;; GIVEN: a rectangle and x and y coordinates of mouse
;; RETURNS: the rectangle following a drag at the given location
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;;(rect-after-drag UNSEL-RECT-AT-CENTER 205 145)=UNSEL-RECT-AT-CENTER
;;(rect-after-drag SEL-NEW-RECT 205 145)=SEL-NEW-RECT-AFTER-DRAG
(define (rect-after-drag r mx my)
  (if (myrect-selected? r)
      (make-myrect
       (current-x (myrect-x r) (myrect-mx r) mx)
       (current-y (myrect-y r) (myrect-my r) my)
       (myrect-vx r)
       (myrect-vy r)
       true
       mx
       my
       (myrect-pen? r))
      r))
;TESTS:
(begin-for-test
  (check-equal? (rect-after-drag UNSEL-RECT-AT-CENTER 205 145)
                UNSEL-RECT-AT-CENTER
                "The rectangle is not selected and hence drag cannot be performed")
  
  (check-equal? (rect-after-drag SEL-NEW-RECT 205 145)
                SEL-NEW-RECT-AFTER-DRAG
                "the rectangle moves to specified drag position after drag event"))

;................................................................................
;Helper funtions for drag

;; current-x : NonNegInt NonNegInt NonNegInt Rectangle
;; GIVEN: a rectangle's x-coordinate, previous and current mouse coordinates
;; RETURNS: the rectangle's updated x-coordinates based on mouse drag
;; STRATEGY: Combine simpler functions
;; EXAMPLES:
;; (current-x 200 0 50)=250
;; (current-x 200 0 -50)=150
(define (current-x x pre-mx mx)
  (if (> mx pre-mx) 
      (+ x (distance-to-drag pre-mx mx))
      (- x (distance-to-drag pre-mx mx))))
;TESTS:
(begin-for-test
  (check-equal? (current-x 200 0 50) 250
                "New mouse coordinate is greater than previous one, hence it is added to
                 the x-coordinate of the rectangle")
  (check-equal? (current-x 200 0 -50) 150
                "New mouse coordinate is smaller than previous one, hence it is subtracted
                 from the x-coordinate of the rectangle"))                         
;....................................................................................
;; current-y : NonNegInt NonNegInt NonNegInt -> Rectangle
;; GIVEN: a rectangle's y-coordinate, previous and current mouse coordinates during drag
;; RETURNS: the rectangle's updated y-coordinates based on mouse drag
;; STRATEGY: Combine simpler functions
;; EXMAPLES:
;; (current-y 0 200 150)=-50
;; (current-y 0 150 200)=50
(define (current-y y pre-my my)
  (if(> my pre-my)
     (+ y (distance-to-drag pre-my my))
     (- y (distance-to-drag pre-my my))))

;TESTS:
(begin-for-test
  (check-equal? (current-y 0 200 150) -50
                "New mouse coordinate is smaller than previous one, hence it is subtracted
                 from the y-coordinate of the rectangle")
  (check-equal? (current-y 0 150 200) 50
                "New mouse coordinate is greater than previous one, hence it is added to
                 the y-coordinate of the rectangle"))   
;...................................................................................
;;distance-to-drag: NonNegInt NonNegInt -> NonNegInt
;GIVEN: previous and current mouse coordinates
;RETURNS: distance between them i.e distance the rectangle is dragged
;STRATEGY: Call simpler functions
;EXAMPLES: (distance-to-drag -100 50)=150
;          (distance-to-drag 20 -10)=30
(define (distance-to-drag p n)
  (abs (- n p)))
;...............................................................................
;; rect-after-button-up : myrect Integer Integer -> Rectangle
;; GIVEN: a rectangle and x and y coordinates of mouse
;; RETURNS: the rectangle following a button-up at the given location
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;; (rect-after-button-up SEL-NEW-RECT-AFTER-DRAG 205 145)
;; UNSEL-NEW-RECT-AFTER-BUTTON-UP
(define (rect-after-button-up r mx my)
  (make-myrect (myrect-x r)
               (myrect-y r)
               (myrect-vx r)
               (myrect-vy r)
               false
               (myrect-mx r)
               (myrect-my r)
               (myrect-pen? r))
  )
;TEST
(begin-for-test
  (check-equal? (rect-after-button-up SEL-NEW-RECT-AFTER-DRAG 205 145)
                UNSEL-NEW-RECT-AFTER-BUTTON-UP
                "After button-up, rectangle is unselected anf the mouse coordinates
                 are stored"))
;.............................................................................
;; in-rect? : Rectangle Integer Integer -> Rectangle
;; GIVEN: a rectangle and mouse coordinates
;; RETURNS true iff the given coordinate is inside the bounding box of
;; the given rectangle.
;; STRATEGY: Use template for myrect on r
(define (in-rect? r x y)
  (and
   (>= (+ (myrect-x r) COLLIDE-WEST-X) x)
   (>= (+ (myrect-y r) COLLIDE-NORTH-Y) y)
   (>= y (- (myrect-y r) COLLIDE-NORTH-Y))
   (>= x (- (myrect-x r) COLLIDE-WEST-X))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;..........................................................................
;; new-rectangle : NonNegInt NonNegInt Int Int -> Rectangle
;; GIVEN: 2 non-negative integers x and y, and 2 integers vx and vy
;; RETURNS: a rectangle centered at (x,y), which will travel with
;; velocity (vx, vy) only if unselected
;; STRATEGY: Call simpler function
;; EXMAPLE:
;; (new-rectangle 100 50 12 -10)=(make-myrect 100 50 12 -10)
(define (new-rectangle x y vx vy)
  (make-myrect x y vx vy #false 0 0 #f))
;TEST:
(begin-for-test
  (check-equal? (new-rectangle 100 50 12 -10)
                (make-myrect 100 50 12 -10 #false 0 0 #f)
                "makes a new Rectangle with center at (100,50), velocity (12,-10)
                 which is UNSELECTED and without mouse coordinates"))
;..........................................................................
;..........................................................................
;; rect-x : Rectangle -> NonNegInt
;; GIVEN: a rectangle
;; RETURNS: x-coordinate of the given rectangle
;; STRATEGY: Use template for Rectangle on r
;; EXMAPLE:
;; (rect-x (new-rectangle 100 50 12 -10))=100
(define (rect-x r)
  (myrect-x r))
;TEST:
(begin-for-test
  (check-equal? (rect-x (new-rectangle 100 50 12 -10)) 100 
                "100 is the x-coordinate of the given rectangle"))
;.................................................................................
;; rect-y : Rectangle -> NonNegInt
;; GIVEN: a rectangle
;; RETURNS: y-coordinate of the given rectangle
;; STRATEGY: Use template for Rectangle on r
;; EXMAPLE:
;; (rect-y (new-rectangle 100 50 12 -10))=50
(define (rect-y r)
  (myrect-y r))
;TEST:
(begin-for-test
  (check-equal? (rect-y (new-rectangle 100 50 12 -10)) 50 
                "50 is the x-coordinate of the given rectangle"))
;.....................................................................................
;; rect-vx : Rectangle -> Integer
;; GIVEN: a rectangle
;; RETURNS: the velocity of the center of the given rectangle in x-axis direction
;; STRATEGY: Use template for Rectangle on r
;; EXMAPLE:
;; (rect-vx (new-rectangle 100 50 12 -10))=12
(define (rect-vx r)
  (myrect-vx r))
;TEST:
(begin-for-test
  (check-equal? (rect-vx (new-rectangle 100 50 12 -10)) 12 
                "12 is the velocity of the center of the given rectangle in
                x-axis direction"))
;.....................................................................................
;; rect-vy : Rectangle -> Integer
;; GIVEN: a rectangle
;; RETURNS: the velocity of the center of the given rectangle in y-axis direction
;; STRATEGY: Use template for Rectangle on r
;; EXMAPLE:
;; (rect-vy (new-rectangle 100 50 12 -10))=-10
(define (rect-vy r)
  (myrect-vy r))
;TEST:
(begin-for-test
  (check-equal? (rect-vy (new-rectangle 100 50 12 -10)) -10 
                "-10 is the velocity of the center of the given rectangle in
                y-axis direction"))
;.......................................................................
;; rect-selected? : Rectangle -> Boolean
;; GIVEN: a rectangle
;; RETURNS: true if the given rectangle is selected.
;; STRATEGY: USe template for Rectangle on r
;; EXAMPLE:
; (rect-selected? (make-myrect 100 50 12 -10 #true 0 0))=#true
(define (rect-selected? r)
  (myrect-selected? r))

;TEST
(begin-for-test
  (check-equal? (rect-selected? (make-myrect 100 50 12 -10 #true 0 0 #t))
                #true
                "The rectangle is selected"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; world-to-scene : WorldState -> Scene
;; GIVEN: a world state
;; RETURNS: tranlation of the given world state into a scene
;; STRATEGY: Use template for WorldState on w
;; EXAMPLES:
;; (world-to-scene PAUSED-WORLD-WITH-ONE-RECT)
;; =(place-image I-UNSEL-RECT-AT-CENTER (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) EMPTY-CANVAS)

(define (world-to-scene w)
  (display-world (world-lor w) (world-lod w)))
;TEST
(begin-for-test
  (check-equal? (world-to-scene PAUSED-WORLD-WITH-ONE-RECT)
                (place-image I-UNSEL-RECT-AT-CENTER
                             (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) EMPTY-CANVAS)
                "A stationary rectagle is created at the center of the canvas"))
;....................................................................................
;; display-world : ListOfRectangles ListOfDots -> Scene
;; GIVEN: a list of rectangles and a list of dots
;; RETURNS: tranlation of the given world state into a scene
;; STRATEGY: Use template for ListOfRectangles on lor
(define (display-world lor lod)
  (cond
    [(empty? lor) (pass-dots lod)]
    [else
     (place-rect (first lor) (display-world (rest lor) lod))]))
;..........................................................................
;; pass-rect : ListOfRectangles -> Scene
;; GIVEN: a list of rectangles
;; RETURNS: tranlation of the list of rectangles into a scene
;; STRATEGY: Use template for ListOfRectangles on lor
(define (pass-rect lor)
  (cond
    [(empty? lor)  EMPTY-CANVAS]
    [else (place-rect (first lor) (pass-rect (rest lor)))]))
;;TESTS:
(begin-for-test
  (check-equal? (pass-rect empty) EMPTY-CANVAS
                "No rectangles are placed on the canvas")
  (check-equal? (pass-rect LIST-OF-UNSEL-ONE-RECT)
                (place-image I-UNSEL-RECT-AT-CENTER (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2)
                             EMPTY-CANVAS)
                "Places the rectangle(s) in list on the canvas"))
;...........................................................................
;; pass-dots : ListOfDots -> Scene
;; GIVEN: a list of dots
;; RETURNS: tranlation of the list of rectangles into a scene
;; STRATEGY: Use template for ListOfDots on lod
(define (pass-dots lod)
  (cond
    [(empty? lod) EMPTY-CANVAS]
    [else (place-dots (first lod) (pass-dots (rest lod)))]))
;;TESTS:
(begin-for-test
  (check-equal? (pass-dots empty) EMPTY-CANVAS
                "No rectangles are placed on the canvas")
  (check-equal? (pass-dots LOD1)
                (place-image PEN-DOT (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2)
                             EMPTY-CANVAS))
  "A dot is placed at the center of the canvas")
;...........................................................................
;; place-dots : Pendot Scene -> Scene
;; GIVEN: a pen dot and a scene
;; RETURNS: a scene similar to given one but with the given dot placed in it
;; STRATEGY:Use template for ListOfDots on lod
(define (place-dots d s)
  (place-image PEN-DOT (pdots-dx d) (pdots-dy d) s))

;..................................................................................
;..................................................................................
;; place-rect : Rectangle Scene -> Scene
;; GIVEN: a rectangle and a scene
;; RETURNS: a scene similar to given one but with the given rectangle placed in it
;; STRATEGY: Use template for Rectangle on r
;; EXAMPLES:
;; (place-rect SEL-RECT-AT-CENTER EMPTY-CANVAS)
;; =(place-image I-SEL-RECT-AT-CENTER (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) EMPTY-CANVAS)
(define (place-rect r s)
  (if (myrect-selected? r)
      (place-selected-rect r s)
      (place-unselected-rect r s)))
;TESTS
(begin-for-test
  (check-equal? (place-rect SEL-RECT-AT-CENTER EMPTY-CANVAS)
                (place-image CIRCLE-ON-MOUSE 0 0
                             (place-image I-SEL-RECT-AT-CENTER
                                          (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) EMPTY-CANVAS))
                "A selected i.e red rectangle is placed at the center of the canvas"))
;..................................................................................
;; place-selected-rect : Rectangle Scene -> Scene
;; GIVEN: a rectangle that is selected and the scene
;; RETURNS: a scene similar to given one but with the given rectangle placed in it
;; STRATEGY: Use template for Rectangle on r
(define (place-selected-rect r s)
  (place-image (circle 5 "outline" "red")
               (myrect-mx r)
               (myrect-my r)
               (place-image (append-vel-text r RECT-CLICKED SEL-COLOR)
                            (myrect-x r)
                            (myrect-y r)
                            s)))
;..................................................................................
;; place-unselected-rect : Rectangle Scene -> Scene
;; GIVEN: a rectangle that is not selected and the scene
;; RETURNS: a scene similar to given one but with the given rectangle placed in it
;; STRATEGY: Use template for Rectangle on r
(define (place-unselected-rect r s)
  (place-image (append-vel-text r RECT UNSEL-COLOR)
               (myrect-x r)
               (myrect-y r)
               s))
;..................................................................................
;; append-vel-text : Rectangle Image String-> Image
;; GIVEN: a rectangle, an image of the rectangle and the color based on whether rectangle
;;        is selected or not
;; RETURNS: an image of the rectangle with its velocity printed above it
;; STRATEGY: Combine simpler functions
(define (append-vel-text r rec c)
  (overlay (text (get-string-vel r) VEL-FONT c) rec))
;..................................................................................
;; get-string-vel : Rectangle -> String
;; GIVEN: a rectangle
;; RETURNS: the string (vx,vy) describing the velocity of the center of the rectangle
;; STRATEGY: Use template for Rectangle on r
(define (get-string-vel r)
  (string-append "(" (number->string (myrect-vx r)) "," (number->string (myrect-vy r)) ")"))