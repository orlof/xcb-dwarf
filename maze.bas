'INCLUDE "lib_colors.bas"
'INCLUDE "lib_random.bas"
'INCLUDE "lib_joy.bas"
'INCLUDE "lib_scr.bas"

SHARED CONST MAZE_WIDTH = 39
SHARED CONST MAZE_HEIGHT = 25

SHARED CONST NORTH = 0
SHARED CONST EAST = 1
SHARED CONST WEST = 2
SHARED CONST SOUTH = 3

SHARED CONST TILE_BUILDING = 98
SHARED CONST TILE_HOURGLASS = 99
SHARED CONST TILE_PLAYER = 100
SHARED CONST TILE_TROLL = 101
SHARED CONST TILE_PASSAGE = 102
SHARED CONST TILE_GEM = 103
SHARED CONST TILE_WALL = 104
SHARED CONST TILE_BLOCK = 105
SHARED CONST TILE_DIGGING = 106

SHARED CONST TRUE = $ff
SHARED CONST FALSE = $00

DIM SHARED nsew(24) AS BYTE @nsew_data

DIM x_stack(255) AS BYTE
DIM y_stack(255) AS BYTE
DIM sp AS BYTE: sp = 0

SUB push(x AS BYTE, y AS BYTE) STATIC
    IF sp = 255 THEN ERROR 100
    x_stack(sp) = x
    y_stack(sp) = y
    sp = sp + 1
END SUB

FUNCTION rnd_loc AS BYTE(size AS BYTE) SHARED STATIC
    RETURN 2 * random(0, size / 2 - 1) + 1
END FUNCTION

SUB maze_create() SHARED STATIC
    DIM x AS BYTE
    DIM y AS BYTE
    MEMSET 1024, 1000, TILE_WALL
    MEMSET $D800, 1000, COLOR_DARKGRAY
    FOR x = 0 TO 38
        CHARAT x, 0, TILE_BLOCK
        CHARAT x, 24, TILE_BLOCK, COLOR_DARKGRAY
    NEXT x
    FOR y = 1 TO 23
        CHARAT 0, y, TILE_BLOCK, COLOR_DARKGRAY
        CHARAT 38, y, TILE_BLOCK, COLOR_DARKGRAY
    NEXT y
    CALL push(rnd_loc(MAZE_WIDTH), rnd_loc(MAZE_HEIGHT))

    DO UNTIL sp = 0
        x = x_stack(sp-1)
        y = y_stack(sp-1)

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

nsew_data:
DATA AS BYTE %11100100, %11100001, %11011000, %11010010
DATA AS BYTE %11001001, %11000110, %10110100, %10110001
DATA AS BYTE %10011100, %10010011, %10001101, %10000111
DATA AS BYTE %01111000, %01110010, %01101100, %01100011
DATA AS BYTE %01001110, %01001011, %00111001, %00110110
DATA AS BYTE %00101101, %00100111, %00011110, %00011011

