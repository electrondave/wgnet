;*******************************************************************************
;                                                                              *
;    Filename:         PHY_MAC_NET.asm                                         *
;    Date:             April 16, 2018                                          *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      WGNET layer processing                                  *
;       The PHY layer is an ook modem.  The OOK modem is primarily driven
;       by a USART.  Except during access arbitration where a 2 bit PPM software generated
;       modulation control with carrier sense back off is implemented.
;       The network system is Master - Slave with one network master.
;       The master indicates to the slaves an interval where they are permitted to contend for access.
;

;
;   Peer to peer comms are available
;The master will send a S which will cause interested slaves to ready themselves.
;    Next the master sends the 100us tone beginning the first arbitration slot
;    this continues for all 8 dibit slots
;
;    upon completion.  the Master sends a T frame with the winning Slave ID which grants the slave opportunity to talk

;Master to Slaves Packet Spec
;    Byte    Desc
;    1       Frame Type - master: G-global, M: master, S: Slaves may vie for the slot, T: time announcement, I: Uninitialized slaves may announce themselves and receive a netowork allocation
;    2-3     Node ID, MSB first MSnibble to LSnibble: NodeClass.NodeArea.NodeRoom.Node
;
;
;    Slave to Master Packet Frame Description
;    | SRC ID | DST ID | Payload LEN  | H SUM  | Payload   | P SUM  |
;    | 16 bits|16 bits | 8 bits       | 8 bits | LEN bytes | 8 bits |
;
;See the google doc: PHY MAC NET for further details
    ; the first byte of the payload is the operation code



;*******************************************************************************

#include "p16f15324.inc"
#include    "../../src/common/forth.inc"
    extern  forth_temp1, forth_temp2, forth_temp3, forth_temp4
#include    "../../src/master/master_job_list.inc"

    CODE

    global  J_Send_net_pulse

    extern  PushSched
    extern  GetTime

; *****************************************************************
J_Send_net_pulse

    banksel TX1REG
    movlw   'P'
    movwf   TX1REG

    ; schedule a recurring  appointment
    Pushl   J_SEND_NET_PULSE   ; job id
    lcall   GetTime
    Pushl   d'2'   ; LSB time
    Pushl   0   ; MSB time
    D_Add
    lcall   PushSched
    return


ProcessRxPacket  ; If either receive buffers are filled, process them
;    btfsc   bufferFlags,1   ; see if buffer full flag is set
;    bra     ProcessRxBuf1
;    btfss   bufferFlags,1
    return

ProcessRxBuf0
;    movlw   high NET_RX0
;    movwf   FSR0H
;    movlw   low NET_RX0
;    movwf   FSR0L
;    bra     ProcessRxBuf

ProcessRxBuf1
;    movlw   high NET_RX1
;    movwf   FSR0H
;    movlw   low NET_RX1
;    movwf   FSR0L
;    bra     ProcessRxBuf

ProcessRxBuf
    ; figure out if the packet is for us
    ; if so then route to a handler based upon payload first byte which is the application code

    ;see if global address: ( 0x ff ff )

    ;see if for me


    return

    END