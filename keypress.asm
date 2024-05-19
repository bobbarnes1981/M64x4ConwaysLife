            #org 0x200

loop:       JAS     _ReadInput
            BEQ     loop
            CPI     0x1b
            BEQ     exit
            JAS     _PrintHex
            JPA     loop
exit:       JPA     _Prompt

#org 0xf003 _Prompt:                    ; Hands back control to the input prompt
#org 0xf012 _ReadInput:                 ; Reads any input (PS/2 or serial)
#org 0xf04b _PrintHex:                  ; Prints a HEX number (advancing)