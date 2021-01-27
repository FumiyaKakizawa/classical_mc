
set rmargin 5
set xr [10:100]
set yr [1e-2:0.5]
set log y
set xlabel "total sweeps"
set xlabel font "Alias,15"
set title "correlation function of afvc:J2=0.5,L=900"
set title font "Alias,15"

plot\
"afvc_14.dat" u 1:2 w lp t "T=0.865",\
"afvc_15.dat" u 1:2 w lp t "T=0.870",\
"afvc_16.dat" u 1:2 w lp t "T=0.875",\
"afvc_17.dat" u 1:2 w lp t "T=0.880",\
"afvc_18.dat" u 1:2 w lp t "T=0.885",\
"afvc_19.dat" u 1:2 w lp t "T=0.890",\
"afvc_20.dat" u 1:2 w lp t "T=0.895",\
"afvc_21.dat" u 1:2 w lp t "T=0.900"


pause -1
