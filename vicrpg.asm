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
        lda #%0011000 //invert OFF (bit set)
        sta $900f //border black, bg white
        lda #%10101111 //pink aux color, volume on
        sta $900e
        //setup subroutines
        jsr PrintText
        jsr DrawHero
        
        jmp !loop+

////////////////////////////////
//; Variable defs block:
    testString:
    .text "This is a test."

*=$1400 "Charset"
    .import binary "map1chars.raw"

*=$1c00 "Code block 2"
    !loop:   
        jmp !loop-

PrintText:
        ldx #0
        !printloop:
        lda testString,x
        sta $1000,x
        inx
        cpx #16
        bcc !printloop-
    rts

DrawHero:
        lda #96
        sta $1000
        lda #97
        sta $1001
        lda #112
        sta $1000+22
        lda #113
        sta $1000+23
        lda #%00001011
        //COLOR INFORMATION:
        //0000x000 = multicolor on for this tile
        //00000xxx = 3bit color value- corresponds to
        //COLOR 0 - background color
        //COLOR 1 - auxiliary color
        //COLOR 2 - border color
        //COLOR 3 - character color
        sta $9400
        sta $9401
        sta $9400+22
        sta $9400+23
    rts