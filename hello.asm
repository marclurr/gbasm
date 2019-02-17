INCLUDE "hardware.inc"

run_dma equ $FF80
fVblank equ $C000
fGameOver equ $C001
playerInput equ $C002
SOAM equ $DE00

playerY equ $DE00
playerX equ $DE01
enemyX equ $DE05
enemyY equ $DE04

SECTION "Interrupts", ROM0[$0]

ret
  REPT 7
    nop
  ENDR
  ; RST 08
  ret
  REPT 7
    nop
  ENDR
  ; RST 10
  ret
  REPT 7
    nop
  ENDR
  ; RST 18
  ret
  REPT 7
    nop
  ENDR
  ; RST 20
  ret
  REPT 7
    nop
  ENDR
  ; RST 28
  ret
  REPT 7
    nop
  ENDR
  ; RST 30
  ret
  REPT 7
    nop
  ENDR
  ; RST 38
  ret
  REPT 7
    nop
  ENDR


; IRQs are RST 40-67, in order
; vblank, status (often hblank), timer, serial, keys

  jp VBlank
  REPT 5
    nop
  ENDR
  jp stat
  REPT 5
    nop
  ENDR
  jp timer
  REPT 5
    nop
  ENDR
  jp serial
  REPT 5
    nop
  ENDR
  jp joypad
  REPT 5
    nop
  ENDR

SECTION "Header", ROM0[$100]

EntryPoint: ; This is where execution begins
    di ; Disable interrupts
    jp Start ; Leave this tiny space
; === NO MORE CODE HERE!!! ===
REPT $150 - $104
    db 0
ENDR

VBlank:
    ld hl, fVblank
    ld [hl], 1 
    ld a, [fGameOver]
    cp a, $01
    jr nz, dontRenderBackground

    ld a, %10000011
    ld [rLCDC], a

dontRenderBackground
    call run_dma
    reti
draw:
stat:
timer:
serial:
joypad:
    reti

SECTION "Game code", ROM0


; ========= Copy data from one memory location to another ==========
; reg de location of the data
; reg hl destination address
; reg bc length of data in bytes
memcpy:
    ld a, [de] ; Grab 1 byte from the source
    ld [hli], a ; Place it at the destination, incrementing hl
    inc de ; Move to next byte
    dec bc ; Decrement count
    ld a, b ; Check if count is 0, since `dec bc` doesn't update flags
    or c
    jr nz, memcpy
    ret

waitvblank:
    ld a, [rLY]
    cp 144 ; Check if the LCD is past VBlank
    jr c, waitvblank
    ret

lcdoff:
	call waitvblank
    xor a ; ld a, 0 ; We only need to reset a value with bit 7 reset, but 0 does the job
    ld [rLCDC], a ; We will have to write to LCDC again later, so it's not a bother, really.
    ret

Start:
    ; Turn off the LCD
    call lcdoff

    ; Move dma copy code into high ram
    ld hl, run_dma
    ld de, run_dma_master
    ld bc, run_dma_end - run_dma_master
    call memcpy


    ; Copy font data in to VRAM
    ld hl, _VRAM
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    call memcpy

    ld hl, $9000 
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    call memcpy
    

    ; Move the letter 'A' into work ram

    ld hl, SOAM
    ld de, Sprite
    ld bc, EndSprite - Sprite
    call memcpy

    ld hl, $9800 ; This will print the string at the top-left corner of the screen
    ld de, GameOverText
.copyString
    ld a, [de]
    ld [hli], a
    inc de
    and a ; Check if the byte we just copied is zero
    jr nz, .copyString ; Continue if it's not

   ; configure background palette
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a

    ;xor a ; ld a, 0
    ld a, 0;
    ld [rSCY], a
    ld [rSCX], a

    ; Shut sound down
    ld [rNR52], a


    ; Turn screen on, display sprites
    ld a, %10000010
    ld [rLCDC], a


    
    ld a, %00000001 ; switch on vblank interrupt
    ld hl, $FFFF
    ld [hl], a
    ei


    ld a, 0
    ld [fGameOver], a

Main:

    halt
    nop
    ld a, [fVblank]
    or a
    jr z, Main
    xor a ; reset fVblank to 0 
    ld [fVblank], a

    call moveEnemy
    call handleInput

    ld a, [playerY]
    ld b, a
    ld a, [enemyY]
    add 4
    cp a, b
    jr nc, testCollision
    jr dontTestCollision


testCollision
    ld a, [playerX]
    ld b, a
    ld a, [enemyX]
    cp a, b
    jr c, checkOtherSide

    ld a, [playerX]
    add 8
    ld b, a
    ld a, [enemyX]

    cp a, b
    jr c, gameOver
;; check other way around
checkOtherSide
    ld a, [enemyX]
    ld b, a
    ld a, [playerX]
    cp a, b
    jr c, dontTestCollision

    ld a, [enemyX]
    add 8
    ld b, a
    ld a, [playerX]

    cp a, b
    jr c, gameOver

dontTestCollision

    jr Main

gameOver
    ld a, $01
    ld [fGameOver], a
loop
    halt
    nop
    jr loop



;========== Move enemy ==========
; enemyY += 1
; if enemyY > 144
;   enemyY = 0
;   enemyX = playerX
; fi
moveEnemy:
    ld a, [enemyY]
    inc a
    ld [enemyY], a
    cp 144
    jr nc, resetPosition
    ret

resetPosition
    ld hl, enemyY
    ld [hl], 0
    inc hl
    ld a, [playerX]
    ld [hl], a
    ret


;========== Handle input ==========
; Set P14 of $FF00 low to read D-pad
; read value a few times for debouncing
; Result would be 0 for on. CPL flips this to 1 meaning on
; and with 00001111 to get just the input data (upper 4-bits aren't interesting for this)
; swap upper and lower bits for convention

; if leftIsPressed
;   playerX -= 1
; else if rightIsPressed
;   playerX += 1
; fi 
handleInput:
    ld a, $20
    ld [$FF00], a
    ld a, [$FF00]
    ld a, [$FF00]
    cpl 
    and $0F
    swap a
    ld [playerInput], a
    ld b, a
    and a, $20   

    jr nz, playerLeft
    jr notPlayerLeft
playerLeft
    ld hl, playerX
    dec [hl]
    jr endInput
notPlayerLeft
    ld a, b
    and a, $10

    jr nz, playerRight
    jr endInput

playerRight
    ld hl, playerX
    inc [hl]
endInput
    ret

;========== procedure for copying sprite data from WRAM to VRAM ==========
; This must be run from 'high-RAM' as all other address space is inaccessible 
; when DMA is triggered
run_dma_master:
  ld a,SOAM >> 8
  ld [rDMA],a
  ld a,40
.loop:
  dec a
  jr nz,.loop
  ret
run_dma_end:

SECTION "Font", ROM0

FontTiles:
INCBIN "font.chr"
FontTilesEnd:

Sprite:
    db 140, 84, 65, %01000000
    db 20, 84, 66, 0
EndSprite:

GameOverText:
    db "==== Game Over ====", 0
EndGameOverText: