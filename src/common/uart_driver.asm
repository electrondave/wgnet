;*******************************************************************************
;                                                                              *
;    Filename:         uart_driver.asm                                         *
;    Date:             April 4, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      usart driver                                            *

;    there are two UARTs (USART) in the MCU
;
;
    ; the user code will place a packet into the Q
    ; then it will increment the packet counter
    ; then the send routine will decrement the counter when done sending the packet.
    ; this is made possible by the atomic incf and decf operations on the single byte counter

;
;                                                                              *
;*******************************************************************************
    errorlevel -302; disable bankswitch warning

#include "p16f15324.inc"
#include "../../src/common/q_macros.inc"

; *******************

    constant LED = 5
    extern delay_10ms

    global  InitUART2
    global  IRQ_UART1_rx

; ram - this section filled up so it is tight.
section_uart_net_tx udata   h'1a0'
; network data link layer Queues
NET_TX_Q_START  res d'20'
NET_TX_A_END    res 1
netTxIn_p       res 1
netTxOut_p      res 1
netTxPktCntr    res 1   ; count of packets in Q

section_uart_net_rx udata   h'1d0'
NET_RX_Q_START  res d'20'
NET_RX_Q_END    res 1
netRxIn_p       res 1
netRxOut_p      res 1
netRxPktCntr    res 1


    CODE

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
InitUART1:      ; network data com port
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    banksel TX1STA
; TXxSTA: CSRC = 1 TX9 = 0 TXEN = 1 SYNC = 0 SENDB = 0 BRGH = 1  TRMT = 0 TX9D = 0
    movlw   b'10100100'
    movwf   TX1STA

    banksel RC1STA
; RCxSTA: SPEN = 1 RX9 = 0 SREN = 0 CREN = 1 ADDEN = 0 2 FRERR = 0 OERR = 0 RX9D = 0
    movlw   b'10010000'
    movwf   RC1STA

;    //BAUDxCON: Baud Rate Control Register
;    // 7 ABDOVF = 0  // auto baud over flow status
;    // 6 RCIDL = 0 // Receiver is idle
;    // 5 Unimp = 0
;    // 4 SCKP = 0 // Transmit polarity 0 = idles high
;    // 3 BRG16 = 1 // use 16 bits
;    // 2 Unimp = 0
;    // 1 WUE = 0
;    // 0 ABDEN = 0 // auto baud detect

;    BAUD1CON = 0b00001000;
    banksel BAUD1CON
    movlw   b'00001000'
    movwf   BAUD1CON

;    SP1BRGH = 0x00;
    banksel SP1BRGH
    movlw   0x00
    movwf   SP1BRGH
;    SP1BRGL = 0x69;
    movlw   0x69
    movwf   SP1BRGL

    return

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
InitUART2:              ; console / bridge to general purpose computer
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    ; RC0 is TX2
    ; RC1 is RX2
    banksel TRISC
    bcf TRISC,0 ; RC0 is TX so make it output
    bsf TRISC,1 ; RC1 is RX of make it input

    banksel PMD0
    bcf     PMD0, SYSCMD    ; enable Fosc to Peripherals

    banksel PMD4    ; enable the UART2
    bcf     PMD4,7

    banksel TX2STA ;
    movlw   0xA4
    movwf   TX2STA

    banksel RC2STA
    movlw   0x90; // SPEN - Serial Port Enable
    movwf   RC2STA

    banksel BAUD2CON
    movlw   b'00001000'
    movwf   BAUD2CON

    banksel SP2BRGH
    movlw   0x00
    movwf   SP2BRGH
    movlw   0x69
    movwf   SP2BRGL


;
;    //RC2REG is where the receive data is read
;    //TX2REG is where the tx data is written
; just try what the C has to see If I can get it to work!
    banksel RC0PPS
    movlw   h'11'
    movwf   RC0PPS ; RC0 is TX2

    banksel ANSELA
    clrw
    movwf   ANSELA

    banksel TRISA
    clrw
    movwf   TRISA

    banksel ANSELC
    clrw
    movwf   ANSELC

    banksel TRISC
    movlw   b'00100010'
    movwf   TRISC

    banksel RA5PPS
    clrw
    movwf   RA5PPS

    banksel RA4PPS
    clrw
    movwf   RA4PPS

; Note that the TX2IF will be set anytime the transmitter can accept a new character
; Note that it will be set now...
; Also the TX2STA, b1 will be set after this so we have to transmit a garbage bit to init the uart

    banksel TX2REG
    movlw   'A'
    movwf   TX2REG

InitUART2_loop_1
    nop
    banksel PIR3
    btfss   PIR3,TX2IF ; transmitting?
    bra InitUART2_loop_1

    return



; ******************************************************************
IRQ_UART1_rx
    ; !!! for now blink the light for each char received
    banksel PORTA
    bsf PORTA,LED
    movlw   d'100'
    lcall   delay_10ms
;    bcf
    ;

    ; check the state machine flags, then jump based upon the state
    ; states: idle, read_header, read_payload, etc...
    ; perhaps the low nibble is state and the upper nibble shows which buffer is being filled
    ; then we won't need the other flags

    ; !!! just for now we will put the packet into a buffer until we see a <cr>

    ; see if a buffer is available

    ; PC is saved on the return stack and the following registers are automatically saved in the shadow registers:
;    ? W register
;    ? STATUS register (except for TO and PD)
;    ? BSR register
;    ? FSR registers
;    ? PCLATH register
;    Upon exiting the Interrupt Service Routine, these
;    registers are automatically restored.

    ; see what state we are in

;    banksel netRxFifo

;    banksel RC2REG
;    movf RC2REG, w
;    banksel netRxFifo
;    movwf   netRxFifo
    ;todo use a pointer and update it
    return

IRQ_UART1_tx
    return


    END
