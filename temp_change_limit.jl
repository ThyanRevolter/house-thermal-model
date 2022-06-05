using LinearAlgebra, JuMP, Clp, Plots
include("thermal_unit_data.jl")
include("get_weather_data.jl")
Tout = temp_data_api
ΔTchange = 1
η_cool = 0.95
η_heat = 0.80
m = Model(Clp.Optimizer)
# Decision variables
# Indoor temperature
@variable(m, T_indoor[1:time_period+1])
# Power consumed heating
@variable(m, Qin_heat[1:time_period]>=0)
# # Power consumed cooling
@variable(m, Qin_cool[1:time_period]>=0)
# Total cost of energy consumed
@objective(m, Min, sum(cost[i]*(Qin_heat[i] + Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
# Inital temperature
@constraint(m, T_indoor[1] == Tbase)
# # Indoor temp lower bound
@constraint(m, T_indoor .>= Tbase-comfort)
# # Indoor temp Upper bound
@constraint(m, T_indoor .<= Tbase+comfort)
# Thermal model of the house
@constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# Per hour temperature should not change more than ΔTchange temperature
@constraint(m, [i=1:time_period],T_indoor[i+1] - T_indoor[i] <=  1)
# Per hour temperature should not change more than ΔTchange temperature7
@constraint(m, [i=1:time_period],T_indoor[i+1] - T_indoor[i] >=  -1)
# # Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# # Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
# # Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t]*joule_watt <= η_heat*99999)
# # Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t]*joule_watt <= η_cool*99999)
# # solve model
optimize!(m)

Cost, T_in, Qin_heat, Qin_cool =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)

plot(T_in, label="Indoor Temp")
plot!(Tout, label="Outdoor Temp")
hline!([Tbase-5*0.556], linestyle=:dash, label="Lower limt")
hline!([Tbase+5*0.556], linestyle=:dash, label="Upper limt")
hline!([Tbase], linestyle=:dash, title="Temperature vs Time for ± 5ᵒC",legend=:bottomright, label="Set point ⁰C", xlabel="Hour of the Day", ylabel="Temperature (⁰C)")
savefig("temperature_profile_comfort_5.png")

plot(Qin_heat*0.000277777778, label="Heating Power")
plot!(Qin_cool*0.000277777778, label="Cooling Power", title="HVAC power vs Time for ± 5ᵒC", xlabel="Hour of the Day", ylabel="HVAC Power (Watts)")
savefig("Power_profile_comfort_5.png")

# minimum(T_in[2:end] - T_in[1:end-1])