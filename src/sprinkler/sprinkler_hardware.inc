;*******************************************************************************
;                                                                              *
;    Filename:         hardware_drivers.inc                                    *
;    Date:             May 1, 2018                                             *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      Hardware setup constants                                *
;                                                                              *
;*******************************************************************************
;  Microcontroller by Microchip
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
;
    constant  LED_MASK = b'00100000'
    constant  LED = 5

    ; for the uarts:
    ; default upon poweron
    ; RC0 is TX2
    ; RC1 is RX2
    ; RC4 is TX1 (This will be the modulator output)
    ; RC5 is RX1

    ; PPS Peripheral Pin Select
    ; Input signal routing shown in DataSheet page 195
    ;
