[org 0x7c00] ; Define o endereço de origem do código

; Pula as inclusões
jmp Start

%include "./STABLE/BOOTLOADER/PRINT.ASM"
%include "./STABLE/BOOTLOADER/DISK.ASM"
%include "./STABLE/BOOTLOADER/MEMORY.ASM"

; Alguns BIOSes pulam para o setor de inicialização com 0x07c0:0x0000 ou 0x0000:0x7c00 e de outras maneiras, então definimos CS para 0
Start:
    cli ; Desabilita interrupções
    jmp 0x0000:Main ; Salta para a parte principal do código
    nop

Main:
    ; Salva o número da unidade onde estamos atualmente
    mov [BootDisk], dl

    ; Configuração dos segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Configuração da pilha
    mov ss, ax
    mov sp, 0x7c00

    sti ; Habilita interrupções

    call GetMemoryAvaiable
    call ReadDisk

    ; Limpa a tela
    mov ah, 0
    mov al, 3
    int 0x10

    call PrintLogo

    ; Aguarda 4 segundos
    mov cx, 0x2d
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    ; Salta para o kernel
    jmp 0x100:0x0

; *AVISO DE CÓDIGO DESNECESSÁRIO! CONTINUE POR SUA PRÓPRIA CONTA E RISCO
PrintLogo:
    xor cx, cx

    .Loop:
        cmp cx, byte 6
        je .Logo

        call PrintNewLine

        inc cx
        jmp .Loop

    .Logo:
        ; Você não escutou o aviso, ah?
        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo
        call PrintString

        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo1
        call PrintString

        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo2
        call PrintString

        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo3
        call PrintString

        ; Mensagem de boas-vindas
        mov si, WelcomeSpace
        call PrintString

        mov si, WelcomeMessage
        call PrintString

    ret

; Por favor, não me mate
MascLogoSpace: db "                 ", 0
MascLogo: db "  \  |                      _ \   ___|", 10, 13, 0
MascLogo1: db " |\/ |   _` |   __|   __|  |   |\___ \", 10, 13, 0
MascLogo2: db " |   |  (   | \__ \  (     |   |      |", 10, 13, 0
MascLogo3: db "_|  _| \__._| ____/ \___| \___/ _____/", 10, 13, 10, 13, 0
WelcomeSpace: db "                      ", 0
WelcomeMessage: db "Bem-vindo ao MascOS! Carregando...", 0

; Preenche o restante do setor com 0s e a assinatura de boot
times 510-($-$$) db 0
dw 0xaa55
