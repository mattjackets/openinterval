;   OpenInterval
;
;   Copyright 2007 Matthew F. Coates (mattjackets+openinterval at gmail.com)
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.

.include "include/tn12def.inc"
.EQU buttonPin	= 1 ; button
.EQU syncPin	= 3 ; sync LED port
.EQU irPort	= PORTB; ir LED port
.EQU irPin	= 4 ; ir LED pin
.equ FREQ	= 0 ; start out with no interval

.def temp	= r16
.def tcounter	= r17
.def tcounter2	= r18
.def mode	= r19
.def DelayReg2	= r24

.cseg
.org 0x0000

reset:
	rjmp	init		; Reset handler
	rjmp	INT0_hand	; INT0 handler
	reti			; Pin change handler
	rjmp	TIM0_OVF	; Timer0 overflow handler
	reti            	; EEPROM Ready handler
	reti			; Analog Comparator handler

;camera include file goes here
.include "cameras/Nikon_OML-L3.inc"

init:
; enable sleep mode and INT0 on falling edge
	ldi	temp, (1 << SE) | (1 << ISC01) & (0 << ISC00)
	out	MCUCR, temp 

; disable ACD
	ldi	temp, (1 << ACD)
	out	ACSR, temp

; enable timer0
;	ldi	temp, 0
;	out	TCNT0, temp

; set timer prescaler 1024
	ldi	temp, (1 << CS02) | (1 << CS00)
	out	TCCR0, temp

; enable timer overflow
	ldi	temp, (1 << TOIE0)
	out	TIMSK, temp

; enable INT0 interrupt
	ldi	temp, (1 << INT0)
	out	GIMSK, temp

	ldi	temp,0
	ldi	DelayReg,FREQ 
	ldi	tcounter,FREQ 
	ldi	mode,0

; Set portB input
	sbi	PORTB,buttonPin ; set b4 config. to enable internal pull-up.
	cbi	DDRB,buttonPin
; Set portB output
	sbi	DDRB,irPin
	sbi	DDRB,syncPin

	sbi	irPort,irPin	; LED off
	rcall	shutterrelease
	sei

GoToSleep:
	sleep
	rjmp	GoToSleep

TIM0_OVF:       ; -- handle timer0 overflow, trigger shutter
	cpi	mode,1
	breq	TIMING
	sbi	portb,syncPin
        cpi	tcounter2, 0
	brne	SKIP
	cpi	tcounter,0
	brne	SKIP
	cbi	portb,syncPin
	mov	tcounter, DelayReg
	rcall	shutterrelease
skip:
        dec	tcounter
	cpi	tcounter,0
	breq	dectcounter2
	reti
DecTCounter2:
	dec	tcounter2
        reti
Timing:
	inc	DelayReg
	cpi	DelayReg,0
	breq	INCDelayReg2
	reti

INCDelayReg2:
	inc	DelayReg2
	reti

INT0_hand:
        ldi     Counter,255
intpause:
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        rcall   delay130
        dec     Counter
        brne    intpause

	cpi	mode,1
	breq	setdelay

; enable timer0
        ldi	temp, 0
        out	TCNT0, temp
	cbi	portb,SyncPin
	ldi	mode,1 ; timing mode
	reti
	
SetDelay:
	sbi	portb,syncPin
	mov	tcounter,DelayReg
	mov	tcounter2,DelayReg2
	ldi	mode,2 ; running mode

	reti
