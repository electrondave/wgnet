;*******************************************************************************
;                                                                              *
;    Filename:         isr.asm                                                 *
;    Date:             April 4, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      Interrupt Service Routine                               *
;         each peripheral has it's own interrupt service routines              *
;           in a separate file specifically for that peripheral
;*******************************************************************************
    errorlevel -302; disable bankswitch warning

#include    "p16f15324.inc"
#include    "../../src/master/master_job_list.inc"
#include    "../../src/common/forth.inc"
#include    "../../src/common/q_macros.inc"

    extern  IRQ_UART1_rx
    global  DisableIRQ
    global  InitISR
    global  ProcessIsrQueue
    extern  PushJob
;    extern  SendConPacket_IRQ

section_ISR_Q    UDATA  h'020'
ISR_Q_START res h'12'
ISR_Q_END
isrQIn_p    res 1
isrQOut_p   res 1
isr_temp1   res 1

;*************************************
; Interrupt Service Routines
;    Handle incomming network data and
;    push job tokens to a IRQ safe Queue for later processing
;*************************************

ISR_Vec	CODE    0x0004           ; interrupt vector location
;todo    Check the seven PIR registers for interrupt source
;    use lcalls to isr routines for each peripheral
    banksel PIR3
    btfss   PIR3,TX2IF
    bra ISR_10

;    lcall   SendConPacket_IRQ
    ;banksel PIR3
    ;bcf     PIR3,TX2IF    ; clear the interrupt - NOPE - Software cannot do this! You must disable the interrupt when transmitting is done!

ISR_10
    banksel PIR3
    btfss   PIR3,RC2IF
    bra ISR_20
    banksel RC2REG
    movfw   RC2REG
    banksel TX2REG
    movwf   TX2REG

ISR_20
    ; **** TOD tick timer is Timer2 *****
    banksel PIR4
    btfss   PIR4, TMR2IF    ; check for timer2 postscale overflow
    bra     ISR_Exit
    bcf     PIR4, TMR2IF
    movlw   TOKEN_TIMER2
    lcall   PushISR
ISR_Exit
    RETFIE


DisableIRQ
    clrf    INTCON  ; Disable interrupts, Core Register
    ; Clear all Peripheral Interrupt Enable Registers
    banksel PIE0 ; PIRx and PIEx are all Bank14
    clrw
    movwf   PIE0 ; b5 Timer 0 ; b4 Change ; b0 INT pin ( not controlled by PEIE but the following are:)
    movwf   PIE1 ; b7: Osc Fail ; b6 Clock switch ; b0: ADC
    movwf   PIE2 ; b6: Zero Cross ; b1: Comparitor 2 ; b0: Comparitor 1
    movwf   PIE3 ; b7: Uart2 Rx ; b6 Uart2Tx ; b5 : Uart1Rx ; b4 : Uart1Tx ; b1:MSSP collision ; b0 MSSP1
    movwf   PIE4 ; b1: TMR2 PostScaler ; b0 Timer 1 overflow
    movwf   PIE5 ; b7 CLC4 ; b6: CLC3 ; b5:CLC2 ; b4:CLC1 ; b0:TMR1 Gate
    movwf   PIE6 ; b1 CCP2 ; b0: CCP1
    movwf   PIE7 ; B5: NVM ; b4 NCO ; b0 CWG1

    ; clear any IRQs
    banksel PIR1
    clrw
    movwf   PIR1
    movwf   PIR2
    movwf   PIR3
    movwf   PIR4
    movwf   PIR5
    movwf   PIR6
    movwf   PIR7

    return

; ******
InitISR
; ******
    ; initialize the ISR Queue
    banksel ISR_Q_START
    movlw   low ISR_Q_START
    movwf   isrQIn_p
    movwf   isrQOut_p

    ;banksel INTCON ; INTCON is a Core Register
    bsf INTCON,PEIE     ; enable peripheral interrupts
    bsf INTCON,GIE      ; enable interrupts

    banksel PIE4
    bsf     PIE4,TMR2IE     ;enable timer 2 interrupts

    return

; ******
PushISR ; Push W to the ISR Queue
    pushQ   ISR_Q_START, ISR_Q_END, isrQIn_p, isr_temp1
    return

; ******
PopISR ; Pop to W from the ISR Queue
    popQ    ISR_Q_START, ISR_Q_END, isrQOut_p, isr_temp1
    return

; ******
ProcessIsrQueue ; called from main loop
; move any tokens stored in ISR Queue to the Job Queue
; ******
    banksel ISR_Q_START
    movfw   isrQIn_p    ; if pointers are equal then the Q is empty
    subwf   isrQOut_p,W
    btfsc   STATUS,Z
    bra     ProccesIsrQ_Exit
    lcall   PopISR
    Push
    lcall   PushJob
    bra     ProcessIsrQueue
ProccesIsrQ_Exit
    return

    END




