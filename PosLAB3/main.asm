;******************************************************************************
; Universidad Del Valle De Guatemala
; IE2023: Programación de Microcontroladores
; Autor: Alan Gomez - 22115
; Proyecto: Laboratorio 3
; Hardware: Atmega238p
; Creado: 2/10/2024
;******************************************************************************



;******************************************************************************
;ENCABEZADO
;******************************************************************************
.include "M328PDEF.inc"
.CSEG
.ORG 0x00
	JMP MAIN  //Vector RESET
.ORG 0X0006
	JMP ISR_PCINT0 //Vector de ISR: PCINT0

.ORG 0X0020
	JMP ISR_TIMER0_OVF //Vector ISR del timer0

MAIN:
	;******************************************************************************
	;STACK POINTER
	;******************************************************************************
	LDI R16, LOW(RAMEND)  
	OUT SPL, R16
	 LDI R17, HIGH(RAMEND)
	OUT SPH, R17

SETUP:
	//reinicio
	LDI R18,0
	LDI R19,0
	LDI R17,0
	LDI R28,0
	LDI R25,0
	LDI R22,0
	LDI R21,0


	LDI R16, 0b1000_0000
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16
	LDI R16, 0b0000_0001
	STS CLKPR, R16			//Preascaler  8MHz

	LDI R16, 0b1111_1100
	OUT DDRD, R16		  // salida D

	LDI R16, 0b0000_1100
	OUT PORTD, R16		// PUll D

	LDI R16, 0b0001_1111
	OUT DDRB, R16		  // Salida B

	LDI R16, 0b0000_1111 // Salida C
	OUT DDRC, R16

	LDI R16, (1<<PCIE0)
	STS PCICR, R16

	LDI R16, (1 << PCINT1)|(1 << PCINT2)
	STS PCMSK0, R16
	SBI PINB, PB4	   //Displays
	SEI

	
	TABLA: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7C, 0x07, 0x7F, 0X6F	   // Tabla
	CALL Inttemer0  


LOOP:
     CPI R22, 10
	 BREQ tIMEREST
     CPI R23, 50   //Verificar TIMER0
	 BREQ UNI

	   CALL retar
       SBI PINB, PB3   //Encender PB3
	   SBI PINB, PB4   //Apagar PB4	 

	   LDI ZH, HIGH(TABLA <<1)  //da el byte mas significativo
	   LDI ZL, LOW(TABLA <<1) //va la dirección de TABLA
	   ADD ZL, R21
	   LPM R25,Z
	   OUT PORTD, R25

	   CALL retar
	   SBI PINB, PB3   //Apagar PB3
	   SBI PINB, PB4   //Encender  PB4

	 
	   LDI ZH, HIGH(TABLA <<1)  //da el byte mas significativo
	   LDI ZL, LOW(TABLA <<1) //va la dirección de TABLA
	   ADD ZL, R22
	   LPM R25,Z
	   OUT PORTD, R25
	   CALL retar

	   CPI R21, 6
	   BREQ DECI
	JMP LOOP// AL  LOOP

	retar:
	LDI R19, 255   //Cargar con un valor a R19
	delay:
		DEC R19 //Decrementa R19
		BRNE delay   //Si R19 if = 1 , tira al delay
	LDI R19, 255   //Cargar con un valor a R19
	delay1:
		DEC R19 //Decrementa R19
		BRNE delay1   //Si R19 if = 1, tira al delay
	LDI R19, 255   //Cargar con un valor a R16
	delay2:
		DEC R19 //Decrementa R19
		BRNE delay2   //Si R19 if = 1, tira al delay
	LDI R19, 255   //Cargar con un valor a R19
	delay3:
		DEC R19 //Decrementa R16
		BRNE delay3  //Si R19 if = 1 , tira al delay															 U

	RET

	tIMEREST:    //reset para el contador 
		LDI R22, 0
		INC R21   //Suma contador de decenas
	    JMP LOOP

	UNI:      //Contador de UNI
		INC R22
		LDI R23, 0
		JMP LOOP

	DECI:    //Resetea el contador de decenas
	CALL retar
	LDI R21, 0
	LDI R22, 0
	JMP LOOP

;**************************Inicio TIMER0***************************************		
Inttemer0:     // TIMER0
	LDI R26, 0
	OUT TCCR0A, R26 //trabajar de forma normal 

	LDI R26, (1<<CS02)|(1<<CS00)
	OUT TCCR0B, R26  //Configurar de 1024

	LDI R26, 100
	OUT TCNT0, R26 //Iniciar timer en 158 para conteo

	LDI R26, (1 << TOIE0)
	STS TIMSK0, R26 //TIMER0 de mascara por overflow

	RET

;********************************SUBRUTINA DE PULSADORES***********************
ISR_PCINT0:
	PUSH R16         //Se guarda en pila el registro R16
	IN R16, SREG
	PUSH R16

	IN R20, PIND  //Leer pureto B
	SBRC R20, PD2 // Salta si el bit del registro es 1
	
	JMP CPD2 //PUSH PD2 PRESIONADO

	DEC R18 //Decrementa R18
	JMP EXIT


CPD2:
	SBRC R20, PD2  //Verifica SI PD2 esta a 1
	JMP EXIT

	INC R18 //Incrementa R18
	JMP EXIT

EXIT:
	CPI R18, -1
	BREQ res1
	CPI R18, 16
	BREQ res2

	OUT PORTC, R18
	SBI PCIFR, PCIF0  //Apagar la bandera de ISR PCINT0

	POP R16         //Obtener el valor de SREG
	OUT SREG, R16   //Restaurar los valores de SREG
	POP R16
	RETI      //Retorna de la ISR


res1:   //Bajo reseteo
	LDI R18, 0
	OUT PORTC, R18
	JMP EXIT

res2:     //Alto reseteo
	LDI R18, 15
	OUT PORTC, R18
	JMP EXIT




;********************************SUBRUTINA DE TIMER0***************************

ISR_TIMER0_OVF:

	PUSH R16   //Se guarda R16 En la pila 
	IN R16, SREG  
	PUSH R16      //Se guarda SREG actual en R16

	LDI R16, 100  //Cagar el valor de desbordamiento
	OUT TCNT0, R16  //Cargar el valor inicial del contador
	SBI TIFR0, TOV0   
	INC R23   

	POP R16   
	OUT SREG, R16   
	POP R16        

	RETI 