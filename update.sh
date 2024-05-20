#!/bin/sh
./download-ncs.lua
./nc_to_txt.lua
./count-flares.lua
./plot.gnuplot
./smoothplot.sh
#git commit -am more && git push
