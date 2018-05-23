tetris_start:
	ld a, 0xFF
	ld [tetris_board_buffer_row], a
	ld [tetris_lines_old], a

	xor a
	ld [tetris_lines], a
	ld hl, tetris_board
	ld b, tetris_board_height_blocks
tetris_clear_board_row:
	ld [hl], a
	dec b
	jp nz, tetris_clear_board_row

	; fall through
	call tetris_choose_and_load_piece

tetris_game_loop:
	; bump the random counter
	ld hl, random_counter
	inc [hl]

	; draw the board
	call tetris_draw_board

	; check for input
	ld a, [last_buttons]
	ld b, a
	ld a, [i8255_port_a]

	bit i8255_button_bit_back, a
	jp z, tetris_game_loop_skip_back
	bit i8255_button_bit_back, b
	jp nz, tetris_game_loop_skip_back
	; back button (exit game)
	ret
tetris_game_loop_skip_back:

	bit i8255_button_bit_up, a
	jp z, tetris_game_loop_skip_up
	bit i8255_button_bit_up, b
	jp nz, tetris_game_loop_skip_up
	; up button (move piece right)
	ld c, 0
	call tetris_side
tetris_game_loop_skip_up:

	bit i8255_button_bit_down, a
	jp z, tetris_game_loop_skip_down
	bit i8255_button_bit_down, b
	jp nz, tetris_game_loop_skip_down
	; down button (move piece left)
	ld c, 255
	call tetris_side
tetris_game_loop_skip_down:

	ld [last_buttons], a

	; check the drop counter
	ld hl, [tetris_drop_counter]
	inc hl
	ld [tetris_drop_counter], hl
	ld a, l
	cp 64
	jp nz, tetris_game_loop_no_drop
	; reset the counter
	xor a
	ld [tetris_drop_counter], a
	ld [tetris_drop_counter+1], a
	; check if we're dropping something
	ld a, [tetris_dropping_something]
	or a
	jp nz, tetris_game_loop_dropping
	; we are not dropping something, choose a piece
	call tetris_choose_and_load_piece
	jp tetris_game_loop_no_drop
tetris_game_loop_dropping:
	; check for a collision first
	call tetris_check_fall_collision
	; check if we're still dropping something
	ld a, [tetris_dropping_something]
	or a
	jp z, tetris_game_loop_no_drop
	; we are, so drop the fall zone down one
	ld hl, tetris_fall_index
	inc [hl]
tetris_game_loop_no_drop:
	jp tetris_game_loop

; tetris_side: Handles side-to-side movement of the falling piece.
; Parameters: C = 0 if moving right, 255 if moving left
; Trashes: D, E, H, L
; Returns: none
tetris_side:
	push af
	push bc

	; if we're not dropping something, return immediately
	ld a, [tetris_dropping_something]
	or a
	jp z, tetris_side_return

	; check what direction we're moving it, and set D to the test mask
	xor a
	or c
	jp z, tetris_side_right
	ld d, 0b10000000
	jp tetris_side_testmask_set
tetris_side_right:
	ld d, 0b00000001
tetris_side_testmask_set:

	; test if we're near the edge
	ld hl, tetris_fall_zone
	ld e, 4
tetris_side_test_row_loop:
	ld a, [hl]
	and d
	jp nz, tetris_side_return ; if it's nz, then there is something on the extreme side and we can't move anything, so just return
	inc hl
	dec e
	jp nz, tetris_side_test_row_loop

	ld d, 0 ; d being zero signals that it's a normal shift (as opposed to an undo)

	; actually do the shift
tetris_side_do_shift:
	xor a
	or c
	jp nz, tetris_side_shift_left
tetris_side_shift_right:
	ld hl, tetris_fall_zone
	ld e, 4
tetris_side_shift_right_loop:
	srl [hl]
	inc hl
	dec e
	jp nz, tetris_side_shift_right_loop
	jp tetris_side_shift_complete

