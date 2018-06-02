;*******************************************************************************
;                                                                              *
;    Filename:         utilities.asm                                           *
;    Start Date:       April 16, 2018                                          *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      common software utilities                               *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                        0.1 initial coding                                    *
;*******************************************************************************
#include "p16f15324.inc"
#include "forth.inc"

    global  delay_10ms
    global  String_0, String_2
    extern  strPtr   ; parameter for which string we are getting
    global  LoadStringPtr
    extern  ii, jj, kk
    global  getStringElement

; section_util UDATA

StringCode macro string
    local BeginS, EndS
    Pop
    addwf   PCL,F
    dt EndS - BeginS
BeginS
    dt string
EndS
    endm

    CODE
delay_10ms ; W * 10ms delay

    ; 16 mhz clock
    ; 4 Mhz sclk
    ; 3 instruction cycles per smallest loop
    ; 100e-3 * 4Mhz / 7 = 133k loop executions

    banksel kk ; may be in the shared data section, but just to be safe.
    movwf   kk
d_l_back
    movlw   low d'2300'
    movwf   ii
    movlw   d'2300' / d'256'
    movwf   jj

delay_loop
    decfsz  ii,F
    bra     delay_loop
    decfsz  jj,F
    bra     delay_loop
    decfsz  kk,F
    bra     d_l_back
    return

; ***************** string operations *********************

String_0 StringCode "\r\nWorking Macro\r\n"
String_1 StringCode "Mission Accomplished!\r\n"
String_2 StringCode " 212 "
String_3 StringCode " 313 "
String_4 StringCode " 414 "

GetStringPtr
    addwf PCL,F
    dt  Low String_0
    dt  Low String_1
    dt  Low String_2
    dt  Low String_3
    dt  Low String_4

LoadStringPtr ; w is which one
    call GetStringPtr
    movwf   strPtr
    return

getStringElement
    ;PCLATH should have this page already
    movfw   strPtr
    movwf   PCL     ; jump to string table lookup

    END