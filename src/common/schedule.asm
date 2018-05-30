;*******************************************************************************
;                                                                              *
;    Filename:         schedule.asm                                            *
;    Start Date:       April 13, 2018                                          *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      event scheduling application                            *
    ; note: most of the appointment scheduling of the BMS is done by the BMS server
    ; this utility is for serving short interval status reporting
    ;

;the schedule contains appointments which expire and generate tasks
    ; SCHEDULE - APPOINTMENT ENTRIES (AE) -
    ;
    ;the appointments are kept in chronological order

    ;so the schedule contains data about each appointment
    ;{ timeH, timeL, token }
    ; 1. what tick time the appointment executes
    ; 2. what routine runs

; The schedule of appointments is a 16 bit number representing the number of
    ;ticks per day of the TOD counter:
    ; this gives 1.3184 seconds per tick or 52,734,375 cycles of 4 Mhz
    ; requireing a 26 bit (32) counter to time them.

; The schedules are neither a stack (FILO) or a queue (FIFO) but
    ; the appointments are pushed in starting at low memory
    ; and grows to higher memory like the stacks or queues
    ; the difference is that as appointments expire or are deleted
    ; they are removed by moving the higher mem appointments down by 1 struct size
    ; starting with the one after the appointment being removed.

;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                        0.1 initial coding                                    *
;*******************************************************************************
#include "p16f15324.inc"
    extern  datStack
#include "forth.inc"
    extern  forth_temp1, forth_temp2
    extern  _Eq2_

    global InitSchedule
    global PushSched
    global IncrementMockTime
    global ProcessSchedule
    global GetTime

    extern  PushJob

section_sched    UDATA  h'140'
sched   	res 20
schedPtr    res 1   ; points to the next available slot
timer_TOD   res 2   ;
sched_temp1 res 1   ;
sched_temp2 res 1

sched_code  CODE

;**********
InitSchedule
;**********
; setup the schedule stack pointers as fifo style
    banksel sched
    movlw   low sched
    movwf   schedPtr

    clrf    timer_TOD
    clrf    timer_TOD+1

    return

;**********
IncrementMockTime ; ( BTW- incf doesn't update the C flag)
;**********
    banksel sched
    movlw   1
    addwf    timer_TOD,F
    btfsc   STATUS,C
    incf    timer_TOD+1,F
    return

;**********
GetTime ; ( - low high )
;**********
    banksel sched
    movfw   timer_TOD
    Push
    movfw   timer_TOD+1
    Push
    return

;**********
PushSched ; appointment on data stack gets popped and then pushed to schedule list
;**********
    ; data stack ( job timeL timeH - )
    ; schedule ( - timeH timeL job )
    ; the struct of an appointement is
    ; appointment
    ;    timeH
    ;    timeL
    ;    token : the symbol that represents the subroutine to execute, (used as index into jump table)
    banksel sched
    movfw   schedPtr        ; FSR1 = schedPtr
    movwf   FSR1L
    movlw   high sched
    movwf   FSR1H
    Pop ; timeH             ; push to schedule
    movwi   FSR1++
    Pop ; timeL
    movwi   FSR1++
    Pop ; job
    movwi   FSR1++
    movfw   FSR1L           ; schedPtr = FSR1
    movwf   schedPtr
    return

;**********
RemoveAppointment ; by job search - may be more than one for that job
;**********
    ; todo
    return

;**********
DeleteAppointment  ; delete appointment pointed to by FSR1
;**********
    banksel sched  ; todo: what subroutines should save and restore the bank selection?
    ; temporarily use the forth data stack pointer (FSR0) to move the remaining items down
    movfw   FSR0L   ;save the forth stack pointer position
    movwf   sched_temp1
    movfw   FSR1L   ; save where we are pointing to now
    movwf   sched_temp2
    ; point at the next appointment with FSR0
    movfw   FSR1L
    movwf   FSR0L
    movlw   3   ; point to the appointment after the expired one
    addwf   FSR0L,F
    movlw   high sched
    movwf   FSR0H
DelApptLoop ; move the next appointments down; FSR0 is source, FSR1 is destination
    ; check if fsr0 is pointing to same as schedPtr, if so then we are done
    movfw   FSR0L
    subwf   schedPtr,W
    btfsc   STATUS,Z
    bra     DelAppt_done
    moviw   FSR0++  ;move the next appt down
    movwi   FSR1++
    moviw   FSR0++
    movwi   FSR1++
    moviw   FSR0++
    movwi   FSR1++
    bra     DelApptLoop
DelAppt_done
    ; update the schedule pointer
    movlw   3
    subwf   schedPtr,F
    ; restore the Forth stack pointer
    movfw   sched_temp1
    movwf   FSR0L
    movlw   high datStack
    movwf   FSR0H
    ; restore where FSR1 was pointing
    movfw   sched_temp2
    movwf   FSR1L
    return

;**********
;**********
; Process Schedule to see if any appointments have expired
    ;if they have then push the job token to the job queue
;**********
;**********

PSExit1
    return
ProcessSchedule ; take any and expired appointments and place on token queue
    banksel sched
    movlw   1
    addwf    timer_TOD,F
    btfsc   STATUS,C
    incf    timer_TOD+1,F
    ; search the schedule for expiring events
    ; assume that this routine gets called often enough to catch them all
    ; by exact match.  Thus events that are further out in time may have lower
    ; values than the present time which may not have wrapped yet.

    ; check for any appointments
    ;banksel sched
    movlw   low sched ; if schedPtr == low sched then it's empty
    subwf   schedPtr,W
    btfsc   STATUS,Z
    bra     PSExit1
    lcall   GetTime ; check to see if any appointments match the current time
    movlw   high sched
    movwf   FSR1H
    movlw   low sched
    movwf   FSR1L
ProSchLoop1
    Dup2    ; make another copy of the time
    moviw   FSR1++  ; MSB get the time of the next scheduled appointment
    Push
    moviw   FSR1++  ; LSB
    Push
    Swap    ; tos is MSB
    moviw   FSR1++  ; save the jump table index for maybe using later if there is a time match
    movwf   sched_temp1
    Eq2
    Pop
    btfsc   STATUS,Z ; with a false (0) z flag will be set.  Therefore clear means found a match.
    bra     ProSch20
    movfw   sched_temp1    ; expired appointment found
    Push
    lcall   PushJob
    ; move the remaining appoinments down a notch:
    ; first move the pointer back to the beginning of this appointment:
    moviw   --FSR1
    moviw   --FSR1
    moviw   --FSR1
    ; next check to see the schedule is empty, if so update and return
;    movfw   FSR1L
;    subwf   low sched,w
;    btfss   STATUS,Z
;    bra     ProSch15
    ; schedule is empty
;    movfw   low sched ; update the top of schedule (tos position) pointer
;    movwf   schedPtr
;    return
ProSch15 ; delete the matching entry and after that continue on to see if another one for the same time exists
    call    DeleteAppointment
ProSch20 ; see if done searching table
    movfw   FSR1L
    subwf   schedPtr,W
    btfss   STATUS,Z
    bra     ProSchLoop1
    Pop ; remove time from the stack
    Pop
    return

    END