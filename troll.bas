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
