DECLARE SUB scr_color(bc AS BYTE, sc AS BYTE) SHARED STATIC
DECLARE SUB scr_centre(s AS STRING * 96) SHARED STATIC
DECLARE SUB scr_cursor(x AS BYTE, y AS BYTE) SHARED STATIC
DECLARE SUB scr_clear() SHARED STATIC

DIM SHARED leading_space AS STRING * 20
leading_space = "                    "

SUB scr_color(bc AS BYTE, sc AS BYTE) SHARED STATIC
    POKE 53280, bc
    POKE 53281, sc
END SUB

SUB scr_centre(s AS STRING * 96) SHARED STATIC
    IF len(s) > 38 THEN
        POKE @leading_space, 0
    ELSE
        POKE @leading_space, SHR(40 - len(s), 1)
    END IF
    PRINT leading_space; s
END SUB

SUB scr_cursor(x AS BYTE, y AS BYTE) SHARED STATIC
    POKE 783, 0
    POKE 782, x
    POKE 781, y
    SYS 65520
END SUB

SUB scr_clear() SHARED STATIC
    MEMSET 1024, 1000, 32
    CALL scr_cursor(0, 0)
END SUB

