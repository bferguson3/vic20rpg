//; DragonHoard
//;  (c)2018 Ben Ferguson
//; UN-Expanded VIC-20 kickstart
*=$1001 "Code block 1"
block1start:
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
playerY: .byte $10
frameCounter: .byte $00
playerDirection: .byte $00 //2 up, 4 right, 6 down, 8 left, 0 = not moving
//playerAnimationFrame: .byte $00

randNo: .byte $00,$00

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
    and #%00000011 
    bne !loop-
    jmp !frame4+
    
    !notzero:
    inc randNo
    bne !loop-
    inc randNo+1
    jmp !loop-
    //jmp !loop-
    
    !frame4:
    jsr FlashPow
    lda frameCounter
    and #%00000111
    bne !loop-

    !frame8:
    jsr CheckInput
    jsr FindNewPlayerPos //do collision here
    jsr DrawPlayer
    jsr IncreaseScore
    lda frameCounter
    and #%00001111
    bne !loop-

    !frame16:
    jsr FindNewEnemyPos
    jsr MoveEnemies //jmp DrawEnemies
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

moveLoop: .byte $fc 

MoveEnemies:
        //replace char first
        
  en1a: ldx enemyx 
  en1b: ldy enemyy 
  en1c: lda enemychar
        jsr DrawCharacter_XYA
  en2a: ldx enemyx 
  en2b: ldy enemyy 
  en2c: lda enemychar
        jsr ColorCharacter_XYA
        ldx enemyx+1 
        ldy enemyy+1 
        lda enemychar+1
        jsr DrawCharacter_XYA
        ldx enemyx+1 
        ldy enemyy+1 
        lda enemychar+1
        jsr ColorCharacter_XYA
        ldx enemyx+2 
        ldy enemyy+2 
        lda enemychar+2
        jsr DrawCharacter_XYA
        ldx enemyx+2 
        ldy enemyy+2 
        lda enemychar+2
        jsr ColorCharacter_XYA
        ldx enemyx+3
        ldy enemyy+3 
        lda enemychar+3
        jsr DrawCharacter_XYA
        ldx enemyx+3 
        ldy enemyy+3 
        lda enemychar+3
        jsr ColorCharacter_XYA
        
        //now acually move:

        lda enemydir
        cmp #3
        bcs !more+
        //up
        ldx enemyy
        dex 
        stx enemyy 
        //draw enemy
        jmp !end+ //?
        !more:
        cmp #5
        bcs !more+
        //right
        ldx enemyx
        inx 
        stx enemyx 
        //draw?
        jmp !end+
        !more:
        cmp #7
        bcs !more+
        //down
        ldx enemyy
        inx 
        stx enemyy
        //draw?
        jmp !end+
        !more:
        //left
        ldx enemyx
        dex 
        stx enemyx
        //draw?
        //rts  //?
        !end:
    jmp MoveEnemies234
    //jmp DrawEnemies


        !quickReturn:
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
        cpy #20
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
        ldy #20
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

/////////////////
// x position
// y position
// returns A = 0 if empty, 1 if blocked
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
        cmp #92+1
        bcs !+
        //
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
        cmp #90
        bcc !+
        cmp #92+1
        bcs !+
        lda #1
        rts 
        !:
        
        lda #0
        rts



LoadCharacter_XYA:
        stx $fd
        sty $fe
        sta drawChar //86-89

        lda #0//screenmem lb
        sta $fb
        lda #$1e //screenmem hb
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
        lda drawChar
        cmp #87 //enemy 1
        bcs !more+
        //Load char into enemy char
        lda ($fb),y 
        sta enemychar
        jmp !end+
        !more:
        cmp #88
        bcs !more+
        lda ($fb),y
        sta enemychar+1
        jmp !end+
        !more:
        cmp #89
        bcs !more+
        lda ($fb),y 
        sta enemychar+2
        jmp !end+
        !more:
        lda ($fb),y 
        sta enemychar+3
        //ldy #0
        //sta ($fb),y
        !end:
rts
///////////////////
// x: x position on-screen
// y: y position on-screen
// A: character # to draw
DrawCharacter_XYA:
        stx $fd
        sty $fe
        sta drawChar

        lda #0//screenmem lb
        sta $fb
        lda #$1e //screenmem hb
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
        //Draw:
        lda drawChar
        ldy #0
        sta ($fb),y
        
