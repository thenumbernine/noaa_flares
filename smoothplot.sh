#!/usr/bin/env bash
../smooth_graph/smooth_graph.lua totalflares-per-month.txt 50 totalflares-per-month-smoothed.svg dontusekeys=true
# dontusekeys because I need to not wrap them in quotes or something
# xtics=time "timefmt=%Y-%m" "format={x='%Y'}"
