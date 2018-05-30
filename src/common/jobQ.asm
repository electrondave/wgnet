;*******************************************************************************
;                          JOB QUEUE                                           *
;    Filename:         jobQ.asm                                         *
;    Date:             April 24, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      token stack fifo processor
;
; Here we temporariliy store deferred operations.  The purpose is to keep
; applications from stepping on each other
; the os will push to the queue outside of application processing time
; or an application will push to this queue during it's processing
; or an interrupt will push to it's own deferred queue which this os will move to
; this queue through a subroutine called in the main loop.
;
; Also in the main loop, the OS will call a routine to pull the job_index
    ; from this queue
    ; then using the the jump table, it will call a routine
    ; the routine shall pull any of it's parameters before it returns

; a variable amount of parameters are acceptable to be pushed on the queue.
    ; the routine placing the job_index must put the proper number on the queue.
    ; the deferred routine when called must remove all it's params.

; somewhere there will be a set of subroutines that are run for each job_index

; queue is first in, first out therfore both queue pointers both only increment.
    ; referred to as the 'job' queue or fifo

;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                        0.1 initial writing                                   *
;*******************************************************************************
#include "p16f15324.inc"
#include "forth.inc"
    extern forth_temp1
    extern forth_temp2
    extern forth_temp3
    extern forth_temp4

;#include    "../../src/snoop/jobList.inc"

    global  InitJobQ
    global  PushJob
    global  ProcessJobQueue
    global  PopJob
    global  jobQFlags

    extern  RunNextJob

section_jobQ    UDATA   h'120'
JOB_Q_START     res d'20'
JOB_Q_END
jobQIn_p        res 1
jobQOut_p       res 1
jobQFlags       res 1 ; bit 0 is empty, bit 1 is full
jobTemp1        res 1
bsrSave         res 1
fsrHSave        res 1
fsrLSave        res 1

    CODE

InitJobQ
; setup the token queue pointers
    banksel jobQIn_p
    movlw   low JOB_Q_START
    movwf   jobQIn_p
    movwf   jobQOut_p
    clrf    jobQFlags
    bsf     jobQFlags,Q_EMPTY
    return

PushJob ; pointer ops are post increment, so it points at the next insertion point,
    ; data stack:  ( a - )
    ; token stack: ( - a )

    ; save the environment
    movfw   BSR
    banksel JOB_Q_START
    movwf   bsrSave
    movfw   FSR1H
    movwf   fsrHSave
    movfw   FSR1L
    movwf   fsrLSave

    ; FSR1 is avail / FSR0 is used for the data stack
    ; after pushing if in_p == out_p then mark full
    ; check full before pushing.
    btfsc jobQFlags,Q_FULL
    bra exe_q_full_error

    movlw   high JOB_Q_START
    movwf   FSR1H
    movfw   jobQIn_p
    movwf   FSR1L
    Pop
    movwi   FSR1++
    ; Handle pointer wrapping:
    ; after pushing check if pointer is at TOQ+1, if so set to BOQ
    movlw   low JOB_Q_END
    subwf   FSR1L,W
    btfss   STATUS,Z
    bra     test_for_full
    ; need to rolover
    movlw   low JOB_Q_START
    bra     ahead
test_for_full
    movfw   FSR1L
ahead
    movwf   jobQIn_p
    subwf   jobQOut_p,W         ; if equal
    btfsc   STATUS,Z
    bsf     jobQFlags,Q_FULL    ; then mark full
    bcf     jobQFlags,Q_EMPTY   ; we just pushed so we can't be empty
    movfw   fsrHSave ; restore the environment
    movwf   FSR1H
    movfw   fsrLSave
    movwf   FSR1L
    movfw   bsrSave ; do BSR last so the above two moves work
    movwf   BSR
    return

exe_q_full_error
    ;todo Push Q_FULL_ERR / call Exception
    nop
    bra exe_q_full_error

; ****************
; get a job from the job q and put on data stack
; ****************

PopJob ; to data stack
    ; token stack: ( a - )
    ; data stack:  ( - a )

    ; save the environment
    movfw   BSR
    banksel JOB_Q_START
    movwf   bsrSave
    movfw   FSR1H
    movwf   fsrHSave
    movfw   FSR1L
    movwf   fsrLSave

    btfsc   jobQFlags,Q_EMPTY  ;check to see if empty
    bra     exe_q_empty_error
    movlw   high JOB_Q_START
    movwf   FSR1H
    movfw   jobQOut_p
    movwf   FSR1L
    moviw   FSR1++  ;
    Push
    ; Handle wrapping if needed:
    ; after poping check if pointer is at JOB_Q_END, if so set to beginning
    movlw   low JOB_Q_END
    subwf   FSR1L ,W
    btfss   STATUS,Z
    bra     test_for_empty
    movlw   low JOB_Q_START ; need to rolover
    bra     test_for_empty_20
test_for_empty
    movfw   FSR1L
test_for_empty_20
    movwf   jobQOut_p           ; update the out pointer
    subwf   jobQIn_p,W          ; if empty?
    btfsc   STATUS,Z
    bsf     jobQFlags,Q_EMPTY   ; then mark empty
    bcf     jobQFlags,Q_FULL    ; we just poped so we can't be full

    movfw   fsrHSave            ; restore the environment
    movwf   FSR1H
    movfw   fsrLSave
    movwf   FSR1L
    movfw   bsrSave             ; restore BSR last of all
    movwf   BSR
    return

exe_q_empty_error
    ;todo Push Q_EMPTY_ERR / call Exception
    nop
    goto exe_q_empty_error

ProcessJobQueue  ; run all the deferred calls
    banksel JOB_Q_START
    btfsc   jobQFlags,Q_EMPTY    ; if the queue is empty then return
    return
    lcall    RunNextJob
    bra     ProcessJobQueue

    END
