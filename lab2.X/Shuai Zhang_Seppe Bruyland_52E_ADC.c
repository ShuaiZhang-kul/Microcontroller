{\rtf1\ansi\ansicpg936\cocoartf1671\cocoasubrtf600
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf0 \
\
#include <xc.h>\
\
void __interrupt (high_priority) high_ISR(void);   //high priority interrupt routine\
void __interrupt (low_priority) low_ISR(void);  //low priority interrupt routine, not used in this example\
void initChip(void);\
void initTimer(void);\
void initAD(void);\
\
volatile int  counter = 0;\
\
\
void __interrupt (high_priority) high_ISR(void)\
\
\{\
	if(PIR1bits.ADIF == 1)\
     \{\
        counter=ADRESH;\
         PIR1bits.ADIF =0;     //CLEAR interrupt flag \
     \} \
    \
    \
    if(INTCONbits.TMR0IF == 1)\
    \{\
        ADCON0 = 0b00000011;     //Start A/D convertor by Timer\
        TMR0L = 0x00;            //reset Timer0\
        INTCONbits.TMR0IF=0;      //clear Timer0 flag\
    \}\
            \
\}\
\
\
\
void main(void) \{\
    initChip();\
    initTimer();\
    initAD();\
    while(1)\
    \{ \
        LATB = counter;\
    \}\
   \
\}\
\
\
void initChip(void)\
\{\
    LATA = 0x00;// initial portA by clearing output;\
    TRISA = 0x01; // Define PORTA0 as input;\
    ANSELA = 0x01; // set the PORTA0 as analog\
    LATB = 0x00;// initial portb by clearing output;\
    TRISB = 0x00;// define portb as output;\
    ANSELB = 0x00;// define portb as digital port.\
    //ADCON1 = 0x00; //AD voltage reference\
    INTCONbits.GIE = 0;// Turn Off global interrupt\
    CM1CON0 = 0x00; // turn off comparator;        \
\}\
\
void initTimer(void)\
\{\
    // in order to conduct more easily,use 8 bit and prescaler instead of 16-bit.\
    //assume fosc/4=12MHz \
    // we need to use interrupt for the timer to get sample with suitable sample rate\
    T0CON = 0x45;   //bit7=0 disable now\
                    //bit6=1 8 bit one\
                    //bit5=0 internal clock;\
                    //bit4=0 rise edge sensitive\
                    //bit3=0 assigned pre scale\
                    //bit2-0 pre scale=1:64\
    TMR0L = 0x45;   // the initial value01000101 is 69 (256-69)*65=11968 around 12000;\
    INTCON =0x20;   // 00100000\
                    // bit7 disable all interrupts including peripherals\
                    // bit6 disable all peripherals\
                    // bit5 enable TMR0 overflow interrupt\
                    // bit4-0 disable some unused interrupts in this project\
    T0CONbits.TMR0ON = 1;///enable timer0;\
\}\
\
void initAD(void)\
\{\
    ADCON1 =0x00;   // for voltage reference,a/d ref +connected to internal signal AVdd\
                    // for negative voltage reference, a/d ref - connected to internal signal\
    ADCON0 = 0x00;  // channel is AN0; go/done =0 because we don't plan to convert at that time.\
                    // after configuration of ADC, I will turn on adc module\
    ADCON2 = 0x36;  //00110110 \
   \
    ADCON0bits.ADON = 1;   //enable AD convertor\
\
    PIR1bits.ADIF = 0; // clear interrupt flag at first\
    PIE1bits.ADIE = 1; // enable interrupt of ADC\
    INTCONbits.GIE = 1;// enable all interrupt\
    INTCONbits.PEIE_GIEL =1; //enable peripheral interrupt\
\}\
}