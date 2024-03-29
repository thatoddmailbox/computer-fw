; driver for ST7565P

.def st7565p_command_reset 0b11100010
.def st7565p_command_column_address_high 0b00010000
.def st7565p_command_column_address_low 0b00000000
.def st7565p_command_page_address 0b10110000

; st7565p_init: Initializes the ST7565P.
; Parameters: none
; Trashes: A, B
; Returns: none
st7565p_init:
	; reset
	ld a, st7565p_command_reset
	ld [st7565p_command], a

	call st7565p_wait

	; set bias 7
	ld a, 0xAE
	ld [st7565p_command], a

	; set adc normal
	ld a, 0xA0
	ld [st7565p_command], a

	; set com normal
	ld a, 0xC0
	ld [st7565p_command], a

	; set display start line
	ld a, 0x40
	ld [st7565p_command], a

	; enable voltage converter
	ld a, (0x28 | 0x4)
	ld [st7565p_command], a

	call st7565p_wait

	; enable voltage regulator
	ld a, (0x28 | 0x6)
	ld [st7565p_command], a

	call st7565p_wait

	; enable voltage follower
	ld a, (0x28 | 0x7)
	ld [st7565p_command], a

	call st7565p_wait

	; set lcd operating voltage
	ld a, (0x20 | 0x6)
	ld [st7565p_command], a

	; display on
	ld a, 0xAF
	ld [st7565p_command], a

	; display normal
	ld a, 0b10100100
	ld [st7565p_command], a

	; set constrast
	ld b, 0x05
	call st7565p_set_contrast

	call st7565p_wait

	; clear ram
	call st7565p_clear

	ret

st7565p_wait:
	ld b, 0
st7565p_wait_loop_outer:
	ld a, 0
st7565p_wait_loop:
	nop
	nop
	nop
	nop
	dec a
	jp nz, st7565p_wait_loop
	dec b
	jp nz, st7565p_wait_loop_outer
	ret

; st7565p_clear: Clears the RAM of the ST7565P.
; Parameters: none
; Trashes: A, B, C
; Returns: none
st7565p_clear:
	ld b, 8
st7565p_clear_page:
	push bc
	ld b, 0
	call st7565p_set_column_address
	pop bc
	dec b
	call st7565p_set_page_address
	inc b
	ld c, 128
	xor a
st7565p_clear_page_loop:
	ld [st7565p_data], a
	dec c
	jp nz, st7565p_clear_page_loop
	dec b
	jp nz, st7565p_clear_page
	ret

; st7565p_set_contrast: Sets the contrast of the ST7565P.
; Parameters: B = new contrast
; Trashes: A
; Returns: none
st7565p_set_contrast:
	ld a, 0x81
	ld [st7565p_command], a

	ld a, b
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
	ld a, 7
	sub b
	or st7565p_command_page_address
	ld [st7565p_command], a

	ret

; st7565p_start_read_modify_write: Enables the read-modify-write mode of the ST7565P.
; Parameters: none
; Trashes: A
; Returns: none
st7565p_start_read_modify_write:
	ld a, 0b11100000
	ld [st7565p_command], a

	ret

; st7565p_end_read_modify_write: Disables the read-modify-write mode of the ST7565P.
; Parameters: none
; Trashes: A
; Returns: none
st7565p_end_read_modify_write:
	ld a, 0b11101110
	ld [st7565p_command], a

	ret

; st7565p_underline: Underlines the currently selected page of the ST7565P, clearing existing contents.
; Parameters: none
; Trashes: A, B
; Returns: none
st7565p_underline:
	ld b, 0
	call st7565p_set_column_address

	ld a, 0b00000001
	ld b, 128
st7565p_underline_loop:
	ld [st7565p_data], a
	dec b
	jp nz, st7565p_underline_loop

	ret

; st7565p_underline_existing: Underlines the currently selected page of the ST7565P, preserving existing contents.
; Parameters: none
; Trashes: A, B, C
; Returns: none
st7565p_underline_existing:
	ld b, 0
	call st7565p_set_column_address

	ld a, [st7565p_data] ; dummy read b/c we just set a column

	call st7565p_start_read_modify_write

	ld b, 128
st7565p_underline_existing_loop:
	ld a, [st7565p_data]
	or 0b00000001
	ld [st7565p_data], a
	dec b
	jp nz, st7565p_underline_existing_loop

	call st7565p_end_read_modify_write

	ret

; st7565p_write_char: Writes the given character to the current cursor position of the ST7565P.
; Parameters: A = character to write, B = 255 to invert, C = 255 to underline
; Trashes: A, D, H, L
; Returns: none
st7565p_write_char:
	; set hl to character
	ld h, 0
	ld l, a

	; shift left 3
	add hl, hl
	add hl, hl
	add hl, hl

	push bc
	ld bc, font
	add hl, bc ; HL is now pointing at the character data to output
	pop bc

	ld d, 8
st7565p_write_char_loop:
	ld a, [hl]
	bit 0, c
	jp z, st7565p_write_char_loop_no_underline
	or 0b00000001
st7565p_write_char_loop_no_underline:
	bit 0, b
	jp z, st7565p_write_char_loop_no_invert
	cpl
st7565p_write_char_loop_no_invert:
	ld [st7565p_data], a
	inc hl
	dec d
	jp nz, st7565p_write_char_loop

	ret

; st7565p_write_turned_char: Writes the given character to the current cursor position of the ST7565P.
; Parameters: A = character to write
; Trashes: B, C, H, L
; Returns: none
st7565p_write_turned_char:
	; set hl to character
	ld h, 0
	ld l, a

	; shift left 3
	add hl, hl
	add hl, hl
	add hl, hl

	ld bc, font
	add hl, bc ; HL is now pointing at the character data to output

	ld a, 0b10000000
st7565p_write_turned_char_loop:
	ld bc, 0x0008
st7565p_write_turned_char_row_loop:
	push af
	and [hl] ; mask off the bit we're looking at now
	scf ; set the carry flag
	jp nz, st7565p_write_turned_char_bit_not_off
st7565p_write_turned_char_bit_off:
	ccf ; the bit is off, so complement carry flag (in this case always clear)
st7565p_write_turned_char_bit_not_off:
	rr b ; rotate the new bit in
	pop af
	inc hl
	dec c
	jp nz, st7565p_write_turned_char_row_loop

	; output the byte
	push af
	ld a, b
	ld [st7565p_data], a
	pop af

	; subtract 8 from hl
	ld bc, 0x0008
	sbc hl, bc

	srl a
	jp nc, st7565p_write_turned_char_row_loop ; can jump directly to the row loop b/c we already set bc correctly

	ret

; st7565p_write_str: Writes the given string to the given position.
; Parameters: HL = address of string to write, A = bit 0 controls invert and bit 7 controls underline, B = x coordinate, C = page to write on
; Trashes: A, B, C, D
; Returns: HL = null byte of string
st7565p_write_str:
	push af
	call st7565p_set_column_address
	ld b, c
	call st7565p_set_page_address
	pop af

	; if b non-zero -> invert, c non-zero -> underline
	ld b, 0
	ld c, 0
	bit 0, a
	jp z, st7565p_write_str_no_invert
	ld b, 0xFF
st7565p_write_str_no_invert:
	bit 7, a
	jp z, st7565p_write_str_loop
	ld c, 0xFF

	; loop over characters
st7565p_write_str_loop:
	ld a, [hl]
	cp 0
	ret z
	push hl
	call st7565p_write_char
	pop hl
	inc hl
	jp st7565p_write_str_loop