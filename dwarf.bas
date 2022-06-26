INCLUDE "lib_colors.bas"
INCLUDE "lib_hex.bas"
INCLUDE "lib_random.bas"
INCLUDE "lib_joy.bas"
INCLUDE "lib_scr.bas"

CONST NORTH = 0
CONST EAST = 1
CONST WEST = 2
CONST SOUTH = 3

CONST TILE_WALL = 102
CONST TILE_PASSAGE = 32
CONST TILE_TROLL = 42
CONST TILE_PLAYER = 81
CONST TILE_GEM = 90

DIM nsew(24) AS BYTE @nsew_data
DIM SHARED offset AS WORD
DIM SHARED width AS BYTE
DIM SHARED height AS BYTE

FUNCTION get_tile AS BYTE(x AS BYTE, y AS BYTE) STATIC
    RETURN PEEK(offset + 40 * CWORD(y) + x)
END FUNCTION

SUB set_tile(x AS BYTE, y AS BYTE, t AS BYTE) STATIC
    POKE offset + 40 * CWORD(y) + x, t
END SUB

FUNCTION rnd_loc AS BYTE(size AS BYTE) STATIC
    RETURN 2 * random(0, size / 2 - 1) + 1
END FUNCTION

SUB wait_for_fire() STATIC
    DO
    LOOP UNTIL NOT joy1_fire()
    DO
    LOOP UNTIL joy1_fire()
END SUB

SUB process_tile(x AS BYTE, y AS BYTE)
    DIM dirs AS BYTE: dirs = nsew(random(0, 23))
    DIM i AS BYTE: i = 4
    DO
        DIM cdir AS BYTE: cdir = dirs AND %11
        dirs = SHR(dirs, 2)
        IF cdir = NORTH AND y > 1 AND get_tile(x, y-2) = TILE_WALL THEN
            CALL set_tile(x, y-1, TILE_PASSAGE)
            CALL set_tile(x, y-2, TILE_PASSAGE)
            CALL process_tile(x, y-2)
        END IF
        IF cdir = SOUTH AND y < HEIGHT-2 AND get_tile(x, y+2) = TILE_WALL THEN
            CALL set_tile(x, y+1, TILE_PASSAGE)
            CALL set_tile(x, y+2, TILE_PASSAGE)
            CALL process_tile(x, y+2)
        END IF
        IF cdir = EAST AND x < WIDTH-2 AND get_tile(x+2, y) = TILE_WALL THEN
            CALL set_tile(x+1, y, TILE_PASSAGE)
            CALL set_tile(x+2, y, TILE_PASSAGE)
            CALL process_tile(x+2, y)
        END IF
        IF cdir = WEST AND x > 1 AND get_tile(x-2, y) = TILE_WALL THEN
            CALL set_tile(x-1, y, TILE_PASSAGE)
            CALL set_tile(x-2, y, TILE_PASSAGE)
            CALL process_tile(x-2, y)
        END IF
        i = i - 1
    LOOP UNTIL i = 0
END SUB

TYPE TypeTroll
    x AS BYTE
    y AS BYTE
    last AS BYTE
    floor AS BYTE

    SUB clear() STATIC
        CALL set_tile(THIS.x, THIS.y, THIS.floor)
    END SUB

    SUB move() STATIC
        DIM dirs AS BYTE: dirs = nsew(random(0, 23))
        DIM x AS BYTE
        DIM y AS BYTE
        DIM d AS BYTE

        FOR i AS BYTE = 0 TO 3
            DIM cdir AS BYTE: cdir = dirs AND %11
            dirs = SHR(dirs, 2)
            IF cdir = NORTH AND get_tile(THIS.x, THIS.y - 1) <> TILE_WALL THEN
                x = THIS.x
                y = THIS.y - 1
                d = cdir
                IF THIS.last <> SOUTH THEN EXIT FOR
            END IF
            IF cdir = SOUTH AND get_tile(THIS.x, THIS.y + 1) <> TILE_WALL THEN
                x = THIS.x
                y = THIS.y + 1
                d = cdir
                IF THIS.last <> NORTH THEN EXIT FOR
            END IF
            IF cdir = WEST AND get_tile(THIS.x - 1, THIS.y) <> TILE_WALL THEN
                x = THIS.x - 1
                y = THIS.y
                d = cdir
                IF THIS.last <> EAST THEN EXIT FOR
            END IF
            IF cdir = EAST AND get_tile(THIS.x + 1, THIS.y) <> TILE_WALL THEN
                x = THIS.x + 1
                y = THIS.y
                d = cdir
                IF THIS.last <> WEST THEN EXIT FOR
            END IF
        NEXT i

        THIS.floor = get_tile(x, y)
        THIS.x = x
        THIS.y = y
        THIS.last = d
    END SUB
