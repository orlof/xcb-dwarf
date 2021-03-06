CONST UP_MASK      = %00000001
CONST DOWN_MASK    = %00000010
CONST LEFT_MASK    = %00000100
CONST RIGHT_MASK   = %00001000
CONST FIRE_MASK    = %00010000
CONST ANY_DIR_MASK = %00001111

DIM Joy1Prev AS BYTE
    Joy1Prev = PEEK($dc01) AND %00011111
DIM Joy1Value AS BYTE
    Joy1Value = Joy1Prev

SUB Joy1Update() SHARED STATIC
    Joy1Prev = Joy1Value    
    Joy1Value = PEEK($dc01) AND %00011111
END SUB

FUNCTION joy1_up AS BYTE () SHARED STATIC
    RETURN (Joy1Value AND UP_MASK) = 0
END FUNCTION

FUNCTION joy1_down AS BYTE () SHARED STATIC
    RETURN (Joy1Value AND DOWN_MASK) = 0
END FUNCTION

FUNCTION joy1_left AS BYTE () SHARED STATIC
    RETURN (Joy1Value AND LEFT_MASK) = 0
END FUNCTION

FUNCTION joy1_right AS BYTE () SHARED STATIC
    RETURN (Joy1Value AND RIGHT_MASK) = 0
END FUNCTION

FUNCTION joy1_fire AS BYTE () SHARED STATIC
    RETURN (Joy1Value AND FIRE_MASK) = 0
END FUNCTION

FUNCTION joy1_horizontal AS INT() SHARED STATIC
    IF joy1_left() THEN RETURN -1
    IF joy1_right() THEN RETURN 1
    RETURN 0
END FUNCTION

FUNCTION joy1_vertical AS INT() SHARED STATIC
    IF joy1_up() THEN RETURN -1
    IF joy1_down() THEN RETURN 1
    RETURN 0
END FUNCTION

FUNCTION Joy1FireDown AS BYTE() SHARED STATIC
    RETURN ((Joy1Value XOR Joy1Prev) AND FIRE_MASK) > 0 AND joy1_fire()
END FUNCTION

FUNCTION Joy1FireUp AS BYTE() SHARED STATIC
    RETURN ((Joy1Value XOR Joy1Prev) AND FIRE_MASK) > 0 AND NOT joy1_fire()
END FUNCTION

FUNCTION Joy1DirectionChange AS BYTE() SHARED STATIC
    RETURN ((Joy1Value XOR Joy1Prev) AND ANY_DIR_MASK) > 0
END FUNCTION

SUB Joy1WaitFireDown() SHARED STATIC
    CALL Joy1Update()
    DO UNTIL Joy1FireDown()
        CALL Joy1Update()
    LOOP
END SUB

FUNCTION joy2_up AS BYTE () SHARED STATIC
    RETURN (PEEK($DC00) AND UP_MASK) = 0
END FUNCTION

FUNCTION joy2_down AS BYTE () SHARED STATIC
    RETURN (PEEK($DC00) AND DOWN_MASK) = 0
END FUNCTION

FUNCTION joy2_left AS BYTE () SHARED STATIC
    RETURN (PEEK($DC00) AND LEFT_MASK) = 0
END FUNCTION

FUNCTION joy2_right AS BYTE () SHARED STATIC
    RETURN (PEEK($DC00) AND RIGHT_MASK) = 0
END FUNCTION

FUNCTION joy2_fire AS BYTE () SHARED STATIC
    RETURN (PEEK($DC00) AND FIRE_MASK) = 0
END FUNCTION
