//; UN-Expanded VIC-20 kickstart
*=$1001 "Code block 1"
    .word basicEnd
    .word 2013
    .byte $9e
    .text " "
    .text "4110" //; $1001+13 basic bytes
    .byte 0
    basicEnd: .word 0

// Screen mem: $1E00
.const screenMem = $1e00
// Color mem: $9600
.const colorMem = $9600

init:
        //; enable charset @ $1400   
        lda #%00001101
        ora $9005
        sta $9005 
        //set palette:
        lda #%00001000
        sta $900f //border black, reverse off, bg white
        lda #%01101111 //pink aux color, volume on
        sta $900e
        //jsr ColorScreen
        jsr DrawLevel
        jsr DrawPlayer
        jmp !loop+

////////////////////////
//Variable declaration block:

playerX: .byte $0a
playerY: .byte $13
frameCounter: .byte $00
playerDirection: .byte $00 //2 up, 4 right, 6 down, 8 left, 0 = not moving
playerAnimationFrame: .byte $00

!loop:
    //FrameCounter routine:
    lda $9004
    cmp #1
    bcs !notzero+
    lda $9003
    and #%10000000
    bne !notzero+ 
    //scanline 0
    
    inc frameCounter
    lda frameCounter
    and #%00000111 //=7
    bne !loop-
    jmp !frame8+
    
    !notzero:
    jmp !loop-
    
    !frame8:
    
    lda playerAnimationFrame
    cmp #1
    bcc !+
    lda #0
    sta playerAnimationFrame
    jmp !go+
    !:inc playerAnimationFrame
    !go:
    
    jsr CheckInput
    jsr FindNewPlayerPos //do collision here
    jsr DrawPlayer
    jmp !loop-

.const eatManLeft = 71
.const eatManRight = 73
.const eatManUp = 74
.const eatManDown = 75
.const eatMan = 72

!quickReturn:
rts

ClearPlayerPos:
        ldx playerX
        ldy playerY
        lda #0
        jsr DrawCharacter_XYA 
    rts

FindNewPlayerPos:
        //check if playerX = 0 and direction=8 then wrap x=22
        //if x=22 and direction=4, wrap to x=0
        //also, check if playerY = 0 and dir=2, wrap y=23
        //if y=23 and dir=6, wrap y=0
        //check direction
        //check next tile in that direction if is a collider
        //if not, update player pos
        lda playerDirection
        cmp #8 //Left direction:
        bcc !+
        ldx playerX
        beq wrapRight
        dex
        ldy playerY
        jsr CheckCollider_XY //collider?
        cmp #1
        bcs !quickReturn-
        //
        jsr ClearPlayerPos
        //
        dec playerX //move payer
        //jsr DrawPlayer
         rts
        wrapRight:
        jsr ClearPlayerPos
        ldx #21
        stx playerX
         rts
        !:cmp #6 //Down direction:
        bcc !+
        ldx playerX
        ldy playerY
        cpy #23
        bcs wrapUp
        iny
        jsr CheckCollider_XY
        cmp #1
        bcs !quickReturn-
        jsr ClearPlayerPos
        inc playerY
        //jsr DrawPlayer
         rts
        wrapUp:
        jsr ClearPlayerPos
        ldy #0
        sty playerY
         rts
        !:cmp #4 //Right
        bcc !+
        ldx playerX
        cpx #21
        bcs wrapLeft
        inx
        ldy playerY
        jsr CheckCollider_XY
        cmp #1
        bcs !end+
        //1 = collider, 0 = not collider
        jsr ClearPlayerPos
        inc playerX
        //jsr DrawPlayer
         rts
        wrapLeft:
        jsr ClearPlayerPos
        ldx #0
        stx playerX
         rts
        !:cmp #2 //Up dir
        bcc !+
        ldx playerX
        ldy playerY
        beq wrapDown
        dey
        jsr CheckCollider_XY
        cmp #1
        bcs !end+
        jsr ClearPlayerPos
        dec playerY
        //jsr DrawPlayer
         rts
        wrapDown:
        jsr ClearPlayerPos
        ldy #22
        sty playerY
         rts
    !:  cmp #1
        bcs !end+
        //no movement
    !end:
    rts

