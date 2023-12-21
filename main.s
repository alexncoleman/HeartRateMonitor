#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message, UART_Transmit_Byte	; UART subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_clear, LCD_shift	; LCD subroutine
extrn	Keypad_INIT, Keypad_READ				; Keypad subroutines
extrn	Read_Age_Input_Find_HR_Max				; Decoding Keypad Input subroutines
extrn	Divide_By_Ten, Load_HRZ_Table, Determine_HRZ, IIR_Filter, Divide_By_Hundred, Sixteen_Division  ; Calculations
extrn	Timer_Setup, Increase_Interrupt				; Timer subroutines
extrn	Heart_Rate_Zone_Msg, Heart_Rate_Msg, Welcome_Msg, Load_Measured_Heart_Rate_Zone, Load_Measured_Heart_Rate, Write_to_FSR	; Messages displayed on LCD
    
global	hr_msg, hrz_msg, welcome_msg, age_address_1, age_address_2, heart_rate_zone_address, measured_heart_rate_zone_address, measured_heart_rate_address
global	OverflowCounter_1, OverflowCounter_2
global	Count, ten_digit, hundred_digit, HR_Zone
	
psect	udata_acs   ; reserve data space in access ram
OverflowCounter_1:ds	1
OverflowCounter_2:ds	1
Count:ds	1
hundred_digit:ds    1
ten_digit:ds	1
single_digit:ds	1
HR_Zone:ds	1
HR_Measured:ds	1   ; reserve one byte for measured HR value from sensor
HR_max: ds	1   ; the maximum heart rate calculated froma ge
hr_msg		EQU 0xE0
hrz_msg		EQU 0xF0
measured_heart_rate_address EQU 0xD0
measured_heart_rate_zone_address EQU 0xC0
welcome_msg EQU 0xB0
age_address_1 EQU	0xA0
age_address_2 EQU	0xA1
heart_rate_zone_address    EQU	0xC2

psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	edata	    ; store data in EEPROM, so can read and write
;ORG 0x1000 
	; ******* myTable containing multipliers to calculate heart rate zones, in EEPROM *****
Database:
	DB  20, 18, 17, 15, 13, 11
	align	2

psect	code, abs	
rst: 	org 0x0
 	goto	setup

Timer_Interrupt:org  0x0008
	btfss   TMR0IF
	retfie	f
	call	Increase_Interrupt
	retfie	f
	
	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	Keypad_INIT	; setup keypad
	call	LCD_Setup
	call	Timer_Setup
	
	; load messages into database
	call	Heart_Rate_Msg
	call	Heart_Rate_Zone_Msg
	call	Welcome_Msg
	
	movlw	0x00
 	movwf	OverflowCounter_1	; Initialise Time_Counter
 	movwf	OverflowCounter_2

	movlw	0x00
	movwf	TRISH

	movlw	0x00
	movwf	TRISF
	
; 	movlw	0x00
; 	movwf	TRISC
	
	movlw	0xFF
	movwf	TRISD
	
	movlw	0x00
	movwf	TRISJ
	
	;movlw	0
	;movwf	kb_pressed, A	; initialise this as 0, to indicate o key has been pressed
		
	goto	start
	
	; ******* Main programme ****************************************

start: 	
	call	LCD_clear
	movlw	welcome_msg
	movwf	FSR2
	movlw	10		; because there are 11 letters
	call	LCD_Write_Message   ; write welcome messgae, prompt age input
	call	LCD_shift
	
	call	Read_Age_Input_Find_HR_Max  ; return with W = HRmax
	movwf	HR_max
	movlw	121
	call	Load_HRZ_Table
	 	
 	call	Timer_Setup	    ; this needs to happen after loading HRZ table, because interrupts interfere with eeprom

	movlw	0x00
	movwf	PORTJ, A		; clear checking port
Detection_Loop:
	
	movlw	0x00
	CPFSGT	PORTD		; skip if pulse signal is high
	bra	Update_and_Branch
	CPFSGT	PORTJ		; skip if previous pulse was also high
	call	Signal_Detected
	bra	Update_and_Branch
Update_and_Branch:
	MOVFF	PORTD, PORTJ	; update LATJ with current value
	MOVLW	0x00
	MOVWF	PORTH
	bra	Detection_Loop
Signal_Detected:
	MOVFF	PORTD, PORTJ	; update LATJ with current value	
	MOVLW	0xFF
	MOVWF	PORTH
	
	;still need to calculate heart rate from here
	movff	OverflowCounter_1, WREG
	mullw	66
	call	Sixteen_Division
	MOVWF	HR_Measured
	
	;MOVFF	PRODL, HR_Measured	; move timer count to WREG, OverflowCounter increments 1 every 4.08ms
	;MOVFF	HR_Measured, WREG
	call	IIR_Filter	; Output_HR = average of past 3 measurements
	; write to LCD
	
	call	Load_Measured_Heart_Rate	; load heart rate into database
	call	LCD_clear
	
	movlw	hr_msg
	movwf	FSR2
	movlw	11		; because there are 11 letters
	call	LCD_Write_Message
	
	; write heart rate to LCD
	movlw	measured_heart_rate_address
	movwf	FSR2
	movlw	3		; assume 3 digits
	call	LCD_Write_Message ; Display the number
	call	LCD_shift
	
	; write heart rate to UART
	movlw	measured_heart_rate_address
	movwf	FSR2
	movlw	3
	call	UART_Transmit_Message
	
	CLRF	OverflowCounter_1, A		; reset time_counter
	
	movlw	','
	call	UART_Transmit_Byte 
		
	MOVFF	HR_Measured, WREG
	call	Determine_HRZ	; return with zone number in WREG
	call	Load_Measured_Heart_Rate_Zone
	
	; write hr zone prompt
	movlw	hrz_msg
	movwf	FSR2
	movlw	5		; because there are 5 letters
	call	LCD_Write_Message
	
	; write zone information
	movlw	measured_heart_rate_zone_address
	movwf	FSR2
	movlw	1
	call	LCD_Write_Message ; Display the number
	call	LCD_shift
	
	movlw	measured_heart_rate_zone_address
	movwf	FSR2
	movlw	1
	call	UART_Transmit_Message
	
	movlw	0x0A
	call	UART_Transmit_Byte 
	
	
	bra	Detection_Loop
	
	
	end	rst
	