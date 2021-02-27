        include "_macros.asm"
; SETTINGS
PRODUCTION = 0

; I/O
HW_version      equ $A10001                 ; hardware version in low nibble
                                            ; bit 6 is PAL (50Hz) if set, NTSC (60Hz) if clear
                                            ; region flags in bits 7 and 6:
                                            ;         USA NTSC = $80
                                            ;         Asia PAL = $C0
                                            ;         Japan NTSC = $00
                                            ;         Europe PAL = $C0

; MSU-MD vars
MCD_STAT        equ $A12020                 ; 0-ready, 1-init, 2-cmd busy
MCD_CMD         equ $A12010
MCD_ARG         equ $A12011
MCD_CMD_CK      equ $A1201F

IO_Z80BUS       equ $A11100
sID_Z80         equ $A01A00

TOTAL_TRACKS    equ 26

; LABLES: ------------------------------------------------------------------------------------------

        org     $208                            ; Original ENTRY POINT
Game


; OVERWRITES: --------------------------------------------------------------------------------------

        org $4
        dc.l    ENTRY_POINT                     ; custom entry point for redirecting


        org     $100
        dc.b    'SEGA MEGASD     '              ; Make it compatible with MegaSD and GenesisPlusGX

        org     $1A4                            ; ROM_END
        dc.l    $001FFFFF                       ; Overwrite with 16 MBIT size

        org     $33C                            ; Wrong Checksum Bypass
        bra.s   ContinueAfterWrongChecksum

        org     $360
ContinueAfterWrongChecksum


        org     $9E0C
        ;jsr     MSU_Play_Sega


        org     $EF4                            ; Sound Hijack
        jmp     playSound

        org     $156B0                          ; Pause on
        nop 
        jsr     MSU_PauseOn

        org     $15782                 
        jsr     MSU_PauseOff

; CUSTOM FUNCTIONS: --------------------------------------------------------------------------------

        org     $100000

MSU_Play_Sega
        MCD_WAIT
        move.w  #($1100|30),MCD_CMD             ; Send MSU-MD command: Play Track 30
        addq.b  #1,MCD_CMD_CK                   ; Increment command clock
        move.w  #3,($FFA404).w                  ; adopt original instruction
        rts


; TABLES: ------------------------------------------------------------------------------------------
    align 2

AUDIO_TBL     ;cmd;code                         ; #Track Name                          #No.
        dc.w    $11A0                           ; Konami Music                          01
        dc.w    $118D                           ; Opening Theme                         02
        dc.w    $128F                           ; Select Your Turtle!                   03
        dc.w    $118E                           ; Bad News                              04
        dc.w    $1281                           ; Turtle Swing                          05
        dc.w    $1282                           ; Alleycat Blues                        06
        dc.w    $1296                           ; Back in the Sewers                    07
        dc.w    $1283                           ; Sewers Surfin'                        08
        dc.w    $1286                           ; Skull and Crossbones                  09
        dc.w    $1287                           ; Prehistoric Turtlesaurus              10
        dc.w    $1297                           ; Outside Shredder's Hideout            11
        dc.w    $1285                           ; Inside Shredder's Hideout             12
        dc.w    $1284                           ; The Gauntlet                          13
        dc.w    $1288                           ; Star Base                             14
        dc.w    $1289                           ; Down the Elevator                     15
        dc.w    $128A                           ; Boss Battle                           16
        dc.w    $128B                           ; Encountering the Shredder             17
        dc.w    $128C                           ; Final Shell Shock                     18
        dc.w    $1193                           ; Stage Clear                           19
        dc.w    $1194                           ; The Turtles Save the Day              20
        dc.w    $1295                           ; Pizza Power!                          21
        dc.w    $1299                           ; Ending (Hard Mode)                    22
        dc.w    $119B                           ; Technodrome appears                   23
        dc.w    $1290                           ; Continue                              24
        dc.w    $1191                           ; Game Over                             25
        dc.w    $1292                           ; High Score Display                    26

        ; COMMANDS:
        ; E0 - FADEOUT
        ; FE - STOP

; MSU-MD INIT: -------------------------------------------------------------------------------------

        align   2
audio_init
        jsr     MSUDRV
        nop
        
        if      PRODUCTION
        tst.b   d0                          ; if 1: no CD Hardware found
        bne     audio_init_fail             ; Return without setting CD enabled
        endif

ready_init
        MCD_WAIT
        move.w  #($1600|1),MCD_CMD          ; seek time emulation switch
                                            ; 0-on(default state), 1-off(no seek delays)
        addq.b  #1,MCD_CMD_CK               ; Increment command clock

        move.w  #($1500|255),MCD_CMD        ; Set CD Volume to MAX
        addq.b  #1,MCD_CMD_CK               ; Increment command clock
        rts
audio_init_fail
        jmp     lockout



