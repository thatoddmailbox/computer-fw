tetris_start:
	ld hl, tetris_board
	ld a, 0b11000011
	ld [hl], a
	; fall through

tetris_loop:
	call tetris_draw_board
tetris_loop_stay:
	jp tetris_loop_stay

tetris_draw_board:
	; the display is oriented so that we will be filling in blocks left to right in a landscape perspective
	; this means that this code must loop over the blocks column by column as opposed to the probably more intuitive row by row
	ld b, 0b10000000 ; the current column mask
	ld c, 0 ; the current column
	ld de, st7565p_data ; the screen data
tetris_draw_board_column_loop:
	ld hl, tetris_board ; the current row
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
	ld a, l
	cp (tetris_board_last_row&0xFF)
	jp nz, tetris_draw_board_row_loop

	; loop until the 1 on the bitmask has been rotated out
	ld b, b
	inc c
	srl b
	jp nc, tetris_draw_board_column_loop

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