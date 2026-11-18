; MULTI_ST.ASM - OR de OBF del 8042 y BUSY# del LPT1
[BITS 16]
[ORG 100h]
STATUS_PORT equ 0379h
start:
.poll:
    in   al, 64h
    and  al, 01h
    mov  bl, al
    mov  dx, STATUS_PORT
    in   al, dx
    and  al, 80h
    shr  al, 7
    mov  bh, al
    mov  al, bl
    or   al, bh
    jz   .poll
    test bl, bl
    jz   .check_lpt
    mov  dx, msg_key
    mov  ah, 09h
    int  21h
.check_lpt:
    test bh, bh
    jz   .finish
    mov  dx, msg_lpt
    mov  ah, 09h
    int  21h
.finish:
    mov  ax, 4C00h
    int  21h
msg_key db 'Teclado listo (OBF=1).',13,10,'$'
msg_lpt db 'LPT1 listo (BUSY#=1).',13,10,'$'
