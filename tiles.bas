SHARED CONST TILE_BUILDING = 97
SHARED CONST TILE_HOURGLASS = 99
SHARED CONST TILE_PLAYER = 100
SHARED CONST TILE_TROLL = 101
SHARED CONST TILE_PASSAGE = 102
SHARED CONST TILE_GEM = 103
SHARED CONST TILE_WALL = 104
SHARED CONST TILE_BLOCK = 120
SHARED CONST TILE_DIGGING = 121

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
