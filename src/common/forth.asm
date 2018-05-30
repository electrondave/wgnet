;*******************************************************************************
;                                                                              *
;    Filename:         forth.asm                                               *
;    Date:             April 17, 2018                                          *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      This is not really Forth, just forth inspired     *
;        This file holds the routines that perform the data stack operations
;        The os and applications use these routines in doing their work
    ;
    ; The banksel function is not needed here because the temp vars used
    ; are in commonly accessable memory

;TODO: watch stack for under / over flow errors - use flag register for full and empty
    ; the data stack is the only filo in service
    ; most of the functionality of the stack is in the forth macros located
    ; in forth.inc
    ; functions document stack as: ( stack items before - stack items after )
    ; the items to the right are on the top of stack
    ; a few application registers are the source and destination of load and store operations
    ; the application registers are in the forth data bank

;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                        0.1 first cut at the RTOS                             *
;*******************************************************************************
#include "p16f15324.inc"
    global  datStack
#include    "forth.inc"
    global  InitForth
    extern  forth_temp1, forth_temp2, forth_temp3, forth_temp4
    extern  strPtr
    extern  ii, jj, kk

sec_forth UDATA h'0a0'
datStack  res 30
_appRegs  res 20


    CODE

InitForth
    ;initialize the Stack Pointer: FSR0 is reserved for data stack pointing
    movlw   high    datStack
    movwf   FSR0H
    movlw   low     (datStack - 1)
    movwf   FSR0L
    return

;**** Subroutines for what would be very long Macros ****

    Global  _Eq2_

_Eq2_  ; leave true false after double comparison
    Pickl   2	; compare highs
    Sub
    Pop
    btfss   STATUS,Z
    bra Equ2_ExitFalse3
    Pickl   2
    Sub
    Pop
    btfss   STATUS,Z
    bra	Equ2_ExitFalse2
    Pop
    Pop
    Pushl   TRUE
    bra	Eq2_Exit
Equ2_ExitFalse3
    Pop
Equ2_ExitFalse2
    Pop
    Pop
    Pushl   FALSE
Eq2_Exit
    return
    END
