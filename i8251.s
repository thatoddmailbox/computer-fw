; driver for Intel 8251A

; i8251_init: Initializes the UART.
; Parameters: none
; Trashes: A
; Returns: none
i8251_init:
	; first perform worst-case reset (see pg 12 of 8251A datasheet)
	xor a
	ld [i8251_command], a
	ld [i8251_command], a
	ld [i8251_command], a

	ld a, 0x40
	ld [i8251_command], a

	; send mode instruction
	; set chip to be 8N1, 64x divider, async mode
	; at 1.8432 MHz, this means 28.8k baud
	ld a, 0b01001111
	ld [i8251_command], a

	; set transmit and receive enable
	ld a, 0b00000101
	ld [i8251_command], a

	ret

; i8251_byte_available: Checks if there is a byte ready on the UART.
; Parameters: none
; Trashes: none
; Returns: A = 1 if there is a byte ready, 0 if otherwise
i8251_byte_available:
	ld a, [i8251_command]
	and 0b00000010
	sra a
	ret

; i8251_read_char: Waits for and reads a character from the UART.
; Parameters: none
; Trashes: none
; Returns: A = the byte read
i8251_read_char:
	call i8251_byte_available
	cp 0
	jp z, i8251_read_char
	ld a, [i8251_data]
	ret

; i8251_write_char: Writes the given character to the UART.
; Parameters: A = character to write
; Trashes: none
; Returns: none
i8251_write_char:
	; wait for txrdy to be 1
	push af
i8251_write_char_wait_rdy:
	ld a, [i8251_command]
	and 0b00000001
	jp z, i8251_write_char_wait_rdy
	pop af

	; output character
	ld [i8251_data], a

	ret

; i8251_write_str: Writes the given null-terminated string to the UART.
; Parameters: HL = address of string to write
; Trashes: none
; Returns: HL = null byte of string
i8251_write_str:
	ld a, [hl]
	inc hl
	call i8251_write_char
	cp 0
	jp nz, i8251_write_str
	ret