; ENTRY POINT: -------------------------------------------------------------------------------------

        align   2
ENTRY_POINT
        tst.w   $00A10008                   ; Test mystery reset (expansion port reset?)
        bne Main                            ; Branch if Not Equal (to zero) - to Main
        tst.w   $00A1000C                   ; Test reset button
        bne Main                            ; Branch if Not Equal (to zero) - to Main
Main
        move.b  $00A10001,d0                ; Move Megadrive hardware version to d0
        andi.b  #$0F,d0                     ; The version is stored in last four bits, so mask it with 0F
        beq     Skip                        ; If version is equal to 0, skip TMSS signature
        move.l  #'SEGA',$00A14000           ; Move the string "SEGA" to 0xA14000
Skip
        btst    #$6,(HW_version).l          ; Check for PAL or NTSC, 0=60Hz, 1=50Hz
        bne     jump_lockout                ; branch if != 0
        jsr     audio_init
        jmp     Game
jump_lockout
        jmp     lockout


; Sound: -------------------------------------------------------------------------------------


playSound
        movem.l d0-d4/a0-a1,-(sp)
        move    sr,-(sp)
        
hijack  ; -----------------------
        cmpi.b  #$FE,d0
        beq.w   MSU_Stop
        cmpi.b  #$59,d0
        beq.w   MSU_Stop
        cmpi.b  #$E0,d0
        beq.w   MSU_Fade

        move.l  #$00,d2                         ; Set d2 to 0 as counter (track number)
        move.l  #$00,d3                         ; Set d3 to 0 as counter (table index)
        lea     AUDIO_TBL,a1                    ; Load audio table address
loop
        move.w  (a1,d3),d4                      ; Load table entry into d4
        cmp.b   d4,d0                           ; Compare given sound ID in d0 to table entry loaded into d4
        beq.s   ready                           ; If given sound ID matches the entry, d2 is our track number, so we branch to .ready
                                                ; sound ID did not match:
        addi    #1,d2                           ; Increment d2 (track number)
        addi    #2,d3                           ; Increment d3 by word-size (table index)
        cmp.b   #TOTAL_TRACKS+1,d2              ; If we reached the total number of tracks, abort. (plus 1 for loop-breaking)
        beq.s   passthrough                     ; If d2 equals TOTAL_TRACKS+1, no match found, branch to .passthrough, break loop
        bra.s   loop                            ; Branch to .loop
     
ready
        addi    #1,d2                           ; Increment d2 (skipped in the last repetition of the loop)
        tst.b   MCD_STAT                        ; MSU-MD driver ready?
        bne.s   ready                           ; If not, test again
        move.b  d2,d4                           ; Set play command, compose by setting byte from track-counter into word-sized command:
                                                ; given: [cmd][sID] -> after: [cmd][trackNo]
        MCD_WAIT
        move.w  d4,MCD_CMD                      ; Send MSU-MD command
        addq.b  #1,MCD_CMD_CK                   ; Increment command clock
        bra     playSound_exit
        
passthrough     ; -----------------
        ori     #$700,sr
        move.w  #$100,(IO_Z80BUS).l
loc_F02
        btst    #0,(IO_Z80BUS).l
        bne.s   loc_F02
        move.b  d0,(sID_Z80).l
        move.w  #0,(IO_Z80BUS).l
playSound_exit
        move    (sp)+,sr
        movem.l (sp)+,d0-d4/a0-a1
        rts

MSU_Stop
        MCD_WAIT
        move.w  #($1300|0),MCD_CMD              ; send cmd: pause track, no fade
        addq.b  #1,MCD_CMD_CK                   ; Increment command clock
        bra.w   passthrough
MSU_Fade
        MCD_WAIT
        move.w  #($1300|40),MCD_CMD             ; send cmd: pause track, no fade
        addq.b  #1,MCD_CMD_CK                   ; Increment command clock
        bra.w   passthrough

MSU_PauseOn
        MCD_WAIT
        move.w  #($1300|0),MCD_CMD              ; send cmd: pause track, no fade
        addq.b  #1,MCD_CMD_CK                   ; Increment command clock
        move.w  #1,($FFC012).l                  ; adopt original instruction: set Pause flag
        rts
MSU_PauseOff
        MCD_WAIT
        move.w  #($1400|0),MCD_CMD              ; send cmd: pause track, no fade
        addq.b  #1,MCD_CMD_CK                   ; Increment command clock
        clr.w   ($FFC012).l                     ; adopt original instruction: clear Pause flag
        rts


; MSU-MD DRIVER: -----------------------------------------------------------------------------------

        align 4
MSUDRV
        incbin  "msu-drv.bin"


; LOCKOUT SCREEN: ----------------------------------------------------------------------------------

        align   4
lockout
        incbin  "msuLockout.bin"

