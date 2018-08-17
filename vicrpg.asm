//////////////////////////////////////////
//////////////////////////////////////////
//
//  Untitled VIC-20 RPG thing
//
// (c) 2018 Ben Ferguson
//////////////////////////////////////////
//////////////////////////////////////////

/////////////////////////////////////////
// Const Def Block
.var mapWidth=64
.var mapHeight=64
.var drawWidth=11
.var drawHeight=11

/////////////////////////////////////


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
        lda #%00001001
        sta $900f //border black, reverse off, bg white
        lda #%01101111 //pink aux color, volume on
        sta $900e
        //setup subroutines
        //jsr PrintText
        jsr DrawMap
        //jsr DrawHero

        jmp !loop+

////////////////////////////////
//; Variable defs block:
    playerX: .byte $05
    playerY: .byte $05
    testString: .text "Test"

//*=$1238 "Code block 2"
    !loop:   
        jsr CheckInput
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
        
        //COLOR INFORMATION:
        //0000x000 = multicolor on for this tile
        //00000xxx = 3bit color value- corresponds to
        //COLOR 0 - background color
        //COLOR 1 - auxiliary color
        //COLOR 2 - border color
        //COLOR 3 - character color
        
DrawHero:
    //draws and colors at center tile
        lda #98
        sta $1002+88+88+8+44
        lda #99
        sta $1003+88+88+8+44
        lda #114
        sta $1002+22+88+88+8+44
        lda #115
        sta $1002+23+88+88+8+44
        lda #%00000011 //cyan
        sta $9403+88+88+8+44
        sta $9403+22+88+88+8+44
        lda #%00000110 //blue
        sta $9402+88+88+8+44
        sta $9402+22+88+88+8+44
    rts


////////////////////////////////////
// Map Draw Routine

mapOffset: .byte $00,$00 //$402 = 1026/2500
mapdrawOffset: .byte $00,$00
maphelper1: .byte $00
maphelper2: .byte $00

DrawMap:
    //mapoffset is # of tiles (bytes) away from start of TileMap to start draw routine
    //$fd-$fe should contain #<TileMap + mapOffset and #>TileMap + mapOffset+1
    //then lda ($fd),y 
    //then ldy maphelper2
        lda mapOffset+1
        clc
        adc #>TileMap
        sta mapdrawOffset+1
        lda mapOffset
        clc
        adc #<TileMap
        bcc !+
        inc mapdrawOffset+1
        !:sta mapdrawOffset
        
    !:  ldy #0
        ldx maphelper1
        cpx #drawWidth //drawWidth
        bcs !yloop+
        lda mapdrawOffset+1
        //lda #>TileMap
        sta $fe
        //lda #<TileMap
        lda mapdrawOffset
        sta $fd
        lda ($fd),y
        ldy maphelper2
        jsr DrawTile_AXY
        inc maphelper1
        inc mapdrawOffset
        bne !next+
        inc mapdrawOffset+1
        !next:
        jmp !-
        !yloop: 
        inc maphelper2
        ldx maphelper2
        cpx #drawHeight //drawHeight //its broken here somewhere
        bcs !end+
        //new row...
        ldx #0
        stx maphelper1
        .eval var widthsize = mapWidth-(drawWidth)
        lda #widthsize //mapWidth - drawWidth
        clc
        adc mapdrawOffset
        bcc !next+
        inc mapdrawOffset+1
        !next:
        sta mapdrawOffset
        jmp !-
    !end:
    lda #0
    sta maphelper1
    sta maphelper2
    jmp DrawHero

DrawTile_AXY:
    //take number 1-40 in A, 1-11 in X, 1-11 in Y
    //add 95 to A, draw that char at (Y*2*22)+(X*2)+$1000
    //color via color chart from input A at (Y*2*22)+(X*2)+$9400
    sta $fe
    stx $fb
    asl $fb 
    lda #$10
    sta $fd

    cpy #1
    bcs !+
    lda $fb
    sta $fc
    jmp !skipmath+
!:
    //fd has hb- fc should have low bit when done
    //y has iterating #
    lda $fb
    sta $fc
    !keepadding:
    lda $fc
    clc
    adc #44
    bcc !+
    inc $fd
    !:sta $fc
    dey
    bne !keepadding-
    !skipmath:
    //get color, store in fb
    lda $fe //A input
    
    //If loading tile numbers directly:
    //tax
    //dex
    //
    
    //If loading charpad tile nums:
    sec
    sbc #96 
    tax
    //
    lda ColorChart,x
    sta $fb
//Draw characters to screen:
    ldy #0
    ldx $fe
    //Loading tile nums directly?
    //txa 
    //clc
    //adc #95
    //

    //loading charpad tile nums?
    txa
    clc
    //
    sta ($fc),y
    adc #1
    iny 
    sta ($fc),y
    clc
    adc #15
    tax
    tya
    adc #21
    tay
    txa
    sta ($fc),y
    tax
    inx
    txa
    iny
    sta ($fc),y
//Colorize:
    //add $84 to fd
    ldy #0
    lda $fd
    clc
    adc #$84
    sta $fd
    lda $fb
    sta ($fc),y
    iny
    sta ($fc),y
    tax
    tya
    adc #21
    tay
    txa
    sta ($fc),y
    iny
    sta ($fc),y
rts

*=$3000 "Code block 2"

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
        //'2' pressed - right
        lda playerX
        .eval var mapsizer = mapWidth-(drawWidth+1)+6
        cmp #mapsizer
        bcs !+
        inc playerX
        inc mapOffset
        bne !skip+
        inc mapOffset+1
        !skip:
        jsr DrawMap
        jmp !end+
        //
        !:
        cmp #253
        bcc !+
        cmp #253+1
        bcs !+
        //'4' pressed
        lda playerX
        cmp #6
        bcc !end+
        dec playerX
        dec mapOffset 
        !skip:
        jsr DrawMap
        jmp !end+
        !:
        lda #223
        sta $9120
        lda $9121
        cmp #253
        bcc !+
        cmp #253+1
        bcs !+
        //'6' pressed
        lda playerY
        cmp #mapHeight-6
        bcs !+
        inc playerY
        lda mapOffset
        clc
        adc #mapWidth
        bcc !skip+
        inc mapOffset+1
        !skip:
        sta mapOffset
        jsr DrawMap
        jmp !end+
        !:
        lda #253
        sta $9120
        lda $9121
        cmp #253
        bcc !+
        cmp #253+1
        bcs !+
        //lda mapOffset+1
        //cmp #1
        //bcc !+
        //'8' pressed
        lda playerY
        cmp #6
        bcc !end+
        dec playerY
        lda mapOffset
        sec
        sbc #mapWidth
        bcs !skip+
        dec mapOffset+1
        !skip:
        sta mapOffset
        jsr DrawMap
        jmp !end+
        !:
    !end:
    rts


*=$1400 "Charset"
    .import binary "chars.raw"

*=$1c00 "Tile map data"
ColorChart:
//40 bytes for tilemap
//TODO FIXME
.byte $05,$00,$06,$00,$06,$00
TileMap: 
    .import binary "map.raw"
