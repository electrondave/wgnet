;
    ; applications - this file initializes all the applications registerd to the node
    ; each application will have it's own routines in it's own file
    ; the jobList and jump table needs entry for each deferable job (application task)
    ;
    ; Author: Dave
    ;
    ; Created on April 18, 2018
    ;
    ; Node application code,
    ; applications are things like:
    ; Local node stats: time, processor temp, number of packets addressed to me, number of packets I have sent, number of rx csum errors ...
    ; ICE Melt
    ; Door detection
    ; HVAC valve control
    ; Blind control
    ; water flood detection

#include "p16f15324.inc"
    extern datStack
#include    "forth.inc"
    extern  forth_temp1, forth_temp2, forth_temp3, forth_temp4
#include    "jobList.inc"

    extern  InitConsole
    extern  PushJob
    extern  PushSched

    global  InitApp
    global  _app_regs_

section_app UDATA

_app_regs_   res d'20'

    CODE

InitApp
    lcall   InitConsole
;    Pushl   J_SND_BOOT_MSG
;    lcall   PushJob

    ; schedule an appointment to blink the LED
    Pushl   J_BLINK_LED   ; job id
    Pushl   3   ; LSB time
    Pushl   0   ; MSB time
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

; thoughts about the sprinkler application
    ; keep it simple
    ; what model should be used to control applications?

    ; timed applications
    ; HVAC applications


    ; turn something on for a time: sprinkler, housewater etc
    ; open blinds
    ; run the room temperature loop at a setpoint

    ; use the applications memory for the unit
    ; create a jop
    ; create a way to call that job

;    1. receive message on the network (start with console)
;    2. parse the message for an operation and parameters
;    3. push to the job Q with the parameters.
;    4. the runner finds it and calls it
