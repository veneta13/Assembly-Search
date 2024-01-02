; 82184
; Search

masm
model medium

.386
.stack 4096

.data

token db 100 dup (?)

enterFileMsg db "Enter file name: $"
enterTokenMsg db "Enter token to search for: $"
fileReadMsg db "File read successfully.$"

lineNumMsg db " line: $"
tokenCountMsg db " token(s) found. $"
sentenceCountMsg db " sentence(s) found.$"

errorCantOpen db "Can't open file. Exiting...$"
errorFileError db "File error occured.$"

newline db 10, 13, '$' ; line feed, carriage return
whitespace db ' $'

fileContent db 500 dup (?)
fileContentLen dw 0

fileName db 30 dup (?)
fileNameLen dw 0
filePtr dw 0

currentLine db 200 dup (?)
lineNum dw 0

tokenFirstCol dw 0
currentCol dw 0
tokenCount dw 0
tokenCountLine dw 0
sentenceCount dw 0

.code
org 100h

; ----------------------------------------------------------------
; COUNT OCCURENCES OF TOKEN IN LINE
countTokenInLine:    
    xor dx, dx
    xor cx, cx
    xor bx, bx
    xor ax, ax
    
    mov tokenCountLine, 0
    mov tokenFirstCol, 0
    mov currentCol, 1

    mov si, 0 ; currentLine
    mov di, 0 ; token

loopTokenInText:
    cmp token[di], '$'
    je endOfToken
    
    cmp currentLine[si], '$'
    je stopCountTokenInLine

    mov al, token[di]
    cmp currentLine[si], al
    jne nextWord

    inc si
    inc di
    jmp loopTokenInText

endOfToken:
    mov di, 0

    cmp currentLine[si], ' '
    je increaseTokenCount
    cmp currentLine[si], '$'
    je increaseTokenCount

nextWord:
    cmp currentLine[si], ' '
    je newWordFound
    cmp currentLine[si], '$'
    je stopcounttokeninline

    inc si
    jmp nextWord

increaseTokenCount:
    inc tokenCount
    inc tokenCountLine

    cmp tokenFirstCol, 0
    je setTokenFirstCol

continueIncreaseTokenCount:
    cmp currentLine[si], '$'
    je stopCountTokenInLine

    jmp nextWord

newWordFound:
    inc si
    mov di, 0

    inc currentCol
    jmp loopTokenInText

stopCountTokenInLine:
    cmp token[di], '$'
    je increaseTokenCount
    
    cmp tokenCountLine, 0
    jne printCurrentLine

exitLine:
    inc lineNum
    ret

printCurrentLine:
    push ax
    mov ax, lineNum
    call printNumber
    pop ax
    
    mov dx, offset lineNumMsg
    mov ah, 09h
    int 21h
    
    push ax
    mov ax, tokenFirstCol
    call printNumber
    pop ax

    mov dx, offset newline
    mov ah, 09h
    int 21h

    mov dx, offset currentLine
    mov ah, 09h
    int 21h
    
    mov dx, offset newline
    mov ah, 09h
    int 21h

    jmp exitLine

setTokenFirstCol:
    mov bx, currentCol
    mov tokenFirstCol, bx
    jmp continueIncreaseTokenCount

; ----------------------------------------------------------------
; READ LINES
readLines:
    xor ax, ax
    xor bx, bx
    xor dx, dx
    xor cx, cx
    cld

    mov si, 0; fileContent
    mov di, 0; currentLine

loopLines:
    cmp fileContent[si], '.'
    je increaseSentenceCount
    cmp fileContent[si], '!'
    je increaseSentenceCount
    cmp fileContent[si], '?'
    je increaseSentenceCount

continueLoopLines:
    cmp fileContent[si], 10
    je nextSymbol
    cmp fileContent[si], 13
    je newLineFound
    cmp fileContent[si], '$'
    je lastLineFound

    mov al, fileContent[si]
    mov currentLine[di], al
    inc di

