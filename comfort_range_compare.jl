using LinearAlgebra, JuMP, Gurobi, Plots

include("thermal_unit_data.jl")
include("get_weather_data.jl")

# Tout get the day ahead input or input you own temp ranges
Tout = temp_data

# Model where comfort level is ± 5ᵒC

m = Model(Gurobi.Optimizer)
# Decision variables
# Indoor temperature
@variable(m, T_indoor[1:time_period+1])
# Power consumed heating
@variable(m, Qin_heat[1:time_period]>=0)
# # Power consumed cooling
@variable(m, Qin_cool[1:time_period]>=0)
# Total cost of energy consumed
@objective(m, Min, sum(cost[i]*(η_heat*Qin_heat[i] + η_cool*Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
# Inital temperature assuming would be around 20
@constraint(m, T_indoor[1] == Tbase)
# # Indoor temp lower bound
@constraint(m, T_indoor .>= Tbase-comfort)
# # Indoor temp Upper bound
@constraint(m, T_indoor .<= Tbase+comfort)
# Thermal model of the house
@constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# # Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# # Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))



# # solve model
optimize!(m)

Cost5, T_in5, Qin_heat5, Qin_cool5 =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)

plot(T_in5, label="Indoor Temp")
plot!(Tout, label="Outdoor Temp")
hline!([Tbase-5*0.556], linestyle=:dash, label="Lower limt")
hline!([Tbase+5*0.556], linestyle=:dash, label="Upper limt")
hline!([Tbase], linestyle=:dash, title="Temperature vs Time for ± 5ᵒC", label="Set point ⁰C", xlabel="Hour of the Day", ylabel="Temperature (⁰C)")
savefig("plots\\temperature_profile_comfort_5.png")

plot(Qin_heat5*0.000277777778, label="Heating Power", color=:red)
plot!(Qin_cool5*0.000277777778, label="Cooling Power", color=:blue, title="HVAC power vs Time for ± 5ᵒC", xlabel="Hour of the Day", ylabel="HVAC Power (Watts)")
savefig("plots\\Power_profile_comfort_5.png")



# Model where comfort level is ± 0ᵒC

m = Model(Gurobi.Optimizer)
# Decision variables
# Indoor temperature
@variable(m, T_indoor[1:time_period+1])
# Power consumed heating
@variable(m, Qin_heat[1:time_period]>=0)
# # Power consumed cooling
@variable(m, Qin_cool[1:time_period]>=0)
# Total cost of energy consumed
@objective(m, Min, sum(cost[i]*(η_heat*Qin_heat[i] + η_cool*Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
# Inital temperature assuming would be around 20
@constraint(m, T_indoor[1] == Tbase)
# # Indoor temp lower bound
@constraint(m, T_indoor .>= Tbase)
# # Indoor temp Upper bound
@constraint(m, T_indoor .<= Tbase)
# Thermal model of the house
@constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# # Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# # Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
# # solve model
# write_to_file(m, "model.mps")
optimize!(m)

Cost, T_in, Qin_heat, Qin_cool =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)

plot(T_in, label="Indoor Temp")
plot!(Tout, label="Outdoor Temp")
hline!([Tbase], linestyle=:dash, title="Temperature vs Time for ± 0ᵒC", label="Set point ⁰C", xlabel="Hour of the Day", ylabel="Temperature (⁰C)")
savefig("plots\\temperature_profile_comfort_0.png")

plot(Qin_heat*0.000277777778, label="Heating Power", color=:red)
plot!(Qin_cool*0.000277777778, label="Cooling Power", color=:blue, title="HVAC power vs Time for ± 0ᵒC", xlabel="Hour of the Day", ylabel="HVAC Power (Watts)")
savefig("plots\\Power_profile_comfort_0.png")
