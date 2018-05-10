; delays
; processor runs at 20000000 Hz
; t state = 1/20000000 = 500 ns

; util_delay_short: Waits around 2 milliseconds.
; Parameters: none
; Trashes: A
; Returns: none
util_delay_short:
	ld a, 0
util_delay_short_loop:
	; m cycles / t states
	nop        ; 1 / 4
	dec a      ; 1 / 4
	jp nz, util_delay_short_loop    ; 3 / 10
	; loop: 5 / 18
	; 18 * 500 ns = 9000 ns = 9 us
	; 9 * 256 = 2304 us = 2.304 ms
	ret