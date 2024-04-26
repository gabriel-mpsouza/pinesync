; Imprime uma string dada
; Define si para o ponteiro da string
PrintString:
    push ax
    mov ah, 0x0e ; Modo teletipo

    .Loop:
        lodsb ; Carrega o byte atual em al

        cmp al, byte 0
        je .Exit

        int 0x10

        jmp .Loop

    .Exit:
        pop ax

        ret


; Sim, faz o que diz
PrintNewLine:
    push ax
    mov ah, 0x0e ; Modo teletipo

    ; Retorno de carro
    mov al, 10
    int 0x10

    ; Nova linha
    mov al, 13
    int 0x10

    pop ax

    ret


; Macro para imprimir um único caractere
; Eu fiz isso em vez de uma "função" porque eu desperdiçaria ax ou si
; *Nota: Eu poderia apenas empilhar ax e si na pilha, mas não me importo por enquanto
%macro PrintChar 1
    push ax

    mov ah, 0x0e ; Modo teletipo
    mov al, %1
    int 0x10

    pop ax

%endmacro
