#include <xc.inc>
    
global	Heart_Rate_Zone_Msg, Heart_Rate_Msg, Welcome_Msg, Load_Measured_Heart_Rate_Zone, Load_Measured_Heart_Rate, Write_to_FSR
extrn	Divide_By_Hundred, Divide_By_Ten
extrn	hr_msg, hrz_msg, welcome_msg, measured_heart_rate_address, measured_heart_rate_zone_address, Count, ten_digit, hundred_digit, HR_Zone
    
psect	Messages, class = CODE

Heart_Rate_Msg:
	movlw   hr_msg
	movwf   FSR0

	movlw   'H'
	movwf   INDF0
	incf    FSR0
	movlw   'e'
	movwf   INDF0
	incf    FSR0
	movlw   'a'
	movwf   INDF0
	incf    FSR0
	movlw   'r'
	movwf   INDF0
	incf    FSR0
	movlw   't'
	movwf   INDF0
	incf    FSR0
	movlw   ' '
	movwf   INDF0
	incf    FSR0
	movlw   'R'
	movwf   INDF0
	incf    FSR0
	movlw   'a'
	movwf   INDF0
	incf    FSR0
	movlw   't'
	movwf   INDF0
	incf    FSR0
	movlw   'e'
	movwf   INDF0
	incf    FSR0
	movlw   ':'
	movwf   INDF0
	incf    FSR0
	return
	
Heart_Rate_Zone_Msg:
	movlw   hrz_msg
	movwf   FSR0

	movlw   'Z'
	movwf   INDF0
	incf    FSR0
	movlw   'o'
	movwf   INDF0
	incf    FSR0
	movlw   'n'
	movwf   INDF0
	incf    FSR0
	movlw   'e'
	movwf   INDF0
	incf    FSR0
	movlw   ':'
	movwf   INDF0
	incf    FSR0
	return

Welcome_Msg:
	movlw   welcome_msg
	movwf   FSR0

	movlw   'I'
	movwf   INDF0
	incf    FSR0
	movlw   'n'
	movwf   INDF0
	incf    FSR0
	movlw   'p'
	movwf   INDF0
	incf    FSR0
	movlw   'u'
	movwf   INDF0
	incf    FSR0
	movlw   't'
	movwf   INDF0
	incf    FSR0
	movlw   ' '
	movwf   INDF0
	incf    FSR0
	movlw   'A'
	movwf   INDF0
	incf    FSR0
	movlw   'g'
	movwf   INDF0
	incf    FSR0
	movlw   'e'
	movwf   INDF0
	incf    FSR0
	movlw   ':'
	movwf   INDF0
	incf    FSR0
	return


Load_Measured_Heart_Rate_Zone:
	movwf	HR_Zone
	
	movlw	measured_heart_rate_zone_address
	movwf	FSR0
	
	movff	HR_Zone, WREG
	addlw	'0'
	call	Write_to_FSR
	return
	
Load_Measured_Heart_Rate:      ; enter with measured heart rate in WREG
	movwf	Count
	
	movlw	measured_heart_rate_address
	movwf	FSR0
	
	movff	Count, WREG
	call	Divide_By_Hundred   ; return with quotient in WREG
	movwf	hundred_digit
	movff	hundred_digit, WREG
	addlw	'0'
	call	Write_to_FSR
	movff	hundred_digit, WREG
	mullw	100		   ; subtract hundred digit
	movff	PRODL, WREG	   
	subwf	Count, 1	    ; Count - PRODL (the hundred digit), store in Count
	
	movff	Count, WREG
	call	Divide_By_Ten
	movwf	ten_digit
	movff	ten_digit, WREG
	addlw	'0'
	call	Write_to_FSR
	movff	ten_digit, WREG
	mullw	10
	movff	PRODL, WREG
	subwf	Count, 1
	
	movff	Count, WREG
	addlw	'0'
	call	Write_to_FSR
	return
		
Write_to_FSR:
	movwf	INDF0
	incf	FSR0
	return
