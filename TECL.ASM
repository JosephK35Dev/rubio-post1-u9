; TECL.ASM - Polling del 8042 y salida hexadecimal del scancode
[BITS 16]
[ORG 100h]
start:
.poll:
    in   al, 64h
    test al, 01h
    jz   .poll
    in   al, 60h
    mov  bl, al
    mov  al, bl
    shr  al, 4
    call hex_digit
    mov  al, bl
    and  al, 0Fh
    call hex_digit
    mov  ah, 02h
    mov  dl, 0Dh
    int  21h
    mov  dl, 0Ah
    int  21h
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
