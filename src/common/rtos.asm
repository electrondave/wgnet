; routines to utilize the deferred job queue

;todo: figure out what parameters would be needed to make the push and pop macros?

    ;*******************************************************************************
;                                                                              *
;    Filename:         rtos.asm       (execution queue processing)                                         *
;    Date:             April 4, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      token stack fifo processor                              *
    ; a token for the routine to call and 0 to n paramaters can be pushed to the fifo
    ; each token processor will push the params onto the data stack and then call a routine
; somewhere there will be a set of subroutines that are run for each token

    ;needed code
    ;breakup pushes into 2 types: push lit to q / push data to q

;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                        0.1 first cut at the RTOS                             *
;*******************************************************************************
#include "p16f15324.inc"
    extern  datStack
#include "forth.inc"
    extern  forth_temp1, forth_temp2

    CODE




    END