rts

///////////////////
// x: x position on-screen
// y: y position on-screen
// A: character # to draw
ColorCharacter_XYA:
        stx $fd
        sty $fe
        sta drawChar

        lda #0//screenmem lb
        sta $fb
        lda #$96 //colormem hb
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
        //Color:
        ldx drawChar
        lda ColorData,x
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
        //lda playerAnimationFrame
        //beq !drawCircle+
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
        //!drawCircle:
        //lda #eatMan
        !:
        ldy #0
        sta ($fb),y
        //color:
        lda #$78
        clc
        adc $fc
        sta $fc
        lda #5
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

IncreaseScore:
        // subtract 48 to get the actual value of the digit
        // increase 1, if its =A then roll up next digit and set
        // this digit to zero.
        lda #<screenMem+((22*21)+14) //location of score lsd
        sta $fb 
        lda #>screenMem+((22*21)+14)
        sta $fc 
        //14,21
        ldy #0
        lda ($fb),y

        clc 
        adc #1
        sta ($fb),y 
        cmp #58
        bcc !skip+
        !rolloverloop:
        lda #48
        sta ($fb),y
        dec $fb     //next most sig digit
        lda ($fb),y 
        clc 
        adc #1
        sta ($fb),y
        cmp #58
        bcs !rolloverloop-
        !skip:
    rts
/*
//from motorola 6800 by don aldridge
.var htd_out = $fb
.var htd_in = $fd
HexToDeci_A:
    cld 
    sta htd_in 
    tay 
    lda #0
    sta htd_out
    sta htd_out+1
*/
block1end:
.print "Code block 1 size: " + (block1end-block1start)
*=$1400 "Chars, map, colors"
datastart:
    .import binary "eatmanchars.raw"
LevelData:
    .import binary "eatmanmap.bin"
ColorData:
    .import binary "eatmancolors.raw"
dataend:
.print "Data block size: " + (dataend-datastart)
*=$195a "Code block 2"

enemyx: .byte $09,$0a,$0b,$0c
enemyy: .byte $09,$09,$09,$09
enemydir: .byte $08,$08,$04,$04


DrawEnemies:
        //replace char first

        ldx enemyx 
        ldy enemyy 
        lda #86
        jsr LoadCharacter_XYA //loads into ram char at new pos
        ldx enemyx 
        ldy enemyy 
        lda #86
        jsr DrawCharacter_XYA //draws enemy at new pos
        ldx enemyx 
        ldy enemyy 
        lda #86
        jsr ColorCharacter_XYA //colors char at new pos
        ldx enemyx+1 
        ldy enemyy+1 
        lda #86+1
        jsr LoadCharacter_XYA //loads into ram char at new pos
        ldx enemyx+1 
        ldy enemyy+1 
        lda #86+1
        jsr DrawCharacter_XYA //draws enemy at new pos
        ldx enemyx+1 
        ldy enemyy+1 
        lda #86+1
        jsr ColorCharacter_XYA //colors char at new pos
        ldx enemyx+2 
        ldy enemyy+2 
        lda #86+2
        jsr LoadCharacter_XYA //loads into ram char at new pos
        ldx enemyx+2 
        ldy enemyy+2 
        lda #86+2
        jsr DrawCharacter_XYA //draws enemy at new pos
        ldx enemyx+2 
        ldy enemyy+2 
        lda #86+2
        jsr ColorCharacter_XYA //colors char at new pos
        ldx enemyx+3
        ldy enemyy+3 
        lda #86+3
        jsr LoadCharacter_XYA //loads into ram char at new pos
        ldx enemyx+3 
        ldy enemyy+3 
        lda #86+3
        jsr DrawCharacter_XYA //draws enemy at new pos
        ldx enemyx+3 
        ldy enemyy+3 
        lda #86+3
        jsr ColorCharacter_XYA //colors char at new pos
rts