nextSymbol:
    inc si
    jmp loopLines

newLineFound:
    call handleLine
    inc si
    jmp loopLines

lastLineFound:
    call handleLine
    ret

handleLine:
    mov currentLine[di], '$'
    
    push si
    push di
    push ax
    push bx
    push cx
    push dx
    call countTokenInLine
    pop dx
    pop cx
    pop bx
    pop ax
    pop di
    pop si

    mov di, 0
    ret

increaseSentenceCount:
    inc sentenceCount
    jmp continueLoopLines

; ----------------------------------------------------------------
; PRINT NUMBER
printNumber:
    mov dx,0
    mov cx,0

    cmp ax, 0
    je checkforNone

separateDigits:
    cmp ax,0
    je printDigit

    mov bx, 10
    div bx

    push dx
    inc cx

    xor dx,dx
    jmp separateDigits

printDigit:
    cmp cx, 0
    je stopPrintNumber

    pop dx
    add dx, 48
    mov ah, 02h
    int 21h

    dec cx
    jmp printDigit

stopPrintNumber:
    ret

checkforNone:
    mov dx, '0'
    mov ah, 02h
    int 21h
    jmp stopPrintNumber

; ----------------------------------------------------------------
; ERRORS
cantOpenFile:
    mov dx, offset errorCantOpen
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

otherFileError:
    mov dx, offset errorFileError
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

; ----------------------------------------------------------------
; MAIN CODE
main:
    mov ax, @data
    mov ds, ax
    xor ax, ax

displayFileReadMessage:
    mov dx, offset enterFileMsg
    mov ah, 09h
    int 21h

    xor bx, bx
    mov cx, 20
    mov ah, 01h

enterFileName:
    int 21h ; display entered symbol
    cmp al, 13 ; check for 'Enter'
    je openFile
    inc fileNameLen
    mov fileName[bx], al
    inc bx
    loop enterFileName
    
openFile:
    mov ah, 3dh
    mov al, 00h
    lea dx, [fileName]
    int 21h
    jc cantOpenFile

getFileSize: ; (http://computer-programming-forum.com/46-asm/dbdeb3e31647c9b3.htm)
    mov filePtr, ax

    mov bx, filePtr
    mov ax, 4202h ; get file size
    xor cx, cx
    xor dx, dx
    int 21h
    jc otherFileError
    mov fileContentLen, ax

    mov ax, 4200h ; reset to beginning of file
    xor cx, cx
    xor dx, dx
    int 21h
    jc otherFileError

readFromFile:
    mov ah, 3fh
    mov bx, filePtr
    mov cx, fileContentLen
    mov dx, offset fileContent
    int 21h
    jc otherFileError
    
    mov ax, fileContentLen
    mov bx, offset fileContent
    add ax, bx
    mov di, ax

    mov byte ptr [di], '$'

fileLoadedMessage:
    mov ah, 09h
    mov dx, offset fileReadMsg
    int 21h
    mov ah, 09h
    mov dx, offset newline
    int 21h

closeFile:
    mov ah, 3eh
    mov bx, filePtr
    int 21h

displayTokenReadMessage:
    mov dx, offset enterTokenMsg
    mov ah, 09h
    int 21h

    xor bx, bx
    mov cx, 20
    mov ah, 01h

enterToken:
    int 21h
    cmp al, 13
    je countToken
    mov token[bx], al
    inc bx
    loop enterToken

countToken:
    mov token[bx], '$'
    call readLines

printStats:
    mov ah, 09h
    mov dx, offset newline
    int 21h

    mov ax, tokenCount
    call printNumber
    
    mov ah, 09h
    mov dx, offset tokenCountMsg
    int 21h

    mov ax, sentenceCount
    call printNumber
    
    mov ah, 09h
    mov dx, offset sentenceCountMsg
    int 21h

exit:
    mov ax, 4c00h
    int 21h

end main