tetris_side_shift_left:
	ld hl, tetris_fall_zone
	ld e, 4
tetris_side_shift_left_loop:
	sla [hl]
	inc hl
	dec e
	jp nz, tetris_side_shift_left_loop

tetris_side_shift_complete:
	; are we doing this to undo something? if so, d is 255 and just return
	xor a
	or d
	jp nz, tetris_side_return

	;ld b, b

	; test if doing that shift caused us to overlap with existing blocks
	ld a, [tetris_fall_index]
	ld d, 0
	ld e, a
	ld hl, tetris_fall_zone
	sbc hl, de
	ld b, tetris_board_height_blocks
	ld de, tetris_board
tetris_side_overlap_test:
	; take the board value and AND it with the fall zone row
	ld a, [de]
	and [hl]
	jp nz, tetris_side_undo_needed
	inc hl
	inc de
	dec b
	jp nz, tetris_side_overlap_test

tetris_side_return:
	pop bc
	pop af
	ret
tetris_side_undo_needed:
	; flip c and re-run the shift
	ld a, c
	cpl
	ld c, a
	ld d, 255 ; d being 0xFF signals that it's an undo shift
	jp tetris_side_do_shift

; tetris_choose_and_load_piece: Selects a piece randomly and loads into the fall zone.
; Parameters: none
; Trashes: A, B, C, D, E, H, L
; Returns: none
tetris_choose_and_load_piece:
	; THIS IS A BAD WAY TO DO RANDOMNESS
	; THE DISTRIBUTION IS IN NO WAY UNIFORM
	; HOWEVER IT'S FAST, SMALL, AND WORKS SO TOO BAD
	ld a, [random_counter]
	add a, 83
	ld [random_counter], a
	and (32-1)
	cp 32
	jp nc, tetris_choose_and_load_piece_no_divide
	srl a
tetris_choose_and_load_piece_no_divide:

	; multiply A by 4 and use that to get the address of the piece from the pieces table
	sla a
	sla a
	ld hl, tetris_pieces
	ld b, 0
	ld c, a
	add hl, bc

	; copy the piece
	ld bc, 4
	ld de, tetris_fall_zone
	ldir

	; we're now dropping something
	ld a, 1
	ld [tetris_dropping_something], a

	ret

; tetris_draw_board: Draws the current tetris board to the screen.
; Parameters: none
; Trashes: A, B, C, D, E, H, L, A', B', C', H', L'
; Returns: none
tetris_draw_board:
	; the display is oriented so that we will be filling in blocks left to right in a landscape perspective
	; this means that this code must loop over the blocks column by column as opposed to the probably more intuitive row by row
	ld b, 0b00000001 ; the current column mask
	ld c, 0 ; the current column
	ld de, st7565p_data ; the screen data
tetris_draw_board_column_loop:
	ld hl, tetris_board ; the current row
	; this code is supposed to set A to 255 if we're in column 0, else A is 0
	; nothing actually uses the result of A
	; but somehow, despite this, this block of code fixes a bug where column zero's falling blocks are offset by one
	; this bug only occurs on real hardware and not in the emulator
	; my guess is some subtle timing issue, but I REALLY HAVE NO IDEA WHY THIS CODE WORKS
	ld a, c
	cp 0
	jp z, tetris_draw_board_zero_column
	ld a, 0
	jp tetris_draw_board_zero_column_checked
tetris_draw_board_zero_column:
	ld a, 0xFF
tetris_draw_board_zero_column_checked:
	exx
	; fetch the fall index and subtract it from the fall zone address
	ld hl, tetris_fall_index
	ld a, [hl]
	ld b, 0
	ld c, a
	ld hl, tetris_fall_zone
	sbc hl, bc
tetris_draw_board_no_offset_hack:
	exx
	push bc
	; set the page to the current column
	ld b, c
	call st7565p_set_page_address

	; set the column address to zero
	ld b, 0
	call st7565p_set_column_address
	pop bc

