; MASK_KB.ASM - Enmascara solo IRQ1 y espera 55 ticks (aprox. 3 s)
[BITS 16]
[ORG 100h]
section .data
old_imr  db 0
start_lo dw 0
start_hi dw 0
msg_mask db 'IRQ1 enmascarado: pulse teclas; no deben procesarse.',13,10,'$'
msg_done db 'IRQ1 restaurado; fin de la prueba.',13,10,'$'
section .text
start:
    in   al, 21h
    mov  [old_imr], al
    or   al, 02h
    out  21h, al
    mov  dx, msg_mask
    mov  ah, 09h
    int  21h
    mov  ah, 00h
    int  1Ah
    mov  [start_lo], dx
    mov  [start_hi], cx
.wait:
    mov  ah, 00h
    int  1Ah
    test al, al             ; BIOS reporta cambio de dia
    jnz  .restore
    sub  dx, [start_lo]
    sbb  cx, [start_hi]
    or   cx, cx
    jnz  .restore
    cmp  dx, 55
    jb   .wait
.restore:
    mov  al, [old_imr]
    out  21h, al
    mov  dx, msg_done
    mov  ah, 09h
    int  21h
    mov  ax, 4C00h
    int  21h
