.org 0x0000
.bank 0

.incasm "defs.s"

main:
	ld sp, 0xFFFF

	xor a
	ld hl, ram_start
	ld bc, (tetris_board_last_row-ram_start)
main_clear_ram_loop:
	ld [hl], a
	dec bc
	jp nz, main_clear_ram_loop

	call i8251_init
	call i8255_init
	call st7565p_init

	; fallthrough to welcome_start
	.incasm "welcome.s"

.incasm "util.s"
.incasm "tetris.s"

.incasm "i8251.s"
.incasm "i8255.s"
.incasm "st7565p.s"

.bank 3
.org 0x0000
.incasm "font_rotated.s"