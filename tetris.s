tetris_start:
	ld a, 0xFF
	ld [tetris_board_buffer_row], a

	ld hl, tetris_board
	ld a, 0b11001111

	; fall through
	call tetris_choose_and_load_piece

tetris_game_loop:
	; draw the board
	call tetris_draw_board

	; check the drop counter
	ld hl, [tetris_drop_counter]
	inc hl
	ld [tetris_drop_counter], hl
	ld a, l
	cp 0x00
	jp nz, tetris_game_loop_no_drop
	ld a, h
	cp 0x08
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

; tetris_choose_and_load_piece: Selects a piece randomly and loads into the fall zone.
; Parameters: none
; Trashes: A, B, C, D, E, H, L
; Returns: none
tetris_choose_and_load_piece:
	; TODO: randomness
	ld a, 3

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
	exx
	; fetch the fall index and subtract it from the fall zone address
	ld hl, tetris_fall_index
	ld a, [hl]
	ld b, 0
	ld c, a
	ld hl, tetris_fall_zone
	sbc hl, bc
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

	; draw the border between the playfield and score
	ld a, 0xFF
	ld [de], a
	ld [de], a

	; loop until the 1 on the bitmask has been rotated out
	inc c
	sla b
	jp nc, tetris_draw_board_column_loop

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
	; clear the dropping something flag and fall index
	ld [tetris_dropping_something], a
	ld [tetris_fall_index], a
	ret

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