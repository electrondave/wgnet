;*******************************************************************************
;                                                                              *
;    Filename:         hardware_drivers.asm                                    *
;    Date:             April 4, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      Hardware Drivers                                        *
;                                                                              *
;*******************************************************************************
;  (See hardware.inc for further info)
;
;                          PIC16F15324
;
;                        -----------------
;                        |               |
;            +5V  Vdd    | 1          14 |   Vss  Ground
;  LED            RA5    | 2          13 |   RA0/ICSPDAT
;  TP12           RA4    | 3          12 |   RA1/ICSPCLK
;             Vpp/RA3    | 4          11 |   RA2    Near Field Detect
;  RXD            RC5    | 5          10 |   RC0    UART TX
;  TXD * Carrier  RC4    | 6           9 |   RC1    UART RX
;  Valve Control  RC3    | 7           8 |   RC2    Valve Current
;                        |               |
;                        -----------------
;
;
    errorlevel -302; disable bankswitch warning

#include    "p16f15324.inc"
#include    "hardware.inc"
#include    "forth.inc"
    extern  forth_temp1, forth_temp2, forth_temp3, forth_temp4
#include    "jobList.inc"

    global  DisablePeripherals
    global  InitHardware
    extern  InitUART2

    extern  GetTime
    extern  PushSched
    global  J_BlinkLed
    extern  PushConTx
    extern  ConTxInc
    extern  SendConString
    extern  kk
    extern  OutHex

section_hardware UDATA
temp_1   res 1   ; todo: see if the common block area has space for this?
temp_2  res 1

    CODE

DisablePeripherals
    ; Peripheral module disables
    banksel PMD0
    movlw   h'ff'
    movwf   PMD0
    movwf   PMD1
    movwf   PMD2
    movwf   PMD3
    movwf   PMD4
    movwf   PMD5
    return

InitHardware
    ; todo: determine cause of reset
    lcall   InitOSC

    lcall   InitGPIOs
    lcall   InitUART2
    lcall   InitTOD_Timer

    return

InitOSC
;    OSCFRQ = 2; // select 4 Mhz HFINTOSC clock
    banksel OSCFRQ
    movlw   h'02'
    movwf   OSCFRQ

;
;      //          NOSC:NDIV  // HFINTOSC: /1
;    OSCCON1 = 0b001100000;
    banksel OSCCON1
    movlw   b'001100000'
    movwf   OSCCON1

    return

    ; *******************************************
InitGPIOs
    ; *******************************************
;    ANSELA  = 0; // high = analog input
    banksel ANSELA
    clrf    ANSELA

;    TRISA   = 0;  // 0 is output
    banksel TRISA
    clrf    TRISA

;    ANSELC = 0;
    banksel ANSELC
    clrf    ANSELC

;    TRISC = 0b00100010;
    banksel TRISC
    clrf    TRISC
;
;    RA5PPS = 0x00;
    banksel RA5PPS
    clrf    RA5PPS

;    RA4PPS = 0x00;
    banksel RA4PPS
    clrf    RA4PPS

    return


; ********** TOD Timer **************

InitTOD_Timer ; TIMER2 Module with hardware limit timer (HLT)
    ; 1 Mhz / 128 prescale / 244 counter/ 16 postscale = 2 Hz
    ; with a 2 byte software counter will count for about 9 hours
    ; before rollover
    ; so the software could  set this soft timer to 0 every 6 hours:
    ;0 to 6
    ;6 to 12
    ;12 to 18
    ;18 to 24

    ; Free running period mode
    ;MODE<4:0> = b'00_0000' ; free running, software gate
    ;BSF T2CON.ON; software enable the timer
    ;T2CON.OUTPS<3:0> ; postscaler select
    ;PIE4.TMR2IE = 1 ; turn on interrupt
    ;PSYNC = 0 ; allow the timer to run during sleep

    banksel PMD1            ; Peripheral Module Disable Control Register
    bcf     PMD1, TMR2MD    ; enable timer 2

    banksel T2CLKCON ; all timer 2 registers are in bank 5
    movlw   b'00000001'     ; select Fosc/4
    movwf   T2CLKCON
    movlw   b'11111111'     ; ON=1,Prescale=128,Postscale=16
    movlw   b'11011111'      ; 1:16 pre and 1:4 post scale for debug dbb qwerty FIXME TODO
    movwf   T2CON
    movlw   b'00000000'     ;Psync=0,CKPOL=0,CKSYNC=0,MODE=0|0
    movwf   T2HLT
    movlw   b'00001101'     ; RSEL=LC4_out
    movwf   T2RST
    movlw   d'243'          ; set the period to 244 clocks
    movwf   T2PR
    ; InitISR will enable timer 2 interrupts
    return

; *****************************************************************
J_BlinkLed
    banksel LATA
    movlw   LED_MASK
    xorwf   LATA,F
    ; schedule a recurring  appointment
    Pushl   J_BLINK_LED   ; job id
    lcall   GetTime
    Pushl   d'2'   ; LSB time dbb qwerty change this back - debug
    Pushl   0   ; MSB time
    D_Add
    lcall   PushSched

    movlw   3
    lcall   SendConString
    movfw   kk
    Push
    lcall   OutHex
    incf    kk

    return



    END
