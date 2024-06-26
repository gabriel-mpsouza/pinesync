[bits 16]
[cpu 8086]


DosInt21:
    cmp ah, byte 0x1
    je ah1
    cmp ah, byte 0x2
    je ah2
    cmp ah, byte 0x3
    je ah3
    cmp ah, byte 0x4
    je ah4
    cmp ah, byte 0x5
    je ah5
    cmp ah, byte 0x6
    je ah6
    cmp ah, byte 0x7
    je ah7
    cmp ah, byte 0x8
    je ah7
    cmp ah, byte 0x9
    je ah9
    cmp ah, byte 0xa
    je ah0a
    ; cmp ah, byte 0xb
    ; je ah0b
    ; cmp ah, byte 0xc
    ; je ah0c
    cmp ah, byte 0xd
    je ah0d
    cmp ah, byte 0x17
    je ah17
    cmp ah, byte 0x19
    je ah19
    cmp ah, byte 0x25
    je ah25
    cmp ah, byte 0x2a
    je ah2a
    cmp ah, byte 0x2c
    je ah2c
    cmp ah, byte 0x30
    je ah30
    cmp ah, byte 0x35
    je ah35
    cmp ah, byte 0x4c
    je ah4c
    cmp ah, byte 0x56
    je ah56

    jmp ReturnFromInt



; Read char from standard input with echo
ah1:
    push cx

    mov bl, byte [cs:NormalColour]

    xor ax, ax
    int 0x16

    call VgaPrintChar

    pop cx
    jmp ReturnFromInt


; Write char to standard output
ah2:
    push bx

    mov bl, byte [cs:NormalColour]

    xchg al, dl
    call VgaPrintChar

    pop bx
    jmp ReturnFromInt


; Read char from serial port
ah3:
    call SerialRead

    jmp ReturnFromInt


; Write char to serial port
ah4:
    push ax

    xchg al, dl
    call SerialWrite

    pop ax
    jmp ReturnFromInt


; Printer output
ah5:
    push ax

    mov al, dl
    call ParallelSendByte

    pop ax
    jmp ReturnFromInt


; Direct console output
ah6:
    cmp dl, byte 0xff
    jne ah2

    jmp ah7

    jmp ReturnFromInt


; Read char form standard input without echo
ah7:
    xor ax, ax
    int 0x16

    jmp ReturnFromInt


; Write string to standard output
ah9:
    push ax
    push si

    push ds
    mov ax, word KernelSeg
    mov ds, ax
    mov al, byte [NormalColour]
    pop ds

    xchg dx, si
    call VgaPrintString

    pop si
    pop ax
    jmp ReturnFromInt


; Buffered input from standard input
ah0a:
    ; ds:dx is the buffer
    ; First byte is buffer size, second byte is the number of chars readed
    push ax
    push bx
    push cx
    push si

    push ds
    mov ax, word KernelSeg
    mov ds, ax
    mov bl, byte [NormalColour]
    pop ds

    mov si, dx
    mov bh, byte [ds:si] ; Buffer size
    xor cl, cl

    .NextChar:
        cmp cl, bh
        je .CarriageReturn

        xor ax, ax
        int 0x16

        cmp al, byte 13
        je .CarriageReturn

        call VgaPrintChar
        mov byte [ds:si], al ; Move char to buffer
        inc cl
        inc si

        jmp .NextChar
    
    .CarriageReturn:
        mov byte [ds:si + 1], cl ; Number of chars readed

        pop si
        pop cx
        pop bx
        pop ax

        jmp ReturnFromInt


; Reset disk
ah0d:
    push ax
    push dx

    xor ah, ah
    mov dl, byte [cs:CurrentDisk]
    int 0x13

    pop dx
    pop ax
    jmp ReturnFromInt


; Rename file using FCB
ah17:
    push si
    push di
    push es
    push ds
    pop es

    mov di, dx
    mov si, dx
    inc di ; Original file name
    add si, 0x11 ; New file name
    call RenameFile

    pop es
    pop di
    pop si
    xor al, al
    jnc ReturnFromInt

    ; Error
    mov al, byte 0xff
    jmp ReturnFromInt



; Get current default drive
ah19:
    mov al, byte [cs:CurrentDisk]

    jmp ReturnFromInt


; Set interrupt vector
ah25:
    push bx
    push cx

    mov bl, al
    mov cl, 2
    shl bx, cl ; bx * 4

    mov word [es:bx], ds ; Set segment
    mov word [es:bx + 2], dx ; Set base

    pop cx
    pop bx
    jmp ReturnFromInt


; Get system date
ah2a:
    push bx

    call CmosGetSystemDate
    mov cx, bx ; Year
    mov dh, ah ; Month
    mov dl, al ; Day
    mov al, dl - 1 ; Day of week

    pop bx
    jmp ReturnFromInt


; Get system time
ah2c:
    push ax
    push bx

    call CmosGetSystemTime
    mov ch, ah ; Hours
    mov cl, al ; Minutes
    mov dh, bl ; Seconds

    ; Get hundredths
    push cx
    push dx
    xor dx, dx
    xor ah, ah
    mov cx, word 60
    div cx

    ; dl is hundredths
    pop dx
    pop cx
    pop bx
    pop ax
    jmp ReturnFromInt


; Get DOS version number
ah30:
    ; We tell it's DOS 3.3 :winky-face:
    mov ax, word 0x0330
    mov bh, byte 0xff ; MS-DOS

    ; bl:cx is the serial number
    xor cx, cx
    xor bl, bl

    jmp ReturnFromInt


; Get interrupt vector
ah35:
    push cx

    xor bx, bx
    mov es, bx

    mov bl, al
    mov cl, 2
    shl bx, cl ; bx * 4

    pop cx
    jmp ReturnFromInt


; Exit program
ah4c:
    jmp ProgramEndPoint


; Rename file
ah56:
    call RenameFile

    jmp ReturnFromInt


ReturnFromInt:
    ; Tell the PIC we are done with interrupt
    ; No idea why but let's do it
    mov al, 0x20
    out 0x20, al

    iret
