.include "constants.inc"
.include "header.inc"

;Sandy Marrero
;Grupo Y
;Referencia: Famicom Party
.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
tile_set_flag: .res 1
jump_state: .res 1
attack_state: .res 1
.exportzp player_x, player_y, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

	; read controller
	JSR read_controller1

  ; update tiles *after* DMA transfer
	; and after reading controller state
	JSR update_player
  JSR draw_player

	LDA scroll
	CMP #$00 ; did we scroll to the end of a nametable?
	BNE set_scroll_positions
	; if yes,
	; Update base nametable
	LDA ppuctrl_settings
	EOR #%00000010 ; flip bit 1 to its opposite
	STA ppuctrl_settings
	STA PPUCTRL
	LDA #240
	STA scroll

set_scroll_positions:
	LDA #$00 ; X scroll first
	STA PPUSCROLL
	DEC scroll
	LDA scroll ; then Y scroll
	STA PPUSCROLL

  RTI
.endproc

.import reset_handler
.import draw_starfield
.import draw_objects

.export main
.proc main
	LDA #239	 ; Y is only 240 lines tall!
	STA scroll

  LDA #$00
  STA attack_state
  LDA #$00
  STA jump_state

  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

	; write nametables
	LDX #$20
	JSR draw_starfield

	LDX #$28
	JSR draw_starfield

	JSR draw_objects

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
	STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed

  LDA player_x    ; Load the current player X position
  CMP #01  ; Compare with the minimum X position (leftmost boundary)
  BEQ no_left_move ; If player_x is already at the leftmost position, don't move left

  DEC player_x    ; If the branch is not taken, move player left

no_left_move:   ; Label for when left movement is not allowed
check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up

  LDA player_x    ; Load the current player X position
  CMP #$F0  ; Compare with the minimum X position (leftmost boundary)
  BEQ no_right_move ; If player_x is already at the leftmost position, don't move left
  INC player_x

no_right_move:
check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down
  DEC player_y
check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ check_b

  LDA player_y
  CMP #$DC
  BEQ no_down_move

  INC player_y

no_down_move:

check_b:
  LDA pad1
  AND #BTN_B
  BEQ b_not_pressed

b_not_pressed:
  ; LDA #$00
  ; STA tile_set_flag


check_a:
  LDA pad1
  AND #BTN_A
  BEQ done_checking

done_checking:
  LDA tile_set_flag
  EOR #$01  
  STA tile_set_flag

  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA


  LDA tile_set_flag
  BEQ use_standing_tile


  JMP use_running_tile

use_attack_tile:
  LDA #$0D
  STA $0201
  LDA #$0E
  STA $0205
  LDA #$1D
  STA $0209
  LDA #$1E
  STA $020d
  JMP done_update

use_jumping_tile:
  LDA #$10
  STA $0201
  LDA #$11
  STA $0205
  LDA #$20
  STA $0209
  LDA #$21
  STA $020d
  JMP done_update

use_running_tile:
  LDA #$0b
  STA $0201
  LDA #$0c
  STA $0205
  LDA #$1b
  STA $0209
  LDA #$1c
  STA $020d
  JMP done_update

use_standing_tile:
  LDA #$09
  STA $0201
  LDA #$0A
  STA $0205
  LDA #$19
  STA $0209
  LDA #$1A
  STA $020d
  JMP done_update

done_update:
  LDA #$01
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc





.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $32, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $19, $30, $16
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "starfield.chr"
