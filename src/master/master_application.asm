;
    ; master_application.asm
    ;
    ; Author: Dave
    ;
    ; Created on May 28, 2018
    ;

    ; Network Master Node
    ; Is the network protocol timing controller
    ; Is the bridge to a general purpose computer IP server for access to the
    ; WG network nodes

#include "p16f15324.inc"
    extern datStack
#include    "../../src/common/forth.inc"
    extern  forth_temp1, forth_temp2, forth_temp3, forth_temp4
#include    "../../src/master/master_job_list.inc"

    global  InitApp
    global  RunNextJob

    extern  PushJob
    extern  PopJob
    extern  PushSched
    extern  ProcessSchedule
    extern  GetTime

    extern  J_BlinkLed
    extern  J_Send_net_pulse

section_app UDATA   h'2a0'

    CODE

InitApp
;    lcall   InitConsole
;    Pushl   J_SND_BOOT_MSG
;    lcall   PushJob

    ; schedule an appointment for sending the net frame indicator
    Pushl   J_SEND_NET_PULSE   ; job id
    Pushl   5   ; LSB time
    Pushl   0   ; MSB time
    lcall   PushSched

    ; schedule an appointment to blink the LED
    Pushl   J_BLINK_LED   ; job id
    Pushl   3   ; LSB time
    Pushl   0   ; MSB time
    lcall   PushSched

    ; schedule a test appointment
    Pushl   J_TEST
    Pushl   7
    Pushl   0
    lcall   PushSched
    return

RunNextJob ; (in the processing any params would be then pulled and used as it moves along...)
    call    PopJob
    Pushl   h'07' ; support up to 8 jobs
    And
    Pop
    lslf    WREG,W
    brw
    lgoto   J_Send_net_pulse    ;0
    lgoto   J_BlinkLed          ;1
    lgoto   J_Extra             ;2
    lgoto   ProcessSchedule     ;3  Job pushed due to Timer2 postscale overflow
    lgoto   J_Test             ;4
    lgoto   J_Extra             ;5
    lgoto   J_Extra             ;6
    lgoto   J_Extra             ;7
    ; if you add another then add 8 more and change the Literal for the And above

    ; these are just for testing

J_Extra
    movlw   h'ee'
    return

J_SndBootMsg
    movlw   h'e1'
    return

J_Test
    ; schedule another test purpose recurring  appointment
    Pushl   J_TEST   ; job id
    lcall   GetTime
    Pushl   d'7'   ; LSB
    Pushl   0   ; MSB time
    D_Add
    lcall   PushSched
    return

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; initial code creation test utility used for Stack testing
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

TestStack:
    Pushl   11
    Pushl   22
    Pushl   33
    Pickl   2
    Pushl   44
    ; watch them come off the stack in reverse order
    movlw   h'aa'
    Pop
    Pop
    Pop
    Pop

    ;lcall   PushJob ; 22 from data stack
    ;lcall   PushJob ; 11 from data stack
    ;lcall   PopJob  ; 22 to data stack
    ;lcall   PopJob ; 11 to data stack
    ;Pop ; w <- 11
    ;Pop ; w <- 22
wait_init_sw_here
    nop
    goto    wait_init_sw_here

    END

