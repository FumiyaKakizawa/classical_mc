
set rmargin 5
set xr [30:60]
set yr [1e-2:0.5]
set log y
set xlabel "total sweeps"
set xlabel font "Alias,15"
set title "correlation function of mq_sqrt3:J2=0.5,L=900"
set title font "Alias,15"

plot\
"mq_sqrt3_w_fc_13.dat" u 1:2 w p t "T=0.860",\
"mq_sqrt3_w_fc_13.dat" u 1:3 w l t "T=0.860",\
"mq_sqrt3_w_fc_14.dat" u 1:2 w p t "T=0.865",\
"mq_sqrt3_w_fc_14.dat" u 1:3 w l t "T=0.865",\
"mq_sqrt3_w_fc_15.dat" u 1:2 w p t "T=0.870",\
"mq_sqrt3_w_fc_15.dat" u 1:3 w l t "T=0.870",\
"mq_sqrt3_w_fc_16.dat" u 1:2 w p t "T=0.875",\
"mq_sqrt3_w_fc_16.dat" u 1:3 w l t "T=0.875",\
"mq_sqrt3_w_fc_17.dat" u 1:2 w p t "T=0.880",\
"mq_sqrt3_w_fc_17.dat" u 1:3 w l t "T=0.880",\
"mq_sqrt3_w_fc_18.dat" u 1:2 w p t "T=0.885",\
"mq_sqrt3_w_fc_18.dat" u 1:3 w l t "T=0.885",\
"mq_sqrt3_w_fc_19.dat" u 1:2 w p t "T=0.890",\
"mq_sqrt3_w_fc_19.dat" u 1:3 w l t "T=0.890",\
"mq_sqrt3_w_fc_20.dat" u 1:2 w p t "T=0.895",\
"mq_sqrt3_w_fc_20.dat" u 1:3 w l t "T=0.895",\
"mq_sqrt3_w_fc_21.dat" u 1:2 w p t "T=0.900",\
"mq_sqrt3_w_fc_21.dat" u 1:3 w l t "T=0.900"


pause -1
