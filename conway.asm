
; *********************************************************************************************
; Elementary Cellular Automata (1 Dimensional CA)
; *********************************************************************************************

; *********************************************************************************************
; TODO
;       > don't check neighbours when out of bounds
;       > use 'p' to pause/unpause simulation
;       > performance improvements
;       > code clean up
;       > comments
; *********************************************************************************************

; *********************************************************************************************
; Start
; *********************************************************************************************

                    #org    0x2000

                    ; initialise

                    MIB     0x00, running                           ;
                    MIW     0x0000, step_count                      ;

                    MIW     0x0190, screen_w                        ; 0x0190 (400)
                    MIB     0xf0, screen_h                          ; 0xf0 (240)

                    MIB     0x28, num_cols                          ; 40
                    MIB     0x18, num_rows                          ; 24

                    MIB     0x0a, cell_size                         ; cell size is 10 pixels 40x24

                    JAS     clear_cells                             ;

                    MIW     0x1100, cella_pointer                   ; init cella pointer
                    MIW     0x14c0, cellb_pointer                   ; init cellb pointer

                    MIB     0x13, cursor_col                        ; cursor at col=19
                    MIB     0x0b, cursor_row                        ; cursor at row=11
                    MIB     0x14, cursor_col2                       ; cursor at col=20
                    MIB     0x0c, cursor_row2                       ; cursor at row=12

                    JAS     _Clear                                  ; clear display

                    ; Glider
                    MIB     0x81, 0x127c
                    MIB     0x81, 0x12a5
                    MIB     0x81, 0x12cd
                    MIB     0x81, 0x12cc
                    MIB     0x81, 0x12cb

                    MIB     0x00, current_y                         ; init current x
                    MIW     0x0000, current_x                       ; init current y

                    ; print title

                    MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x00, _YPos                             ; set print to y=0
                    JPS     _Print "Conway's Life (esc to exit)", 0 ; print the title
                    LDI     0x0a                                    ; load carriage return
                    JAS     _PrintChar                              ; print carriage return

                    ; main loop

loop:
                    JAS     draw_cells                              ;

                    ; show step counter

show_steps:         MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x1d, _YPos                             ; set print to y=29
                    LDB     step_count+1                            ;
                    JAS     _PrintHex                               ; print MSB
                    LDB     step_count                              ;
                    JAS     _PrintHex                               ; print LSB

                    LDB     cursor_col
                    JAS     _PrintHex
                    LDB     cursor_row
                    JAS     _PrintHex
                    
                    ; check for exit

                    JAS     _ReadInput                              ; read serial/ps2 input
                    STB     in                                      ;

                    ; exit (escape)

                    CIB     0x1b, in                                ;
                    BEQ     exit                                    ;

                    ; up 0xe1, dn 0xe2, lt 0xe3, rt 0xe4, spc 0x20

check_up:           CIB     0xe1, in                                ;
                    BNE     check_dn                                ;
                    DEB     cursor_row2                             ;

check_dn:           CIB     0xe2, in                                ;
                    BNE     check_lt                                ;
                    INB     cursor_row2                             ;

check_lt:           CIB     0xe3, in                                ;
                    BNE     check_rt                                ;
                    DEB     cursor_col2                             ;

check_rt:           CIB     0xe4, in                                ;
                    BNE     check_sp                                ;
                    INB     cursor_col2                             ;

check_sp:           CIB     0x20, in                                ;
                    BNE     check_st                                ;
                    ; toggle the current cursor cell
                    MIW     0x1100, tmp_pointer                     ; initialise pointer for cells ram
                    MBB     cursor_row, yd                          ;
                    MBB     cursor_col, xd                          ;
find_y_loop:
                    CIB     0x00, yd                                ;
                    BEQ     found_y_loop                            ;
                    DEB     yd                                      ;
                    ABV     num_cols, tmp_pointer                   ;
                    JPA     find_y_loop                             ;
found_y_loop:
find_x_loop:
                    CIB     0x00, xd                                ;
                    BEQ     found_x_loop                            ;
                    DEB     xd                                      ;
                    INW     tmp_pointer                             ;
                    JPA     find_x_loop                             ;
found_x_loop:


