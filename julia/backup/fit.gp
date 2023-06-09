
f(x) = a + b/(sqrt(x-c))
a=1e-2
b=1e-2
c=1e-2

fit f(x) "tau_Gt.dat" u 1:(log($2)) via a,b,c

plot \
"tau_Gt.dat" u 1:(log($2)) w lp,\
f(x)

pause -1
