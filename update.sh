#!/bin/sh
./download-ncs.lua
./nc_to_txt.lua
./count-flares.lua
./plot.gnuplot
../smooth_graph/smooth_graph.lua totalflares-per-month.txt 50 totalflares-per-month-smoothed.svg
#git commit -am more && git push