found_cell:
                    LDR     tmp_pointer                             ;
                    ANI     0x01                                    ;
                    CPI     0x01                                    ;
                    BEQ     cell_0                                  ;
                    MIR     0x81, tmp_pointer                       ; set cell as white/dirty
                    JPA     cell_done
cell_0:             MIR     0x80, tmp_pointer                       ; set cell as black/dirty
cell_done:

check_st:           CIB     0x0a, in                                ;
                    BNE     check_run                               ;
                    MIB     0x01, running                           ;

check_run:          CIB     0x00, running                           ;
                    BEQ     end_loop                                ;

                    INW     step_count                              ; increment steps

                    JAS     process_cells                           ;

                    ; end of loop

end_loop:
                    JAS     cursor_draw                             ;
                    JPA     loop                                    ; continue loop

exit:               MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x01, _YPos                             ; set print to y=1
                    JPA     _Prompt                                 ; hand controll back to prompt

; *********************************************************************************************
; draw cursor
; *********************************************************************************************

cursor_draw:
                    CBB     cursor_row, cursor_row2
                    BNE     cursor_clr
                    CBB     cursor_col, cursor_col2
                    BNE     cursor_clr
                    RTS

                    ; remove old cursor

cursor_clr:
                    MIV     0x0000, xa
                    CLZ     yc
                    MIZ     0x00, ya
                    CLZ     xc
                    JAS     inc_ya
                    JAS     inc_xa
cur_clr_a:
                    JPS     _ClearPixel
                    INZ     ya
                    INZ     yc
                    CBZ     cell_size, yc
                    BNE     cur_clr_a
cur_clr_b:
                    JPS     _ClearPixel
                    INV     xa
                    INZ     xc
                    CBZ     cell_size, xc
                    BLE     cur_clr_b

                    MIV     0x0000, xa
                    CLZ     yc
                    MIZ     0x00, ya
                    CLZ     xc
                    JAS     inc_ya
                    JAS     inc_xa
cur_clr_c:
                    JPS     _ClearPixel
                    INV     xa
                    INZ     xc
                    CBZ     cell_size, xc
                    BNE     cur_clr_c
cur_clr_d:
                    JPS     _ClearPixel
                    INZ     ya
                    INZ     yc
                    CBZ     cell_size, yc
                    BLE     cur_clr_d

                    ; move cursor

                    MBB     cursor_row2, cursor_row
                    MBB     cursor_col2, cursor_col

                    ; draw new cursor

cursor_set:
                    MIV     0x0000, xa
                    CLZ     yc
                    MIZ     0x00, ya
                    CLZ     xc
                    JAS     inc_ya
                    JAS     inc_xa
cur_set_a:
                    JPS     _SetPixel
                    INZ     ya
                    INZ     yc
                    CBZ     cell_size, yc
                    BNE     cur_set_a
cur_set_b:
                    JPS     _SetPixel
                    INV     xa
                    INZ     xc
                    CBZ     cell_size, xc
                    BLE     cur_set_b

                    MIV     0x0000, xa
                    CLZ     yc
                    MIZ     0x00, ya
                    CLZ     xc
                    JAS     inc_ya
                    JAS     inc_xa
cur_set_c:
                    JPS     _SetPixel
                    INV     xa
                    INZ     xc
                    CBZ     cell_size, xc
                    BNE     cur_set_c
cur_set_d:
                    JPS     _SetPixel
                    INZ     ya
                    INZ     yc
                    CBZ     cell_size, yc
                    BLE     cur_set_d

cursor_done:        RTS

inc_ya:
                    MBB     cursor_row, yd
loop_inc_ya:
                    LDB     yd
                    CPI     0x00
                    BEQ     done_inc_ya
                    DEB     yd
                    ABZ     cell_size, ya
                    JPA     loop_inc_ya
done_inc_ya:
                    RTS

inc_xa:
                    MBB     cursor_col, xd
loop_inc_xa:
                    LDB     xd
                    CPI     0x00
                    BEQ     done_inc_xa
                    DEB     xd
                    ABV     cell_size, xa
                    JPA     loop_inc_xa
done_inc_xa:
                    RTS

; *********************************************************************************************
; process the cells
; *********************************************************************************************

process_cells:
                    MIW     0x1100, cella_pointer
                    MIW     0x14c0, cellb_pointer
                    MIB     0x00, yc
