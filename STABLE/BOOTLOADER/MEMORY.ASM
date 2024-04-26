[bits 16]


MemoryAvaiable: dw 0


; Consgue a quantidade de memória em KB disponível para uso
GetMemoryAvaiable:
    push ax

    int 0x12
    mov [MemoryAvaiable], ax ; Salva o número que conseguimos

    pop ax

    ret
