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
.def tetris_board_height_blocks 14
.def tetris_board_width_px (tetris_board_width_blocks*tetris_board_width_blocks)
.def tetris_board_height_px (tetris_board_height_blocks*tetris_board_height_blocks)

;
; SRAM
;
.def ram_size 4*1024
.def ram_start 0x3000

;
; variables
;
.def last_buttons (ram_start+0)
.def current_menu_item (last_buttons+1)
.def random_counter (current_menu_item+1)

.def welcome_need_redraw (random_counter+1)

.def calc_buffer (welcome_need_redraw+1) ; size: 2 bytes
.def calc_flip_buffer (calc_buffer+2) ; size: 2 bytes
.def calc_selected_button (calc_flip_buffer+1)

.def tetris_lines (calc_selected_button+1)
.def tetris_lines_old (tetris_lines+1)
.def tetris_need_collision_check (tetris_lines_old+1)
.def tetris_dropping_something (tetris_need_collision_check+1)
.def tetris_drop_counter (tetris_dropping_something+1) ; size: 2 bytes
.def tetris_fall_index (tetris_drop_counter+2)

.def tetris_fall_zone_start_buffer (tetris_fall_index+1) ; size: 15 bytes
.def tetris_fall_zone (tetris_fall_zone_start_buffer+15) ; size: 4 bytes
.def tetris_fall_zone_last_row (tetris_fall_zone+(4-1))
.def tetris_fall_zone_end_buffer (tetris_fall_zone+4) ; size: 15 bytes
.def tetris_fall_zone_end_buffer_last_row (tetris_fall_zone_end_buffer+(15-1))

.def tetris_board (tetris_fall_zone_end_buffer+15) ; size: 14 bytes
.def tetris_board_last_row (tetris_board+(14-1))
.def tetris_board_buffer_row (tetris_board_last_row+1)
