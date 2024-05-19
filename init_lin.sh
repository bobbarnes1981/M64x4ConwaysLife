#!/bin/bash

# path to the Minimal 64x4 repository
LOCATION="../Minimal-64x4-Home-Computer"

# copy the emulator into the current directory
# currently the emulator will need to be executed using wine
cp "$LOCATION/Revision 1.1/FLASH Images/flash.bin" .
cp "$LOCATION/Support/Emulator/Minimal64x4.exe" .

# compile the assmebler into the current directory
g++ "$LOCATION/Support/Assembler/asm.cpp" -O2 -o ./asm -s -static
