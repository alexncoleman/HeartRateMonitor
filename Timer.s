#include <xc.inc>

global	Timer_Setup, Increase_Interrupt
extrn	OverflowCounter_1, OverflowCounter_2
psect	External_timer, class = CODE

Timer_Setup:	
	movlw   10000011B	; Fcyc/16 = 1MHz
	movwf   T0CON, A
	bsf	GIE	    ;enable all interrupts 7=GIE
	bsf	INTCON, 6
	bsf     INTCON, 5 ;TMR0IE
	return
	
Increase_Interrupt:
	INCF	OverflowCounter_1, 1
	MOVFF	OverflowCounter_1, WREG
	;MOVFF	OverflowCounter_1, LATH
	bcf     TMR0IF
	movlw   10000011B	; Fcyc/16 = 1MHz
	movwf   T0CON, A
	BC	Increment_OFC2		; Branch if carry
	return
Increment_OFC2:
	INCF	OverflowCounter_2, 1
	;MOVFF	OverflowCounter_2, WREG
	return

	