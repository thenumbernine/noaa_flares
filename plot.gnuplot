#!/usr/bin/env gnuplot
set terminal svg size 1024,768 background rgb "white"
set output "flares.svg"
set style data linespoints
set xlabel "year"
set ylabel "count"
set log y
fn = "flares.txt"
plot [1975:2021]\
	fn using 1:2 title "A" linecolor rgb "blue",\
	fn using 1:3 title "B" linecolor rgb "cyan",\
	fn using 1:4 title "C" linecolor rgb "green",\
	fn using 1:5 title "M" linecolor rgb "orange",\
	fn using 1:6 title "X" linecolor rgb "red"
