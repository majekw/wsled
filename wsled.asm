; This is simple 'one night' program to make christmas tree light
; using chain of 50 ws2811 leds and cheap Arduino Pro Mini board
;
; (C) 2014 Marek Wodzinski http://majek.mamy.to
;
; Code is under GPL license. For full license see LICENSE file
; 
;
.include "m328def.inc"

;constants
.equ		LEDS=50
.equ		PORT_OUT=PORTB	;leds are on Arduino pin 10
.equ		BIT_OUT=PB2
.equ		DDR_OUT=DDRB

;registers
.def		zero=r2
.def		temp=r16
.def		bytecount=r17
.def		bitcount=r18
.def		loopcount=r19


; macros
;reti but occupying 2 words (M168/328)
.macro		m_reti
		reti
		nop
.endmacro

; wait a while
.macro		m_wait
		ldi	YL,low(@0)
		ldi	YH,high(@0)
		rcall	wait_generic
.endmacro


.cseg
		jmp	reset	;RESET
		m_reti		;INT0
		m_reti		;INT1
		m_reti		;PCINT0
		m_reti		;PCINT1
		m_reti		;PCINT2
		m_reti		;WDT
		m_reti		;Timer2 Compare Match A
		m_reti		;Timer2 Compare Match B
		m_reti		;Timer2 Overflow
		m_reti		;Timer1 Capture
		m_reti		;Timer1 CompareA
		m_reti		;Timer1 CompareB
		m_reti		;Timer1 Overflow
		m_reti		;Timer0 Compare MAtch A
		m_reti		;Timer0 Compare Match B
		m_reti		;Timer0 Overflow
		m_reti		;SPI transfer complete
		m_reti		;USART RX complete
		m_reti		;USART data register empty (UDRE)
		m_reti		;USART TX complete
		m_reti		;ADC conversion complete
		m_reti		;EEPROM ready
		m_reti		;Analog comparator
		m_reti		;Two wire serial interface
		m_reti		;SPM ready

reset:
		cli				;disable interrupts
		
		;set stack pointer
		ldi	temp,low(RAMEND)
		out	SPL,temp
		ldi	temp,high(RAMEND)
		out	SPH,temp
		
		;prepare zero register
		clr	zero
		
		;program timer for delay measurements
		sts	PRR,zero	;enable power for timer1 and everything else (in fact it should be already enabled after reset)
		ldi	temp,0		;normal operation mode
		sts	TCCR1A,temp
		ldi	temp,(1<<CS12)	;prescaler clk/256
		sts	TCCR1B,temp
		sts	TCCR1C,zero	;nothing special
		;ldi	temp,(1<<TOIE1)	;enable interrupt on overflow
		;sts	TIMSK1,temp
		sts	TIMSK1,zero
		
		;prepare port
		sbi	DDR_OUT,BIT_OUT	;set port to output
		
		;clear leds
		rcall	clear_led_buffer
loop:
		;two sparks
		rcall	biegaj2
		rcall	biegaj2

		;fill ram with something
		rcall	fill_led_buffer
		
		;show it
		rcall	wait_ws2811
		rcall	send_ws2811
		
		;dim it using simple shift/division by 2
		rcall	dimit
		
		;running spark
		rcall	biegaj
		m_wait	60000
		rcall	biegajb

		;dim it another way (non linear but more pleasant to eye)
		rcall	fill_led_buffer
		rcall	wait_ws2811
		rcall	send_ws2811
		rcall	dimit2

		
		;repeat everything  again
		rjmp	loop
;




;
; running sparks
.equ	biegaj2_speed=6000
biegaj2:
;		rcall	clear_led_buffer
		ldi	loopcount,0
biegaj2_1:
		m_wait	biegaj2_speed
		rcall	send_ws2811
		rcall	dim_led_buffer

		ldi	XL,low(pixbuf)		;pixbuf+3*loopcount
		ldi	XH,high(pixbuf)
		add	XL,loopcount
		adc	XH,zero
		add	XL,loopcount
		adc	XH,zero
		add	XL,loopcount
		adc	XH,zero
		
		ldi	temp,255	;set pixel
		adiw	XL,1
		st	X,temp		;g

		ldi	XL,low(pixbuf)		;pixbuf+3*loopcount
		ldi	XH,high(pixbuf)
		ldi	temp,LEDS
		sub	temp,loopcount
		add	XL,temp
		adc	XH,zero
		add	XL,temp
		adc	XH,zero
		add	XL,temp
		adc	XH,zero
		adiw	XL,2		;skip r ang g

		ldi	temp,255	;set pixel
		st	X,temp		;b

		
		inc	loopcount
		cpi	loopcount,LEDS
		brcs	biegaj2_1
		ret
;


;
; running spark
.equ	biegaj_speed=6000
biegaj:
;		rcall	clear_led_buffer
		ldi	loopcount,0
biegaj_1:
		m_wait	biegaj_speed

		rcall	send_ws2811
		rcall	dim_led_buffer

		ldi	XL,low(pixbuf)		;pixbuf+3*loopcount
		ldi	XH,high(pixbuf)
		add	XL,loopcount
		adc	XH,zero
		add	XL,loopcount
		adc	XH,zero
		add	XL,loopcount
		adc	XH,zero
		
		ldi	temp,255	;set pixel
		st	X+,temp		;r
		st	X+,temp		;g
		st	X+,temp		;b
		
		inc	loopcount
		cpi	loopcount,LEDS+1
		brcs	biegaj_1
		ret
;

;
; running spark backwards
.equ	biegajb_speed=6000
biegajb:
		;rcall	clear_led_buffer
		ldi	loopcount,LEDS
biegajb_1:
		m_wait	biegajb_speed

		rcall	send_ws2811
		rcall	dim_led_buffer

		ldi	XL,low(pixbuf)		;pixbuf+3*loopcount
		ldi	XH,high(pixbuf)
		add	XL,loopcount
		adc	XH,zero
		add	XL,loopcount
		adc	XH,zero
		add	XL,loopcount
		adc	XH,zero
		
		ldi	temp,255	;set pixel
		st	X+,temp		;r
		st	X+,temp		;g
		st	X+,temp		;b
		
		dec	loopcount
		brne	biegajb_1
		ret
;



;
; dim it by division
.equ	dim_speed=40000
dimit:
		ldi	loopcount,4
dimit_1:
		rcall	dim_led_buffer
		m_wait	dim_speed
		rcall	send_ws2811
		
		dec	loopcount
		brne	dimit_1
		ret
;


;
; dim it by decreasing
.equ	dim2_speed=1000
dimit2:		
		ldi	loopcount,0	;256
dimit2_0:
		ldi	XL,low(pixbuf)
		ldi	XH,high(pixbuf)
		ldi	bytecount,3*LEDS
dimit2_1:
		ld	temp,X
		tst	temp
		breq	dimit2_2
		dec	temp
dimit2_2:
		st	X+,temp
		dec	bytecount
		brne	dimit2_1
		
		ldi	YL,low(dim2_speed)
		ldi	YH,high(dim2_speed)
		rcall	wait_generic
		rcall	send_ws2811
		
		dec	loopcount
		brne	dimit2_0
		ret
;
		


;fill led buffer with something
fill_led_buffer:
		ldi	XL,low(pixbuf)
		ldi	XH,high(pixbuf)
		ldi	bytecount,3*LEDS
		ldi	temp,0
fill_led_buffer_1:
		st	X+,temp
		subi	temp,-111	;add prime number to pseudo random fill
		dec	bytecount
		brne	fill_led_buffer_1
		ret
;


;
; clear ler buffer
clear_led_buffer:
		ldi	XL,low(pixbuf)
		ldi	XH,high(pixbuf)
		ldi	bytecount,3*LEDS
clear_led_buffer_1:
		st	X+,zero
		dec	bytecount
		brne	clear_led_buffer_1
		ret
;


;
; dim led buffer
dim_led_buffer:
		ldi	XL,low(pixbuf)
		ldi	XH,high(pixbuf)
		ldi	bytecount,3*LEDS
dim_led_buffer_1:
		ld	temp,X
		lsr	temp
		st	X+,temp
		dec	bytecount
		brne	dim_led_buffer_1
		ret
;


		
; send buffer to all ws2811 chips in chain
;
; 400kHz
;  ______
; |      |______|
;   TH      TL
;
; 0: TH=0.5us=8clk TL=2.0us=32clk 
; 1: TH=1.2us=19.2clk TL=1.3us=20.8clk
;
send_ws2811:
		ldi	XL,low(pixbuf)
		ldi	XH,high(pixbuf)
		ldi	bytecount,3*LEDS
send_ws2811_byte:
		ld	temp,X+			;..3	;2	;get byte
		ldi	bitcount,8		;..1	;1	;bits count
send_ws2811_bit:
		sbi	PORT_OUT,BIT_OUT	;2	;set 1
		rol	temp			;1
		brcs	send_ws2811_one		;1 for zero, 2 for 1
		
		;zero
		nop				;..4 left to change
		nop				;..3
		nop				;..2
		nop				;..1
		cbi	PORT_OUT,BIT_OUT	;2
		nop				;..30 left to change
		nop				;..29
		nop				;..28
		nop				;..27
		nop				;..26
		nop				;..25
		nop				;..24
		rjmp	send_ws2811_e1		;..22	;2	;go to end of bit shift loop

send_ws2811_one:
		;one				;19-5=14 left to change
		nop				;..14
		nop				;..13
		nop				;..12
		nop				;..11
		nop				;..10
		nop				;..9
		nop				;..8
		nop				;..7
		nop				;..6
		nop				;..5
		nop				;..4
		nop				;..3
		nop				;..2
		nop				;..1
		cbi	PORT_OUT,BIT_OUT	;2
send_ws2811_e1:	
		nop				;19 left to change
		cpi	bitcount,1		;..18	;1	;check if last bit
		breq	send_ws2811_e2		;..17	;..16	;2/1	;if yes, skip some nops
		nop				;..16
		nop				;..15
		nop				;..14
		nop				;..13
		nop				;..12
		nop				;..11
send_ws2811_e2:
		nop				;..10	;..15
		nop				;..9	;..14
		nop				;..8	;..13
		nop				;..7	;..12
		nop				;..6	;..11
		nop				;..5	;..10
		nop				;..4	;..9
		dec	bitcount		;..3	;..8	;1
		brne	send_ws2811_bit		;..2	;..7	;2 or 1
		dec	bytecount		;	;..6;1
		brne	send_ws2811_byte	;	;..5	;2
		ret
;


;
; wait about 60us
wait_ws2811:
		;wait at least 50us = 800clk
		cbi	PORT_OUT,BIT_OUT	;just for sure
		
		ldi	YH,high(5)
		ldi	YL,low(5)
		rcall	wait_generic
		ret
;


;
; wait some time
; Y - time to wait
wait_generic:
		push	ZL
		push	ZH
		
		sts	TCNT1H,zero
		sts	TCNT1L,zero
wait_generic_1:
		lds	ZL,TCNT1L
		lds	ZH,TCNT1H
		sub	ZL,YL
		sbc	ZH,YH
		brcs	wait_generic_1
		
		pop	ZH
		pop	ZL
		ret
;


.dseg
pixbuf:		.byte	3*LEDS