tetris_draw_board_row_loop:
	ld a, [hl] ; load the current row
	; OR the current row with the fall zone equivalent
	exx
	or [hl]
	exx
	and b ; mask off the current column
	jp z, tetris_draw_board_no_block
	; draw the block here
	push hl
	push bc
	ld hl, tetris_block
	ld bc, 8
	ldir
	pop bc
	pop hl
	jp tetris_draw_board_block_done
tetris_draw_board_no_block:
	xor a
	ld [de], a
	ld [de], a
	ld [de], a
	ld [de], a
	ld [de], a
	ld [de], a
	ld [de], a
	ld [de], a
tetris_draw_board_block_done:
	; go to the next row, unless we're on the last row
	inc hl
	exx
	inc hl
	exx
	ld a, l
	cp ((tetris_board_last_row+1)&0xFF)
	jp nz, tetris_draw_board_row_loop

	; load the current score and compare to the last drawn
	ld hl, tetris_lines
	ld a, [hl]
	inc hl
	cp [hl]
	jp z, tetris_draw_board_do_not_redraw_score

	; draw the border between the playfield and score
	ld a, 0xFF
	ld [de], a
	ld [de], a
	xor a
	ld [de], a
	ld [de], a
	ld [de], a

	; compare the current column
	ld a, c
	cp 2
	jp nc, tetris_draw_board_do_not_redraw_score ; column > 2 -> don't draw score

	push bc
	push hl

	; a contains the current column
	; 0 -> 00001111
	; 1 -> 11110000
	or a
	ld a, [tetris_lines]
	jp nz, tetris_draw_board_column_not_zero
	ld c, 0b00001111
	and c
	jp tetris_draw_board_column_found
tetris_draw_board_column_not_zero:
	ld c, 0b11110000
	and c
	srl a
	srl a
	srl a
	srl a
tetris_draw_board_column_found:

	ld b, '0'
	add a, b
	call st7565p_write_turned_char

	pop hl
	pop bc

	; finish screen
	xor a
	ld [de], a
	ld [de], a
	ld [de], a

tetris_draw_board_do_not_redraw_score:
	; loop until the 1 on the bitmask has been rotated out
	inc c
	sla b
	jp nc, tetris_draw_board_column_loop

	; copy the drawn tetris score to the old one
	ld hl, tetris_lines
	ld a, [hl]
	inc hl
	ld [hl], a

	ret

; tetris_check_fall_collision: Check if the fall zone is on top of a block, and if so, add the fall zone to the board.
; Parameters: none
; Trashes: A, B, C, D, E, H, L
; Returns: none
tetris_check_fall_collision:
	; get the top index of the fall zone and get the corresponding board address, adding 4 to start at the row under the bottom
	ld hl, tetris_board
	ld a, [tetris_fall_index]
	add a, 4
	ld b, 0
	ld c, a
	add hl, bc
	ld de, (tetris_fall_zone+3) ; start at the bottom of the fall zone
tetris_check_fall_collision_row_loop:
	ld b, 0b10000000
tetris_check_fall_collision_column_loop:
	ld a, [de]
	and b
	jp z, tetris_check_fall_collision_column_loop_no_block
	; if we got here, this means that there is a block at this position
	; so, get the corresponding board row and see if there is a block there
	ld a, [hl]
	and b
	jp nz, tetris_check_fall_collision_found_block
	; if we got here, there is no collision, so keep going
tetris_check_fall_collision_column_loop_no_block:
	srl b
	jp nc, tetris_check_fall_collision_column_loop
	dec de
	dec hl
	ld a, e
	cp ((tetris_fall_zone-1)&0xFF)
	jp nz, tetris_check_fall_collision_row_loop

	ret
