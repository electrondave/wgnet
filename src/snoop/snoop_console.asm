; console.asm
; Author Dave B.
; May 5th, 2018

    errorlevel -302; disable bankswitch warning

#include "p16f15324.inc"
#include "../../src/common/q_macros.inc"
#include "../../src/common/forth.inc"
    extern  forth_temp1, forth_temp2, forth_temp3, forth_temp4


    global  InitConsole
    global  SendConPacket_IRQ
    global  PushConTx
    global  ConTxInc
    global  ProcessConTx
    global  SendConString
    extern  LoadStringPtr
    extern  String_0, String_2
    extern  getStringElement
    extern  ii, jj, kk
    global  OutHex
    global  ProcessConRx

section_uart_con_tx UDATA
CON_TX_Q_START  res d'70'
CON_TX_Q_END    ; end of Q plus 1
conTxIn_p       res 1
conTxOut_p      res 1
conTxByteCntr   res 1
conTxPktCntr    res 1
conTxFlags      res 1
conTxTemp       res 1

section_uart_con_rx UDATA
CON_RX_Q_START  res d'70'
CON_RX_Q_END    ; end of Q plus 1
conRxIn_p       res 1
conRxOut_p      res 1
conRxByteCntr   res 1
conRxPktCntr    res 1
conRxFlags      res 1
conRxTemp       res 1

section_temp    UDATA
temp_1  res 1   ; todo: see if the common block area has space for this?
temp_2  res 1

    CODE

; *******************************************************************
InitConsole
    banksel     CON_TX_Q_START
    movlw low   CON_TX_Q_START
    movwf       conTxIn_p
    movwf       conTxOut_p
    clrf        conTxByteCntr
    clrf        conTxPktCntr
    clrf        conTxFlags

    banksel     CON_RX_Q_START
    movlw low   CON_RX_Q_START
    movwf       conRxIn_p
    movwf       conRxOut_p
    clrf        conRxByteCntr
    clrf        conRxPktCntr
    clrf        conRxFlags

    clrf    kk
    return

; *******************************************************************
PushConTx ; Push W to the CON_TX Queue, temp needs to be in same bank
    pushQ  CON_TX_Q_START, CON_TX_Q_END, conTxIn_p, conTxTemp
    return

; *******************************************************************
PopConTx ; Pop to W from the Console Queue, temp needs to be in same bank
    popQ    CON_TX_Q_START, CON_TX_Q_END, conTxOut_p, conTxTemp
    return

; *******************************************************************
ConTxInc
    banksel conTxPktCntr
    incf    conTxPktCntr,F
    return

; *******************************************************************
PushConRx ; Push W, temp needs to be in same bank
    pushQ  CON_RX_Q_START, CON_RX_Q_END, conRxIn_p, conRxTemp
    return

; *******************************************************************
PopConRx ; Pop to W, temp needs to be in same bank
    popQ    CON_RX_Q_START, CON_RX_Q_END, conRxOut_p, conRxTemp
    return

; *******************************************************************
ConRxInc
    banksel conRxPktCntr
    incf    conRxPktCntr,F
    return

; *******************************************************************
ProcessConTx
; See if we need to initate the transmission of a console packet
; todo: can this call be placed on the jopQ instead of polling in main?
    banksel conTxFlags
    btfsc   conTxFlags,0    ; exit if already in the middle of sending
    bra     ProcConTxExit

    movfw   conTxPktCntr  ; exit if no packets to send
    btfsc   STATUS,Z
    bra     ProcConTxExit

    banksel PIR3
    btfss   PIR3,TX2IF      ; if uart is busy then exit
    bra     ProcConTxExit

    banksel conTxPktCntr
    decf    conTxPktCntr,F

    call    PopConTx           ; get packet length
    banksel conTxByteCntr
    movwf   conTxByteCntr   ; initialize the Message Byte Counter
    decf    conTxByteCntr,F
    bsf     conTxFlags,0    ; Set the sending packet flag
    call    PopConTx        ; initiate packet message transmission by sending the first byte
    banksel TX2REG
    movwf   TX2REG
    nop
    nop
    banksel PIE3
    bsf     PIE3,TX2IE      ; enable interrupt
    bsf     PIE3,RC2IE

ProcConTxExit
    return

; *******************************************************************
SendConPacket_IRQ
    banksel conTxByteCntr
    movfw   conTxByteCntr    ; check to see if there are bytes to send
    btfsc   STATUS,Z
    bra     ScpIsrDone

    call    PopConTx        ; send a char
    banksel TX2REG
    movwf   TX2REG

    banksel conTxByteCntr   ; decrement the byte counter
    decf    conTxByteCntr,F
    bra     ScpIrqExit

ScpIsrDone
    banksel conTxFlags
    bcf     conTxFlags,0    ; mark this transmission as done.
    banksel PIE3
    bcf     PIE3,TX2IE      ; disable the interrupt

ScpIrqExit
    return

; Send String to Console
SendConString
    lcall   LoadStringPtr
    clrw    ; tos gets index into string
    Push
    Dup
    lcall   getStringElement    ; the first element is length of string
    movwf   ii
    lcall   PushConTx
Loopieo
    Inc
    Dup
    lcall   getStringElement
    lcall   PushConTx
    decfsz  ii,F
    bra     Loopieo
    lcall   ConTxInc  ; tell the system we have a message to send
    Pop ;drop the counter index
    return

OutHex
    movlw   d'2'
    lcall   PushConTx
    Dup
    Swapnib
    call    Hex2Ascii
    lcall   PushConTx
    call    Hex2Ascii
    lcall   PushConTx
    lcall   ConTxInc
    return

Hex2Ascii
    Pop
    andlw h'0f'
    addlw a'0'
    ; see if it's bigger than '9'
    Push
    sublw a'9'
    btfsc   STATUS,C
    bra around
    Pop
    addlw   a'A' - a'9' - 1
    bra to_exit
around
    Pop
to_exit
    return

; ******************************************************************************
ProcessConRx
    banksel conRxPktCntr
    movfw   conRxPktCntr  ; exit if no packets
    btfsc   STATUS,Z
    bra     ProcConRxExit

    ; parse the received packet till end of char delimiter?
    ; for now just put out the number of bytes:

ProcConRxExit
    return

    END