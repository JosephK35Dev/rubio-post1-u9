; LPT1.ASM - Puerto paralelo; usa DX porque 0379h/037Ah no caben en IN/OUT inmediato
[BITS 16]
[ORG 100h]
DATA_PORT   equ 0378h
STATUS_PORT equ 0379h
CTRL_PORT   equ 037Ah
start:
    ; Espera acotada a BUSY#=1 (periferico listo)
    mov  dx, STATUS_PORT
    mov  cx, 0FFFFh
.wait_ready:
    in   al, dx
    test al, 80h
    jnz  .ready
    loop .wait_ready
    mov  dx, msg_busy
    jmp  .print_exit
.ready:
    ; Coloca 'A' en D0-D7
    mov  dx, DATA_PORT
    mov  al, 41h
    out  dx, al
    ; Pulso STROBE# activo-bajo, preservando los demas bits
    mov  dx, CTRL_PORT
    in   al, dx
    mov  bl, al
    and  al, 0FEh
    out  dx, al
    mov  cx, 20
.delay:
    loop .delay
    mov  al, bl
    or   al, 01h
    out  dx, al
    ; Espera ACK# bajo, tambien con limite
    mov  dx, STATUS_PORT
    mov  cx, 0FFFFh
.wait_ack:
    in   al, dx
    test al, 40h
    jz   .ack
    loop .wait_ack
    mov  dx, msg_noack
    jmp  .print_exit
.ack:
    mov  dx, msg_sent
.print_exit:
    mov  ah, 09h
    int  21h
    mov  ax, 4C00h
    int  21h
msg_busy  db 'Timeout: LPT1 ocupado o sin estado listo.',13,10,'$'
msg_noack db 'Dato A enviado; no se detecto ACK del periferico.',13,10,'$'
msg_sent  db 'Dato A enviado; ACK recibido.',13,10,'$'
