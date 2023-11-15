  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

 LDA #$3F
  STA $2006             ; write the high byte of $3F10 address (start of sprite palettes)
  LDA #$10
  STA $2006             ; write the low byte of $3F10 address
  LDX #$00              ; reset X to 0

LoadSpritePalettesLoop:
  LDA spritePalette, x  ; load data from address (spritePalette + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$10              ; Compare X to hex $10, decimal 16 (4 palettes * 4 colors each)
  BNE LoadSpritePalettesLoop

















; Referencia NerdyNights
LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$C0              ; Compare X to hex $C0, 192 decimal 48 sprites * 4bytes
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
              
              
























  LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
 

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer


LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons


ReadA:
  LDA $4016         ; player 1 - A
  AND #%00000001    ; only look at bit 0
  BEQ ReadADone     ; branch to ReadADone if button is NOT pressed (0)

  ; Move all the sprites to the right
  LDX #$00
  LDY #$04          ; Number of sprites to update
MoveSpritesRightLoop:
  LDA $0203, X      ; Load sprite X position
  CLC               ; Clear the carry flag
  ADC #$01          ; A = A + 1 (Move sprite to the right)
  STA $0203, X      ; Save updated sprite X position
  INX               ; Increment X for the next sprite
  INX
  INX
  INX
  DEY               ; Decrement Y to check if we've updated all sprites
  BNE MoveSpritesRightLoop  ; Repeat the loop if there are more sprites to update
ReadADone:          ; Handling this button is done

ReadB: 
  LDA $4016       ; player 1 - B
  AND #%00000001  ; only look at bit 0
  BEQ ReadBDone   ; branch to ReadBDone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)
  ; LDA $0203       ; load sprite X position
  ; SEC             ; make sure carry flag is set
  ; SBC #$01        ; A = A - 1
  ; STA $0203       ; save sprite X position
  LDX #$00
  LDY #$04          ; Number of sprites to update
MoveSpritesLeftLoop:
  LDA $0203, X       ; load sprite X position
  SEC             ; make sure carry flag is set
  SBC #$01        ; A = A - 1
  STA $0203, X      ; Save updated sprite X position
  INX               ; Increment X for the next sprite
  INX
  INX
  INX
  DEY               ; Decrement Y to check if we've updated all sprites
  BNE MoveSpritesLeftLoop  ; Repeat the loop if there are more sprites to update
ReadBDone:        ; handling this button is done

ReadSelect:
  LDA $4016         ; player 1 - A
ReadStart:
  LDA $4016         ; player 1 - A
ReadUp:
  LDA $4016         ; player 1 - A
  AND #%00000001    ; only look at bit 0
  BEQ ReadUpDone     ; branch to ReadADone if button is NOT pressed (0)

  ; Move all the sprites up (negative value) or down (positive value)
  LDX #$00
  LDY #$04          ; Number of sprites to update
MoveUpLoop:
  LDA $0200, X    ; Load sprite Y position
  SEC             ; Set the carry flag
  SBC #$01        ; A = A - (-4) (Move sprite down by 4 units)
        ; A = A - 4 (Move sprite up by 4 units) 
                    ; or SBC #$FC to move sprite down by 4 units
  STA $0200, X    ; Save updated sprite Y position

  INX             ; Increment X by 4 to skip to the next sprite's Y position
  INX
  INX
  INX

  DEY             ; Decrement Y to check if we've updated all sprites
  BNE MoveUpLoop  ; Repeat the loop if there are more sprites to update

ReadUpDone:          ; Handling this button is done


ReadDown:
  LDA $4016         ; player 1 - A
  AND #%00000001    ; only look at bit 0
  BEQ ReadDownDone  ; branch to ReadDownDone if button is NOT pressed (0)

  ; Move all the sprites down
  LDX #$00
  LDY #$04          ; Number of sprites to update
MoveDownLoop:
  LDA $0200, X    ; Load sprite Y position
  SEC             ; Set the carry flag
  ADC #$01
  STA $0200, X    ; Save updated sprite Y position

  INX             ; Increment X by 4 to skip to the next sprite's Y position
  INX
  INX
  INX

  DEY             ; Decrement Y to check if we've updated all sprites
  BNE MoveDownLoop  ; Repeat the loop if there are more sprites to update

ReadDownDone:        


RTS               ; Return from subroutine

  ; Add any additional code to be executed when the button is pressed (1) here


  
  RTI             ; return from interrupt
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000

