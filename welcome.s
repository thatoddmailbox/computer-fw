welcome_start:
	; draw text
	ld b, 0
	ld c, 0
	ld hl, welcome_title
	call st7565p_write_str

	ld b, 8
	ld c, 2
	inc hl
	call st7565p_write_str

	ld b, 8
	ld c, 3
	inc hl
	call st7565p_write_str

	ld b, 8
	ld c, 4
	inc hl
	call st7565p_write_str

welcome_loop:
	ld a, [last_buttons]
	ld b, a
	ld a, [i8255_port_a]

	; button testing

	bit i8255_button_bit_up, a
	jp z, welcome_loop_skip_up
	bit i8255_button_bit_up, b
	jp nz, welcome_loop_skip_up
	; up button
	call welcome_up
welcome_loop_skip_up:

	bit i8255_button_bit_down, a
	jp z, welcome_loop_skip_down
	bit i8255_button_bit_down, b
	jp nz, welcome_loop_skip_down
	; down button
	call welcome_down
welcome_loop_skip_down:

welcome_loop_cont:
	ld [last_buttons], a
	jp welcome_loop

welcome_up:
	push af
	push hl
	ld hl, current_menu_item
	dec [hl]
	jp welcome_cursor_update
welcome_down:
	push af
	push hl
	ld hl, current_menu_item
	inc [hl]
	; fallthrough
welcome_cursor_update:
	ld a, [hl]
	cp 255
	jp nz, welcome_cursor_update_greater_than_min
	ld a, 2
welcome_cursor_update_greater_than_min:
	cp 3
	jp nz, welcome_cursor_update_less_than_max
	ld a, 0
welcome_cursor_update_less_than_max:
	ld [hl], a

	push af

	; clear cursors
	ld b, 0
	ld c, 2
	ld hl, welcome_blank
	call st7565p_write_str

	ld b, 0
	ld c, 3
	ld hl, welcome_blank
	call st7565p_write_str

	ld b, 0
	ld c, 4
	ld hl, welcome_blank
	call st7565p_write_str

	pop af

	; a now contains the current selected option, from 0 to 2
	ld b, 0
	add a, 2
	ld c, a
	ld hl, welcome_cursor
	call st7565p_write_str

	pop hl
	pop af
	ret

welcome_blank:
	asciz " "

welcome_cursor:
	asciz ">"

welcome_title:
	asciz "Select an option"

option_one:
	asciz "Option 1"

option_two:
	asciz "Option 2"

option_three:
	asciz "Option 3"