INCLUDE "lib_hex.bas"

DECLARE SUB sid_init(s AS WORD, e AS WORD) SHARED STATIC
DECLARE SUB sid_play() SHARED STATIC OVERLOAD

DIM SHARED init AS WORD
DIM SHARED play AS WORD

DIM SHARED sid_debug AS BYTE
sid_debug = 0

SUB sid_init(s AS WORD, e AS WORD) SHARED STATIC
    POKE @init, PEEK(s + $0b)
    POKE @init+1, PEEK(s + $0a)

    POKE @play, PEEK(s + $0d)
    POKE @play+1, PEEK(s + $0c)

    DIM load_addr AS WORD
    POKE @load_addr, PEEK(s + $7c)
    POKE @load_addr+1, PEEK(s + $7d)

    DIM length AS WORD
    length = e - (s + $7e)

    IF sid_debug THEN 
        PRINT "init", hex(init)
        PRINT "play", hex(play)
        PRINT "load", hex(load_addr)
        PRINT "length", length
    END IF

    MEMCPY s + $7e, load_addr, length
END SUB

SUB sid_play() SHARED STATIC
    ' print hex(init), hex(play)

    ASM
        lda {init}
        sta jsr_init + 1
        lda {init}+1
        sta jsr_init + 2

        lda {play}
        sta jsr_play + 1
        lda {play}+1
        sta jsr_play + 2

        sei 
        lda #<irq
        sta $0314
        lda #>irq
        sta $0315

        lda #$7f        ; CIA interrupt off
        sta $dc0d

        lda #$01        ; Raster interrupt on
        sta $d01a

        lda $d011
        and #%01111111  ; High bit of interrupt position = 0
        sta $d011

        lda #$00        ; Line where next IRQ happens
        sta $d012

        lda $dc0d       ; Acknowledge IRQ (to be sure)
jsr_init:
        jsr $dead       ; Initialize music
        cli

        rts

irq:
        dec $d019       ; ACK any raster IRQs
jsr_play:
        jsr $6450       ; Play the music

        jmp $ea31
    END ASM
END SUB
