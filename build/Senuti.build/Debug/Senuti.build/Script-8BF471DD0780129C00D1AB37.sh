#!/bin/sh
gcc -E -P -x c -Wno-trigraphs -include "$SCRIPT_INPUT_FILE_0" -C "$SCRIPT_INPUT_FILE_1" -o "$SCRIPT_OUTPUT_FILE_0"
