CONST MODE_MOVE = 0
CONST MODE_BUILD = 1
CONST MODE_IDLE = 2

GOTO START_OF_PROGRAM

ORIGIN 4096
START_OF_PROGRAM:

INCLUDE "lib_colors.bas"
INCLUDE "lib_random.bas"
INCLUDE "lib_joy.bas"
INCLUDE "lib_scr.bas"
INCLUDE "lib_sid.bas"
INCLUDE "maze.bas"

TYPE TypeTroll
    x AS BYTE
    y AS BYTE
    xnext AS BYTE
    ynext AS BYTE
    last AS BYTE
    floor AS BYTE
    floor_color AS BYTE

    SUB clear() STATIC
        CHARAT THIS.x, THIS.y, THIS.floor, THIS.floor_color
    END SUB

    SUB move() STATIC
        DIM dirs AS BYTE: dirs = nsew(random(0, 23))
        DIM x AS BYTE: x = THIS.x
        DIM y AS BYTE: y = THIS.y
        DIM d AS BYTE

        FOR i AS BYTE = 0 TO 3
            DIM cdir AS BYTE: cdir = dirs AND %11
            dirs = SHR(dirs, 2)
            IF cdir = NORTH AND scr_charat(THIS.x, THIS.y - 1) < TILE_WALL THEN
                x = THIS.x
                y = THIS.y - 1
                d = cdir
                IF THIS.last <> SOUTH THEN EXIT FOR
            END IF
            IF cdir = SOUTH AND scr_charat(THIS.x, THIS.y + 1) < TILE_WALL THEN
                x = THIS.x
                y = THIS.y + 1
                d = cdir
                IF THIS.last <> NORTH THEN EXIT FOR
            END IF
            IF cdir = WEST AND scr_charat(THIS.x - 1, THIS.y) < TILE_WALL THEN
                x = THIS.x - 1
                y = THIS.y
                d = cdir
                IF THIS.last <> EAST THEN EXIT FOR
            END IF
            IF cdir = EAST AND scr_charat(THIS.x + 1, THIS.y) < TILE_WALL THEN
                x = THIS.x + 1
                y = THIS.y
                d = cdir
                IF THIS.last <> WEST THEN EXIT FOR
            END IF
        NEXT i

        THIS.xnext = x
        THIS.ynext = y
        THIS.last = d
    END SUB
END TYPE
DIM troll(10) AS TypeTroll

TYPE TypePlayer
    x AS BYTE
    y AS BYTE
END TYPE
DIM player AS TypePlayer
DIM build AS TypePlayer

DIM sid_info AS SidInfo
sid_info = sid_load(@SID_START, @SID_END)

CALL scr_charrom(CHARSET_GRAPHICS, 2048)
CALL scr_charmem(2048)
CALL scr_set_glyph(TILE_PLAYER, @glyph_dwarf)
CALL scr_set_glyph(TILE_TROLL, @glyph_troll)
CALL scr_set_glyph(TILE_PASSAGE, @glyph_passage)
CALL scr_set_glyph(TILE_GEM, @glyph_gem)
CALL scr_set_glyph(TILE_WALL, @glyph_wall)
CALL scr_set_glyph(TILE_BLOCK, @glyph_block)
CALL scr_set_glyph(TILE_HOURGLASS, @glyph_hourglass)
CALL scr_set_glyph(TILE_DIGGING, @glyph_picking)
CALL scr_set_glyph(TILE_BUILDING, @glyph_picking)

MENU:
CALL sid_play(sid_info.init, sid_info.play, 1)
CALL scr_color(COLOR_BLACK, COLOR_BLACK)
MEMCPY @MenuScreenCodes, 1024, 1000
MEMCPY @MenuColorCodes, $d800, 1000

CALL Joy1WaitFireDown()

REM start game
CALL sid_play(sid_info.init, sid_info.play, 0)

RANDOMIZE TI()
CALL maze_create()

REM place diamonds
DIM t AS BYTE FAST
DIM x AS BYTE
DIM y AS BYTE
DIM tile AS BYTE
DIM gems_left AS BYTE: gems_left = 0
DO
    x = rnd_loc(MAZE_WIDTH)
    y = rnd_loc(MAZE_HEIGHT)
    IF scr_charat(x, y) <> TILE_GEM THEN
        gems_left = gems_left + 1
        CHARAT x, y, TILE_GEM, gems_left 
    END IF
LOOP UNTIL gems_left = 14

REM create trolls
FOR t = 0 TO 9
    DO
        troll(t).x = rnd_loc(MAZE_WIDTH)
        troll(t).y = rnd_loc(MAZE_HEIGHT)
    LOOP WHILE troll(t).x < 8 AND troll(t).y > 18
    troll(t).xnext = troll(t).x
    troll(t).ynext = troll(t).y
    troll(t).last = 4
    troll(t).floor = scr_charat(troll(t).x, troll(t).y)
    troll(t).floor_color = scr_color_at(troll(t).x, troll(t).y)
NEXT t
FOR t = 0 TO 9
    CHARAT troll(t).x, troll(t).y, TILE_TROLL, COLOR_BROWN
NEXT t

REM place player
player.x = 1
player.y = 23
x = 1
y = 23

CHARAT x, y, TILE_PLAYER, COLOR_LIGHTGRAY

DIM CurTime AS LONG
DIM TrollTime AS LONG
    TrollTime = 0
DIM PlayerTime AS LONG
    PlayerTime = 0

DIM Rounds AS WORD
    Rounds = 0

DIM Joy1State AS BYTE
DIM Mode AS BYTE
    Mode = MODE_MOVE

DIM ZP_W0 AS WORD

'GOTO MOVE_PLAYER

GAME_LOOP:
    CurTime = TI()    

    IF Curtime > PlayerTime THEN
        PlayerTime = CurTime + 20

        Rounds = Rounds + 32
        IF rounds > $1900 THEN GOTO GAME_OVER_TIME
        FOR t = 0 TO 24
            IF t < PEEK(@Rounds+1) THEN 
                CHARAT 39, t, 32
            ELSE
                CHARAT 39, t, TILE_HOURGLASS, COLOR_BLUE
            END IF
        NEXT t

        IF scr_charat(build.x, build.y) = TILE_BUILDING THEN
            CHARAT build.x, build.y, TILE_PASSAGE
        END IF
        IF scr_charat(build.x, build.y) = TILE_DIGGING THEN
            CHARAT build.x, build.y, TILE_WALL
        END IF
    
        CALL Joy1Update()

        IF Mode = MODE_IDLE THEN
            IF Joy1FireUp() THEN
                Mode = MODE_MOVE
            ELSE
                If Joy1DirectionChange() THEN 
                    Mode = MODE_BUILD
                END IF
            END IF
        ELSE
            IF MODE = MODE_BUILD THEN
                IF Joy1FireUp() THEN
                    Mode = MODE_MOVE
                END IF
            ELSE
                IF MODE = MODE_MOVE THEN
                    IF Joy1FireDown() THEN
                        Mode = MODE_BUILD
                    END IF
                END IF
            END IF
        END IF

        x = player.x + joy1_horizontal()
        y = player.y + joy1_vertical()

        IF Mode = MODE_BUILD THEN
            IF (x = player.x) XOR (y = player.y) THEN
                tile = scr_charat(x, y)
                IF tile = TILE_WALL THEN
                    IF RNDB() < 40 THEN 
                        CHARAT x, y, TILE_PASSAGE
                        Mode = MODE_IDLE
                    ELSE
                        build.x = x
                        build.y = y
                        CHARAT x, y, TILE_DIGGING
                    END IF
                END IF
                IF tile = TILE_PASSAGE THEN
                    IF RNDB() < 40 THEN 
                        CHARAT x, y, TILE_WALL
                        Mode = MODE_IDLE
                    ELSE
                        build.x = x
                        build.y = y
                        CHARAT x, y, TILE_BUILDING
                    END IF
                END IF
            END IF
        ELSE
            IF Mode = MODE_MOVE THEN
                IF x <> player.x THEN
                    y = player.y
                END IF
                IF y <> player.y THEN
                    x = player.x
                END IF
                IF x <> player.x OR y <> player.y THEN
                    tile = scr_charat(x, y)
                    IF tile = TILE_WALL OR tile = TILE_BLOCK THEN GOTO MOVE_TROLLS
                    CHARAT player.x, player.y, TILE_PASSAGE, COLOR_DARKGRAY
                    CHARAT x, y, TILE_PLAYER, COLOR_LIGHTGRAY
                    player.x = x
                    player.y = y

                    IF tile = TILE_TROLL THEN GOTO GAME_OVER_TROLL
                    IF tile = TILE_GEM THEN 
                        gems_left = gems_left - 1
                        IF Rounds < $0180 THEN
                            Rounds = 0
                        ELSE
                            Rounds = Rounds - $0180
                        END IF

                        IF gems_left = 0 THEN GOTO YOU_WIN
                    END IF
                END IF
            END IF
        END IF
    END IF

MOVE_TROLLS:
    IF Curtime > TrollTime THEN
        TrollTime = CurTime + 20

        FOR t = 0 TO 9
            CALL troll(t).move()
        NEXT t
        FOR t = 0 TO 9
            CHARAT troll(t).x, troll(t).y, troll(t).floor, troll(t).floor_color
        NEXT t
        FOR t = 0 TO 9
            troll(t).floor = scr_charat(troll(t).xnext, troll(t).ynext)
            troll(t).floor_color = scr_color_at(troll(t).xnext, troll(t).ynext)
        NEXT t
        FOR t = 0 TO 9
            CHARAT troll(t).xnext, troll(t).ynext, TILE_TROLL, COLOR_BROWN
        NEXT t
        FOR t = 0 TO 9
            troll(t).x = troll(t).xnext
            troll(t).y = troll(t).ynext
            IF troll(t).floor = TILE_PLAYER THEN GOTO GAME_OVER_TROLL
        NEXT t
    END IF
    GOTO GAME_LOOP

GAME_OVER_TIME:
    CALL scr_clear()
    CALL scr_centre(8, "time run out")
    CALL scr_centre(12, "game over")
    CALL Joy1WaitFireDown()
    GOTO MENU

GAME_OVER_TROLL:
    CALL scr_clear()
    CALL scr_centre(8,  "troll ate you")
    CALL scr_centre(12, "game over")
    CALL Joy1WaitFireDown()
    GOTO MENU

YOU_WIN:
    CALL scr_clear()
    CALL scr_centre(10, "you win!!!")
    CALL Joy1WaitFireDown()
    GOTO MENU

glyph_dwarf:
DATA AS BYTE %11100000
DATA AS BYTE %11101010
DATA AS BYTE %01001110
DATA AS BYTE %01011111
DATA AS BYTE %01111111
DATA AS BYTE %01001111
DATA AS BYTE %00001010
DATA AS BYTE %00001010

glyph_troll:
DATA AS BYTE %00111100
DATA AS BYTE %01011010
DATA AS BYTE %00111100
DATA AS BYTE %01111110
DATA AS BYTE %10111101
DATA AS BYTE %10100101
DATA AS BYTE %00100100
DATA AS BYTE %01100110

glyph_passage:
DATA AS BYTE %00000000
DATA AS BYTE %00000000
DATA AS BYTE %00000000
DATA AS BYTE %00000000
DATA AS BYTE %00000000
DATA AS BYTE %00000000
DATA AS BYTE %00000000
DATA AS BYTE %00000000

glyph_wall:
DATA AS BYTE %00000000
DATA AS BYTE %10111101
DATA AS BYTE %00000000
DATA AS BYTE %11111101
DATA AS BYTE %00000000
DATA AS BYTE %11011111
DATA AS BYTE %11011111
DATA AS BYTE %00000000

glyph_gem:
DATA AS BYTE %00000000
DATA AS BYTE %00010000
DATA AS BYTE %00111000
DATA AS BYTE %01111100
DATA AS BYTE %00111000
DATA AS BYTE %00010000
DATA AS BYTE %00000000
DATA AS BYTE %00000000

glyph_block:
DATA AS BYTE %00000000
DATA AS BYTE %01111110
DATA AS BYTE %01111110
DATA AS BYTE %01111110
DATA AS BYTE %01111110
DATA AS BYTE %01111110
DATA AS BYTE %01111110
DATA AS BYTE %00000000

glyph_hourglass:
DATA AS BYTE %01000010
DATA AS BYTE %01111110
DATA AS BYTE %01111110
DATA AS BYTE %00111100
DATA AS BYTE %00011000
DATA AS BYTE %00111100
DATA AS BYTE %01111110
DATA AS BYTE %01111110

glyph_picking:
DATA AS BYTE %00000000
DATA AS BYTE %01000010
DATA AS BYTE %00100100
DATA AS BYTE %00011000
DATA AS BYTE %00011000
DATA AS BYTE %00100100
DATA AS BYTE %01000010
DATA AS BYTE %00000000

MenuScreenCodes:
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$55,$43,$43,$43,$43,$43,$43,$43,$43,$49,$20,$20,$20,$20,$20,$20,$20,$20,$20,$6F,$62,$6F,$20,$20,$20,$20,$20,$6F,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$55,$43,$4B,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$4A,$43,$43,$49,$20,$20,$20,$20,$20,$E9,$A0,$A0,$A0,$DF,$20,$20,$E9,$A0,$A0,$A0,$DF,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$5D,$E6,$04,$E6,$17,$E6,$01,$E6,$12,$E6,$06,$E6,$E6,$E6,$5D,$20,$20,$20,$20,$20,$A0,$69,$A0,$5F,$A0,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$5D,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$5D,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$20,$20,$20,$A0,$57,$A0,$57,$A0,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$5D,$E6,$E6,$0D,$E6,$09,$E6,$0E,$E6,$05,$E6,$12,$E6,$E6,$5D,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$20,$20,$6F,$A0,$4A,$43,$4B,$A0,$6F,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$4A,$49,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$5D,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$E9,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$DF,$20,$20,$20
DATA AS BYTE $20,$20,$20,$42,$E6,$E6,$E6,$E6,$55,$43,$43,$43,$43,$43,$43,$43,$4B,$20,$20,$20,$20,$20,$20,$20,$FF,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20
DATA AS BYTE $20,$20,$20,$4A,$43,$43,$43,$43,$4B,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$FF,$A0,$A0,$69,$20,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$20,$20,$20,$A0,$A0,$20,$A0,$A0,$20,$FF,$69,$20,$20,$20
DATA AS BYTE $20,$20,$03,$0F,$0C,$0C,$05,$03,$14,$20,$04,$09,$01,$0D,$0F,$0E,$04,$13,$20,$20,$20,$20,$20,$20,$A0,$20,$20,$20,$E9,$A0,$A0,$20,$A0,$A0,$DF,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$02,$05,$06,$0F,$12,$05,$20,$14,$09,$0D,$05,$20,$12,$15,$0E,$13,$20,$0F,$15,$14,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E9,$DF,$20,$20,$20
DATA AS BYTE $20,$20,$02,$05,$17,$01,$12,$05,$20,$14,$08,$05,$20,$14,$12,$0F,$0C,$0C,$13,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E9,$CE,$CD,$DF,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E9,$CE,$CE,$CD,$CD,$DF,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$D6,$D6,$D6,$D6,$D6,$D6,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5F,$CD,$CD,$CE,$CE,$69,$20
DATA AS BYTE $20,$20,$0A,$0F,$19,$13,$14,$09,$03,$0B,$20,$31,$20,$14,$0F,$20,$0D,$0F,$16,$05,$2C,$20,$06,$09,$12,$05,$20,$14,$0F,$20,$20,$20,$20,$20,$5F,$CD,$CE,$69,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$02,$15,$09,$0C,$04,$20,$01,$0E,$04,$20,$04,$09,$07,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5F,$69,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$06,$09,$12,$05,$20,$14,$0F,$20,$13,$14,$01,$12,$14,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
DATA AS BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
MenuColorCodes:
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0B,$09,$0B,$0E,$0E,$0E,$0E,$0E,$0B,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0B,$0B,$0B,$0B,$0B,$0E,$0E,$0B,$0B,$0B,$0B,$0B,$0E,$0E,$0E,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$09,$09,$0C,$09,$0C,$09,$0C,$09,$0C,$09,$0C,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$02,$0B,$09,$0B,$0B,$0E,$0E,$0B,$0B,$0B,$0B,$0B,$0E,$0E,$0E,$0E,$01,$0E
DATA AS BYTE $0E,$0E,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$09,$0E,$0E,$0E,$0E,$0B,$08,$0B,$08,$0B,$0E,$0E,$0E,$01,$01,$01
DATA AS BYTE $01,$0E,$09,$09,$09,$0B,$09,$0B,$09,$0B,$09,$0B,$09,$0B,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$09,$0E,$0E,$0E,$0B,$0B,$0C,$0C,$0C,$0B,$0B,$0E,$0E,$01,$01,$01
DATA AS BYTE $01,$0E,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$09,$0E,$0B,$0B,$0B,$0B,$0C,$0C,$0C,$0B,$0B,$0B,$0B,$01,$01,$01
DATA AS BYTE $01,$0E,$01,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0C,$0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C,$0B,$0B,$0B,$0B,$01,$01,$01
DATA AS BYTE $01,$01,$01,$09,$09,$09,$09,$09,$09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0C,$0B,$0B,$0B,$0E,$0B,$0B,$0C,$0B,$0B,$0F,$0B,$0B,$0E,$01,$0E
DATA AS BYTE $01,$01,$01,$01,$01,$01,$01,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$09,$0F,$0E,$0E,$0E,$0B,$0B,$0B,$0B,$0B,$0E,$0B,$0B,$0E,$01,$0E
DATA AS BYTE $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$09,$0E,$0E,$0E,$0E,$0B,$0B,$0E,$0B,$0B,$0E,$0C,$0C,$01,$01,$01
DATA AS BYTE $01,$01,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$01,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0E,$0E,$0E,$0E,$0E,$0E,$09,$0E,$0E,$0E,$0B,$0B,$0B,$0E,$0B,$0B,$0B,$0E,$0E,$01,$01,$01
DATA AS BYTE $0E,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$01,$01,$01,$01
DATA AS BYTE $0E,$0E,$01,$0C,$0C,$0C,$0C,$0C,$0C,$01,$0C,$0C,$0C,$0C,$01,$0C,$0C,$0C,$0C,$01,$0C,$0C,$0C,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$01,$0E
DATA AS BYTE $0E,$0E,$01,$01,$01,$01,$01,$01,$01,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$0E,$0F,$0E
DATA AS BYTE $0E,$0E,$0C,$0C,$0C,$0C,$0C,$0C,$01,$0C,$0C,$0C,$01,$0C,$0C,$0C,$0C,$0C,$0C,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$07,$07,$0E,$0E
DATA AS BYTE $0E,$0E,$01,$0E,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$07,$07,$07,$07,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$07,$07,$07,$07,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$07,$07,$07,$07,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$01,$0E,$01,$0E,$0E,$01,$0E,$0E,$0E,$0E,$0E,$01,$0E,$0E,$0E,$0E,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$07,$07,$0E,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$01,$01,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$01,$0E,$0E,$0E,$01,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$07,$07,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F,$01,$0F,$0F,$01,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$0E,$0E,$0E,$0E,$0E,$0E
DATA AS BYTE $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E


SID_START:
INCBIN "Castle_of_Life.sid"
SID_END:
END
