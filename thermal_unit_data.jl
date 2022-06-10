using LinearAlgebra

time_period = 24

# efficiency
η_cool = 0.95
η_heat = 0.80

# electricity price
on_peak = 20.448
mid_peak = 15.119
off_peak = 4.128
cost = zeros(time_period)
cost[1:6] .= off_peak
cost[7:15] .= mid_peak
cost[16:20] .= on_peak
cost[21:24] .= off_peak
C2F = 0.5556

# temp data simulated
temp_data = [58.9, 58.5, 58.3, 57.7, 57. , 59.7, 65.2, 70.8, 75.6, 79.2, 81.5,
83. , 83.6, 82.7, 81.5, 81 , 78.1, 74.3, 69.6, 65.5, 62.7, 60.5,
59.3, 58.7] 

# converting F to C of temp_data
temp_data = (temp_data .- 32)*C2F

# conversion factor Joule/hr to watts
joule_watt = 0.000277777778
Tbase = 21

# Heating efficiency
heat_coeff = 0.80

# cooling efficiency
cool_coeff = 0.70

# comfort range
comfort = 5*C2F
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