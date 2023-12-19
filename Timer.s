#include <xc.inc>

global	Timer_Setup
psect	External_timer, class = CODE

Timer_Setup:	
	movlw   10000011B	; Fcyc/256 = 62.5 KHz
	movwf   T0CON, A
	bsf	GIE	    ;enable all interrupts 7=GIE
	bsf	INTCON, 6
	bsf     INTCON, 5 ;TMR0IE
	return
	


	