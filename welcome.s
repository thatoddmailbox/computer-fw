welcome_start:
	; clear redraw flag
	xor a
	ld [welcome_need_redraw], a

	; clear the screen
	call st7565p_clear

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

welcome_loop:
	; if redraw flag is not zero, redraw screen
	ld a, [welcome_need_redraw]
	or a
	jp nz, welcome_start

	ld hl, random_counter
	inc [hl]

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

	bit i8255_button_bit_select, a
	jp z, welcome_loop_skip_select
	bit i8255_button_bit_select, b
	jp nz, welcome_loop_skip_select
	; select button
	call welcome_select
welcome_loop_skip_select:

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
	cp 2
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

	pop af

	; a now contains the currently selected option, from 0 to 1
	; draw the cursor for the currently selected option
	ld b, 0
	add a, 2
	ld c, a
	ld hl, welcome_cursor
	call st7565p_write_str

	pop hl
	pop af
	ret

welcome_select:
	push af
	push bc
	push hl

	; give the function a return address
	ld hl, welcome_select_end
	push hl

	; get the function to call from the jump table
	ld a, [current_menu_item]
	add a, a
	ld b, 0
	ld c, a
	ld hl, welcome_jump_table

	add hl, bc

	ld a, [hl]
	inc hl
	ld b, [hl]
	ld h, b
	ld l, a

	jp [hl]

welcome_select_end:
	ld a, 0xFF
	ld [welcome_need_redraw], a

	pop hl
	pop bc
	pop af
	ret

welcome_blank:
	asciz " "

welcome_cursor:
	asciz ">"

welcome_title:
	asciz "Select an option"

welcome_option_one:
	asciz "Option 1"

welcome_option_two:
	asciz "Tetris"

welcome_jump_table:
	dw 0
	dw tetris_start