; Blank GB base file
; Luigi Guatieri
; superluigiland.net
; based on David Pello's tutorial

; hardware definitions
INCLUDE "gbhw.inc"

;user data
;**********************************************************************

;Constants
;**********************************************************************

;Directions for BG loadings
_EAST		EQU		%00000001
_WEST		EQU		%00000010

; Bitflags for dpad directions
_PAD_RIGHT		EQU		%00010000
_PAD_LEFT		EQU		%00100000
_PAD_UP			EQU		%01000000
_PAD_DOWN		EQU		%10000000

_PLAYER_ANIM_SPEED	EQU		5

; define sprites and attributes

; EXAMPLE:
;_SPR0_Y	EQU			_OAMRAM   ; store sprite 0, first object attribute memory ram location
;					              ; 1st byte is y location
;_SPR0_X	EQU			_OAMRAM+1
;_SPR0_NUM	EQU			_OAMRAM+2	; tile number stored here
;_SPR0_ATT	EQU			_OAMRAM+3	; byte for sprite atttributes

; More OAM data for sprites goes here

_SPR0_Y		EQU			_OAMRAM		; Y Coord
_SPR0_X		EQU			_OAMRAM+1	; X Coord
_SPR0_NUM	EQU			_OAMRAM+2	; Tile number
_SPR0_ATT	EQU			_OAMRAM+3	; Attribute flags

_SPR1_Y		EQU			_OAMRAM+4	; Y Coord
_SPR1_X		EQU			_OAMRAM+5	; X Coord
_SPR1_NUM	EQU			_OAMRAM+6	; Tile number
_SPR1_ATT	EQU			_OAMRAM+7	; Attribute flags

_SPR2_Y		EQU			_OAMRAM+8	; Y Coord
_SPR2_X		EQU			_OAMRAM+9	; X Coord
_SPR2_NUM	EQU			_OAMRAM+10	; Tile number
_SPR2_ATT	EQU			_OAMRAM+11	; Attribute flags


;Variables
;**********************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;BLOCK 0 is mostly for global data like buttons and world state
_RAM_BLOCK_0	EQU		_RAM					;RAM is 8K without bank switching

padInput		EQU		_RAM_BLOCK_0			;The input from the d-pad and buttons
currentWorld	EQU		_RAM_BLOCK_0+1			;Which world are we in
currentLevel	EQU		_RAM_BLOCK_0+2			;Which level are we on

backgroundDrawDirection	EQU		_RAM_BLOCK_0+3			;Which direction of the background do we draw, 1 = east, 2 = west
backgroundLightOffset	EQU		_RAM_BLOCK_0+4			;how far to the right (in tiles) is our leftmost Light bg tile in data
backgroundDarkOffset	EQU		_RAM_BLOCK_0+5			;how far to the right (in tiles) is our leftmost Dark bg tile in data
backgroundLightVramEast	EQU		_RAM_BLOCK_0+6			;where are we writing our next east tile 0-31
backgroundLightVramWest	EQU		_RAM_BLOCK_0+7			;where are we writing our next west tile 0-31
backgroundDarkVramEast	EQU		_RAM_BLOCK_0+8			;where are we writing our next east tile 0-31
backgroundDarkVramWest	EQU		_RAM_BLOCK_0+9			;where are we writing our next west tile 0-31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;BLOCK 1 is mostly for player data, including direction, animation states, sprite tile, etc.
_RAM_BLOCK_1			EQU	_RAM_BLOCK_0+128

playerLightXFrame		EQU _RAM_BLOCK_1		; player x coordinate (page in world)
playerLightXPixel		EQU _RAM_BLOCK_1+1		; player x coordinate (relative to page)
playerLightYFrame		EQU _RAM_BLOCK_1+2		; player y coordinate (page in world)
playerLightYPixel		EQU _RAM_BLOCK_1+3		; player y coordinate (relative to page)
playerLightFrame		EQU _RAM_BLOCK_1+4		; what frame of the animation
playerLightDirection 	EQU _RAM_BLOCK_1+5		; bit 0 = up/down, up = 1;  bit 1 = left/right, left = 1
playerLightSpriteNumber	EQU	_RAM_BLOCK_1+6		; which sprite number is used to render the player

