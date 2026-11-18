; ISR_CHAIN.ASM - Cuenta IRQ1 y encadena al handler BIOS para conservar el teclado DOS
[BITS 16]
[ORG 100h]
section .data
old_isr   dd 0
irq_count dw 0
msg_intro db 'Escriba cinco caracteres; DOS debe hacer eco: $'
msg_count db 13,10,'Eventos IRQ1 observados (hex): $'
msg_end   db 13,10,'Handler original restaurado.',13,10,'$'
hexbuf    db '0000$'
section .text
start:
    mov  ax, 3509h
    int  21h
    mov  [old_isr], bx
    mov  [old_isr+2], es
    push ds
    push cs
    pop  ds
    mov  dx, mi_isr_chain
    mov  ax, 2509h
    int  21h
    pop  ds
    sti
    mov  dx, msg_intro
    mov  ah, 09h
    int  21h
    mov  cx, 5
.read_char:
    mov  ah, 01h            ; DOS lee y hace eco; el ISR encadenado preserva el handler
    int  21h
    loop .read_char
    cli
    push ds
    lds  dx, [old_isr]
    mov  ax, 2509h
    int  21h
    pop  ds
    sti
    mov  dx, msg_count
    mov  ah, 09h
    int  21h
    mov  ax, [irq_count]
    call print_hex
    mov  dx, msg_end
    mov  ah, 09h
    int  21h
    mov  ax, 4C00h
    int  21h
mi_isr_chain:
    push ax
    push ds
    mov  ax, cs
    mov  ds, ax
    inc  word [irq_count]
    pop  ds
    pop  ax
    pushf
    call far [old_isr]   ; el handler BIOS lee 60h y env?a el EOI
    iret
print_hex:
    push ax
    push bx
    push cx
    push si
    mov  bx, ax
    mov  si, hexbuf+3
    mov  cx, 4
.digit:
    mov  al, bl
    and  al, 0Fh
    cmp  al, 9
    jbe  .number
    add  al, 7
.number:
    add  al, '0'
    mov  [si], al
    dec  si
    shr  bx, 1
    shr  bx, 1
    shr  bx, 1
    shr  bx, 1
    loop .digit
    mov  dx, hexbuf
    mov  ah, 09h
    int  21h
    pop  si
    pop  cx
    pop  bx
    pop  ax
    ret

