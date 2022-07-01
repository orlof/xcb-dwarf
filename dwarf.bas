GOTO START_OF_PROGRAM

ORIGIN 4096
START_OF_PROGRAM:

INCLUDE "lib_colors.bas"
INCLUDE "lib_random.bas"
INCLUDE "lib_joy.bas"
INCLUDE "lib_scr.bas"
INCLUDE "lib_sid.bas"

CONST MAZE_WIDTH = 39
CONST MAZE_HEIGHT = 25

CONST NORTH = 0
CONST EAST = 1
CONST WEST = 2
CONST SOUTH = 3

CONST TILE_PLAYER = 100
CONST TILE_TROLL = 101
CONST TILE_WALL = 102
CONST TILE_PASSAGE = 103
CONST TILE_GEM = 104

DIM nsew(24) AS BYTE @nsew_data

DIM x_stack(255) AS BYTE
DIM y_stack(255) AS BYTE
DIM sp AS BYTE: sp = 0

SUB push(x AS BYTE, y AS BYTE) STATIC
    IF sp = 255 THEN ERROR 100
    x_stack(sp) = x
    y_stack(sp) = y
    sp = sp + 1
END SUB

FUNCTION rnd_loc AS BYTE(size AS BYTE) STATIC
    RETURN 2 * random(0, size / 2 - 1) + 1
END FUNCTION

SUB press_fire_button() STATIC
    DO
    LOOP UNTIL NOT joy1_fire()
    DO
    LOOP UNTIL joy1_fire()
END SUB

SUB maze_create() STATIC
    MEMSET 1024, 1000, TILE_WALL
    MEMSET $D800, 1000, COLOR_LIGHTGRAY
    CALL push(rnd_loc(MAZE_WIDTH), rnd_loc(MAZE_HEIGHT))

    DO UNTIL sp = 0
        DIM x AS BYTE: x = x_stack(sp-1)
        DIM y AS BYTE: y = y_stack(sp-1)

        DIM dirs AS BYTE: dirs = nsew(random(0, 23))
        FOR i AS BYTE = 0 TO 3
            DIM cdir AS BYTE: cdir = dirs AND %11
            dirs = SHR(dirs, 2)
            IF cdir = NORTH AND y > 1 AND scr_charat(x, y-2) = TILE_WALL THEN
                CHARAT x, y-1, TILE_PASSAGE
                CHARAT x, y-2, TILE_PASSAGE
                CALL push(x, y-2)
                EXIT FOR
            END IF
            IF cdir = SOUTH AND y < MAZE_HEIGHT-2 AND scr_charat(x, y+2) = TILE_WALL THEN
                CHARAT x, y+1, TILE_PASSAGE
                CHARAT x, y+2, TILE_PASSAGE
                CALL push(x, y+2)
                EXIT FOR
            END IF
            IF cdir = EAST AND x < MAZE_WIDTH-2 AND scr_charat(x+2, y) = TILE_WALL THEN
                CHARAT x+1, y, TILE_PASSAGE
                CHARAT x+2, y, TILE_PASSAGE
                CALL push(x+2, y)
                EXIT FOR
            END IF
            IF cdir = WEST AND x > 1 AND scr_charat(x-2, y) = TILE_WALL THEN
                CHARAT x-1, y, TILE_PASSAGE
                CHARAT x-2, y, TILE_PASSAGE
                CALL push(x-2, y)
                EXIT FOR
            END IF
        NEXT i
        IF i = 4 THEN sp = sp - 1
    LOOP
END SUB

TYPE TypeTroll
    x AS BYTE
    y AS BYTE
    xnext AS BYTE
    ynext AS BYTE
    last AS BYTE
    floor AS BYTE

    SUB clear() STATIC
        CHARAT THIS.x, THIS.y, THIS.floor
    END SUB

    SUB move() STATIC
        DIM dirs AS BYTE: dirs = nsew(random(0, 23))
        DIM x AS BYTE: x = THIS.x
        DIM y AS BYTE: y = THIS.y
        DIM d AS BYTE

        FOR i AS BYTE = 0 TO 3
            DIM cdir AS BYTE: cdir = dirs AND %11
            dirs = SHR(dirs, 2)
            IF cdir = NORTH AND scr_charat(THIS.x, THIS.y - 1) <> TILE_WALL THEN
                x = THIS.x
                y = THIS.y - 1
                d = cdir
                IF THIS.last <> SOUTH THEN EXIT FOR
            END IF
            IF cdir = SOUTH AND scr_charat(THIS.x, THIS.y + 1) <> TILE_WALL THEN
                x = THIS.x
                y = THIS.y + 1
                d = cdir
                IF THIS.last <> NORTH THEN EXIT FOR
            END IF
            IF cdir = WEST AND scr_charat(THIS.x - 1, THIS.y) <> TILE_WALL THEN
                x = THIS.x - 1
                y = THIS.y
                d = cdir
                IF THIS.last <> EAST THEN EXIT FOR
            END IF
            IF cdir = EAST AND scr_charat(THIS.x + 1, THIS.y) <> TILE_WALL THEN
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

DIM sid_info AS SidInfo
sid_info = sid_load(@SID_START, @SID_END)
CALL sid_play(sid_info.init, sid_info.play)

CALL scr_charrom(CHARSET_LOWERCASE, 2048)
CALL scr_charmem(2048)
CALL scr_set_glyph(TILE_PLAYER, @glyph_dwarf)
CALL scr_set_glyph(TILE_TROLL, @glyph_troll)
CALL scr_set_glyph(TILE_WALL, @glyph_wall)
CALL scr_set_glyph(TILE_PASSAGE, @glyph_passage)
CALL scr_set_glyph(TILE_GEM, @glyph_gem)

