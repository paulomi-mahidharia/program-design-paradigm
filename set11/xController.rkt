#lang racket

(require 2htdp/image)
(require 2htdp/universe)
(require rackunit)
(require "extras.rkt")
(require "Interfaces.rkt")
(require "ImageController.rkt")
(require "Model.rkt")

(provide xController%)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS :

(define X-CONTROLLER-RECT-WIDTH 150)
(define Y-CONTROLLER-RECT-HEIGHT 50)


; constants for the display of controller
(define RADIUS-SMALL 2 )
(define RADIUS-BIG 10)
(define STYLE-MODE-CIRCLE "solid")
(define STYLE-MODE-RECTANGLE "outline")
(define COLOR-RECTANGLE "blue")
(define COLOR-SMALL-CIRCLE "black")
(define COLOR-BIG-CIRCLE "red")
(define HANDLE-LENGTH 10)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The xController% class :

;; A xController% is a (new xyController% [model Model<%>]) ???

;; xyController% is a subclass of ImageController% class and it implements the
;; Controller<%> interface.

;; An X controller, which is like the XY controller, except that it displays only the
;; x coordinate of the particle's motion.

;; Dragging the mouse in the X controller alters the particle's position in the
;; x direction in both X and XY controllers.

;; The controller can de dragged by mouse drag KeyEvent if the mouse click is
;; within the handler which appears on the left top corner of the controller

;; The particle, represented as a circle, can be dragged if the event
;; mouse drag is inside the controller and the drag alters the x and y
;; coordinate of particle's center

