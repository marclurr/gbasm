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

memset:
    ld a, d
    ld [hli], a
    dec bc
    ld a, b ; Check if count is 0, since `dec bc` doesn't update flags
    or c
    jr nz, memset
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

copyDmaRoutineToHRAM:
    ld hl, run_dma
    ld de, run_dma_master
    ld bc, run_dma_end - run_dma_master
    call memcpy
    ret

multiply:
    ld hl, 0
mulloop:
    add hl, bc
    dec d
    ld a, d
    xor 0
    jr nz, mulloop
    ret


divide:
    ld c, 0
    sub a, b
divloop:
    inc c
    sub a, b
    jr nc, divloop
    ld a, c
    ret

scrollSprite:
    ld hl, SOAM
    sla c ; multiply by 4 to get sprite offset from SOAM+0
    sla c
    ld b, 0
    add hl, bc
    ld a, [hl]
    add a, e
    ld [hli], a
    ld a, [hl]
    add a, d
    ld [hl], a
    ret
