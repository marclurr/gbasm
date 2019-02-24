SECTION "Header", ROM0[$100]

EntryPoint: ; This is where execution begins
    di ; Disable interrupts
    jp Start ; Leave this tiny space
; === NO MORE CODE HERE!!! ===
REPT $150 - $104
    db 0
ENDR