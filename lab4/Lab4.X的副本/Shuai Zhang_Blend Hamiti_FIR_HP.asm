;***********************************************************
; File Header
;***********************************************************

    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>

 
    config SDOMX = RC7
    
    
outcome_1_L	 equ 0x05
outcome_1_H	 equ 0x10
outcome_2_L	 equ 0x06  
outcome_2_H	 equ 0x11  
outcome_3   equ 0x09	 
buffer_1    equ 0x07
buffer_2    equ 0x08
;input  equ 0x12


    
;***********************************************************
; Reset Vector
;***********************************************************

    ORG     0x1000   ; Reset Vector
           ; When debugging:0x000; when loading: 0x1000
    goto    START


;***********************************************************
; Interrupt Vector
;***********************************************************

    ORG     0x1008 ; Interrupt Vector  HIGH priority
    goto    inter_high ; When debugging:0x008; when loading: 0x1008
    ORG     0x1018 ; Interrupt Vector  HIGH priority
    goto    inter_low ; When debugging:0x008; when loading: 0x1018


;***********************************************************
; Program Code Starts Here
;***********************************************************

    ORG     0x1020 ; When debugging:0x020; when loading: 0x1020

START
    call    init_chip  ; initialize ports and some other registers
    call    init_timer  ; initialize timers
    call    init_ADC  ; initialize A/D converter
    call    init_PWM  ; initialize PWM module
    call    init_FIR  ; initialize filter
    bsf     T0CON, 7  ; TMR0ON, Enable Timer0
    bsf     T2CON, 2  ; TMR2ON, Enable Timer2
    bsf     INTCON, 7  ; GIE, Enable interrupt
    
main
    
    ;bsf     PIR1,6
    bra     main
    
init_chip
    movlw   0x80
    movwf   OSCTUNE
    movlw   0x70
    movwf   OSCCON
    movlw   0x10
    movwf   OSCCON2
    
    clrf    PORTA   ; Initialize PORTA by clearing output data latches
    movlw   0xFF   ; Value used to initialize data direction
    movwf   TRISA   ; Set PORTA as input
    movlw   0x00   ; Configure comparators for digital input
    movwf   CM1CON0
    clrf    PORTB   ; Initialize PORTB by clearing output data latches
    movlw   0x00   ; Value used to initialize data direction
    movwf   TRISB   ; Set PORTB as output
    clrf    PORTC   ; Initialize PORTC by clearing output data latches
    clrf    TRISC  ; define PORTC as outpnput
    bcf     UCON,3  ; to be sure to disable USB module
    bsf     UCFG,3  ; disable internal USB transceiver
    clrf outcome_1_L	 
    clrf outcome_1_H	 
    clrf outcome_2_L	 
    clrf outcome_2_H	   
    clrf outcome_3    	 
    clrf buffer_1     
    clrf buffer_2    
    return

init_timer
    movlw   0x41 ;Timer0 defines sample rate CHANGE THE LITERAL HERE!!!!!!!!!!!
    movwf   T0CON ;Timer0 Control Register
                 ;bit7 "0": Disable Timer
                 ;bit6 "1": 8-bit timer
                 ;bit5 "0": Internal clock
                 ;bit4 "0": not important in Timer mode
                 ;bit3 "0": Timer0 prescale is assigned
                 ;bit2-0  : prescale=1:4 which means bit2-0: 001 
    ;F = Fosc/(4*Prescale*number of counting)   F:sampling requency=12Khz, Fosc=48Mhz,prescale=4,number of counting=250 
    clrf    TMR0L ;clear timer
    movlw   0x20 ;Interrupt settings for Timer0
    movwf   INTCON ;Interrupt Control Register
                 ;bit7 "0": Global interrupt Enable
                 ;bit6 "0": Peripheral Interrupt Enable
                 ;bit5 "1": Enables the TMR0 overflow interrupt
                 ;bit4 "0": Disables the INT0 external interrupt
                 ;bit3 "0": Disables the RB port change interrupt
                 ;bit2 "0": TMR0 Overflow Interrupt Flag bit
   ;bit1 "0": INT0 External Interrupt Flag bit
   ;bit0 "0": RB Port Change Interrupt Flag bit
    movlw   0x00 ;Timer2 is used for PWM
    movwf   T2CON ;Timer2 Control Register
                 ;bit7 "0": unimplemented
                 ;bit6-3 "0000": Postscale 1:1
                 ;bit2 "0": Timer off
                 ;bit1-0 "00": Prescale 1:1  
    clrf    TMR2 ;clear timer
    return

