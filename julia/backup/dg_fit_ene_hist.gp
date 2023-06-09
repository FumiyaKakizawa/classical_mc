set title "Fitting for energy histogram"
set xlabel "Energy"
set ylabel "Count"

g(x) = h1*exp(-((x-c1)/w1)**2 + a1*((x-c1)/w1)**3 + b1*((x-c1)/w1)**4) + h2*exp(-((x-c2)/w2)**2 + a2*((x-c2)/w2)**3 + b2*((x-c2)/w2)**4)

h1 = 1.0
c1 = -0.965
w1 = 0.01
a1 = 1e-3
b1 = 1e-5

h2 = 1.0
c2 = -0.9525
w2 = 0.01
a2 = 1e-3
b2 = 1e-5

fit g(x) "ene_hist_19.txt" u 1:($2/200000) via h1, c1, w1, h2, c2, w2, a1, a2, b1, b2

plot\
"ene_hist_19.txt" u 1:($2/200000) w lp,\
g(x) w l

pause -1
