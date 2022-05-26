using LinearAlgebra, JuMP, Clp, Plots
include("thermal_model_matlab.jl")

on_peak = 20.448
mid_peak = 15.119
off_peak = 4.128

time_period = 24

cost = zeros(time_period)
cost[1:6] .= off_peak
cost[7:15] .= mid_peak
cost[16:20] .= on_peak
cost[21:24] .= off_peak
plot(cost, linetype=:steppre, ylims = (0,on_peak+1), xlabel="Hour of Day", ylabel="Cost ¢/Kwh", legend=false)

hvac_summer = [141.86477342, 132.60864012, 130.19934317, 137.10680433,
156.71479116, 201.35955563, 226.95572972, 218.40664651,
233.49045198, 252.89962132, 274.42608917, 321.39917324,
369.55676788, 426.87438347, 490.54312613, 553.79274378,
591.22108132, 588.98170654, 520.48118708, 420.48413995,
346.17063838, 264.96366629, 200.02642004, 161.11546989]



temp_data = [58.9, 58.5, 58.3, 57.7, 57. , 59.7, 65.2, 70.8, 75.6, 79.2, 81.5,
83. , 83.6, 82.7, 81.5, 81 , 78.1, 74.3, 69.6, 65.5, 62.7, 60.5,
59.3, 58.7] 

plot(hvac_summer*3.6)

t_set = 70
t_initial = 70

home_temp = zeros(time_period+1)
home_temp[1] = t_initial
heat_needed = zeros(time_period)

heat_loss = zeros(time_period)

for i = 1:time_period
    heat_loss[i] = (70 - temp_data[i])/Req
end

plot(heat_loss*0.000000277777778)