tetris_check_fall_collision_found_block:
	; we found a collision
	; calculate the fall zone address minus the fall index
	ld hl, tetris_fall_index
	ld a, [hl]
	ld d, 0
	ld e, a
	ld hl, tetris_fall_zone
	sbc hl, de
	ld de, tetris_board
	ld b, 15
	; merge the fall zone with the board
tetris_check_fall_collision_found_block_row_loop:
	ld a, [de]
	or [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jp nz, tetris_check_fall_collision_found_block_row_loop
	; reset the fall zone
	xor a
	ld hl, tetris_fall_zone
	ld b, 4
tetris_check_fall_collision_found_block_reset:
	ld [hl], a
	inc hl
	dec b
	jp nz, tetris_check_fall_collision_found_block_reset

	; check for completed lines
tetris_check_fall_collision_complete_check_start:
	ld hl, tetris_board
	ld b, tetris_board_height_blocks
tetris_check_fall_collision_complete_check_row_loop:
	ld a, [hl]
	cp 0xFF
	jp z, tetris_check_fall_collision_complete_check_done
	inc hl
	dec b
	jp nz, tetris_check_fall_collision_complete_check_row_loop

	; clear the dropping something flag and fall index
	xor a
	ld [tetris_dropping_something], a
	ld [tetris_fall_index], a

	ret
tetris_check_fall_collision_complete_check_done:
	; copy the above row down one
	dec hl
	ld a, [hl]
	inc hl
	ld [hl], a

	dec hl

	inc b
	ld a, b
	cp tetris_board_height_blocks
	jp nz, tetris_check_fall_collision_complete_check_done

	; add a line
	ld a, [tetris_lines]
	inc a
	daa
	ld [tetris_lines], a

	; restart the check from the beginning now
	jp tetris_check_fall_collision_complete_check_start

tetris_block:
	db 0b11111111
	db 0b11111111
	db 0b11000011
	db 0b11011011
	db 0b11011011
	db 0b11000011
	db 0b11111111
	db 0b11111111

.def tetris_piece_count 19
tetris_pieces:
	; o (normal)
	db 0b00011000
	db 0b00011000
	db 0b00000000
	db 0b00000000
	; i (normal)
	db 0b00111100
	db 0b00000000
	db 0b00000000
	db 0b00000000
	; i (90)
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	; s
	db 0b00011000
	db 0b00110000
	db 0b00000000
	db 0b00000000
	; s (90)
	db 0b00010000
	db 0b00011000
	db 0b00001000
	db 0b00000000
	; z
	db 0b00110000
	db 0b00011000
	db 0b00000000
	db 0b00000000
	; z (90)
	db 0b00001000
	db 0b00011000
	db 0b00010000
	db 0b00000000
	; l
	db 0b00001000
	db 0b00111000
	db 0b00000000
	db 0b00000000
	; l (90)
	db 0b00010000
	db 0b00010000
	db 0b00011000
	db 0b00000000
	; l (180)
	db 0b00111000
	db 0b00100000
	db 0b00000000
	db 0b00000000
	; l (270)
	db 0b00011000
	db 0b00001000
	db 0b00001000
	db 0b00000000
	; j
	db 0b00100000
	db 0b00111000
	db 0b00000000
	db 0b00000000
	; j (90)
	db 0b00011000
	db 0b00010000
	db 0b00010000
	db 0b00000000
	; j (180)
	db 0b00111000
	db 0b00001000
	db 0b00000000
	db 0b00000000
	; j (270)
	db 0b00010000
	db 0b00010000
	db 0b00110000
	db 0b00000000
	; t
	db 0b00111000
	db 0b00010000
	db 0b00000000
	db 0b00000000
	; t (90)
	db 0b00010000
	db 0b00110000
	db 0b00010000
	db 0b00000000
	; t (180)
	db 0b00010000
	db 0b00111000
	db 0b00000000
	db 0b00000000
	; t (270)
	db 0b00010000
	db 0b00011000
	db 0b00010000
	db 0b00000000