proc_row_loop:
                    MIB     0x00, xc
proc_col_loop:
                    ; TODO: don't check neighbour when out of bounds
                    ; check all 8 neighbours in cella_pointer addresses
                    ; 0 1 2
                    ; 3|4|5
                    ; 6 7 8
                    MIB     0x00, neighbours
                    MWV     cella_pointer, tmp_pointer

                    ; cell 1
proc_1:             SBW     num_cols, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_0
                    INB     neighbours
                    ; cell 0
proc_0:             SIW     0x01, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_2
                    INB     neighbours
                    ; cell 2
proc_2:             AIW     0x02, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_5
                    INB     neighbours
                    ; cell 5
proc_5:             ABW     num_cols, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_8
                    INB     neighbours
                    ; cell 8
proc_8:             ABW     num_cols, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_7
                    INB     neighbours
                    ; cell 7
proc_7:             SIW     0x01, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_6
                    INB     neighbours
                    ; cell 6
proc_6:             SIW     0x01, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_3
                    INB     neighbours
                    ; cell 3
proc_3:             SBW     num_cols, tmp_pointer
                    CIR     0x01, tmp_pointer
                    BNE     proc_end
                    INB     neighbours
proc_end:

                    LDR     cella_pointer
                    CPI     0x01
                    BEQ     check_live

check_dead:
                    LDB     neighbours

chk_dead_0:         CIB     0x00, neighbours
                    BNE     chk_dead_1
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_dead_1:         CIB     0x01, neighbours
                    BNE     chk_dead_2
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_dead_2:         CIB     0x02, neighbours
                    BNE     chk_dead_3
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_dead_3:         CIB     0x03, neighbours
                    BNE     chk_dead_4
                    MIR     0x01, cellb_pointer
                    JPA     proc_endloop

chk_dead_4:         CIB     0x04, neighbours
                    BNE     chk_dead_5
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_dead_5:         CIB     0x05, neighbours
                    BNE     chk_dead_6
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_dead_6:         CIB     0x06, neighbours
                    BNE     chk_dead_7
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_dead_7:         CIB     0x07, neighbours
                    BNE     chk_end
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

check_live:
                    LDB     neighbours

chk_live_0:         CIB     0x00, neighbours
                    BNE     chk_live_1
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_live_1:         CIB     0x01, neighbours
                    BNE     chk_live_2
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_live_2:         CIB     0x02, neighbours
                    BNE     chk_live_3
                    MIR     0x01, cellb_pointer
                    JPA     proc_endloop

chk_live_3:         CIB     0x03, neighbours
                    BNE     chk_live_4
                    MIR     0x01, cellb_pointer
                    JPA     proc_endloop

chk_live_4:         CIB     0x04, neighbours
                    BNE     chk_live_5
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_live_5:         CIB     0x05, neighbours
                    BNE     chk_live_6
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_live_6:         CIB     0x06, neighbours
                    BNE     chk_live_7
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop

chk_live_7:         CIB     0x07, neighbours
                    BNE     chk_end
                    MIR     0x00, cellb_pointer
                    JPA     proc_endloop
chk_end:

proc_endloop:

                    ; end of col loop

                    INW     cella_pointer                           ;
                    INW     cellb_pointer                           ;

                    INB     xc                                      ;
                    CBB     xc, num_cols                            ;
                    BNE     proc_col_loop                           ; continue loop

                    ; end of row loop

                    INB     yc                                      ;
                    CBB     yc, num_rows                            ;
                    BNE     proc_row_loop                           ; continue loop

                    JAS     swap

                    RTS

swap:

                    MIW     0x1100, cella_pointer
                    MIW     0x14c0, cellb_pointer
                    MIB     0x00, yc
swap_row_loop:
                    MIB     0x00, xc
swap_col_loop:
                    LDR     cellb_pointer
                    CPR     cella_pointer
                    BEQ     swap_skip
                    ORI     0x80                                    ; enable dirty bit 7
                    STR     cella_pointer
swap_skip:
                    ; end of col loop

                    INW     cella_pointer                           ;
                    INW     cellb_pointer                           ;

                    INB     xc                                      ;
                    CBB     xc, num_cols                            ;
                    BNE     swap_col_loop                           ; continue loop

                    ; end of row loop

                    INB     yc                                      ;
                    CBB     yc, num_rows                            ;
                    BNE     swap_row_loop                           ; continue loop

                    RTS

