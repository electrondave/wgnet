; Q Macros May 12, 2018

pushQ   macro   Q_START, Q_END, in_p, temp
    local PushQ_10, PushQ_Exit
    ; W is pushed, the routing uses FSR1
    ; doesn't check for full
    ; temp needs to be in same bank
    banksel Q_START
    movwf   temp
    movlw   high Q_START
    movwf   FSR1H
    movfw   in_p
    movwf   FSR1L
    movfw   temp
    movwi   FSR1++
    movlw   low Q_END           ; if past end of Q
    subwf   FSR1L,w
    btfss   STATUS,Z
    bra     PushQ_10
    movlw   low Q_START         ; then Wrap the pointer back to Q start
    bra     PushQ_Exit
PushQ_10
    movfw   FSR1L               ; else update with FSR
PushQ_Exit
    movwf   in_p
    endm

; **************

popQ    macro   Q_START, Q_END, out_p, temp
    local PopQ_10, PopQ_Exit
    ; W gets Top of Q
    ; over writes FSR1
    ; temp needs to be in same bank
    banksel Q_START
    movlw   high Q_START
    movwf   FSR1H
    movfw   out_p
    movwf   FSR1L
    moviw   FSR1++
    movwf   temp
    movlw   low Q_END       ; if past end of q
    subwf   FSR1L,W
    btfss   STATUS,Z
    bra     PopQ_10
    movlw   low Q_START     ; then wrap pointer back to start of Q
    bra     PopQ_Exit
PopQ_10
    movfw   FSR1L           ; else use the incremented FSR
PopQ_Exit
    movwf   out_p
    movfw   temp
    endm