palette:
  ; Background palettes (not used for sprites)
  .db $0F, $31, $32, $33   ; Background palette 0
  .db $0F, $1C, $15, $14   ; Background palette 1
  .db $0F, $02, $38, $3C   ; Background palette 2
  .db $0F, $20, $13, $28   ; Background palette 3

spritePalette:
  .db $0F, $1A, $20, $16   ; Sprite palette 0
  .db $0F, $1A, $20, $16   ; Sprite palette 1
  .db $0F, $1A, $20, $16   ; Sprite palette 2
  .db $0F, $1A, $20, $16   ; Sprite palette 3



;Personaje Referencias NerdyNights:
sprites:
  ;   vert tile attr horiz
  .db $80, $00, $02, $10   ;sprite 0 (top left)
  .db $80, $01, $02, $18   ;sprite 1 (top right)
  .db $88, $10, $02, $10   ;sprite 2 (bottom left)
  .db $88, $11, $02, $18   ;sprite 3 (bottom right)
  
  .db $80, $02, $02, $30   ;sprite 4 (top left)
  .db $80, $03, $02, $38   ;sprite 5 (top right)
  .db $88, $12, $02, $30   ;sprite 6 (bottom left)
  .db $88, $13, $02, $38   ;sprite 7 (bottom right)
  
  .db $80, $04, $02, $50   ;sprite 8 (top left)
  .db $80, $05, $02, $58   ;sprite 9 (top right)
  .db $88, $14, $02, $50   ;sprite 10 (bottom left)
  .db $88, $15, $02, $58   ;sprite 11 (bottom right)

  .db $A0, $06, $02, $10   ;sprite 12 (top left)
  .db $A0, $07, $02, $18   ;sprite 13 (top right)
  .db $A8, $16, $02, $10   ;sprite 14 (bottom left)
  .db $A8, $17, $02, $18   ;sprite 15 (bottom right)
  
  .db $A0, $08, $02, $30   ;sprite 16 (top left)
  .db $A0, $09, $02, $38   ;sprite 17 (top right)
  .db $A8, $18, $02, $30   ;sprite 18 (bottom left)
  .db $A8, $19, $02, $38   ;sprite 19 (bottom right)

  .db $A0, $0A, $02, $50   ;sprite 20 (top left)
  .db $A0, $0B, $02, $58   ;sprite 21 (top right)
  .db $A8, $1A, $02, $50   ;sprite 22 (bottom left)
  .db $A8, $1B, $02, $58   ;sprite 23 (bottom right)

  ;Reflected

  .db $40, $00, $42, $88   ;sprite 0 (top left)
  .db $40, $01, $42, $80   ;sprite 1 (top right)
  .db $48, $10, $42, $88  ;sprite 2 (bottom left)
  .db $48, $11, $42, $80   ;sprite 3 (bottom right)
  
  .db $40, $02, $42, $A8   ;sprite 4 (top left)
  .db $40, $03, $42, $A0   ;sprite 5 (top right)
  .db $48, $12, $42, $A8   ;sprite 6 (bottom left)
  .db $48, $13, $42, $A0   ;sprite 7 (bottom right)
  
  .db $40, $04, $42, $C8   ;sprite 8 (top left)
  .db $40, $05, $42, $C0   ;sprite 9 (top right)
  .db $48, $14, $42, $C8   ;sprite 10 (bottom left)
  .db $48, $15, $42, $C0   ;sprite 11 (bottom right)

  .db $60, $06, $42, $88   ;sprite 12 (top left)
  .db $60, $07, $42, $80   ;sprite 13 (top right)
  .db $68, $16, $42, $88   ;sprite 14 (bottom left)
  .db $68, $17, $42, $80   ;sprite 15 (bottom right)
  
  .db $60, $08, $42, $A8   ;sprite 16 (top left)
  .db $60, $09, $42, $A0   ;sprite 17 (top right)
  .db $68, $18, $42, $A8   ;sprite 18 (bottom left)
  .db $68, $19, $42, $A0   ;sprite 19 (bottom right)

  .db $60, $0A, $42, $C8   ;sprite 20 (top left)
  .db $60, $0B, $42, $C0   ;sprite 21 (top right)
  .db $68, $1A, $42, $C8   ;sprite 22 (bottom left)
  .db $68, $1B, $42, $C0   ;sprite 23 (bottom right)


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1