; *********************************************************************************************
; draw the cells subroutine
; *********************************************************************************************

draw_cells:         MIW     0x1100, cella_pointer                   ; current cell array address
                    CLB     current_y                               ; start at y 0

                    ; start of row loop

cell_row_loop:      CLW     current_x                               ; start at x 0

                    ; start of col loop

cell_col_loop:

                    ; check cell pointer for cell colour

                    LDR     cella_pointer                           ; load cell info byte
                    ANI     0x80                                    ; check if 'dirty' using bit 7
                    CPI     0x80                                    ;
                    BNE     dontprocess                             ;

                    LDR     cella_pointer                           ;
                    ANI     0x7F                                    ; disable bit 7
                    STR     cella_pointer                           ;
                    STB     current_info                            ;
                    JAS     fill_cell                               ; set cell black

dontprocess:
                    INW     cella_pointer                           ; increment cell address (pointer to cell info bytes)

                    ; end of col loop

                    ABW     cell_size, current_x                    ; increment current_x by cell_size
                    CBB     screen_w+1, current_x+1                 ; compare MSB to screen_w MSB
                    BNE     cell_col_loop                           ; continue loop
                    CBB     screen_w, current_x                     ; compare LSB to screen_w LSB
                    BNE     cell_col_loop                           ; continue loop

                    ; end of row loop

                    ABB     cell_size, current_y                    ; increment current_y by cell_size
                    CBB     screen_h, current_y                     ; compare to screen_h
                    BNE     cell_row_loop                           ; continue loop

                    RTS                                             ;

; *********************************************************************************************
; fill a cell
; *********************************************************************************************

fill_cell:          MWV     current_x, xa                           ; copy x to pixel x
                    INV     xa
                    MIZ     0x01, xc                                ; reset x counter
fill_loop_x:        MBZ     current_y, ya                           ; copy y to pixel y
                    INZ     ya
                    MIZ     0x01, yc                                ; reset y counter
fill_loop_y:        LDB     current_info                            ; load cell info byte
                    CPI     0x00                                    ; check if zero
                    BEQ     fill_black                              ; if byte is zero black else white

fill_white:         JPS     _SetPixel                               ; set pixel
                    JPA     fill_loop_end                           ; jump to end of loop
fill_black:         JPS     _ClearPixel                             ; clear pixel

fill_loop_end:      INZ     yc                                      ; increment y counter
                    INZ     ya                                      ; increment y pixel
                    CBZ     cell_size, yc                           ; check if reached cell_size
                    BNE     fill_loop_y                             ; continue loop
                    INZ     xc                                      ; increment x counter
                    INV     xa                                      ; increment x pixel
                    CBZ     cell_size, xc                           ; check if reached cell_size
                    BNE     fill_loop_x                             ; continue loop

fill_done:          RTS                                             ; return

; *********************************************************************************************
; clear the memory to hold the cells
; *********************************************************************************************

clear_cells:        MIW     0x1100, cella_pointer
                    MIW     0x14c0, cellb_pointer
                    CLB     current_y
clear_row_loop:     CLW     current_x
clear_col_loop:     MIR     0x00, cella_pointer
                    MIR     0x00, cellb_pointer
                    INW     cella_pointer
                    INW     cellb_pointer
                    ABW     cell_size, current_x
                    CBB     screen_w+1, current_x+1
                    BNE     clear_col_loop
                    CBB     screen_w, current_x
                    BNE     clear_col_loop
                    ABB     cell_size, current_y
                    CBB     screen_h, current_y
                    BNE     clear_row_loop
                    RTS

; *********************************************************************************************
; Data
; *********************************************************************************************

#mute

#org 0x0000

in:                 0xff                                            ;
xc:                 0xff                                            ;
yc:                 0xff                                            ;
xd:                 0xff                                            ;
yd:                 0xff                                            ;
tmp_pointer:        0xffff                                          ;
neighbours:         0xff                                            ;

#org 0x1000

cell_size:          0xff                                            ;
screen_w:           0xffff                                          ;
screen_h:           0xff                                            ;

