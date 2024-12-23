using LinearAlgebra, JuMP, Clp, Plots, Ipopt


time_period = 24

# electricity price
on_peak = 20.448
mid_peak = 15.119
off_peak = 4.128
cost = zeros(time_period)
cost[1:6] .= off_peak
cost[7:15] .= mid_peak
cost[16:20] .= on_peak
cost[21:24] .= off_peak

# Data
hvac_summer = [141.86477342, 132.60864012, 130.19934317, 137.10680433,
156.71479116, 201.35955563, 226.95572972, 218.40664651,
233.49045198, 252.89962132, 274.42608917, 321.39917324,
369.55676788, 426.87438347, 490.54312613, 553.79274378,
591.22108132, 588.98170654, 520.48118708, 420.48413995,
346.17063838, 264.96366629, 200.02642004, 161.11546989]

# temp data
temp_data = [58.9, 58.5, 58.3, 57.7, 57. , 59.7, 65.2, 70.8, 75.6, 79.2, 81.5,
83. , 83.6, 82.7, 81.5, 81 , 78.1, 74.3, 69.6, 65.5, 62.7, 60.5,
59.3, 58.7] 
Tout = (temp_data .- 32)*0.5556

# Thermal constant
# -------------------------------
# converst radians to degrees
r2d = 180/pi;
# -------------------------------
# Define the house geometry
# House length = 30 m
lenHouse = 40;
# House width = 10 m
widHouse = 20 ;
# House height = 4 m
htHouse = 8;
# Roof pitch = 40 deg
pitRoof = 40/r2d;
# Number of windows = 2
numWindows = 2;
# Height of windows = 1 m
htWindows = 1;
# Width of windows = 1 m
widWindows = 1;
windowArea = numWindows*htWindows*widWindows;
wallArea = 2*lenHouse*htHouse + 2*widHouse*htHouse + 2*(1/cos(pitRoof/2))*widHouse*lenHouse + tan(pitRoof)*widHouse - windowArea;
# Define the type of insulation used
# -------------------------------
# Glass wool in the walls, 0.4 m thick
# k is in units of J/sec/m/C - convert to J/hr/m/C multiplying by 3600
kWall = 0.038*3600;   # hour is the time unit
LWall = .4;
RWall = LWall/(kWall*wallArea);
# Glass windows, 0.01 m thick
kWindow = 0.78*3600;  # hour is the time unit
LWindow = .01;
RWindow = LWindow/(kWindow*windowArea);
# -------------------------------
# Determine the equivalent thermal resistance for the whole building
# -------------------------------
Req = RWall*RWindow/(RWall + RWindow);
# c = cp of air (273 K) = 1005.4 J/kg-K
c = 1005.4;
# -------------------------------
# The air exiting the heater has a constant temperature which is a heater
# property. THeater = 50 deg C
THeater = 50;
# Air flow rate Mdot = 1 kg/sec = 3600 kg/hr
Mdot = 3600;  # hour is the time unit
# -------------------------------
# Determine total internal air mass = M
# Density of air at sea level = 1.2250 kg/m^3
densAir = 1.2250;
M = (lenHouse*widHouse*htHouse+tan(pitRoof)*widHouse*lenHouse)*densAir;
# -------------------------------
mdot = 1

# Build optimization model
m = Model(Ipopt.Optimizer)

# Decision variables
@variable(m, T_indoor[1:time_period])
@variable(m, Qin[1:time_period])
@variable(m, Ts[1:time_period]>=0)


@NLobjective(m, Min, sum(cost[i]*abs(Qin[i]/1000) for i = 1:time_period))

Tbase = 21
deltaT = 0.556*4
@constraint(m, T_indoor[1] == Tbase)
@constraint(m, T_indoor[end] == Tbase)
@constraint(m, T_indoor .>= Tbase -deltaT)
@constraint(m, T_indoor .<= Tbase +deltaT)
# @constraint(m, Ts .== 20)C
# @constraint(m, Qin[1] == 0)
# @constraint(m, Qin[end] == Qin[1])

@NLconstraint(m, [i=1:time_period-1], T_indoor[i+1] == T_indoor[i] + (1/(M*c))*((Qin[i])*3600 - (T_indoor[i] - Tout[i])/(Req)))
@NLconstraint(m, [t=1:time_period], Qin[t] == mdot*c*(Ts[t] - T_indoor[t]))




# solve model
optimize!(m)
Cost = objective_value(m)
println("Cost=", (Cost)) 


T_in = value.(T_indoor)
Q_in = abs.(value.(Qin))
Ts = value.(Ts)

# plot(hcat(T_in, (Q_in[1:end])), layout = (2,1))
plot(T_in)
plot!(Tout)
plot!(Ts)
hline!([Tbase-5*0.556], linestyle=:dash)
hline!([Tbase+5*0.556], linestyle=:dash)
hline!([Tbase], linestyle=:dash)

plot(Q_in[1:end])
# savefig("Power.png")