MENU:
CALL scr_color(COLOR_BLACK, COLOR_BLACK)
CALL scr_clear()
CALL scr_centre(4, "Dwarf Miner")
CALL scr_centre(7, "Collect 15 diamonds")
CALL scr_centre("before time ends")
CALL scr_centre(10, "Avoid trolls")
CALL scr_centre(13, "Joystick 1 to move")
CALL scr_centre(15, "Fire button and direction")
CALL scr_centre("to build walls or dig tunnels")
CALL scr_centre(18, "Building and digging takes time")
CALL scr_centre(21, "Press fire to start")

CALL press_fire_button()

REM start game

RANDOMIZE TI()
CALL maze_create()

REM place diamonds
DIM x AS BYTE
DIM y AS BYTE
DIM gems_left AS BYTE: gems_left = 0
DO
    x = rnd_loc(MAZE_WIDTH)
    y = rnd_loc(MAZE_HEIGHT)
    IF scr_charat(x, y) <> TILE_GEM THEN
        CHARAT x, y, TILE_GEM
        gems_left = gems_left + 1
    END IF
LOOP UNTIL gems_left = 15

REM create trolls
FOR t AS BYTE = 0 TO 9
    DO
        troll(t).x = rnd_loc(MAZE_WIDTH)
        troll(t).y = rnd_loc(MAZE_HEIGHT)
    LOOP WHILE troll(t).x < 8 AND troll(t).y > 18
    troll(t).xnext = troll(t).x
    troll(t).ynext = troll(t).y
    troll(t).floor = scr_charat(troll(t).x, troll(t).y)
    troll(t).last = 4
    CHARAT troll(t).x, troll(t).y, TILE_TROLL
NEXT t

REM place player
player.x = 1
player.y = 23
x = 1
y = 23
DIM end_time AS LONG: end_time = ti() + 20
DIM rounds AS WORD: rounds = 199
GOTO MOVE_PLAYER

GAME_LOOP:
    IF ti() < end_time THEN GOTO GAME_LOOP
    end_time = ti() + 20

    rounds = rounds - 1
    IF rounds = 0 THEN GOTO GAME_OVER
    POKE 2023-40 * SHR(rounds, 3), 32

    x = player.x
    y = player.y
    IF joy1_up() THEN
        y = y - 1
        GOTO MOVE_PLAYER
    END IF
    IF joy1_down() THEN
        y = y + 1
        GOTO MOVE_PLAYER
    END IF
    IF joy1_left() THEN
        x = x - 1
        GOTO MOVE_PLAYER
    END IF
    IF joy1_right() THEN
        x = x + 1
        GOTO MOVE_PLAYER
    END IF
    GOTO MOVE_TROLLS

MOVE_PLAYER:
    DIM tile AS BYTE
    tile = scr_charat(x, y)

    IF joy1_fire() THEN
        IF tile = TILE_WALL AND x > 0 AND y > 0 AND x < MAZE_WIDTH-1 AND y < MAZE_HEIGHT-1 THEN
            IF RNDB() < 40 THEN CHARAT x, y, TILE_PASSAGE
        END IF
        IF tile = TILE_PASSAGE THEN
            IF RNDB() < 40 THEN CHARAT x, y, TILE_WALL
        END IF
    ELSE
        IF tile = TILE_WALL THEN GOTO MOVE_TROLLS

        CHARAT player.x, player.y, TILE_PASSAGE
        CHARAT x, y, TILE_PLAYER
        player.x = x
        player.y = y

        IF tile = TILE_TROLL THEN GOTO GAME_OVER
        IF tile = TILE_GEM THEN 
            gems_left = gems_left - 1
            FOR t AS BYTE = 0 TO 2
                POKE 2023 - 40 * SHR(rounds, 3), TILE_WALL
                rounds = rounds + 8
                IF rounds > 199 THEN rounds = 199
            NEXT t
        END IF
        IF gems_left = 0 THEN GOTO YOU_WIN
    END IF

MOVE_TROLLS:
    FOR t AS BYTE = 0 TO 9
        CALL troll(t).move()
    NEXT t
    FOR t AS BYTE = 0 TO 9
        CHARAT troll(t).x, troll(t).y, troll(t).floor
    NEXT t
    FOR t AS BYTE = 0 TO 9
        troll(t).floor = scr_charat(troll(t).xnext, troll(t).ynext)
    NEXT t
    FOR t AS BYTE = 0 TO 9
        CHARAT troll(t).xnext, troll(t).ynext, TILE_TROLL
    NEXT t
    FOR t AS BYTE = 0 TO 9
        troll(t).x = troll(t).xnext
        troll(t).y = troll(t).ynext
        IF troll(t).floor = TILE_PLAYER THEN GOTO GAME_OVER
    NEXT t

    GOTO GAME_LOOP

GAME_OVER:
    CALL scr_clear()
    TEXTAT 15,10, "Game over"
    CALL press_fire_button()
    GOTO MENU

YOU_WIN:
    CALL scr_clear()
    TEXTAT 17,10, "You win"
    CALL press_fire_button()
    GOTO MENU

nsew_data:
DATA AS BYTE %11100100, %11100001, %11011000, %11010010
DATA AS BYTE %11001001, %11000110, %10110100, %10110001
DATA AS BYTE %10011100, %10010011, %10001101, %10000111
DATA AS BYTE %01111000, %01110010, %01101100, %01100011
DATA AS BYTE %01001110, %01001011, %00111001, %00110110
DATA AS BYTE %00101101, %00100111, %00011110, %00011011

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

SID_START:
INCBIN "Castle_of_Life.sid"
SID_END:
END
