;*******************************************************************************
;                                                                              *
;    Filename:         memory_map.asm                                         *
;    Date:             April 10, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      memory allocation file                                            *
;*******************************************************************************

; variables should be defined locally if possible
; there are 6 80 byte (0x50) UDATA sections available in the PIC16F15324
; for general purpose and 16 more in the 7th one

; a note about section types:
	; udata is user data allocated to general purpose ram
	; udata_acs is not for this processor type
	; udata_ovr is when you want to re-use the same memory with new labels
	; udata_shr is available in all of the banks


; reserve FSR0 for the data_stack pointer
; FSR1 not reserved so it is open for usage by all
; inside of interrupts, the FSRn are stored and restored so they can use at will

; bank allocation
; lowest mem is os, highest is application
;    0 - 020: isr_fifo
;    1 - 0A0: data_stack (forth); _appRegs
;    2 - 120: jobQ; system variables; schedule
;    3 - 1A0: com network fifos
;    4 - 220: com console/bridge fifos
;    5 - 2A0: application
;    6 - 320: 20 to 2F only; rtos system variables
;

; shared ram
;    70: forth_temp1
;    71: forth_temp2
;    72: forth_temp3
;    73: forth_temp4
;    74: str_ptr
;    75: ii
;    76: jj
;    77: kk
;    78:
;    79:
;    7a:
;    7b:
;    7c:
;    7d:
;    7e:
;    7f:


#include "p16f15324.inc"

    global ii
    global jj
    global kk
    global strPtr
    global forth_temp1, forth_temp2, forth_temp3, forth_temp4



sec_shared  UDATA_SHR ; 16 memories Xf0-Xff available.  Accessable from any bank
forth_temp1 res 1
forth_temp2 res 1
forth_temp3 res 1
forth_temp4 res 1
strPtr  res 1
ii  res 1
jj  res 1
kk  res 1

    END
