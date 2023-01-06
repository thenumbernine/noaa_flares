#!/usr/bin/env gnuplot
set terminal svg size 1024,768 background rgb "white"

max(a,b) = a > b ? a : b

fn = "flares-per-type-per-year.txt"
set style data linespoints
set output "flares-per-type-per-year.svg"
set xlabel "year"
set ylabel "count"
set log y
plot [1975:2023]\
	fn using 1:(max($2,.1)) title "A" linecolor rgb "blue",\
	fn using 1:(max($3,.1)) title "B" linecolor rgb "cyan",\
	fn using 1:(max($4,.1)) title "C" linecolor rgb "green",\
	fn using 1:(max($5,.1)) title "M" linecolor rgb "orange",\
	fn using 1:(max($6,.1)) title "X" linecolor rgb "red"
unset log y

fn = "flares-per-type-per-month.txt"
set style data linespoints
set output "flares-per-type-per-month.svg"
set xlabel "year+month"
set ylabel "count"
set xdata time
set timefmt "%Y-%m"
set format x "%Y" 
set log y
plot \
	fn using 1:(max($2,.1)) title "A" linecolor rgb "blue" pointtype 5 pointsize .3,\
	fn using 1:(max($3,.1)) title "B" linecolor rgb "cyan" pointtype 5 pointsize .3,\
	fn using 1:(max($4,.1)) title "C" linecolor rgb "green" pointtype 5 pointsize .3,\
	fn using 1:(max($5,.1)) title "M" linecolor rgb "orange" pointtype 5 pointsize .3,\
	fn using 1:(max($6,.1)) title "X" linecolor rgb "red" pointtype 5 pointsize .3
unset log y

fn = "totalflares-per-month.txt"
set style data linespoints
set output "totalflares-per-month.svg"
set xlabel "year+month"
set ylabel "count"
set xdata time
set timefmt "%Y-%m"
set format x "%Y" 
plot fn using 1:2 notitle
