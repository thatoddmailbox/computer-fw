; driver for Intel 8255

; i8255_init: Initializes the PIO chip.
; Parameters: none
; Trashes: A
; Returns: none
i8255_init:
	ld a, 0b10010000 ; mode 0, port A input, all else output
	ld [i8255_control], a
	ret