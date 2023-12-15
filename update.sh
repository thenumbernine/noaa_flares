#!/bin/sh
./download-ncs.lua
./nc_to_txt.lua
./count-flares.lua
./plot.gnuplot
#git commit -am more && git push
