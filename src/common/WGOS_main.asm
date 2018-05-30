; todo: fix: master scheduling of light blink and network pulse never blinks light
    ; I found that the blink routine runs once!  See if 3 destroys it?
    



    ; todo: 1. master, 2. snoop, 3. sprinkler
    ; in the master node code:
    ; does this file need to be unique?
    ; put out a character once a second,
    ; next try to snoop it.


    ; Use the USART to transmit and receive data:
    ; It looks like I need to write some python that will receive packets.
    ; But I will start by receiving just a character on a Putty terminal
    ; The transmit ( led blinker ) dies after sending about 7 lines of output



    ; Later:
    ; check to see if any code crosses branch and goto boundaries.
    ;  if so then does a routine need to re-page select upon a return from a lcall?

    ; Test Driven Development order of operations:
    ; 1) requirements, 2) Tests 3) coding
    ; TDD encourages you to think like the end user and utilize the spec, instead of likea coder
    ; because you are writing the test to the spec instead of to your understaning of the code
    ; you just wrote.  (Note the change in mindset.)



    ; ********************************************************************************

    ; WGOS requirements:
        ; ability to receive and transmit messages on the network
        ; ability to read status
        ; ability to write settings
        ; ability to schedule atonomus status updates and transmit readings
        ; ability to receive interupts with trigger an action

    ; job execution requirement:
        ; a queue holds jobs
        ; ability to push job tokens to Q
        ; service that checks for job tokens on the Q then runs the Job subroutine assigned to that token

    ; Scheduling requirement:
        ; Ability to set an appointment within a 6 hour block of time within 0.5 second resolution
        ; Ability to keep track of the time of day
        ; when time of day changes a message is sent to the os to run the schedule
        ; schedule looks for an expired appointment and places the job token on the job queue



    ;Note: This is not really the sprinkler as much as it is a generic network node for now
    ; Beware: a lower case pop does nothing and causes no error! happened once to me...


;*******************************************************************************
;                                                                              *
;    Filename:         WGOS_main.asm                                      *
;    Date:             April 4, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      RTOS main                              *
;
;
;    This OS relies upon interrupts for all event processing.
;    If anything needs attention, it shall cause an IRQ through the various
;    pins and peripherals inside the chip.
;
;    The IRQ servicing is broken into two components.  The event IRQ processing
;    done within the IRQ event service. For example the USART Rx routine will
    ;transfer the received data to a receive fifo, and parse it enough to know
    ;that it is good and fully received

    ; The IRQ service routines place a job token on the IRQ fifo (TBD?: along with any
    ; required parameters)
    ;
    ; The main software loop checks the IRQ fifo for new data and transfers
    ; to the job token execution queue.
    ;
    ; The main software loop then executes any tokens on the execution queue.
    ; The reason for these two queues is so that interrupts cannot conflict
    ; with queue in process of processing queue pointers in the main loop.
    ; so we don't have to disable interrupts while we update the pointers and flags.

;
;    The scheduling service uses a timer interrupt that places the timer job
;   on the IRQ statk.  When executing, process sechedule routine checks when the next appoinment
;    occurs.  It then pushes a service call on the execution stack.
    ; this schedule service keeps an appointment calandar on a schedule data structure.
;
;    The purpose of the deferred processing is to create some sort of order
;    out of chaos.  The asynchronous IRQs themselves access private variables
;    to do their work.  This is to arbitrate
;    against contending for variables and peripherals.
;    the updating of flags is atomic in the cpu.

;Coding style guide:
; variables start with lower case then camel case:  exampleVariable
; subroutines start with upper case then camel case: ExampleSubroutine
; constants are all upper case: EXAMPLE_CONSTANT
; OS variables and functions begin with an underscore char to show they are system variables to not play with in applications
; OS variables should have getter and setter functions.
    ;
    ; somday write a boot loader application?
    ; how much data can be transported, what is the MTU?
    ;


    ; about programming
    ; the page select isn't much of an issue until
    ; the branches and calls go further than?
    ;
    ; when routines use the bsr, they should back it up and at the end restore it
    ;there are in low bank memory the core registers and in high bank memory the common ram 70-7f
    ; the common ram is used for the forthish machine so bank selecting doesn't need to be done for it's routines
    ;
    ; note that some of the includes needed path name prefixes added and some did not.
;*******************************************************************************

#include "p16f15324.inc"
    extern  datStack
#include "forth.inc"
    extern  forth_temp1, forth_temp2


; PIC16F15324 Configuration Bit Settings
; CONFIG1
; __config 0xFF8C
    __CONFIG _CONFIG1, _FEXTOSC_OFF & _RSTOSC_HFINT32 & _CLKOUTEN_OFF & _CSWEN_ON & _FCMEN_ON
; CONFIG2
; __config 0xF7DC
    __CONFIG _CONFIG2, _MCLRE_OFF & _PWRTE_ON & _LPBOREN_ON & _BOREN_ON & _BORV_LO & _ZCD_OFF & _PPS1WAY_OFF & _STVREN_ON
; CONFIG3
; __config 0xFF9F
    __CONFIG _CONFIG3, _WDTCPS_WDTCPS_31 & _WDTE_OFF & _WDTCWS_WDTCWS_7 & _WDTCCS_SC
; CONFIG4
; __config 0xFFFF
    __CONFIG _CONFIG4, _BBSIZE_BB512 & _BBEN_OFF & _SAFEN_OFF & _WRTAPP_OFF & _WRTB_OFF & _WRTC_OFF & _WRTSAF_OFF & _LVP_ON
; CONFIG5
; __config 0xFFFF
    __CONFIG _CONFIG5, _CP_OFF

    extern  DisablePeripherals
    extern  InitHardware
    extern  InitJobQ
    extern  InitForth
    extern  InitSchedule
    extern  InitApp
    extern  DisableIRQ
    extern  InitISR
    extern  PushJob
    extern  PopJob
    extern  ProcessIsrQueue
    extern  ProcessSchedule
    extern  ProcessJobQueue
    extern  IncrementMockTime

;    extern  ProcessConTx
;    extern  ProcessConRx

;*******************************************************************************
; Reset Vector
;*******************************************************************************

ResVec  code    0x0000           ; processor reset vector
    goto    Start                ; go to beginning of program

;*****************************************

    CODE

Start:
    lcall   DisableIRQ
    lcall   DisablePeripherals
    lcall   InitForth
    lcall   InitJobQ
    lcall   InitSchedule
    lcall   InitHardware
    lcall   InitApp
    lcall   InitISR             ; Initialize the Interrupt systems
MainLoop:
    CLRWDT
    lcall   ProcessIsrQueue     ; translate events to deferred calls
    lcall   ProcessJobQueue     ; execute handlers for deferred calls

    ; can the isr put these call onto the IsrQ?
;    lcall   ProcessConTx        ; Usart Communication handler
;    lcall   ProcessConRx
    bra	    MainLoop

    END

; considerations:
; I read that the linker/assembler doesn't place code across page boundaries
; so the 'lcall' functions to the same sections could be reduced to just 'call'.