CheckInput:
        //;row sel register $9120
        //; data reg $9121
        lda #251 //cur, ; , l, j, g, d, a, ctrl
        sta $9120
        lda $9121
        cmp #251
        bcc !+
        cmp #251+1
        bcs !+
        //'D' pressed
        //only if no collision, update player direction
        ldx playerX
        inx
        ldy playerY
        jsr CheckCollider_XY
        cmp #1
        bcs !end-
        lda #4
        sta playerDirection
         rts
    !:  cmp #253
        bcc !+
        cmp #253+1
        bcs !+
        //'A'
        ldx playerX
        dex
        ldy playerY
        jsr CheckCollider_XY
        cmp #1
        bcs !end+
        lda #8 //left
        sta playerDirection
         rts
    !:  lda #223
        sta $9120
        lda $9121
        cmp #253
        bcc !+
        cmp #253+1
        bcs !+
        //'S' pressed
        ldx playerX
        ldy playerY
        iny
        jsr CheckCollider_XY
        cmp #1
        bcs !end+
        lda #6
        sta playerDirection
         rts
    !:  lda #253
        sta $9120
        lda $9121
        cmp #253
        bcc !end+
        cmp #253+1
        bcs !end+
        //'W'
        ldx playerX
        ldy playerY
        dey
        jsr CheckCollider_XY
        cmp #1
        bcs !end+
        lda #2
        sta playerDirection
    !end:
    rts

drawChar: .byte $00

CheckCollider_XY:
        stx $fd
        sty $fe

        lda #0
        sta $fb
        lda #$1e
        sta $fc
        lda #0
        ldy $fe
    !:  beq !yzero+
        clc
        adc #22
        bcc !noinc+
        inc $fc
        !noinc:
        dey
        bpl !-
        !yzero:
        ldx $fd
        stx $fb
        clc
        adc $fb
        bcc !noinc+
        inc $fc
        !noinc:
        sta $fb
        //draw:
        ldy #0
        lda ($fb),y
        cmp #83
        bcc !+
        cmp #84+1
        bcs !+
        //
        lda #1
        rts
        !:
        cmp #85
        bcc !+
        cmp #85+1
        bcs !+ //missing before:
        lda #1
        rts
    !:  //between 77-80 = edges
        cmp #77
        bcc !+
        cmp #81
        bcs !+
        lda #1
        rts
    !:  
        lda #0
        rts

DrawCharacter_XYA:
        stx $fd
        sty $fe
        sta drawChar

        lda #0
        sta $fb
        lda #$1e
        sta $fc
        lda #0
        ldy $fe
    !:  beq !yzero+
        clc
        adc #22
        bcc !noinc+
        inc $fc
        !noinc:
        dey
        bpl !-
    !yzero:
        ldx $fd
        stx $fb
        clc
        adc $fb
        bcc !noinc+
        inc $fc
        !noinc:
        sta $fb
        //draw:
        lda drawChar
        ldy #0
        sta ($fb),y
        
rts

DrawPlayer:
//fb,fc = screenMem offset
//00 1e
        lda #0
        sta $fb
        lda #$1e
        sta $fc //($fb) = screenMem

        //22*playerY + playerX = offset screenMem (1e00)
        lda #0
        ldy playerY //0-21
    !:  beq !yzero+
        clc
        adc #22
        bcc !noinc+
        inc $fc
        !noinc:
        dey
        bpl !-
    !yzero:ldx playerX
        stx $fb
        clc
        adc $fb
        bcc !noinc+
        inc $fc
        !noinc:
        sta $fb
        //actually draw
        //check playerAnimationFrame
        lda playerAnimationFrame
        beq !drawCircle+
        //
        lda playerDirection
        cmp #8
        bcc !next+
        lda #eatManLeft
        jmp !+
        !next:
        cmp #6
        bcc !next+
        lda #eatManDown
        jmp !+
        !next:
        cmp #4
        bcc !next+
        lda #eatManRight
        jmp !+
        !next:
        lda #eatManUp
        jmp !+
        !drawCircle:
        lda #eatMan
        !:
        ldy #0
        sta ($fb),y
        //color:
        lda #$78
        clc
        adc $fc
        sta $fc
        lda #7
        sta ($fb),y
    rts


DrawLevel:
        ldx #0
     !: lda LevelData,x
        sta screenMem,x
        tay
        lda ColorData,y
        sta colorMem,x

        lda LevelData+256,x
        sta screenMem+256,x
        tay
        lda ColorData,y
        sta $9600+256,x
        inx
        bne !-
    rts

*=$1400
    .import binary "eatmanchars.raw"
LevelData:
    .import binary "eatmanmap.bin"
ColorData:
    .import binary "eatmancolors.raw"
