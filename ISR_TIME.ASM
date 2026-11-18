; ISR_TIME.ASM - Guarda ticks entre cinco make-codes, salida DOS fuera del ISR
[BITS 16]
[ORG 100h]
MAX_KEYS equ 5
section .data
old_isr    dd 0
last_tick  dw 0
contador   dw 0
intervalos times MAX_KEYS dw 0
msg_intro  db 'Pulse cinco teclas separadas por el intervalo que desea medir.',13,10,'$'
msg_item   db 'Intervalo de ticks: $'
msg_done   db 13,10,'ISR_TIME restaurado.',13,10,'$'
section .text
start:
    mov  ax, 3509h
    int  21h
    mov  [old_isr], bx
    mov  [old_isr+2], es
    push es
    mov  ax, 40h
    mov  es, ax
    mov  ax, [es:6Ch]
    mov  [last_tick], ax
    pop  es
    push ds
    push cs
    pop  ds
    mov  dx, mi_isr
    mov  ax, 2509h
    int  21h
    pop  ds
    sti
    mov  dx, msg_intro
    mov  ah, 09h
    int  21h
.wait:
    cmp  word [contador], MAX_KEYS
    jb   .wait
    cli
    push ds
    lds  dx, [old_isr]
    mov  ax, 2509h
    int  21h
    pop  ds
    sti
    mov  si, intervalos
    mov  cx, MAX_KEYS
.show:
    push cx
    push si
    mov  dx, msg_item
    mov  ah, 09h
    int  21h
    mov  ax, [si]
    call print_decimal
    mov  dl, 13
    mov  ah, 02h
    int  21h
    mov  dl, 10
    int  21h
    pop  si
    add  si, 2
    pop  cx
    loop .show
    mov  dx, msg_done
    mov  ah, 09h
    int  21h
    mov  ax, 4C00h
    int  21h
mi_isr:
    push ax
    push bx
    push dx
    push si
    push ds
    push es
    mov  ax, cs
    mov  ds, ax
    in   al, 60h
    test al, 80h
    jnz  .send_eoi
    cmp  word [contador], MAX_KEYS
    jae  .send_eoi
    mov  ax, 40h
    mov  es, ax
    mov  ax, [es:6Ch]
    mov  bx, ax
    sub  bx, [last_tick]    ; modulo 65536, valido para intervalos menores a ~1 h
    mov  [last_tick], ax
    mov  si, [contador]
    shl  si, 1
    mov  [intervalos+si], bx
    inc  word [contador]
.send_eoi:
    mov  al, 20h
    out  20h, al
    pop  es
    pop  ds
    pop  si
    pop  dx
    pop  bx
    pop  ax
    iret
print_decimal:
    push ax
    push bx
    push cx
    push dx
    mov  bx, 10
    xor  cx, cx
.divide:
    xor  dx, dx
    div  bx
    push dx
    inc  cx
    test ax, ax
    jnz  .divide
.print:
    pop  dx
    add  dl, '0'
    mov  ah, 02h
    int  21h
    loop .print
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
