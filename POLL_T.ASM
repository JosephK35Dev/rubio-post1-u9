; POLL_T.ASM - Polling acotado del 8042; MAX_RETRY peque?o para probar timeout
[BITS 16]
[ORG 100h]
MAX_RETRY equ 0005h
start:
    mov  cx, MAX_RETRY
.poll:
    in   al, 64h
    test al, 01h
    jnz  .ready
    loop .poll
    mov  dx, msg_timeout
    mov  ah, 09h
    int  21h
    jmp  .finish
.ready:
    in   al, 60h
    mov  bl, al
    mov  dx, msg_data
    mov  ah, 09h
    int  21h
    mov  al, bl
    shr  al, 4
    call hex_digit
    mov  al, bl
    and  al, 0Fh
    call hex_digit
.finish:
    mov  ax, 4C00h
    int  21h
hex_digit:
    and  al, 0Fh
    cmp  al, 9
    jbe  .num
    add  al, 7
.num:
    add  al, '0'
    mov  dl, al
    mov  ah, 02h
    int  21h
    ret
msg_timeout db 'Timeout: sin respuesta del dispositivo.',13,10,'$'
msg_data    db 'Scancode recibido: $'