MoveEnemies234:
        lda enemydir+1
        cmp #3
        bcs !more+
        //up
        ldx enemyy+1
        dex 
        stx enemyy+1 
        //draw enemy
        jmp !end+ //?
        !more:
        cmp #5
        bcs !more+
        //right
        ldx enemyx+1
        inx 
        stx enemyx+1 
        //draw?
        jmp !end+
        !more:
        cmp #7
        bcs !more+
        //down
        ldx enemyy+1
        inx 
        stx enemyy+1
        //draw?
        jmp !end+
        !more:
        //left
        ldx enemyx+1
        dex 
        stx enemyx+1
        //draw?
        //rts  //?
        !end:

        lda enemydir+2
        cmp #3
        bcs !more+
        //up
        ldx enemyy+2
        dex 
        stx enemyy+2 
        //draw enemy
        jmp !end+ //?
        !more:
        cmp #5
        bcs !more+
        //right
        ldx enemyx+2
        inx 
        stx enemyx+2 
        //draw?
        jmp !end+
        !more:
        cmp #7
        bcs !more+
        //down
        ldx enemyy+2
        inx 
        stx enemyy+2
        //draw?
        jmp !end+
        !more:
        //left
        ldx enemyx+2
        dex 
        stx enemyx+2
        //draw?
        //rts  //?
        !end:

        lda enemydir+3
        cmp #3
        bcs !more+
        //up
        ldx enemyy+3
        dex 
        stx enemyy+3 
        //draw enemy
        jmp !end+ //?
        !more:
        cmp #5
        bcs !more+
        //right
        ldx enemyx+3
        inx 
        stx enemyx+3 
        //draw?
        jmp !end+
        !more:
        cmp #7
        bcs !more+
        //down
        ldx enemyy+3
        inx 
        stx enemyy+3
        //draw?
        jmp !end+
        !more:
        //left
        ldx enemyx+3
        dex 
        stx enemyx+3
        //draw?
        //rts  //?
        !end:
    jmp DrawEnemies

enemyposloop: .byte $00

Rand2468:
        !:
        lda randNo
        and #%00001110
        cmp #9
        bcc !+
        asl randNo
        jmp !-
        !:
    rts
RandAndLoop:
        jsr Rand2468
        ldx enemyposloop
        sta enemydir,x 
        jmp newposloop

FindNewEnemyPos:
        //zp: $fb $fc $fd $fe 
        //using CheckCollider_XY clobs all zp
        ldx #0
        stx enemyposloop
    newposloop:
        ldx enemyposloop
        lda enemydir,x //2, 4, 6, 8
        cmp #3
        bcs !more+
        //UP:::::
        //2/up OR 6/down
        // check left/right tiles for collision
        // if empty, change direction randomly
        // check random direction for collision
        // repeat if needed
        // end sub
        // else
        // check forward tile for collision
        // end sub
        // else
        // dir = backwards
        // end sub
        !checkright: //>>checkleft
        lda enemyy,x 
        tay 
        lda enemyx,x 
        tax 
        inx //one tile right
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkleft+
        // empty
        jmp RandAndLoop
        
        !checkleft:
        ldx enemyposloop
        lda enemyy,x 
        tay 
        lda enemyx,x 
        tax 
        dex //one tile left
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkoneup+
        //1 left is empty
        jmp RandAndLoop
        //RIGHT:::
        !more:
        cmp #5
        bcs !more+
        //4 - right
        !checkup:
        ldx enemyposloop
        lda enemyy,x 
        tay 
        dey 
        lda enemyx,x 
        tax 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkdown+
        jmp RandAndLoop
        !checkdown:

        !more:
        !checkoneup:
        !checkoneleft:
        !checkoneright:
        !checkonedown:
endNMECollision:
        inc enemyposloop
        lda enemyposloop
        cmp #4
        bcs !+
        jmp newposloop
        !:
        lda #0
        sta enemyposloop
    rts 
        // 4/right OR 8/left
        // check up/down for collision
        // if empty, change dir random
        // check new dir for collision
        // repeat if needed
        // end sub
        // else
        // check forward tile for collision
        // end sub
        // else
        // dir = backwards
        // end sub
        /*
        ldx #0
        stx enemyposloop // loop number
nmeColLoop:
        ldx enemyposloop
        lda enemydir,x //has enemy dir
        // check lateral from dir
        cmp #3
        bcs !more+
        //up: check x+1 and x-1
        lda enemyy,x
        tay 
        lda enemyx,x
        tax 
        inx //x=x+1, y=y
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkleft+
        //unblocked on right
        //INSTEAD:
        //roll random: 2, 4, 6, or 8
        //store in dir and jmp back to nmecolloop
        // need: 0010 0100 0110 1000
        //not need: 1110 1010 
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        //lda #4 
        //ldx enemyposloop
        //sta enemydir,x //change dir to RIGHT
        jmp endNMECollision //?
        !checkleft:
        ldx enemyposloop
        lda enemyy,x 
        tay 
        lda enemyx,x 
        tax 
        dex 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcc !+//checkfrontback+
        jmp checkfrontback
        !:
        //unblocked on left
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        
        !more: //dir = 4 next
        cmp #5
        bcs !more+
        //right- check up and down
        lda enemyy,x 
        tay 
        iny 
        lda enemyx,x 
        tax 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkup+
        //unblocked DOWN, change dir
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        !checkup:
        ldx enemyposloop
        lda enemyy,x 
        tay 
        dey 
        lda enemyx,x 
        tax 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcc !+//checkfrontback+
        jmp checkfrontback
        !:
        //unblocked UP
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        !more: //6
        cmp #7
        bcs !more+
        //down - check r:
        lda enemyy,x 
        tay 
        lda enemyx,x 
        tax 
        inx 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkleft+
        //unblocked right, change dir
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        !checkleft:
        ldx enemyposloop
        lda enemyy,x 
        tay 
        lda enemyx,x 
        tax 
        dex 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcc !+//checkfrontback+
        jmp checkfrontback
        !:
        //unblocked l
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        
        !more: //left: 8
        //check up and down
        lda enemyy,x 
        tay 
        iny 
        lda enemyx,x 
        tax 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcs !checkup+
        //unblocked down
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        !checkup:
        ldx enemyposloop
        lda enemyy,x 
        tay 
        dey 
        lda enemyx,x 
        tax 
        jsr CheckEnemyCollider_XY
        cmp #1
        bcc !+
        jmp checkfrontback
        !:
        //unblocked up
        lda randNo
        and #%01110000
        lsr 
        lsr 
        lsr // xxxx111x
        cmp #9
        bcc !+
        jmp checkfrontback
        !:
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
checkfrontback:
        ldx enemyposloop
        lda enemydir,x
        cmp #3
        bcs !more+
        //UP
        lda enemyy,x 
        tay 
        dey 
        lda enemyx,x 
        tax 
        jsr CheckCollider_XY
        cmp #1
        bcs !+
        jmp endNMECollision
        !:
        lda #6
        ldx enemyposloop
        sta enemydir,x
        jmp endNMECollision
        !more:
        cmp #5
        bcs !more+
        //right
        lda enemyy,x 
        tay 
        dey 
        lda enemyx,x 
        tax 
        jsr CheckCollider_XY
        cmp #1
        bcs !+
        jmp endNMECollision
        !:
        lda #8
        ldx enemyposloop
        sta enemydir,x
        !more:
endNMECollision:
        inc enemyposloop
        lda enemyposloop
        cmp #4
        bcs !+
        jmp nmeColLoop
        !:
        lda #0
        sta enemyposloop
        */
    //rts

enemychar: .byte $00,$00,$00,$00

FlashPow:

    rts

/////////////////
// x position
// y position
// returns A = 0 if empty, 1 if blocked
CheckEnemyCollider_XY:
        cpx #1
        bcs !+
        lda #1
        rts 
        !:
        cpx #22
        bcc !+
        lda #1
        rts 
        !:
        cpy #1
        bcs !+
        lda #1
        rts 
        !:
        cpy #21
        bcc !+
        lda #1
        rts 
        !:

        stx $fd
        sty $fe

        lda #0
        sta $fb
        lda #$1e
        sta $fc //$fb,$fc = $1e00
        lda #0
        ldy $fe //ypos
    !:  beq !yzero+
        clc
        adc #22 //move to row2
        bcc !noinc+
        inc $fc 
        !noinc:
        dey
        bpl !-
        !yzero:
        ldx $fd //x
        stx $fb //x offset
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
        cmp #92+1
        bcs !+
        //
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
        cmp #90
        bcc !+
        cmp #92+1
        bcs !+
        lda #1
        rts 
        !:
        
        lda #0
        rts

codeEnd:
.print "Code block 2 size: " + (codeEnd - dataend)
.print "---"
.print "Total size: " + (codeEnd - block1start)
.print "Bytes remaining: " + (7679 - codeEnd)