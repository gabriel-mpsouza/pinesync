[org 0x1000]
[bits 16]

jmp Main

; Isso funcionará por enquanto
%include "./STABLE/BOOTLOADER/PRINT.ASM"
; %include "./KERNEL/VGA.ASM"
%include "./STABLE/KERNEL/SHELL.ASM"


Main:
    ; Limpa a tela
    mov ah, 0
    mov al, 3
    int 0x10

    ; chama VgaInit
    ; mov al, 67
    ; mov ah, 0
    ; call VgaPrintChar
    
    jmp InitShell

    cli
    hlt


; Preenche 6 setores
times 3072 db 0
