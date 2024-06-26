[bits 16]
[cpu 8086]


; *NOTES
; *FAT on disk looks like this:
; *-------------------------------------------------------------------------------
; *| Boot sector | Extra reserved sectors | FAT1 | FAT2 | Root dir | Data region |
; *-------------------------------------------------------------------------------
;
; *How to calculate start point of root directory:
; ReservedSectors + (NumberOfFATs * SectorsPerFAT) = 19
; *How to calculate the size of the root dir:
; 32(entry size) * RootDirEntries / BytesPerSector
;
; *How to convert LBA to CHS:
; sector = (LBA % SectorsPerTrack) + 1
; head = (LBA / SectorsPerTrack) % DiskHeads
; track = LBA / (SectorsPerTrack * DiskHeads)
;
; I saw online that entries with a file attribute of 0xf are "fake" ones to use for long file names
;
; *Useful stuff:
; https://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html



; Reads the disk into the specified buffer in memory
; Input:
;   bx = buffer offset
;   al = sectors to read
ReadDisk:
    call ResetDisk

    push dx

    ; Buffer to read to(ES:BX) is already set
    mov ah, 0x02 ; Read please
    ; Sectors to read are already set
    mov dl, byte [BootDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, byte [ChsTrack] ; C (cylinder)
    mov dh, byte [ChsHead] ; H (head)
    mov cl, byte [ChsSector] ; S (sector). Starts from 1, not 0. Why?

    stc
    int 0x13
    jc .Check ; Carry flag set

    mov [ReadAttempts], byte 0
    pop dx
    ret
    
    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add [ReadAttempts], byte 1 ; If I use inc I get an error
        cmp [ReadAttempts], byte 3
        je ReadDiskError

        jmp ReadDisk



; Loads the first FAT
LoadFAT:
    ; FATs are just after the reserved sectors, so...
    mov ax, word ReservedSectors
    call LbaToChs

    mov bx, FATMemLocationOffset
    mov al, byte SectorsPerFAT ; Sectors to read
    call ReadDisk



; Loads the root directory
LoadRootDir:
    ; Get CHS info
    mov ax, word RootDirStartPoint
    call LbaToChs

    mov bx, RootDirMemLocationOffset
    mov al, byte RootDirSize ; Sectors to read
    call ReadDisk



; Searches for an entry in the root dir with the kernel file name
SearchKernel:
    mov di, RootDirMemLocationOffset
    mov cx, word RootDirEntries ; Counter

    .NextEntry:
        push di
        push cx

        lea si, KernelFileName ; First string
        mov cx, 11 ; How many bytes to compare

        repe cmpsb

        pop cx
        pop di ; Get the original value back(current entry start)
        je LoadKernel

        add di, 32 ; Every entry is 32 bytes
        loop .NextEntry

        ; Nope. Nope.
        jmp ReadDiskError



LoadKernel:
    mov ax, word [di + 0x1a] ; Bytes 26-27 is the first cluster
    mov word [CurrentCluster], ax ; Save it

    ; Where we load the kernel
    mov ax, word KernelSeg
    mov es, ax
    xor bx, bx

    .LoadCluster:
        ; The actual data sector starts at sector 33.
        ; Also -2 because the first 2 entries are reserved
        mov ax, word [CurrentCluster]
        add ax, 31

        call LbaToChs

        mov bx, word [KernelAddress]
        mov al, byte SectorsPerCluster
        call ReadDisk

        ; Calculates next cluster
        ; Since the values for the clusters are 12 bits we need to read two bytes
        ; and kick off the other 4 bits. We do:
        ; CurrentCluster + (CurrentCluster / 2)
        mov ax, word [CurrentCluster]
        mov dx, ax
        mov bx, ax
        mov cl, byte 1
        shr bx, cl ; Shift a bit to the right, aka divide by 2
        add bx, ax

        ; Get the 12 bits
        mov ax, FATMemLocationOffset
        add bx, ax
        mov ax, word [bx]

        ; Checks if the current cluster is even or not
        ; Checks if the first bit is 1 or 0
        test dx, 1
        jz .EvenCluster

        .OddCluster:
            mov cl, byte 4
            shr ax, cl
            jmp .Continue

        .EvenCluster:
            and ax, 0xfff

        .Continue:
            cmp ax, word 0xff8 ; 0xff8 - 0xfff represent the last cluster
            jae .KernelLoaded

            mov word [CurrentCluster], ax ; Save the new cluster
            add word [KernelAddress], 512 ; Next sector
            jmp .LoadCluster


        .KernelLoaded:
            ; Clears the screen
            xor ah, ah
            mov al, 3
            int 0x10

            ; Should be useful
            mov dl, byte [BootDisk]

            ; Jump to kernel
            mov ax, word KernelSeg
            xor bx, bx
            push ax
            push bx
            retf



; Resets the disk: moves to the first sector
; Output:
;   ah = status (0 if success)
;   cf = 0 if success, set if not
ResetDisk:
    push ax

    xor ah, ah
    mov dl, byte [BootDisk]
    int 0x13

    pop ax

    ret



; Converts LBA to CHS
; Input:
;   ax = lba address to convert
LbaToChs:
    push ax

    ; Sector
    xor dx, dx
    mov bx, word SectorsPerTrack
    div bx
    inc dl ; Sectors start from 1
    mov byte [ChsSector], dl

    pop ax

    ; Head and track
    xor dx, dx
    mov bx, word SectorsPerTrack
    div bx
    
    xor dx, dx
    mov bx, word DiskHeads
    div bx
    mov byte [ChsTrack], al
    mov byte [ChsHead], dl

    ret


; Gets a cluster number and converts it to LBA
; Input:
;   ax = chs address to convert
; Output:
;   ax = LBA
ClusterToLba:
    xor cx, cx
    xor dx, dx

    sub ax, 2
    mov cl, byte SectorsPerCluster
    mul cx

    ret


ReadDiskError:
    pop dx
    lea si, ReadDiskErrorMessage
    call PrintString

    ; Wait for key press
    xor ah, ah
    int 0x16

    ; Reboot
    xor ah, ah
    int 0x19





BootDisk: db 0
KernelFileName: db "KERNEL  BIN"
CurrentCluster: dw 0
KernelAddress: dw 0

ChsSector: db 0
ChsTrack: db 0
ChsHead: db 0

ReadAttempts: db 0
ReadDiskErrorMessage: db 10, 13, "Disk read error", 0
