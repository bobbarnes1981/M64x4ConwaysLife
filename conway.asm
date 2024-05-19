
; *********************************************************************************************
; Elementary Cellular Automata (1 Dimensional CA)
; *********************************************************************************************

; *********************************************************************************************
; TODO
;       > use space bar to enable/disable cell 8x8
;       > use 'p' to pause/unpause simulation
;       > add flag for which cell pointer is to be used
;       > loop through all cells in screen (increment cell pointer and alt cell pointer)
;       > check neighbours using offsets in cell pointer
;       > update cell state in alternative cell pointer
;       > update cell on screen
;       > update flag to correct cell pointer
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

                    MIB     0x0a, cell_size                         ; cell size is 10 pixels 40x24

                    JAS     clear_cells                             ;

                    MIW     0x1100, cella_pointer                   ; init cella pointer
                    MIW     0x14c0, cellb_pointer                   ; init cellb pointer

                    MIW     0x00C7, cursor_x                        ; cursor at x=200 pixels
                    MIB     0x77, cursor_y                          ; curosr at y=120 pixels
                    MIW     0x00c8, cursor_x2                       ; cursor at x=200 pixels
                    MIB     0x78, cursor_y2                         ; curosr at y=120 pixels

                    JAS     _Clear                                  ; clear display

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
                    
                    ; check for exit

                    JAS     _ReadInput                              ; read serial/ps2 input

                    ; exit (escape)

                    CPI     0x1b
                    BEQ     exit

                    ; up 0xe1, dn 0xe2, lt 0xe3, rt 0xe4, spc 0x20

check_up:           CPI     0xe1
                    BNE     check_dn
                    JAS     cursor_up

check_dn:           CPI     0xe2
                    BNE     check_lt
                    JAS     cursor_dn

check_lt:           CPI     0xe3
                    BNE     check_rt
                    JAS     cursor_lt

check_rt:           CPI     0xe4
                    BNE     check_sp
                    JAS     cursor_rt

check_sp:           CPI     0x20
                    BNE     check_st
                    JAS     cursor_sp

check_st:           CPI     0x0a
                    BNE     check_run
                    JAS     start_sim

check_run:          CIB     0x00, running
                    BEQ     end_loop

                    INW     step_count                              ; increment steps

                    JAS     process_grid

                    ; end of loop

end_loop:
                    JAS     cursor_draw
                    JPA     loop                                    ; continue loop

exit:               MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x01, _YPos                             ; set print to y=1
                    JPA     _Prompt                                 ; hand controll back to prompt

; *********************************************************************************************
; up
; *********************************************************************************************

cursor_up:          SBB     cell_size, cursor_y2
                    RTS

; *********************************************************************************************
; down
; *********************************************************************************************

cursor_dn:          ABB     cell_size, cursor_y2
                    RTS

; *********************************************************************************************
; left
; *********************************************************************************************

cursor_lt:          SBW     cell_size, cursor_x2
                    RTS

; *********************************************************************************************
; right
; *********************************************************************************************

cursor_rt:          ABW     cell_size, cursor_x2
                    RTS

; *********************************************************************************************
; toggle cell
; *********************************************************************************************

cursor_sp:          
                    RTS

; *********************************************************************************************
; process grid
; *********************************************************************************************

process_grid:       
                    RTS

; *********************************************************************************************
; draw cursor
; *********************************************************************************************

cursor_draw:
                    CBB     cursor_y, cursor_y2
                    BNE     cursor_clr
                    CBB     cursor_x+1, cursor_x2+1
                    BNE     cursor_clr
                    CBB     cursor_x, cursor_x2
                    BNE     cursor_clr
                    JPA     cursor_done

                    ; remove old cursor

cursor_clr:
                    MWV     cursor_x, xa
                    CLZ     yc
                    MBZ     cursor_y, ya
                    CLZ     xc
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

                    MWV     cursor_x, xa
                    CLZ     yc
                    MBZ     cursor_y, ya
                    CLZ     xc
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

                    MBB     cursor_y2, cursor_y
                    MBB     cursor_x2+1, cursor_x+1
                    MBB     cursor_x2, cursor_x

                    ; draw new cursor