init_ADC
    movlw   0x00
    movwf   ADCON1 ;A/D Control Register 1
   ;bit7-6 "00": unimplemented
   ;bit5   "0": VSS as voltage reference
   ;bit4   "0": VDD as voltage reference
   ;bit3-0 "0000": all ports are analog input
    movlw   0x01
    movwf   ADCON0 ;A/D Control Register 0
   ;bit7-6 "00": unimplemented
   ;bit5-2 "0000": Channel 0 (AN0)
   ;bit1   "0": A/D idle, do not start conversion yet
   ;bit0   "1": A/D converter module is enabled
    movlw   0x36
    movwf   ADCON2 ;A/D Control Register 2
   ;bit7   "0": left justified
   ;bit6   "0": unimplemented
   ;bit5-3 "110": A/D Acquisition Time is 16 Tad
   ;bit2-0 "110": A/D Conversion Clock is Fosc/64
    bsf     INTCON, 6 ;PEIE_GIEL bit, enables peripheral interrupts 
    bcf     PIR1, 6 ;ADIF bit = flag bit
    bsf     PIE1, 6 ;ADIE bit, enables the A/D interrupt
    return

init_PWM
    movlw   0xFF
    movwf   PR2  ;PWM period = 255
   ;Period = [(PR2+1)*4*Tosc*(TMR2 Prescale value)
   ;= 256 * 4 * (1/48 MHz) * 1
   ;= 21,33 µs (46,8 kHz)
    movlw   0x0F
    movwf   CCP2CON ;Standard CCP2 control register
   ;bit7-6 "00": unimplemented
   ;bit5-4 "00": 2 LSBs of duty cycle (10-bit)
   ;bit3-0 "1111": PWM mode
    movlw   D'128'
    movwf   CCPR2L ;Duty cycle = 128 to start with
    return

init_FIR
    ; buffer of input samples starts at address 0x020
    lfsr    0, 0x020 ; FSR0 is used for the input samples
    clrf    0x20 ; now follows a buffer of 9 samples
    clrf    0x21 ; all cleared
    clrf    0x22
    clrf    0x23
    clrf    0x24
    clrf    0x25
    clrf    0x26
    clrf    0x27
    clrf    0x28
 
    ; table of filter coefficients starts at address 0x030
    lfsr    1, 0x030 ; FSR1 is used for the filter coefficients
    movlw   D'40'	; b(0)
    movwf   0x30
    movlw   D'35'	; b(1)
    movwf   0x31
    movlw   D'20'	; b(2)
    movwf   0x32
    movlw   D'0'	; b(3)
    movwf   0x33
    movlw   D'247'	; b(4)
    movwf   0x34
    movlw   D'0'	; b(5)
    movwf   0x35
    movlw   D'20'	; b(6)
    movwf   0x36
    movlw   D'35'	; b(7)
    movwf   0x37
    movlw   D'40'	; b(8)
    movwf   0x38
    return

operation_before
    movf  POSTDEC0,0			 ;take the value from input buffer at current point then change the address to the before
    mulwf POSTINC1			 ;multiply the value from coefficient buffer at start point then change the address to the next
    movf  PRODH,0
    addwf outcome_1_L,1			 ;refresh the outcome register
    movlw 0x00
    addwfc outcome_1_H,1
    movlw 0x20
    CPFSLT FSR0L			 ;go back to 0x20 if value of FSR0L smaller than 0x20
    goto operation_before
    lfsr 0,0x28
    goto operation_after
    
operation_after 
    movf  POSTDEC0,0	
    mulwf POSTINC1		
    movf  PRODH,0
    addwf outcome_1_L,1			 ;refresh the outcome register
    movlw 0x00
    addwfc outcome_1_H,1
    movlw  0x38
    CPFSGT FSR1L			 ;finish the operation if the FSR1 address is bigger than 0x38
    goto operation_after
    call init_FSR
    lfsr    0, 0x020
    goto second_term

second_term
   movlw D'41'
   mulwf POSTINC0
   movf PRODH,0
   addwf outcome_2_L,1
   movlw 0x00
   addwfc outcome_2_H,1
   movlw 0x28
   CPFSGT FSR0L
   goto second_term
   call init_FSR
   goto subtraction

subtraction
   movf outcome_2_L,0
   subwf outcome_1_L,1
   movf outcome_2_H,0
   subwfb outcome_1_H,1
   call negative_detect
   movlw  0x00
   CPFSGT outcome_1_H		;if final outcome is not negative value then continu judge 
   goto low_bit
   goto high_bit
   
negative_detect
   BTFSS STATUS,4	    ;check if the final outcome is negative value
   return
   movlw 0x00
   movwf outcome_3
   clrf outcome_1_H
   clrf outcome_1_L
   clrf outcome_2_H
   clrf outcome_2_L
   return


high_bit
 movlw 0xFF
 movwf outcome_3
 clrf outcome_1_H
 clrf outcome_1_L
 clrf outcome_2_H
 clrf outcome_2_L
 return
 
low_bit
 movff outcome_1_L,outcome_3
 clrf outcome_1_H
 clrf outcome_1_L
 clrf outcome_2_H
 clrf outcome_2_L
 return
   
init_FSR
    movlw 0x23
    movwf FSR0L		    ;initialize FSR0L
    lfsr    1, 0x030		;initialize FSR1L
    return
    
refresh_input_buffer_before   
    movff INDF0,buffer_2
    movff buffer_1,POSTDEC0
    movff buffer_2,buffer_1
    movlw 0x20
    CPFSLT FSR0L
    goto refresh_input_buffer_before
    lfsr 0,0x28
    goto refresh_input_buffer_after
    
refresh_input_buffer_after   
    movff INDF0,buffer_2
    movff buffer_1,POSTDEC0
    movff buffer_2,buffer_1
    movlw 0x24
    CPFSLT FSR0L
    goto refresh_input_buffer_after
    clrf buffer_1
    clrf buffer_2
    return
max_duty 
    movlw 0xFF
    movwf outcome_3
    return
    
inter_high
    btfss   PIR1, 6		    	; ADIF bit, interrupt is caused by A/D converter
    bra     inter_tmr0			; check next interrupt source
inter_ADC
    bcf     ADCON0, 1			; GODONE bit, stop the A/D conversion
    call init_FSR	    		;set initial FSR0 and FSR1   
    movff    ADRESH, buffer_1			; read the value of the ADC (only upper 8 bits)
    call refresh_input_buffer_before
    call operation_before
    movlw D'94'
    addwf outcome_3,1
    BTFSC STATUS,0
    call  max_duty
    movf outcome_3,0
    movwf   CCPR2L			; and store it in the duty cycle register
    clrf   outcome_3			;clear result register for next time usage
					; WRITE THE CODE FOR THE FIR FILTER BETWEEN THE TWO INSTRUCTIONS ABOVE!!!!!!!!!!!!!!!!
    bcf     PIR1, 6			; ADIF bit has to be cleared
    retfie
    
inter_tmr0
    btfss   INTCON, 2			; TMR0IF, interrupt is caused by Timer0
    retfie				; if not, then return
    movlw   D'5'			; this value sets the sample frequency (see formula in init_timer) CHANGE IT!!!!!!!!!!!!!
    movwf   TMR0L			; initialize timer again
    bsf     ADCON0, 1			; GODONE bit, starts the A/D conversion
    bcf     INTCON, 2			; clear interrupt flag
    retfie

inter_low
    nop
    retfie

    END