void __interrupt (high_priority) high_ISR(void);   //high priority interrupt routine
void __interrupt (low_priority) low_ISR(void);  //low priority interrupt routine, not used in this example
void initChip(void);
void initTimer(void);
void initAD(void);
void set_duty( unsigned duty);
void initPWM();

#define MAX_DUTY 300
#define _XTAL_FREQ 45000000
#define TOO


volatile int  counter = 0;
int duty =0;


void __interrupt (high_priority) high_ISR(void)
{
 if(PIR1bits.ADIF == 1)
     {
        counter=ADRESH;
         PIR1bits.ADIF =0;     //CLEAR interrupt flag
     }
    

    if(INTCONbits.TMR0IF == 1)
    {
        ADCON0 = 0b00000011;     //Start A/D convertor by Timer
        TMR0L = 0x00;            //reset Timer0
        INTCONbits.TMR0IF=0;      //clear Timer0 flag
    }
            
}



void main(void) {
    initChip();
    initPWM();
    while(1)
    {
       unsigned char down = 0;

#ifdef TRI
        if(duty == MAX_DUTY)
            down = 1;
        if(duty == 0)
            down = 0;
        if(down)
            duty --;
        else
            duty++;
#endif
#ifdef TOO
        if(duty == MAX_DUTY)
            duty = 0;
        else
            duty ++;
#endif
       
        set_duty(duty);
        __delay_ms(0.5);
    }
    }
   


void initChip(void)
{
    LATA = 0x00;// initial portA by clearing output;
    TRISA = 0x01; // Define PORTA0 as input;
    ANSELA = 0x01; // set the PORTA0 as analog
    LATB = 0x00;// initial portb by clearing output;
    TRISB = 0x00;// define portb as output;
    ANSELB = 0x00;// define portb as digital port.
    //ADCON1 = 0x00; //AD voltage reference
    INTCONbits.GIE = 0;// Turn Off global interrupt
        
}

void initTimer(void)
{
    // in order to conduct more easily,use 8 bit and prescaler instead of 16-bit.
    //assume fosc/4=12MHz
    // we need to use interrupt for the timer to get sample with suitable sample rate
    T0CON = 0x45;   //bit7=0 disable now
                    //bit6=1 8 bit one
                    //bit5=0 internal clock;
                    //bit4=0 rise edge sensitive
                    //bit3=0 assigned pre scale
                    //bit2-0 pre scale=1:64
    TMR0L = 0x45;   // the initial value01000101 is 69 (256-69)*65=11968 around 12000;
    INTCON =0x20;   // 00100000
                    // bit7 disable all interrupts including peripheral
                    // bit6 disable all peripherals
                    // bit5 enable TMR0 overflow interrupt
                    // bit4-0 disable some unused interrupts in this project
    T0CONbits.TMR0ON = 1;///enable timer0;
}

void initAD(void)
{
    ADCON1 =0x00;   // for voltage reference,a/d ref +connected to internal signal AVdd
                    // for negative voltage reference, a/d ref - connected to internal signal
    ADCON0 = 0x00;  // channel is AN0; go/done =0 because we don't plan to convert at that time.
                    // after configuration of ADC, I will turn on adc module
    ADCON2 = 0x36;  //00110110
   
    ADCON0bits.ADON = 1;   //enable AD convertor

    PIR1bits.ADIF = 0; // clear interrupt flag at first
    PIE1bits.ADIE = 1; // enable interrupt of ADC
    INTCONbits.GIE = 1;// enable all interrupt
    INTCONbits.PEIE_GIEL =1; //enable peripheral interrupt
}
void initPWM()
{
            TRISC=0b00000000;           //set PORTC.bit2 as output
            PORTC=0b00000000;           //Initializing PORTC
            PR2=0b01001010;             //Set period of signal for 1KHZ
            CCP1CON=0b00001100;            //Set CCP2 in PWM mode and set bit4&5 duty ratio
            CCPR1L=0b00000000;                   //set 8 bit lower DuTy ratio
            PIR1bits.TMR2IF=0;
            T2CONbits.T2CKPS0=0;
            T2CONbits.T2CKPS1=1;                  // Prescaler 1:16
            T2CONbits.TMR2ON=1;                   //Enable Timer 2
            
}

void set_duty( unsigned duty)
{
    CCPR1L = duty;
}}

