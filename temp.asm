.SEGMENT "CODE"
	.org 	$1d80

RASTER_REG=$9004
NTSC_SCR_Y=118

	_vwait:
		lda RASTER_REG 
		cmp #NTSC_SCR_Y 
		bcc _vwait			; wait for raster line 118
	VBLANK:
		rts 				; back to basic 

; end of available memory
	.org 	$1dff
	.byte 	0
