calc_start:
	; clear the screen
	call st7565p_clear

	; draw broken text
	xor a
	ld b, 0
	ld c, 0
	ld hl, calc_title
	call st7565p_write_str

	xor a
	ld b, 0
	ld c, 2
	ld hl, calc_broken_line_one
	call st7565p_write_str

	xor a
	ld b, 0
	ld c, 3
	ld hl, calc_broken_line_two
	call st7565p_write_str

	;ld b, 0
	;call st7565p_set_page_address
	;call st7565p_underline

	; draw text
	;ld a, 0b10000000 ; underline
	;ld b, 0
	;ld c, 0
	;ld hl, calc_title
	;call st7565p_write_str

	;call calc_draw

calc_loop:
	; loop until back is pressed
	ld a, [i8255_port_a]

	bit i8255_button_bit_back, a
	jp z, calc_loop
	bit i8255_button_bit_back, b
	jp nz, calc_loop

	; if we got here, back is pressed! return
	ret

calc_draw:
	; result
	ld b, 1
	call st7565p_set_page_address
	call st7565p_underline

	ld a, 0b10000000 ; underline
	ld b, 0
	ld c, 1
	ld hl, (calc_numbers)
	call st7565p_write_str

	; buttons
	ld b, 2
	call st7565p_set_page_address

	ld d, 10
	ld a, '0'
calc_draw_button_loop:
	ld b, 255
	ld c, 0
	call st7565p_write_char

	ret

calc_title:
	asciz "Calculator"

calc_broken_line_one:
	asciz "I don't work"

calc_broken_line_two:
	asciz "right now :("

calc_numbers:
	asciz "0123456789"