; ***************
; *** Devices ***
; ***************

;
; i8251
;
.def i8251_base 0b0100000000000000
.def i8251_data (i8251_base|0x00)
.def i8251_command (i8251_base|0x01)

;
; i8255
;
.def i8255_base 0b0101000000000000
.def i8255_port_a (i8255_base|0b00)
.def i8255_port_b (i8255_base|0b01)
.def i8255_port_c (i8255_base|0b10)
.def i8255_control (i8255_base|0b11)

; port A: buttons
.def i8255_button_bit_up 7
.def i8255_button_bit_down 6
.def i8255_button_bit_left 5
.def i8255_button_bit_right 4
.def i8255_button_bit_back 3
.def i8255_button_bit_select 2

.def i8255_button_up (1<<i8255_button_bit_up)
.def i8255_button_down (1<<i8255_button_bit_down)
.def i8255_button_left (1<<i8255_button_bit_left)
.def i8255_button_right (1<<i8255_button_bit_right)
.def i8255_button_back (1<<i8255_button_bit_back)
.def i8255_button_select (1<<i8255_button_bit_select)

;
; CompactFlash
;
.def cf_base 0b0110000000000000

;
; ST7565P
;
.def st7565p_width 128
.def st7565p_height 64

.def st7565p_base 0b0111000000000000
.def st7565p_command (st7565p_base|0b000000000000)
.def st7565p_data (st7565p_base|0b100000000000)

; ***********************
; *** Other constants ***
; ***********************

;
; Tetris
;
.def tetris_block_width_px 8
.def tetris_block_height_px 8 
.def tetris_board_width_blocks 8
.def tetris_board_height_blocks 15
.def tetris_board_width_px (tetris_board_width_blocks*tetris_board_width_blocks)
.def tetris_board_height_px (tetris_board_height_blocks*tetris_board_height_blocks)

;
; SRAM
;
.def ram_size 4*1024
.def ram_start ((0xFFFF-ram_size)+1)

;
; variables
;
.def last_buttons (ram_start+0)
.def current_menu_item (ram_start+1)

.def tetris_board (ram_start+16) ; size: 12 bytes
.def tetris_board_last_row (ram_start+16+(12-1))
