
set rmargin 5
set xlabel "temperature"
set xlabel font "Alias,15"
set ylabel "logarithm of relaxation time"
set ylabel font "Alias,15"
set title font "Alias,12"
set title "relaxation time of dynamical correlation function of mq_sqrt3:J2=0.5,L=900"

f(x) = a + b/sqrt(x-c)
a=1e0
b=1e0
c=1e-1

fit f(x) "mq_sqrt3_tau.dat" u 1:(log($2)) via a,b,c

plot \
"mq_sqrt3_tau.dat" u 1:(log($2)) w lp t "neumerical data",\
f(x) t "fitting curve"

pause -1