END TYPE
DIM troll(10) AS TypeTroll

TYPE TypePlayer
    x AS BYTE
    y AS BYTE
END TYPE
DIM player AS TypePlayer

MENU:
CALL scr_color(COLOR_BLACK, COLOR_BLACK)
CALL scr_clear()
CALL scr_cursor(0, 4)
CALL scr_centre("dwarf miner")
CALL scr_cursor(0, 7)
CALL scr_centre("collect 15 diamonds")
CALL scr_centre("before time ends")
CALL scr_cursor(0, 10)
CALL scr_centre("avoid trolls")
CALL scr_cursor(0, 13)
CALL scr_centre("joystick 1 to move")
CALL scr_cursor(0, 15)
CALL scr_centre("fire button and direction")
CALL scr_centre("to build walls or dig tunnels")
CALL scr_cursor(0, 18)
CALL scr_centre("building and digging takes time")
CALL scr_cursor(0, 21)
CALL scr_centre("press fire to start")

CALL wait_for_fire()

START_GAME:
RANDOMIZE TI()

REM clear dungeon
MEMSET 1024, 1000, TILE_WALL

REM draw right dungeon
offset = 1044
width = 19
height = 25
CALL process_tile(rnd_loc(width), rnd_loc(height))

REM draw left dungeon
offset = 1024
width = 21
CALL process_tile(rnd_loc(width), rnd_loc(height))

REM open passage
CALL set_tile(20, rnd_loc(height), TILE_PASSAGE)

REM place diamonds
DIM x AS BYTE
DIM y AS BYTE
DIM gems_left AS BYTE: gems_left = 0
width = 39
DO
    x = rnd_loc(width)
    y = rnd_loc(height)
    IF get_tile(x, y) <> TILE_GEM THEN
        CALL set_tile(x, y, TILE_GEM)
        gems_left = gems_left + 1
    END IF
LOOP UNTIL gems_left = 15

REM create trolls
FOR t AS BYTE = 0 TO 9
    DO
        troll(t).x = rnd_loc(width)
        troll(t).y = rnd_loc(height)
    LOOP WHILE troll(t).x < 8 AND troll(t).y > 18
    troll(t).floor = get_tile(troll(t).x, troll(t).y)
    troll(t).last = 4
    CALL set_tile(troll(t).x, troll(t).y, TILE_TROLL)
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
    tile = get_tile(x, y)

    IF joy1_fire() THEN
        IF tile = TILE_WALL AND x > 0 AND y > 0 AND x < width-1 AND y < height-1 THEN
            IF RNDB() < 40 THEN CALL set_tile(x, y, TILE_PASSAGE)
        END IF
        IF tile = TILE_PASSAGE THEN
            IF RNDB() < 40 THEN CALL set_tile(x, y, TILE_WALL)
        END IF
    ELSE
        IF tile = TILE_WALL THEN GOTO MOVE_TROLLS

        CALL set_tile(player.x, player.y, TILE_PASSAGE)
        player.x = x
        player.y = y
        CALL set_tile(x, y, TILE_PLAYER)

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
        CALL set_tile(troll(9-t).x, troll(9-t).y, troll(9-t).floor)
    NEXT t

    FOR t AS BYTE = 0 TO 9
        CALL troll(t).move()
        CALL set_tile(troll(t).x, troll(t).y, TILE_TROLL)
        IF troll(t).floor = TILE_PLAYER THEN GOTO GAME_OVER
    NEXT t

    GOTO GAME_LOOP

GAME_OVER:
    MEMSET 1024, 1000, TILE_PASSAGE
    TEXTAT 15,10, "game over"
    CALL wait_for_fire()
    GOTO MENU

YOU_WIN:
    MEMSET 1024, 1000, TILE_PASSAGE
    TEXTAT 17,10, "you win"
    CALL wait_for_fire()
    GOTO MENU

nsew_data:
DATA AS BYTE %11100100, %11100001, %11011000, %11010010
DATA AS BYTE %11001001, %11000110, %10110100, %10110001
DATA AS BYTE %10011100, %10010011, %10001101, %10000111
DATA AS BYTE %01111000, %01110010, %01101100, %01100011
DATA AS BYTE %01001110, %01001011, %00111001, %00110110
DATA AS BYTE %00101101, %00100111, %00011110, %00011011
