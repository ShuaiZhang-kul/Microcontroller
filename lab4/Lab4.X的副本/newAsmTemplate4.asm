Changed version of high pass
;***********************************************************
; File Header
;***********************************************************

    list p=18F2550, r=hex, n=0
    #include <p18F2550.inc>
    
;***********************************************************
; Reset Vector
;***********************************************************

    ORG     0x1000   ; Reset Vector
    		     ; When debugging:0x000; when loading: 0x1000
    goto    START


;***********************************************************
; Interrupt Vector
;***********************************************************

    ORG     0x1008	; Interrupt Vector  HIGH priority
    goto    inter_high	; When debugging:0x008; when loading: 0x1008
    ORG     0x1018	; Interrupt Vector  HIGH priority
    goto    inter_low	; When debugging:0x008; when loading: 0x1018


;***********************************************************
; Program Code Starts Here
;***********************************************************

    ORG     0x1020	; When debugging:0x020; when loading: 0x1020

START
    valueL equ 0x0A
    valueH equ 0x0B 
    location equ 0x0C  ;2 location variable to locate register
    location2 equ 0x1F 
    SUBSL equ 0x0E  
    SUBSH equ 0x0F
    call    init_chip		; initialize ports and some other registers
    call    init_timer		; initialize timers
    call    init_ADC		; initialize A/D converter
    call    init_PWM		; initialize PWM module
    call    init_FIR		; initialize filter
   
    bsf	    T0CON, 7		; TMR0ON, Enable Timer0
    bsf	    T2CON, 2		; TMR2ON, Enable Timer2
    bsf	    INTCON, 7		; GIE, Enable interrupt
    
main
    bra	    main

init_chip
    clrf    PORTA 		; Initialize PORTA by clearing output data latches
    movlw   0xFF 		; Value used to initialize data direction
    movwf   TRISA 		; Set PORTA as input
    movlw   0x07 		; turn off comparators
    movwf   CMCON
    clrf    PORTB 		; Initialize PORTB by clearing output data latches
    movlw   0x00 		; Value used to initialize data direction
    movwf   TRISB 		; Set PORTB as output
    clrf    PORTC 		; Initialize PORTC by clearing output data latches
    clrf    TRISC		; define PORTC as outpnput
    bcf     UCON,3		; to be sure to disable USB module
    bsf     UCFG,3		; disable internal USB transceiver
     movlw 0x20
   movwf FSR2L
    return

init_timer
    movlw   0x42	;Timer0 defines sample rate CHANGE THE LITERAL HERE!!!!!!!!!!!
    movwf   T0CON	;Timer0 Control Register
               		;bit7 "0": Enable Timer
               		;bit6 "1": 8-bit timer
               		;bit5 "0": Internal clock
               		;bit4 "0": not important in Timer mode
               		;bit3 "0": Timer0 prescale is assigned
               		;bit2-0 "010"  : 1:8
			;F = Fosc/(4*Prescale*number of counting)
    clrf    TMR0L	;clear timer
    movlw   0x20	;Interrupt settings for Timer0
    movwf   INTCON	;Interrupt Control Register
               		;bit7 "0": Global interrupt Enable
               		;bit6 "0": Peripheral Interrupt Enable
               		;bit5 "1": Enables the TMR0 overflow interrupt
               		;bit4 "0": Disables the INT0 external interrupt
               		;bit3 "0": Disables the RB port change interrupt
               		;bit2 "0": TMR0 Overflow Interrupt Flag bit
			;bit1 "0": INT0 External Interrupt Flag bit
			;bit0 "0": RB Port Change Interrupt Flag bit
    movlw   0x00	;Timer2 is used for PWM
    movwf   T2CON	;Timer2 Control Register
               		;bit7 "0": unimplemented
               		;bit6-3 "0000": Postscale 1:1
               		;bit2 "0": Timer off
               		;bit1-0 "00": Prescale 1:1  
    clrf    TMR2	;clear timer
    return

init_ADC
    movlw   0x00
    movwf   ADCON1	;A/D Control Register 1
			;bit7-6 "00": unimplemented
			;bit5   "0": VSS as voltage reference
			;bit4   "0": VDD as voltage reference
			;bit3-0 "0000": all ports are analog input
    movlw   0x01
    movwf   ADCON0	;A/D Control Register 0
			;bit7-6 "00": unimplemented
			;bit5-2 "0000": Channel 0 (AN0)
			;bit1   "0": A/D idle, do not start conversion yet
			;bit0   "1": A/D converter module is enabled
    movlw   0x36
    movwf   ADCON2	;A/D Control Register 2
			;bit7   "0": left justified
			;bit6   "0": unimplemented
			;bit5-3 "110": A/D Acquisition Time is 16 Tad
			;bit2-0 "110": A/D Conversion Clock is Fosc/64
    bsf	    INTCON, 6	;PEIE_GIEL bit, enables peripheral interrupts 
    bcf	    PIR1, 6	;ADIF bit = flag bit
    bsf	    PIE1, 6	;ADIE bit, enables the A/D interrupt
    return

init_PWM
    movlw   0xFF
    movwf   PR2		;PWM period = 255
			;Period = [(PR2+1)*4*Tosc*(TMR2 Prescale value)
			;= 256 * 4 * (1/48 MHz) * 1
			;= 21,33 µs (46,8 kHz)
    movlw   0x0F
    movwf   CCP2CON	;Standard CCP2 control register
			;bit7-6 "00": unimplemented
			;bit5-4 "00": 2 LSBs of duty cycle (10-bit)
			;bit3-0 "1111": PWM mode
    movlw   D'128'
    movwf   CCPR2L	;Duty cycle = 128 to start with
    return

init_FIR
    ; buffer of input samples starts at address 0x020
    lfsr    0, 0x020	; FSR0 is used for the input samples
    clrf    0x20	; now follows a buffer of 9 samples
    clrf    0x21	; all cleared
    clrf    0x22
    clrf    0x23
    clrf    0x24
    clrf    0x25
    clrf    0x26
    clrf    0x27
    clrf    0x28
 
    ; table of filter coefficients starts at address 0x030
    lfsr    1, 0x030	; FSR1 is used for the filter coefficients
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
    
    clrf valueL
    clrf valueH
    movlw 0x20
    movwf location
    movwf location2
    
    return
    
 
multiply
    movff location2,FSR0L
    movlw 0x30
    movwf FSR1L
    
multiplyloop
    movf POSTINC0,0
    mulwf POSTINC1
   movf PRODL,0
   addwf valueL,1
   movf PRODH,0
   addwfc valueH,1
   movlw 0x29
   CPFSLT FSR0L  
   call refreshfsr0
   movlw 0x38
   CPFSGT FSR1L  
   goto multiplyloop
   return
   
refreshfsr0
   movlw 0x20
   movwf FSR0L
   return
   
substraction
  
   movlw D'41'
   mulwf POSTINC2
   movf PRODL,0
   addwf SUBSL,1
   movf PRODH,0
   addwfc SUBSH,1
   movlw 0x28
   cpfsgt FSR2L
   goto substraction
   movf SUBSL,0 ;do the final subtraction
   subwf valueL
   movf SUBSH,0
   subwfb valueH
   clrf SUBSL
   clrf SUBSH
   return
   
   
addoffset
    movlw D'80'
    addwf valueH,1
    movff valueH,CCPR2L
    clrf valueH
    clrf valueL
    return
inter_ADC
     movff location,FSR0L
   movff FSR0L,location2
   movff ADRESH,POSTINC0
   movff FSR0L,location
     movlw 0x29
   CPFSLT FSR0L  ;if fsr0 is SMALLER than w,skip. when the address overflow
   call initiate
    call multiply
    call substraction
    call addoffset
    bcf	    PIR1, 6	; ADIF bit has to be cleared
    retfie
inter_tmr0
    btfss   INTCON, 2	; TMR0IF, interrupt is caused by Timer0
    retfie		; if not, then return
    movlw   D'58'	; this value sets the sample frequency (see formula in init_timer) CHANGE IT!!!!!!!!!!!!! 8 prescale
    movwf   TMR0L	; initialize timer again
    bsf	    ADCON0, 1	; GODONE bit, starts the A/D conversion
    bcf	    INTCON, 2	; clear interrupt flag
    retfie
    
 initiate
   clrf location
   movlw 0x20
   movwf FSR0L
   movff FSR0L,location
   return
   
inter_high
    btfss   PIR1, 6	; ADIF bit, interrupt is caused by A/D converter
    goto    inter_tmr0	; check next interrupt source
    goto     inter_ADC

inter_low
    nop
    retfie

    END




