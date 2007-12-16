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

.include "include/tn13def.inc"
.EQU buttonPin	= 1 ; button
.EQU syncPin	= 3 ; sync LED port
.EQU irPort	= PORTB; ir LED port
.EQU irPin	= 4 ; ir LED pin
.equ freq = 2;

.def mode	= r16
.def tcounter	= r17
.def tcounter2	= r18
.def Idelay	= r19
.def Idelay2	= r20


.cseg
.org 0x0000

reset:
	rjmp	init		; Reset handler
	rjmp	INT0_hand	; INT0 handler
	reti			; Pin change handler
	rjmp	TIM0_OVF	; Timer overflow handler
	reti            	; EEPROM Ready handler
	reti			; Analog Comparator handler
	reti            	; Timer/Counter Compare Match A handler
	reti			; Timer/Counter Compare Match B handler
	reti            	; Watchdog Time-out handler
	reti			; ADC Conversion Complete handler


;camera include file goes here
.include "cameras/Nikon_OML-L3.inc"

init:
	ldi	mode, low(ramend)
	out	spl, mode
; enable sleep mode and INT0 on falling edge
	ldi	mode, (1 << SE) | (1 << ISC01)
	out	MCUCR, mode 

; disable ACD
	ldi	mode, (1 << ACD)
	out	ACSR, mode

; enable timer0
	ldi	mode, 0
	out	TCNT0, mode

; set timer prescaler 1024
	ldi	mode, (1 << CS02) | (1 << CS00)
	out	TCCR0B, mode

; reset timer
	ldi	mode, 0
	out	TCNT0, mode

; enable INT0 interrupt
	ldi	mode, (1 << INT0)
	out	GIMSK, mode

; Set portB input
	sbi	PORTB,buttonPin ; set b4 config. to enable internal pull-up.
	cbi	DDRB,buttonPin
; Set portB output
	sbi	DDRB,irPin
	sbi	DDRB,syncPin
	sbi	DDRB,2 

	sbi	irPort,irPin	; LED off
	ldi	tcounter,0
	ldi	tcounter2,1
	ldi	Idelay,0
	ldi	Idelay2,1
	ldi	mode,0

	sei


testloop:
	sbi	irPort,syncPin
	rcall	shutterrelease
	cbi	irPort,syncPin
;	rcall	longdelay
;	rjmp	testloop
	

GoToSleep:
	sleep
	rjmp	GoToSleep

TIM0_OVF:

	cpi	mode,0
	breq	ReturnFI
	cpi	mode,1
	breq	Timing
	cbi	irport,syncPin
        cpi	tcounter, 0
        brne	SKIP
	cpi	tcounter2,0
	brne	SKIP
	sbi	irport,syncPin
	mov	tcounter, Idelay
	mov	tcounter2, Idelay2
	rcall	shutterrelease
SKIP:
        dec	tcounter
	brne	ReturnFI
	dec	tcounter2
        reti
Timing:
	inc	Idelay
	brne	ReturnFI
	inc	Idelay2
	reti

ReturnFI:
	reti
LongDelay:
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
	ret

INT0_hand:
	rcall	longdelay
	brne    intpause
	cpi	mode,2
	breq	ReturnFI
	cpi	mode,1
	breq	setDelay
	ldi	mode,1
; enable timer overflow
	ldi	tcounter, (1 << TOIE0)
	out	TIMSK0, tcounter
	sbi	irport,syncpin
	reti
setDelay:
	cbi	irport,syncpin
	ldi	mode,2
	ldi	tcounter,0
	ldi	tcounter2,0
	reti
