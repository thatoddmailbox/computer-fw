; driver for ST7565P

.def st7565p_command_reset 0b11100010
.def st7565p_command_column_address_high 0b00010000
.def st7565p_command_column_address_low 0b00000000
.def st7565p_command_page_address 0b10110000

; st7565p_init: Initializes the ST7565P.
; Parameters: none
; Trashes: A
; Returns: none
st7565p_init:
	ld a, st7565p_command_reset
	ld [st7565p_command], a

	ret

; st7565p_set_column_address: Sets the column address of the ST7565P.
; Parameters: B = new column address
; Trashes: A
; Returns: none
st7565p_set_column_address:
	; set high bits
	ld a, b
	and 0b11110000
	srl a
	srl a
	srl a
	srl a
	or st7565p_command_column_address_high
	ld [st7565p_command], a

	; set low bits
	ld a, b
	and 0b00001111
	; or st7565p_command_column_address_low - it's just zero, so do nothing
	ld [st7565p_command], a

	ret

; st7565p_set_page_address: Sets the page address of the ST7565P.
; Parameters: B = new page address (zero-indexed, max of 8)
; Trashes: A
; Returns: none
st7565p_set_page_address:
	ld a, b
	or st7565p_command_page_address
	ld [st7565p_command], a

	ret

; st7565p_write_char: Writes the given character to the current cursor position of the ST7565P.
; Parameters: A = character to write
; Trashes: B, C, H, L
; Returns: none
st7565p_write_char:
	; set hl to character
	ld h, 0
	ld l, a

	; shift left 3
	add hl, hl
	add hl, hl
	add hl, hl

	ld bc, font
	add hl, bc ; HL is now pointing at the character data to output

	ld b, 8
st7565p_write_char_loop:
	ld a, [hl]
	ld [st7565p_data], a
	inc hl
	dec b
	jp nz, st7565p_write_char_loop

	ret

; st7565p_write_str: Writes the given string to the given position.
; Parameters: HL = address of string to write, B = x coordinate, C = page to write on
; Trashes: A, B, C
; Returns: HL = null byte of string
st7565p_write_str:
	call st7565p_set_column_address
	ld b, c
	call st7565p_set_page_address
st7565p_write_str_loop:
	ld a, [hl]
	cp 0
	ret z
	push hl
	call st7565p_write_char
	pop hl
	inc hl
	jp st7565p_write_str_loop