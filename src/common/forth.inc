;
; File:   forth.inc
; Author: Dave
;
; Created on April 18, 2018, 10:39 AM
;

;    Double-precision Operations
;In this group of words, we see another naming convention: the ?D?
;prefix identifies words that work with double-length integers. These
;are always represented as two stack items with the high-order (most
;significant) part in the higher stack position and the low-order (least
;significant) part beneath.


; new operations to write:
    ; double operations
    ; d_inc
    ; d_dec
;swap  ( a b -- b a )
;over  ( a b -- a b a )
;rot   ( a b c -- b c a ) the third item on the stack moves to the top

; FSR0 points to the top of stack after a push

    constant Q_EMPTY	=   0
    constant Q_FULL	=   1
    constant TRUE	= h'ff'
    constant FALSE	= h'00'

; comment
Push macro
    MOVWI   ++FSR0
    endm

Pushl macro lit
    movlw   lit
    Push
    endm

Pop macro
    MOVIW   FSR0--
    endm

And macro
    Pop
    andwf   INDF0,F
    endm

Or  macro
    Pop
    iorwf   INDF0,F
    endm

Xor macro
    Pop
    xorwf   INDF0,F
    endm

Add macro
    Pop
    addwf   INDF0,F
    endm

Sub macro
    Pop
    subwf   INDF0,F
    endm

Swapnib macro
    swapf   INDF0,F
    endm

;negate macro ;; tos --- ~tos+1
;    pop

Com macro   ; tos --- ~tos
    comf    INDF0,F
    endm

Inc macro
    incf    INDF0,F
    endm

; pick: w contains the level [1= TOS] ( - picked )
PickW macro ; (temporary registers are accessable in every bank)
    movwf   forth_temp1	; save index to temp1
    movfw   FSR0L	; save stack pointer to temp2
    movwf   forth_temp2
    movfw   forth_temp1 ; restore the index
    subwf   FSR0L,f	; point back into earlier stack
    movfw   INDF0	; pick
    movwf   forth_temp1 ; save
    movfw   forth_temp2 ; restore stack pointer
    movwf   FSR0L
    movfw   forth_temp1	; picked
    Push
    endm

Pickl macro lit
    movlw   lit
    PickW
    endm

Pick macro
    pop
    PickW
    endm

Dup macro
    Pop
    Push
    Push
    endm

Load macro ; address --- reg[tos]
    Pop
    movwf   FSR1L
    movlw   low _app_regs
    addwf   FSR1L
    movlw   high _app_regs
    movfw   INDF1
    Push
    endm

Store   macro   ; value address ---
    Pop                         ; w gets the register index
    movwf   FSR1L
    movlw   low _app_regs
    addwf   FSR1L               ; add the base address
    movlw   high _app_regs
    Pop                         ; get the value to be stored
    movwf   INDF1                ; put it out
    endm

Dup2 macro
    Pickl   1
    Pickl   1
    endm

Eq2 macro ; xh xl yh hl - res(eq) ; leave true false after double comparison
    ; todo: save the page
    lcall   _Eq2_
    ; todo: restore the page
    endm

Swap macro; ( a b - b a )
    Pop
    movwf   forth_temp1 ; store b
    Pop
    movwf   forth_temp2 ; store a
    movfw   forth_temp1 ; push b
    Push
    movfw   forth_temp2 ; push a
    Push
    endm

D_Add macro ; ( al ah bl bh - sl sh )
    Pop
    movwf   forth_temp1 ; bh
    Pop
    movwf   forth_temp2 ; bl
    Pop
    movwf   forth_temp3 ; ah
    movfw   forth_temp2 ; let w = bl
    addwf   INDF0,F     ; let tos = a1 + b1
    movfw   forth_temp3
    Push
    movfw   forth_temp1
    addwfc   INDF0,F	; let tos = ah + bh + C
    endm


    ; ##############################

FIf macro label1 ; ( b - ) if true take the branch
    pop
    btfss STATUS,Z
    bra	label1
    endm

FIfNot macro label1 ; ( b - ) if false take the branch
    pop
    btfsc STATUS,Z
    bra label1
    endm

movff macro f1, f2
    movfw   f1
    movwf   f2
    endm

movlf macro lit1, f1
    movlw   lit1
    movwf   f1
    endm

