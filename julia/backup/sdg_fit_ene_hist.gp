set title "Fitting for energy histogram at J2/J1=-0.07, L=72"
set xlabel "Energy"
set ylabel "Count"

sg(x) = sh1*exp(-((x-sc1)/sw1)**2 + sa1*((x-sc1)/sw1)**3 + sb1*((x-sc1)/sw1)**4) 

sh1 = 1.0
sc1 = -0.905
sw1 = 0.005
sa1 = 1e-3
sb1 = 1e-5

fit sg(x) "ene_hist_27.txt" u 1:($2/25000) via sh1, sc1, sw1, sa1, sb1

dg(x) = h1*exp(-((x-c1)/w1)**2 + a1*((x-c1)/w1)**3 + b1*((x-c1)/w1)**4) + h2*exp(-((x-c2)/w2)**2 + a2*((x-c2)/w2)**3 + b2*((x-c2)/w2)**4)

h1 = 1.0
c1 = -0.905
w1 = 0.005
a1 = 1e-3
b1 = 1e-5

h2 = 0.6
c2 = -0.89
w2 = 0.005
a2 = 1e-3
b2 = 1e-5

fit dg(x) "ene_hist_27.txt" u 1:($2/25000) via h1, c1, w1, h2, c2, w2, a1, a2, b1, b2

plot\
"ene_hist_27.txt" u 1:($2/25000) w lp,\
sg(x) w l t "Single Gaussian",\
dg(x) w l t "Double Gaussian"

pause -1