; reserved for future player data

playerDarkXFrame		EQU _RAM_BLOCK_1+16		; player x coordinate (page in world)
playerDarkXPixel		EQU _RAM_BLOCK_1+17		; player x coordinate (relative to page)
playerDarkYFrame		EQU _RAM_BLOCK_1+18		; player y coordinate (page in world)
playerDarkYPixel		EQU _RAM_BLOCK_1+19		; player y coordinate (relative to page)
playerDarkFrame			EQU _RAM_BLOCK_1+20		; what frame of the animation
playerDarkDirection 	EQU _RAM_BLOCK_1+21		; bit 0 = up/down, up = 1;  bit 1 = left/right, left = 1
playerDarkSpriteNumber	EQU	_RAM_BLOCK_1+22		; which sprite number is used to render the player

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_RAM_BLOCK_2 EQU	_RAM_BLOCK_1+128

startScreenToggle	EQU	_RAM_BLOCK_2+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_RAM_BLOCK_3 EQU	_RAM_BLOCK_2+128
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_RAM_BLOCK_4 EQU	_RAM_BLOCK_3+128
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_RAM_BLOCK_5 EQU	_RAM_BLOCK_4+128
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_RAM_BLOCK_6 EQU	_RAM_BLOCK_5+128
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_RAM_BLOCK_7 EQU	_RAM_BLOCK_6+128
soundToggle EQU _RAM_BLOCK_7
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;CARTRIDGE HEADER
;**********************************************************************
; Program Begins
SECTION "start",HOME[$0100] ; location to begin memory (< $0100 is saved for interupts)
							; HOME is memory bank 0 
	nop	; no operation
	jp	start
	
; ROM Header (Macro defined in gbhw.inc)
; defines ROM without mapper, 32K without RAM, the basics
;(like Tetris)
	ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

; Our program begins
start:
	nop
	di				; disable interupts
	ld	sp, $ffff	; load stack pointer into highest ram location
	

; initialization
; load pallets for sprites, windows and backgrounds here
; load map location and scroll variables
; remember to stop LCD before copying tiles to memory
.Init:
	; pallet data

	; palletes
	ld	a, %11100100
	;ld	a, %11100100	; pallete colors, darkest to lightest
	ld	[rBGP], a		; load colors into contents of pallete register
	ld	[rOBP0], a		; load contents of pallete into sprite pallete
	
	; create another pallete for other sprites
	;ld	a, %11010000	; for Mario
	;ld	a, %11100100
	ld	[rOBP1], a		; into location 1
	
	;scroll variables

	
	call StopLCD
	
	; copy tiles
	ld		hl, Tiles			; HL loaded with sprite data
	ld		de, _VRAM			; address for video memory into de
	ld		bc, EndTiles-Tiles	; number of bytes to copy
	call	CopyMemory
	
	; copy tile maps
	ld		hl, MAIN_MAP
	ld		de, _SCRN0		; map 0 loaction
	call	CopyTileMap


	; copy	window tile map
	ld	hl, WINDOW_START
	ld	de, _SCRN1		; map 1 location
	ld	bc, 32*32		; screen size
	call CopyMemory
	
	ld	a, 0			; load start screen toggle value
	ld	[startScreenToggle], a
	
	; sound
	ld a, 0
	ld [soundToggle], a
	
	;turn on sound
	ld	a,%10000000
	ld	[rAUDENA],a
	
	call PlaySound
	
	ld a, 0
	ld [currentWorld], a
	ld [currentLevel], a
	
	; set current background offset
	ld a, 6
	ld [backgroundLightOffset], a
	ld [backgroundDarkOffset], a
	ld a, 0
	ld [backgroundLightVramEast], a
	ld a, 31
	ld [backgroundLightVramWest], a
	
	
	; erase sprite memory
	ld		de, _OAMRAM		; Sprite attribut memory
	ld		bc, 56*4		; 40 sprites, 4 bytes each
	ld		l, 0			; put everything to zero
	call 	FillMemory		; Unused sprites remain off-screen
	
	; Position screen rect
	ld	a, 0
	ld	[rSCY], a
	ld	a, 32
	ld	[rSCX], a
	
	; Set the initial state of the player.
	ld a, 60
	ld [playerLightYPixel], a
	ld [playerLightXPixel], a
	ld a, _PLAYER_ANIM_SPEED
	ld [playerLightFrame], a
	ld a, 0
	ld [playerLightSpriteNumber], a
	
	; create player sprite
	call RenderPlayer

	ld a, [playerLightYPixel]
	ld [_SPR0_Y], a
	ld a, [playerLightXPixel]
	ld [_SPR0_X], a

	
	; configure and activate display
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00
	ld	[rLCDC], a
	
; GAMEPLAY CODE
.GameLoop
	call StartScreen
	call PlaySound
	call ReadPad
	
	;clear backgroundDraw before checking for scroll
	ld a, 0
	ld [backgroundDrawDirection], a
	
	call UsePadAB
	call Movement
	call AnimatePlayer

.wait: ; wait for VBLANK
	ld	a, [rLY]	; check scanline
	cp	145			; compare to final scanline
	jr	nz, .wait	; if not, loop again
	
; End of gameplay code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;TIME CRITICAL STUFF STARTS HERE - Edit at own risk!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
;1140 clock cycles to do all the drawing 
 
	; we are in VBlank, turn off LCD
	;ld	a, [rLCDC]	; load rLCDC in a			;4
	;res	7, a	; reset bit 7 to 0 in LCD		;2
	;ld	[rLCDC], a	; save changes				;4

; RENDERING CODE

	; Set the sprite x,y
	call RenderPlayer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;TIME CRITICAL STUFF ENDS HERE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Render the appropriate sprites
	
.RenderOthers:

	;NOTE: Currently only draws the light world (for simplicity)
	
	;Check if we need to draw a new bg tile
	ld a, [backgroundDrawDirection]
	cp 0
	jr z, .DoneBg
	
	;store the counter to the stack
	ld a, 16
	push af
	
	;load the background map into bc
	ld bc, MAIN_MAP
	
	;offset the index into Bg source if we are in dark world
	ld a, [currentWorld]
	jr nz, .DrawBg
	
	ld a, b			;1 ;dark world offset
	add 16			;2
	ld b, a			;1
	
.DrawBg:
	ld de, _SCRN0
	ld h, 0
	;check which direction we are drawing
	ld a, [backgroundDrawDirection]
	cp _EAST
	jr z, .DrawEast
.DrawWests:
	;get the destination in vram
	ld a, [backgroundLightVramWest]
	ld l, a
	add hl,de
	;set the low index to offset-6
	ld a, [backgroundLightOffset]
	sub 6
	ld c, a
	xor a
	jr z, .CopyBgLine
.DrawEast:
	;get the destination in vram
	ld a, [backgroundLightVramEast]
	ld l, a
	add hl,de
	;set the high index to offset+20+6
	ld a, [backgroundLightOffset]
	add a,26
	add a,c
	ld c, a
	
	;bc is now the correct source of our ROM data
	;hl is the correct destination of our VRAM
.CopyBgLine:
	;DE = 32, so we can iterate our background output targets
	ld d, 0
	ld e, 32
.NextBgLine	
	ld a, [bc]
	ld [hl], a
	add hl, de		;add 32 to the RAM destination
	inc b			;increment the ROM source
	
	pop af
	dec a
	jr z, .DoneBg
	push af
	jr nz, .NextBgLine
	
.DoneBg

	; a small delay
	ld		bc, 2000
	call	Delay

	jr .GameLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subroutines here:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RenderPlayer:
	ld a, [playerLightYPixel]
	ld [_SPR0_Y], a
	ld a, [playerLightXPixel]
	ld [_SPR0_X], a

	ld 		a, [playerLightDirection] ; has bit 1 set for left/right.  1 is left 
	and		%00000001	; mask out the y-direction bit
	sla		a
	ld		b, a

	ld 		a, [playerLightSpriteNumber]
	add 	a, b
	ld 		[_SPR0_NUM], a

	; byte 3 bit 5 for x-swap
	ld 		a, [playerLightDirection] ; has bit 1 set for left/right.  1 is left 
	and		%00000010	; mask out the x-direction bit
	swap	a			; swap nibbles (puts the x direction value in the x-flip attribute bit location)
	or		16			; additional flags
	ld [_SPR0_ATT], a	; set the attributes

	; Reset the up/down flag so the player doesn't stay facing up
	ld		a, [playerLightDirection]
	and		%11111110	; Clear the up bit		
	ld		[playerLightDirection], a


	ret

AnimatePlayer:
	; If we have no input, just set it to the start sprite
	ld	a, [padInput]
	cp 0
	jr z, .reset_anim

	ld	a, [playerLightFrame]	; load anim speed var into a
	dec	a						; decrement
	ld	[playerLightFrame], a	; save value
	cp	0						; is it 0 yet?
	ret	nz						; if it is not, return (this is the delay)

	ld	a, _PLAYER_ANIM_SPEED	; reset when 0
	ld	[playerLightFrame], a	; save original value
	
	; change the sprite
	ld	a, [playerLightSpriteNumber]	; load tile number
	inc	a	; increment
	ld	[playerLightSpriteNumber], a	; save tile number
	cp	2	; check to see if it's over
	ret	nz	; if not, return
	
.reset_anim
	ld	a, _PLAYER_ANIM_SPEED	; reset when 0
	ld	[playerLightFrame], a	; save original value

	ld	a, 0	; retart aniamtion loop
	ld	[playerLightSpriteNumber], a	; save sprite
	ret

Movement:
	ld		a, [padInput]	; load status of pad
	ld		b, a			; Save in b so we can reset easily

	and		_PAD_RIGHT
	call	nz, MoveRight
	
	ld		a, b
	and		_PAD_LEFT
	call	nz, MoveLeft
	
	ld		a, b
	and		_PAD_UP
	call	nz, MoveUp
	
	ld		a, b
	and		_PAD_DOWN
	call	nz, MoveDown
	ret

MoveLeft:
	; TODO Move the screen to keep the player visible
	ld a, [playerLightXPixel]
	dec a
	ld [playerLightXPixel], a

	; Set the direction flag bit
	ld		a, [playerLightDirection]
	or		%00000010
	ld		[playerLightDirection], a

	ret

MoveRight:
	; TODO Move the screen to keep the player visible
	ld		a, [playerLightXPixel]
	inc		a
	ld		[playerLightXPixel], a

	ld		a, [playerLightDirection]
	and		%11111101
	ld		[playerLightDirection], a

	ret

MoveUp:
	; TODO Move the screen to keep the player visible
	ld a, [playerLightYPixel]
	dec a
	ld [playerLightYPixel], a

	ld		a, [playerLightDirection]
	or		%00000001
	ld		[playerLightDirection], a

	ret

MoveDown:
	; TODO Move the screen to keep the player visible
	ld a, [playerLightYPixel]
	inc a
	ld [playerLightYPixel], a

	ld		a, [playerLightDirection]
	and		%11111110
	ld		[playerLightDirection], a

	ret

; read input pad and store the state into [padInput]
ReadPad:
	; check the d-pad
	ld	a, %00100000	; bit 4 to 0, 5 to 1 (Activate d-pad, not buttons)
	ld	[rP1], a	; button register
	
	; now we read the state of the d-pad, and avoid bouncing
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	
	and	$0F	; only care about the lower 4 bits
	swap	a	; lower and upper combined
	ld	b, a	; save state in b
	
	; check buttons
	ld	a, %00010000	; bit 4 to 1, 5 to 0 (activated buttons, no d-pad)
	ld	[rP1], a
	
	; read several times to avoid bouncing
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	ld	a, [rP1]
	
	; check A against buttons
	and $0F	; only care about bottom 4 bits
	or b	; or with b to 'meter' the d-pad status
	
	; now we have in A the state of all buttons, compliment and store variable
	cpl
	ld	[padInput], a
	ret

StartScreen:
	ld	a, [startScreenToggle]
	cp	0
	ret nz
	
	ld	a, 8
	ld	[rWX], a	; window x location
	
	ld	a, 0
	ld	[rWY], a	; window y location
	
	; activate windows and deactivate sprites
	ld	a, [rLCDC]	; load LCD control contents
	or	LCDCF_WINON	; check if window is on
	res	1, a	; bit 1 to 0
	ld	[rLCDC], a
	
.CheckExit
	call ReadPad
	and	%00001000	; start button
	jr	z, .CheckExit
	
.CloseWindow
	; turn off start screen toggle
	ld	a, 5
	ld	[startScreenToggle], a
	
	; deactivate the window and activate the sprites
	ld	a, [rLCDC]
	res	5, a	; reset window sprites to 0
	or	LCDCF_OBJON	; turn on objects
	ld	[rLCDC], a	; apply changes
	ret
	
	
; Uses Pad values to call functions
UsePadAB:
	ld	a, [padInput]	; load status of pad
	and	%0000010	; A button
	call	nz, MoveA ; if pressed, call routine move right
	;call	nz, LoadRight
	
	ld	a, [padInput]
	and	%00000001	; B button 
	call	nz, MoveB ; ; if pressed, call routine move left
	;call	nz, LoadLeft
	
	ret

LoadRight:
	ld	a, [rSCX]	; load a with x scroll value
	inc a	; increment a
	ld	[rSCX], a
	and	%00000111	; check if divisible by 8
	jp z, .IncBgLight
	ret

; increment background light vram east and west
.IncBgLight:
	ld	a, [backgroundLightVramEast]
	inc	a
	ld	[backgroundDarkVramEast], a
	
	ld	a,	[backgroundDarkVramWest]
	inc	a
	ld	[backgroundDarkVramWest], a
	
	ld a, 1
	ld [backgroundDrawDirection], a
	
	ret

LoadLeft:
	ld	a, [rSCX]	; load a with screen x scroll
	dec	a	; decrement a
	ld	[rSCX], a
	and	%00000111	; check if divisible by 8
	jp z, .DecBgLight
	ret	
	
; decrement background light vram east and west
.DecBgLight:
	ld	a, [backgroundLightVramEast]
	dec	a
	ld	[backgroundDarkVramEast], a
	
	ld	a,	[backgroundDarkVramWest]
	dec	a
	ld	[backgroundDarkVramWest], a
	
	ld a, 2
	ld [backgroundDrawDirection], a
	ret	
	
MoveA:	
	; move screen to bottom of map
	ld	a, 128
	ld	[rSCY], a	; set scroll y value to 145
	
	
	; flip palettes
	; palletes
	ld	a, %00011011	; pallete colors, darkest to lightest
	ld	[rBGP], a		; load colors into contents of pallete register
	ld	[rOBP0], a		; load contents of pallete into sprite pallete
	
	; create another pallete for other sprites
	ld	a, %00011011	; for Player
	ld	[rOBP1], a		; into location 1
	
	ret 
	
MoveB:
	; move screen to top of map
	ld	a, 0
	ld	[rSCY], a	; set scroll y value to 145
	
	; flip palettes
	; palletes
	ld	a, %11100100	; pallete colors, darkest to lightest
	ld	[rBGP], a		; load colors into contents of pallete register
	ld	[rOBP0], a		; load contents of pallete into sprite pallete
	
	; create another pallete for other sprites
	ld	a, %11100100	; for Player
	ld	[rOBP1], a		; into location 1
	ret 

; Spin-locks until a VBLANK
; destroys a
WaitForVBlank:
	ld a, [rLY]	; get the scanline number
	cp 145		; compare to the final scanline number
	jr nz, WaitForVBlank	; if not equal, loop again

; Turn off the LCD
; destroys a
StopLCD:
	ld	a,[rLCDC]
	rlca	; rotate high bit into the carry
	ret	nc	; the screen is already off

	call WaitForVBlank

	; we are in VBlank, turn off LCD
	ld	a, [rLCDC]	; load rLCDC in a
	res	7, a		; reset bit 7 to 0 in LCD
	ld	[rLCDC], a	; save changes

	ret

; delay routine
; spin-locks for a specified number of iterations
; bc = number of iterations
Delay:
.Slow:
	dec	bc ; decrement the iteration count

	; Check if bc is zero
	ld	a, b
	or	c
	jr	z, .EndDelay ; if so, we're done.

	nop
	jr	.Slow

.EndDelay:
	ret

PlaySound:
    ld a, [rAUDENA]
    and %00000010
;    jr nz, .EndSoundLoop
;    ld a, [soundToggle]
;    cp 0
;    jr z, .Rest
    
.Sound
	ld a, 0
    ld [soundToggle], a
	
    ld a, %10000000
    ld [rAUD2LEN], a
	
    ld a, %11110111
    ld [rAUD2ENV], a
	
    ld a, %00011110
    ld [rAUD2LOW], a
	
    ld a, %10000110
    ld [rAUD2HIGH], a
    xor a
    jr z, .EndSoundLoop
.Rest:
	ld a, 1
    ld [soundToggle], a
    ld a, %10000000
    ld [rAUD2LEN], a
    ld a, %01101010
    ld [rAUD2ENV], a
    ld a, %00001010
.EndSoundLoop
	ret

; memory copy routine
; copy number of bytes from one directory to another
; expects parameters:
; hl: source address
; de: destination address
; bc: number of bytes to copy
; destroys contents of about
CopyMemory:
	ld	a, [hl]	; load data to be copied in a
	ld	[de], a	; load copied to data to new address
	dec	bc	; moving to next copy

	; check if bc is zero
	ld	a, c
	or	b
	ret	z ; if zero, return

	; no? continue
	inc hl ; Move the source pointer
	inc de ; Move the destination pointer
	jr CopyMemory ; loop

; hl: source address
; de: destination address
CopyTileMap:
	ld	b, 32 ; number of lines to copy

.copy_bg_row
	; Do we have more lines to copy?
	ld		a, b
	add 	a, 0
	ret 	z ; if zero, return

	; decrement the line count and save in b
	sub 	1
	ld 		b, a
	push 	bc

	; copy a line
	ld		bc, 32
	call 	CopyMemory

	; add offset to the src pointer
	ld		bc, 96
	add		hl, bc

	pop 	bc
	inc hl
	inc de
	jr 		.copy_bg_row ; loop

; fill memory routine
; fill a number of bytes of memory with data
; expects the parameters:
; de: destination address
; bc: number of bytes to fill
; l: data to fill
FillMemory:
	ld	a, 1
	ld	[de], a	; write data to destination
	dec	bc ; decrement byte count
	
	; check if bc is zero
	ld a, c
	or b
	ret	z ; return if zero

	inc	de ; select the next address
	jr FillMemory ; loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SPRITE FILES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Tiles:
INCLUDE "maintiles.z80"
EndTiles:

;screen size 20x17
Map:
INCLUDE"mainmap.z80"
EndMap:

;window start
WindowStart:
INCLUDE"windowstart.z80"
EndWindowStart:
