Clear: MACRO
    ld d, 0
    ld hl, \1
    ld bc, \2
    call memset
    ENDM

Copy: MACRO
    ld hl, \1
    ld de, \2
    ld bc, \3
    call memcpy
    ENDM

SetAllPallettes: MACRO
    ld a, \1
    ld [rOBP0], a
    ld [rOBP1], a
    ld [rBGP], a
    ENDM

EnableInterrupts: MACRO
;    ld a, \1 
    ld hl, rIE
    ld [hl], \1
    ei
    ENDM

; Be careful only to set bit 7 (on/off) while in VBlank
ControlLCD: MACRO
    ld a, \1
    ld [rLCDC], a
    ENDM

GetMapOffset: MACRO
    ld bc, \2
    ld d, 32
    call multiply

    ld bc, $9800
    add hl, bc
    ld bc, \1
    add hl, bc
    ENDM

Divide: MACRO
    ld a, \1
    ld b, \2
    call divide
    ENDM

SaveRegisters: MACRO
    push af
    push bc
    push de
    push hl
    ENDM

RestoreRegisters: MACRO
    pop af
    pop bc
    pop de
    pop hl
    ENDM


ScrollSprite: MACRO
    ;SaveRegisters
    ld c, \1
    ld d, \2
    ld e, \3
    call scrollSprite
    ;RestoreRegisters
    ENDM

AwaitAndResetFlag: MACRO
     ; wait for VBlank
    ld a, \1
    or a
    jr z, \2
    xor a ; reset fVblank to 0 
    ld \1, a
    ENDM

AwaitVBlank: MACRO
.keepwaiting\@
    halt
    nop
    AwaitAndResetFlag [fVblank], .keepwaiting\@
    ENDM

IfFlag: MACRO
    ld a, \1
    and \2
    jr z, \3
    ENDM