; Infrared remote control for Nikon D70 with Atmel 8bit MCU
; 
; Copyright (C) 2005, 2006 Michele Bighignoli - Laives (BZ) - ITALY # www.bigmike.it/ircontrol
;
; Version 2.0.0-OI - 12/2007
; Modified by Matt Coates (mattjackets+openinterval at gmail.com)
; for use as an include file for the OpenInterval project
; (http://repo.or.cz/w/OpenInterval.git)
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;
;
; Implementation note:
; ---------------------------
; IR led is controlled by PD0 (with NPN transistor).
; Led is "on" when PD0 is high.
;
; This code has tested with ATTiny2313 and ATMEGA8535 with 8.0 MHz Xtal
;
; Should work with every Atmel 8bit MCU
;
;
; Special thanks to:
; ------------------
; Gerhard Schmidt (DG4FAC) - http://www.avr-asm-tutorial.net/index.html
; Brian Hammill - http://www.ipass.net/~hammill
;
;
; WaveForm data (03/2006 version):
;
; Infrared period = 26us (~38.4kHz)
;
; Strart pulse:	 2000us
; pause:		27830us
; 1st pulse:	  390us
; pause:		 1580us
; 2nd pulse:	  410us
; pause:		 3580us
; 3rd pulse:	  400us
; longpause:	63200us
; 
; REPEAT ONE TIME
;

.DEF DelayReg  = R23
.DEF MainLoopC = R22
.DEF Counter   = R21
.DEF Counter2  = R20

delay130:
; This is a 13.0 uS delay (104 cycles @ 8MHz)
;
; sbi/cbi = 2 cycles
; rcall = 3 cycles
;
	nop
	nop
;
delay130_led_on:
	nop
	nop
	nop
;
delay130_led_off:
	nop
	nop
	ldi	DelayReg,30		; 1 cycle
delay130_loop:
	dec 	DelayReg			; 1 cycle
	brne	delay130_loop		; 2 cycle if jump to label, 1 if not
	ret				; 4 cycles


; Code executed at startup

shutterrelease:
	ldi	MainLoopC,2		; Send a complete waveform 2 times

mainloop:

; Send start pulse (2000 uS)
	ldi	Counter,77		; (13 uS * 2 ) * 77 = 2002 uS
startpulse:
	sbi	irport,irpin			; LED on
	rcall	delay130_led_on		; Wait 13.0 uS
	cbi	irport,irpin			; LED off
	rcall	delay130_led_off		; wait 13.0 uS
	dec	Counter
	brne	startpulse

; Pause (27830 uS)
	ldi	Counter,237
startpause:
	rcall	delay130
	rcall	delay130
	rcall	delay130
	rcall	delay130
	rcall	delay130
	rcall	delay130
	rcall	delay130
	rcall	delay130
	rcall	delay130
	dec	Counter
	brne	startpause

	rcall	delay130_led_off

; Send first pulse (390 uS)
	ldi	Counter,15
pulse1:
	sbi	irport,irpin			; LED on
	rcall	delay130_led_on
	cbi	irport,irpin			; LED off
	rcall	delay130_led_off
	dec	Counter
	brne	pulse1

; Pause (1580 uS)
	ldi	Counter,118
pause1:
	rcall	delay130
	dec	Counter
	brne	pause1

	ldi	Counter,5
pause1b:
	dec	Counter
	brne	pause1b


; Send 2nd pulse (410 uS)
;
; NOTE: with Counter=16 the pulse width is 416 uS (counting the last "led off" time)
; using Counter=15 and an additional "led on", it's possible to add the last 7 uS (led off) to the pause 2
; 
; Counter=15 = 390 uS +
; "led on"   =  13 uS =
; TOTAL      = 403 uS
;

	ldi	Counter,15
pulse2:
	sbi	irport,irpin			; LED on
	rcall	delay130_led_on
	cbi	irport,irpin			; LED off
	rcall	delay130_led_off
	dec	Counter
	brne	pulse2

	sbi	irport,irpin			; LED on
	rcall	delay130_led_on
	cbi	irport,irpin			; LED off

; Pause (3580 uS + 7 uS from pulse2 = 3587 uS)
	ldi	Counter,136
pause2:
	rcall	delay130
	rcall	delay130
	dec	Counter
	brne	pause2

; Send 3th pulse (400 uS) - (in real world = 403 uS)
	ldi	Counter,15
pulse3:
	sbi	irport,irpin			; LED on
	rcall	delay130_led_on
	cbi	irport,irpin			; LED off
	rcall	delay130_led_off
	dec	Counter
	brne	pulse3

	sbi	irport,irpin			; LED on
	rcall	delay130_led_on
	cbi	irport,irpin			; LED off

	dec	MainLoopC
; No long pause before sleep
	breq	returnfromshutterrelease


; Pause for 63200 uS
	ldi	Counter,239
longpause:
	ldi	Counter2,10
longpause1:	
	rcall	delay130
	rcall	delay130
	dec	Counter2
	brne	longpause1
	dec	Counter
	brne	longpause

; At moment : 63126 uS + 3 uS from pulse3 = 63129 uS

	ldi	Counter,5
longpause2:
	rcall	delay130
	dec	Counter
	brne	longpause2

; At moment 63193 uS + 3 uS from pulse3 = 63196 uS

	ldi	Counter,10		; 3,75 uS
longpause3:
	dec	Counter
	brne	longpause3
	
	rjmp	mainloop

returnfromshutterrelease:
	ret
