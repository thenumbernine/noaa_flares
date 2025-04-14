#!/usr/bin/env gnuplot
set terminal svg size 1024,768 background rgb "white"

max(a,b) = a > b ? a : b

mytimefmt = "%Y-%m"
time_Ym(s) = strptime(mytimefmt, s)

now = time(0)	# seconds since 1970
year = tm_year(now)		# year
month = tm_mon(now)+1	# month ... tm_mon returns [0,11], unlike time/date format which takes [1,12] ... hmmmmm
print(sprintf("now %d", now))
print(sprintf("year %d", year))
print(sprintf("month %d", month))
print(sprintf("current year/month date %04d-%02d", year, month))

fn = "flares-per-type-per-year.txt"
set style data linespoints
set output "flares-per-type-per-year.svg"
set xlabel "year"
set ylabel "count"
set log y
set xrange [1975:year]
plot \
	fn using 1:(max($2,.1)) title "A" linecolor rgb "blue",\
	fn using 1:(max($3,.1)) title "B" linecolor rgb "cyan",\
	fn using 1:(max($4,.1)) title "C" linecolor rgb "green",\
	fn using 1:(max($5,.1)) title "M" linecolor rgb "orange",\
	fn using 1:(max($6,.1)) title "X" linecolor rgb "red"
unset log y
unset xrange

set terminal svg size 2048,768 background rgb "white"

fn = "flares-per-type-per-month.txt"
set style data lines
set output "flares-per-type-per-month.svg"
set xlabel "year+month"
set ylabel "count"
set xtics time
set timefmt mytimefmt
set format x "%Y"
set xrange [time_Ym("1976-01"):time_Ym(sprintf("%04d-%02d", year, month))]
set log y
plot fn using (timecolumn(1)):(max($2,.1)):(0) title "A" linecolor rgb "blue" with filledcurves,\
	fn using (timecolumn(1)):(max($3,.1)):(0) title "B" linecolor rgb "cyan" with filledcurves,\
	fn using (timecolumn(1)):(max($4,.1)):(0) title "C" linecolor rgb "green" with filledcurves,\
	fn using (timecolumn(1)):(max($5,.1)):(0) title "M" linecolor rgb "orange" with filledcurves,\
	fn using (timecolumn(1)):(max($6,.1)):(0) title "X" linecolor rgb "red" with filledcurves
unset log y

fn = "totalflares-per-month.txt"
set style data linespoints
set output "totalflares-per-month.svg"
set xlabel "year+month"
set ylabel "count"
set xtics time
set timefmt "%Y-%m"
set format x "%Y" 
plot fn using (timecolumn(1)):2 notitle

fn = "flares-per-type-per-moon-day.txt"
set style data lines
set output "flares-per-type-per-moon-day.svg"
set xlabel "moon phase day"
set ylabel "count"
unset timefmt
unset format x
set xtics 1
unset xrange
set log y
plot fn using 1:(max($2,.1)):(0) title "A" linecolor rgb "blue" with filledcurves,\
	fn using 1:(max($3,.1)):(0) title "B" linecolor rgb "cyan" with filledcurves,\
	fn using 1:(max($4,.1)):(0) title "C" linecolor rgb "green" with filledcurves,\
	fn using 1:(max($5,.1)):(0) title "M" linecolor rgb "orange" with filledcurves,\
	fn using 1:(max($6,.1)):(0) title "X" linecolor rgb "red" with filledcurves
unset log y
