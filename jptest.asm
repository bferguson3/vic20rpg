//; Expanded VIC-20 kickstart
*=$1201 "Code block 1"
    .word basicEnd
    .word 2013
    .byte $9e
    .text " "
    .text "4622" //; $1201+13 basic bytes
    .byte 0
    basicEnd: .word 0

init:
        //; enable charset @ $1400   
        lda #%00001101
        ora $9005
        sta $9005 
        //set palette:
        lda #%00011000
        sta $900f //border black, reverse off, bg white
        lda #%01101111 //pink aux color, volume on
        sta $900e
        jsr PrintJPText

        jmp !loop+

!loop:
    jmp !loop-

PrintJPText:
        ldx #0
    !:  lda JPText,x
        sta $1000+(22*11),x
        lda #0
        sta $9400+(22*11),x
        lda JPText2,x
        sta $1000+(22*12),x
        lda #0
        sta $9400+(22*12),x
        inx
        cpx #16
        bcc !-
    rts

JPText: .import binary "jpmap.raw"
JPText2: .import binary "jpmap2.raw"

*=$1400 "JP Charset"
    .import binary "vic1001chars.bin"