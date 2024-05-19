
# path to the Minimal 64x4 repository
$location = "..\Minimal-64x4-Home-Computer"

# copy the emulator into the current directory
Copy-Item "$location\Revision 1.1\FLASH Images\flash.bin" .
Copy-Item "$location\Support\Emulator\Minimal64x4.exe" .

# copy the assembler into the current directory
Copy-Item "$location\Support\Assembler\asm.exe" .
