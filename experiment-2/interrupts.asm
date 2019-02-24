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