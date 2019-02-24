INCLUDE "hardware.inc"

run_dma equ _HRAM+2
keysdown equ _HRAM
newkeys equ _HRAM+1
fVblank equ $C000
SOAM equ $DE00



playerX equ $C001
playerY equ $C002
garbage equ $C003
hasKey equ $C004
newPlayerX equ $C100
newPlayerY equ $C101
projectedTile equ $C102



INCLUDE "interrupts.asm"
INCLUDE "header.asm"


VBlank:
    push af
    push bc
    push de
    push hl
    ld hl, fVblank
    ld [hl], 1 
    call run_dma
    pop hl
    pop de
    pop bc
    pop af
    reti
draw:
stat:
timer:
serial:
joypad:
    reti

SECTION "Game code", ROM0

INCLUDE "util.asm"

INCLUDE "macros.asm"

Start:
    ; Turn off the LCD
    call lcdoff

    Clear SOAM, (40 * 4)
    Clear _VRAM, $9FFF - $8000

    Copy run_dma, run_dma_master, run_dma_end - run_dma_master  ; Copy DMA routine into HRAM
    Copy SOAM, Sprite, EndSprite - Sprite
    Copy _VRAM, Tiles, TilesEnd - Tiles
    Copy _SCRN0, BGMap, BGMapEnd - BGMap

    ; Shut sound down
    ld a, 0
    ld [rNR52], a
    SetAllPallettes %11100100
    ControlLCD LCDCF_ON|LCDCF_OBJON|LCDCF_BGON|LCDCF_BG8000
    EnableInterrupts IEF_VBLANK
    
    ld a, 2
    ld [playerX], a
    ld a, 3
    ld [playerY], a
    ld a, 0
    ld [hasKey], a


Main:

    ;halt
    ;nop

    ;AwaitAndResetFlag [fVblank], Main
    AwaitVBlank

    ld a, [playerX]
    cp 20
    jr nz, .it
    ld a, [playerY]
    cp 18
    jr z, .youwon

.it 


    call ReadJoypad

    call MovePlayer


    call DrawPlayer



    jp Main

.youwon
    ; set background to You win
    
    Copy _SCRN0 + 262, YouWin, YouWinEnd - YouWin
.winloop
    AwaitVBlank
    jr .winloop

    
keys_Right  equ %00010000
keys_Left   equ %00100000
keys_Down   equ %10000000
keys_Up     equ %01000000
playerSpeed equ 1



MovePlayer:
    ld a, [playerX]
    ld [newPlayerX], a
    ld a, [playerY]
    ld [newPlayerY], a
    ;ld hl, garbage
; Start If
    IfFlag [keysdown], keys_Up, .tryDown 
    ld a, [playerY] 
    add a, -playerSpeed
    ld [newPlayerY], a
    jr .skip
    
.tryDown:
    IfFlag [keysdown], keys_Down, .tryLeft
    ld a, [playerY]
    add a, playerSpeed
    ld [newPlayerY], a
    jr .skip
 
.tryLeft
    IfFlag [keysdown], keys_Left, .tryRight
    ld a, [playerX]
    add a, -playerSpeed
    ld [newPlayerX], a
    jr .skip

.tryRight
    IfFlag [keysdown], keys_Right, .skip
    ld a, [playerX]
    add a, playerSpeed
    ld [newPlayerX], a
  

.skip:
; End If


    ld a, [newPlayerY]
    dec a
    dec a
    ld c, a
    ld d, 32
    call multiply
    ld a, [newPlayerX]
    dec a
    ld c, a
    ld b, 0
    add hl, bc
    ld bc, _SCRN0
    add hl, bc
    ld a, h
    ld [$C104], a
    ld a, l
    ld [$C105], a

    ld a, [hl]
    ld [projectedTile], a

    cp $2
    jr z, .dontMove

    cp $3
    call z, CollectKey

    cp $4
    call z, HandleDoor

    cp 0
    jr nz, .dontMove

    ; get tile at coord (y * 32) + x
    ; If new coord is not a wall
    ld a, [newPlayerX]
    ld [playerX], a
    ld a, [newPlayerY]
    ld [playerY], a
    ;else
.dontMove    
    ret

CollectKey:
    ld hl, _SCRN0 + 513
    ld [hl], 0
    ld hl, hasKey
    ld [hl], 1
    ld a, 0
    ret

HandleDoor
    ld a, [hasKey]
    cp 1
    jr nz, .skip    
    ld hl, _SCRN0 + 483
    ld [hl], 0
    ld a, 0
    ret
.skip
    ld a, 1
    ret

DrawPlayer:
    REPT 6
    AwaitVBlank
    ENDR
    ld a, [playerX]
    ld c, a
    ld d, 8
    call multiply
    ld a, l
    ld [SOAM+1], a

    ld a, [playerY]
    ld c, a
    ld d, 8
    call multiply
    ld a, l
    ld [SOAM], a
    ret

ReadJoypad:
    ld a, $20
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    cpl 
    and $0F
    swap a
    ld b, a

    ld a, $10
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    cpl
    and $0F
    or b
    ld b, a

    ld a, [keysdown]
    xor b
    and b
    ld [newkeys], a
    ld a, b
    ld [keysdown], a


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

SECTION "data", ROM0

Tiles:
INCBIN "tiles.bin"
TilesEnd:

BGMap:
INCBIN  "bg.bin"
BGMapEnd:


Sprite:
    db 24, 16, 1, 0
EndSprite:

YouWin:
    db 5, 6, 7, 0, 8, 9, 10, 11
YouWinEnd:
