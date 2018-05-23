calc_start:
	; clear the screen
	call st7565p_clear

	ld b, 0
	call st7565p_set_page_address
	call st7565p_underline

	; draw text
	ld a, 0b10000000 ; underline
	ld b, 0
	ld c, 0
	ld hl, calc_title
	call st7565p_write_str

	call calc_draw

calc_loop:
	jp calc_loop

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

	ld b, 255
	ld c, 0
	call st7565p_write_char

	ret

calc_title:
	asciz "Calculator"

calc_numbers:
	asciz "0123456789"