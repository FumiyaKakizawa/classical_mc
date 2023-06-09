
set rmargin 5
set xr [30:60]
set yr [1e-2:1.0]
set log y
set xlabel "total sweeps"
set xlabel font "Alias,15"
set title "correlation function of mq_sqrt3:J2=0.5,L=900"
set title font "Alias,15"

plot\
"mq_sqrt3_13.dat" u 1:2 w lp t "T=0.860",\
"mq_sqrt3_14.dat" u 1:2 w lp t "T=0.865",\
"mq_sqrt3_15.dat" u 1:2 w lp t "T=0.870",\
"mq_sqrt3_16.dat" u 1:2 w lp t "T=0.875",\
"mq_sqrt3_17.dat" u 1:2 w lp t "T=0.880",\
"mq_sqrt3_18.dat" u 1:2 w lp t "T=0.885",\
"mq_sqrt3_19.dat" u 1:2 w lp t "T=0.890",\
"mq_sqrt3_20.dat" u 1:2 w lp t "T=0.895",\
"mq_sqrt3_21.dat" u 1:2 w lp t "T=0.900"


pause -1