cursor_col:         0xff                                            ;
cursor_row:         0xff                                            ;
cursor_col2:        0xff                                            ;
cursor_row2:        0xff                                            ;

current_x:          0xffff                                          ;
current_y:          0xff                                            ;
current_info:       0xff                                            ;

cella_pointer:      0xffff                                          ;
cellb_pointer:      0xffff                                          ;

step_count:         0xffff                                          ;

running:            0xff                                            ;

num_cols:           0xff                                            ;
num_rows:           0xff                                            ;

#org 0x1100     cells_a: ;40x24 cells
#org 0x14c0     cells_b: ;40x24 cells

; zero-page graphics interface (OS_SetPixel, OS_ClearPixel, OS_Line, OS_Rect)

#org 0x0080     xa: steps: 0xffff
                ya:        0xff
                xb:        0xffff
                yb:        0xff
                dx:        0xffff
                dy:        0xff
                bit:       0xff
                err:       0xffff

; API Function

#org 0xf000 _Start:                     ; Start vector of the OS in RAM
#org 0xf003 _Prompt:                    ; Hands back control to the input prompt
#org 0xf006 _MemMove:                   ; Moves memory area (may be overlapping)
#org 0xf009 _Random:                    ; Returns a pseudo-random byte (see _RandomState)
#org 0xf00c _ScanPS2:                   ; Scans the PS/2 register for new input
#org 0xf00f _ResetPS2:                  ; Resets the state of PS/2 SHIFT, ALTGR, CTRL
#org 0xf012 _ReadInput:                 ; Reads any input (PS/2 or serial)
#org 0xf015 _WaitInput:                 ; Waits for any input (PS/2 or serial)
#org 0xf018 _ReadLine:                  ; Reads a command line into _ReadBuffer
#org 0xf01b _SkipSpace:                 ; Skips whitespaces (<= 39) in command line
#org 0xf01e _ReadHex:                   ; Parses command line input for a HEX value
#org 0xf021 _SerialWait:                ; Waits for a UART transmission to complete
#org 0xf024 _SerialPrint:               ; Transmits a zero-terminated string via UART
#org 0xf027 _FindFile:                  ; Searches for file <name> given by _ReadPtr
#org 0xf02a _LoadFile:                  ; Loads a file <name> given by _ReadPtr
#org 0xf02d _SaveFile:                  ; Saves data to file <name> defined at _ReadPtr
#org 0xf030 _ClearVRAM:                 ; Clears the video RAM including blanking areas
#org 0xf033 _Clear:                     ; Clears the visible video RAM (viewport)
#org 0xf036 _ClearRow:                  ; Clears the current row from cursor pos onwards
#org 0xf039 _ScrollUp:                  ; Scrolls up the viewport by 8 pixels
#org 0xf03c _ScrollDn:                  ; Scrolls down the viewport by 8 pixels
#org 0xf03f _Char:                      ; Outputs a char at the cursor pos (non-advancing)
#org 0xf042 _PrintChar:                 ; Prints a char at the cursor pos (advancing)
#org 0xf045 _Print:                     ; Prints a zero-terminated immediate string
#org 0xf048 _PrintPtr:                  ; Prints a zero-terminated string at an address
#org 0xf04b _PrintHex:                  ; Prints a HEX number (advancing)
#org 0xf04e _SetPixel:                  ; Sets a pixel at position (x, y)
#org 0xf051 _Line:                      ; Draws a line using Bresenham's algorithm
#org 0xf054 _Rect:                      ; Draws a rectangle at (x, y) of size (w, h)
#org 0xf057 _ClearPixel:                ; Clears a pixel at position (x, y)

; API Data

#org 0x00c0 _XPos:                      ; 1 byte: Horizontal cursor position (see _Print)
#org 0x00c1 _YPos:                      ; 1 byte: Vertical cursor position (see _Print)
#org 0x00c2 _RandomState:               ; 4 bytes: _Random state seed
#org 0x00c6 _ReadNum:                   ; 3 bytes: Number parsed by _ReadHex
#org 0x00c9 _ReadPtr:                   ; 2 bytes: Command line parsing pointer
#org 0x00cb                             ; 2 bytes: unused
#org 0x00cd _ReadBuffer:                ; 2 bytes: Address of command line input buffer
