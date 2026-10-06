#!/bin/bash
# Crop a region out of a PNG. usage: crop.sh <in.png> <out.png> <x> <y> <w> <h>
# sips treats an offset of 0 0 as "centre the crop", so a zero offset is nudged to 1.
x="$3"; y="$4"; [ "$x" -eq 0 ] && x=1; [ "$y" -eq 0 ] && y=1
sips -c "$6" "$5" --cropOffset "$y" "$x" "$1" --out "$2" >/dev/null 2>&1 && echo "wrote $2"
