;*******************************************************************************
;                                                                              *
;    Filename:         ook_driver.asm                                          *
;    Date:             April 4, 2018                                           *
;    File Version:     0.1                                                     *
;    Author:           David Bartholomew                                       *
;    Company:          Walnut Glen                                             *
;    Description:      ook modulator / PPM Media Access Arbitrator      *
;                                                                              *
;*******************************************************************************

;    global 
#include "p16f15324.inc"

;    RC0PPS = 0x11;  // RC0 is TX2
;    
;// CLC1 configuration
;    
;    
;//? Disable CLCx by clearing the LCxEN bit of the
;//CLCxCON register.
;    CLC1CON = 0;
;    
;//? Select desired inputs using CLCxSEL0 through
;//CLCxSEL3 registers (See Table 31-2).
;    CLC1SEL0 = 4;  // 4 mhz
;    CLC1SEL1 = 31; // Uart 1 tx
;    CLC1SEL2 = 8;  // 32kHz
;    CLC1SEL3 = 8;  // 32kHz
;    
;        
;//? Clear any associated ANSEL bits.
;    
;//? Enable the chosen inputs through the four gates
;//using CLCxGLS0, CLCxGLS1, CLCxGLS2, and
;//CLCxGLS3 registers.
;    CLC1GLS0 = 2;  // b1: odd bits are true select the 4 mhz only
;    CLC1GLS1 = 8;  // b3: select the uart only
;    CLC1GLS2 = 0;  // no signal
;    CLC1GLS3 = 0;  // no signal
;    
;    
;//? Select the gate output polarities with the
;//LCxGyPOL bits of the CLCxPOL register.
;    CLC1POL = 0x02;  // channel 1 inverted
;    
;//? Select the desired logic function with the
;//LCxMODE<2:0> bits of the CLCxCON register.
;    CLC1CON = 0; // 'AND-OR' functional mode
;    
;//? Select the desired polarity of the logic output with
;//the LCxPOL bit of the CLCxPOL register. (This
;//step may be combined with the previous gate output
;//polarity step).
;    // done iwth high bit 0
;    
;//? If driving a device pin, set the desired pin PPS
;//control register and also clear the TRIS bit
;//corresponding to that output.
;    //RC4 is the modulator output
;    RC4PPS = 1; // select CLC1OUT;
;        
;    
;//? If interrupts are desired, configure the following
;//bits:
;//- Set the LCxINTP bit in the CLCxCON register
;//for rising event.
;//- Set the LCxINTN bit in the CLCxCON
;//register for falling event.
;//- Set the CLCxIE bit of the PIE5 register.
;//- Set the GIE and PEIE bits of the INTCON
;//register.
;    
;//? Enable the CLCx by setting the LCxEN bit of the
;//CLCxCON register.
;        CLC1CON  |= 0x80;
;
;    
;    
;    
;    
;    
;    
;    
;; use dibit (2 bits) ppm encoding
    
    END