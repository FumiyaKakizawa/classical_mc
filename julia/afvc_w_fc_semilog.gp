
set rmargin 5
set xr [30:60]
set yr [1e-2:0.5]
set log y
set xlabel "total sweeps"
set xlabel font "Alias,15"
set title "correlation function of afvc:J2=0.5,L=900"
set title font "Alias,15"

plot\
"afvc_w_fc_13.dat" u 1:2 w p t "T=0.860",\
"afvc_w_fc_13.dat" u 1:3 w l t "T=0.860",\
"afvc_w_fc_14.dat" u 1:2 w p t "T=0.865",\
"afvc_w_fc_14.dat" u 1:3 w l t "T=0.865",\
"afvc_w_fc_15.dat" u 1:2 w p t "T=0.870",\
"afvc_w_fc_15.dat" u 1:3 w l t "T=0.870",\
"afvc_w_fc_16.dat" u 1:2 w p t "T=0.875",\
"afvc_w_fc_16.dat" u 1:3 w l t "T=0.875",\
"afvc_w_fc_17.dat" u 1:2 w p t "T=0.880",\
"afvc_w_fc_17.dat" u 1:3 w l t "T=0.880",\
"afvc_w_fc_18.dat" u 1:2 w p t "T=0.885",\
"afvc_w_fc_18.dat" u 1:3 w l t "T=0.885",\
"afvc_w_fc_19.dat" u 1:2 w p t "T=0.890",\
"afvc_w_fc_19.dat" u 1:3 w l t "T=0.890",\
"afvc_w_fc_20.dat" u 1:2 w p t "T=0.895",\
"afvc_w_fc_20.dat" u 1:3 w l t "T=0.895",\
"afvc_w_fc_21.dat" u 1:2 w p t "T=0.900",\
"afvc_w_fc_21.dat" u 1:3 w l t "T=0.900"


pause -1
