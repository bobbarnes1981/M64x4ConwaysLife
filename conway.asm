
; *********************************************************************************************
; Elementary Cellular Automata (1 Dimensional CA)
; *********************************************************************************************

; *********************************************************************************************
; TODO
;       > grid 40x24
;       > draw cursor box on 10 pixel grid
;       > move cursor box on 10 pixel grid using arrow keys
;       > use space bar to enable/disable cell 8x8
;       > use enter to start simulation
;       > use 'p' to pause/unpause simulation
;       > count steps taken
;       > display steps taken 0,29
;       > reserve memory for two representations if screen
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

                    MIW     0x0190, screen_w                        ; 0x0190 (400)
                    MIB     0xf0, screen_h                          ; 0xf0 (240)

                    MIB     0x0a, cell_size                         ; cell size is 10 pixels 40x24

                    MIW     0x1100, cella_pointer                   ; init cella pointer
                    MIW     0x14c0, cellb_pointer                   ; init cellb pointer

                    MIW     0x00c8, cursor_x                        ; cursor at x=200 pixels
                    MIB     0x78, cursor_y                          ; curosr at y=120 pixels

                    ; TODO: clear memory for cells?

                    JAS     _Clear                                  ; clear display

                    MIB     0x00, grid_current_y                    ; init current x
                    MIW     0x0000, grid_current_x                  ; init current y

                    ; print title

                    MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x00, _YPos                             ; set print to y=0
                    JPS     _Print "Conway's Life (esc to exit)", 0 ; print the title
                    LDI     0x0a                                    ; load carriage return
                    JAS     _PrintChar                              ; print carriage return

                    ; main loop

loop:

                    ; show step counter

show_steps:         MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x1d, _YPos                             ; set print to y=29
                    LDB     step_count+1                            ;
                    JAS     _PrintHex                               ; print MSB
                    LDB     step_count                              ;
                    JAS     _PrintHex                               ; print LSB
                    
                    ; check for exit

                    JAS     _ReadInput                              ; read serial/ps2 input
                    CPI     0x1b                                    ; escape key
                    BEQ     exit                                    ; branch to exit

                    ; up 0xe1, dn 0xe2, lt 0xe3, rt 0xe4, spc 0x20
                    CPI     0xe1
                    JAS     cursor_up

                    CPI     0xe2
                    JAS     cursor_dn

                    CPI     0xe3
                    JAS     cursor_lt

                    CPI     0xe4
                    JAS     cursor_rt

                    CPI     0x20
                    JAS     cursor_sp

                    JAS     cursor_draw

                    ; TODO: skip simulation if not 'running'

                    INW     step_count                              ; increment steps

                    ; end of loop
end_loop:
                    JPA     loop                                    ; continue loop


exit:               MIB     0x00, _XPos                             ; set print to x=0
                    MIB     0x01, _YPos                             ; set print to y=1
                    JPA     _Prompt                                 ; hand controll back to prompt

cursor_up:          
                    RTS

cursor_dn:          
                    RTS

cursor_lt:          
                    RTS

cursor_rt:          
                    RTS

cursor_sp:          
                    RTS

cursor_draw:
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

grid_current_x:     0xffff                                          ;
grid_current_y:     0xff                                            ;

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