cursor_set:
                    MWV     cursor_x, xa
                    CLZ     yc
                    MBZ     cursor_y, ya
                    CLZ     xc
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

                    MWV     cursor_x, xa
                    CLZ     yc
                    MBZ     cursor_y, ya
                    CLZ     xc
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

; *********************************************************************************************
; start sim
; *********************************************************************************************

start_sim:          MIB     0x01, running
                    RTS
; *********************************************************************************************
; draw the cells subroutine : draw cell content and do the ant logic
; *********************************************************************************************

draw_cells:     MIW 0x1100, cella_pointer                       ; current cell array address
                CLB current_y                                   ; start at y 0

                ; start of row loop

cell_row_loop:  CLW current_x                                   ; start at x 0

                ; start of col loop

cell_col_loop:

                ; check cell pointer for cell colour

                LDR cella_pointer                               ; load cell info byte
                CPI 0x00                                        ; check if zero
                BEQ dontprocess                                 ;

cell_white:
                JAS fill_cell                                   ; set cell black

process:
                INW cella_pointer                               ; increment cell address (pointer to cell info bytes)

dontprocess:

                ; end of col loop

                ABW cell_size, current_x                        ; increment current_x by cell_size
                CBB screen_w+1, current_x+1                     ; compare MSB to screen_w MSB
                BNE cell_col_loop                               ; continue loop
                CBB screen_w, current_x                         ; compare LSB to screen_w LSB
                BNE cell_col_loop                               ; continue loop

                ; end of row loop

                ABB cell_size, current_y                        ; increment current_y by cell_size
                CBB screen_h, current_y                         ; compare to screen_h
                BNE cell_row_loop                               ; continue loop

                RTS                                             ;

; *********************************************************************************************
; fill a cell
; *********************************************************************************************

fill_cell:      MWV current_x, xa                               ; copy x to pixel x
                CLZ xc                                          ; reset x counter
fill_loop_x:    MBZ current_y, ya                               ; copy y to pixel y
                CLZ yc                                          ; reset y counter
fill_loop_y:    LDR cella_pointer                               ; load cell info byte
                CPI 0x00                                        ; check if zero
                BEQ fill_black                                  ; if byte is zero black else white

fill_white:     JPS _SetPixel                                   ; set pixel
                JPA fill_loop_end                               ; jump to end of loop
fill_black:     JPS _ClearPixel                                 ; clear pixel

fill_loop_end:  INZ yc                                          ; increment y counter
                INZ ya                                          ; increment y pixel
                CBZ cell_size, yc                               ; check if reached cell_size
                BNE fill_loop_y                                 ; continue loop
                INZ xc                                          ; increment x counter
                INV xa                                          ; increment x pixel
                CBZ cell_size, xc                               ; check if reached cell_size
                BNE fill_loop_x                                 ; continue loop

fill_done:      RTS                                             ; return

; *********************************************************************************************
; clear the memory to hold the cells
; *********************************************************************************************

clear_cells:    MIW 0x1100, cella_pointer
                MIW 0x14c0, cellb_pointer
                CLB current_y
clear_row_loop: CLW current_x
clear_col_loop: MIR 0x00, cella_pointer
                MIR 0x00, cellb_pointer
                INW cella_pointer
                INW cellb_pointer
                ABW cell_size, current_x
                CBB screen_w+1, current_x+1
                BNE clear_col_loop
                CBB screen_w, current_x
                BNE clear_col_loop
                ABB cell_size, current_y
                CBB screen_h, current_y
                BNE clear_row_loop
                RTS

; *********************************************************************************************
; Data
; *********************************************************************************************

#mute

#org 0x0000

xc:                 0xff                                            ;
yc:                 0xff                                            ;

#org 0x1000

cell_size:          0xff                                            ;
screen_w:           0xffff                                          ;
screen_h:           0xff                                            ;

cursor_x:           0xffff                                          ;
cursor_y:           0xff                                            ;
cursor_x2:          0xffff                                          ;
cursor_y2:          0xff                                            ;

current_x:          0xffff                                          ;
current_y:          0xff                                            ;

cella_pointer:      0xffff                                          ;
cellb_pointer:      0xffff                                          ;

step_count:         0xffff                                          ;

running:            0xff                                            ;

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
