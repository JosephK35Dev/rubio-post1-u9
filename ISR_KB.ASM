; ISR_KB.ASM - Captura cinco make-codes de IRQ1; salida DOS fuera del ISR
[BITS 16]
[ORG 100h]
MAX_KEYS equ 5
section .data
old_isr   dd 0
contador  dw 0
mostrado  dw 0
msg_key   db 'Tecla registrada por ISR: $'
msg_end   db 13,10,'ISR restaurado. Fin.',13,10,'$'
section .text
start:
    mov  ax, 3509h
    int  21h
    mov  [old_isr], bx
    mov  [old_isr+2], es
    push ds
    push cs
    pop  ds
    mov  dx, mi_isr
    mov  ax, 2509h
    int  21h
    pop  ds
    sti
.wait:
    mov  ax, [contador]
    cmp  ax, [mostrado]
    je   .wait
    mov  [mostrado], ax
    mov  dx, msg_key
    mov  ah, 09h
    int  21h
    mov  dl, al
    ; vuelve a cargar el contador, no depende del AX destruido por DOS
    mov  ax, [contador]
    add  al, '0'
    mov  dl, al
    mov  ah, 02h
    int  21h
    mov  dl, 13
    int  21h
    mov  dl, 10
    int  21h
    cmp  word [contador], MAX_KEYS
    jb   .wait
    cli
    push ds
    lds  dx, [old_isr]
    mov  ax, 2509h
    int  21h
    pop  ds
    sti
    mov  dx, msg_end
    mov  ah, 09h
    int  21h
    mov  ax, 4C00h
    int  21h
mi_isr:
    push ax
    push dx
    push ds
    mov  ax, cs
    mov  ds, ax
    in   al, 60h
    test al, 80h
    jnz  .eoi
    cmp  word [contador], MAX_KEYS
    jae  .eoi
    inc  word [contador]
.eoi:
    mov  al, 20h
    out  20h, al
    pop  ds
    pop  dx
    pop  ax
    iret