;; The mouse button down pauses the particle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define xController%
  (class* ImageController% (Controller<%>)
    
    (init-field [width-data-image X-CONTROLLER-RECT-WIDTH])
    (init-field [height-data-image Y-CONTROLLER-RECT-HEIGHT])
    
    ;................................................................................
    
    ;; INTERPRETATION:
    ;--------------------------------------------------------------------------------
    ;; width-data-image : The width of the data image (particle-window)
    ;;                               of the controller
    ;; height-data-image: The height of the data image (particle-window)
    ;;                               of the controller
    ;--------------------------------------------------------------------------------
    
    ; the inherited fields from the super class 
    ; -------------------------------------------------------------------------------
    
    ; the model
    (inherit-field model) 
    
    ; represents the position of the center of the controller
    (inherit-field x y)   
    
    ; represents the dimensions of the controller
    (inherit-field width height)
    
    ; represents half dimensions of the controller
    (inherit-field half-width half-height)
    
    ; represents the coordinates of center of the particle
    (inherit-field particle-x particle-y)
    
    ; represents the velocity of the particle in x, y direction
    (inherit-field particle-vx particle-vy) 
    
    ; set to true only if mouse click is within the handle of controller,
    ; else false
    (inherit-field handle-selected?)
    
    ; set to true only if mouse click is within the controller,
    ; else false
    (inherit-field controller-selected?)
    
    ; the coordiantes of the mouse click wrt the handle of controller,
    (inherit-field saved-mx)  
    (inherit-field saved-my)
    
    ;...............................................................................
    
    (super-new)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;; Registering this object to the model to fetch latest position and velocity values
    ;; of the particle
    (send model register this)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     
    
    ; viewer-image : -> Void
    ; GIVEN : no arguments
    ; EFFECT : updates the fields (width-controller-data-image,
    ;          height-controller-data-image) of controller and sends this
    ;          data to the methods in super class to calculate the
    ;          final dimension of the controller image 
    ; STRATEGY : Combining simple functions
    
    (define/override (viewer-image)
      (let ((the-data-image (data-image)))
        (begin
          (set! width-data-image (image-width the-data-image))
          (set! height-data-image (image-height the-data-image))
          (send this final-controller-height (- height-data-image 30))
          (send this final-controller-width width-data-image)
          the-data-image)))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;; data-image : -> Image
    ;; GIVEN : The location 'l' of the click of the mouse
    ;; EFFECT: Updates the controller's selected field to true
    
    (define/override (data-image) 
      (overlay
       (place-image
        (overlay (circle RADIUS-SMALL STYLE-MODE-CIRCLE COLOR-SMALL-CIRCLE)
                 (circle RADIUS-BIG STYLE-MODE-CIRCLE COLOR-BIG-CIRCLE))
        particle-x (/ height-data-image 2)
        (rectangle width-data-image height-data-image STYLE-MODE-RECTANGLE COLOR-RECTANGLE))
       (rectangle width-data-image height-data-image STYLE-MODE-RECTANGLE COLOR-RECTANGLE)))
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ; after-drag : NonNegInt NonNegInt -> Void
    ; GIVEN : the coordinates of mouse click
    ; EFFECTS : updates the controller in response to the mouse drag event
    ; STRATEGY : Combine simple functions
    
    (define/override (after-drag mx my) 
      (cond
        [controller-selected?
         (update-view-controller mx my)]
        [handle-selected?
         (begin
           (set! x (- mx saved-mx)) 
           (set! y (- my saved-my)))]))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    ; update-view-controller : NonNegInt NonNegInt -> Void
    ; GIVEN   : coordinates representing the coordinates of mouse click
    ; EFFECT  : updates fields (offset-controller-mx,offset-controller-my)
    ;           of controller
    ; STRATEGY : Combining simpler functions
    
    (define/override (update-view-controller mx my)  
      (send this set-particle (- mx saved-mx)
            (- my saved-my)))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    ; set-handle : bool -> Void
    ; GIVEN : Boolean
    ; EFFECT : Updates the handle-selected?
    (define/public (set-handle bool)
      (set! handle-selected? bool))
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    ; set-controller-selected : bool -> Void
    ; GIVEN : Boolean
    ; EFFECT : Updates the controller-selected?
    
    (define/public (set-controller-selected bool)
      (set! controller-selected? bool))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ; TEST CASES :
;
(define xController1 (new xController% [model (new Model%)] ))
(define xController2 (new xController% [model (new Model%)] ))
(define xController3 (new xController% [model (new Model%)] ))


(define X-CONTROL (new xController% [model (new Model%)] ))
(define DATA-IMAGE-HEIGHT (image-height (send X-CONTROL data-image)))
(define DATA-IMAGE-WIDTH (image-width (send X-CONTROL data-image)))
(define VIEWR-IMAGE (send X-CONTROL viewer-image)) 

(define MOUSE-X 300)
(define MOUSE-Y 250) 
(define MOUSE-X1 225)
(define MOUSE-Y1 350)
(define MOUSE-X2 220)
(define MOUSE-Y2 195)

(define xCon-AFTER-KEY-EVENT (send xController1 after-key-event "left"))
(define xCon-AFTER-MOUSE-BUTTON-DOWN (send xController1 after-button-down
                                           MOUSE-X MOUSE-Y))
(define xCon-AFTER-MOUSE-DRAG1 (send xController1 after-drag (+ MOUSE-X 2)
                                     (+ MOUSE-Y 2)))


(define xCon-AFTER-MOUSE-BUTTON-DOWN2 (send xController2 after-button-down
                                            MOUSE-X2 MOUSE-Y2))
(define xCon-AFTER-MOUSE-DRAG2 (send xController2 after-drag MOUSE-X2
                                     MOUSE-Y2))


(begin-for-test
  (check-equal? (send xController1 in-this?
                      (+ MOUSE-X 5) MOUSE-Y) true
                                             "it should be inside controller")
  (check-equal? (send xController1 in-handle?
                      (+ MOUSE-X1 ) MOUSE-Y1) false
                                              "it should not be inside handler") 
  (check-equal? (send xCon-AFTER-KEY-EVENT in-this?
                      (+ MOUSE-X 5) MOUSE-Y) true
                                             "it should be inside controller")
  
  (check-equal? (send xController1 in-this?
                      (+ MOUSE-X 2) MOUSE-Y) true
                                             "it should be inside controller") 
  
  (check-equal? (send xController1 in-handle?
                      (+ MOUSE-X 2) MOUSE-Y) false
                                             "it should not be inside handler")
  
  (check-equal? (send xController2 in-handle?
                      MOUSE-X2 MOUSE-Y2) false
                                         "it should not be inside handler")
  (begin
    (send xController2 set-handle true)
    (send xController2 set-controller-selected false)
    (send xController2 after-drag MOUSE-X2
          MOUSE-Y2)
    (check-equal?   (send xController2 in-handle?
                          MOUSE-X2 MOUSE-Y2) false
                                             "it should not be inside handler")))



