using LinearAlgebra, JuMP, Clp, Plots, Ipopt, Gurobi

include("thermal_unit_data.jl")
include("get_weather_data.jl")
T_indoor = temp_data_api


m = Model(Clp.Optimizer)
# Decision variables
# Indoor temperature
@variable(m, T_indoor[1:time_period+1])
# Power consumed heating
@variable(m, Qin_heat[1:time_period]>=0)
# # Power consumed cooling
@variable(m, Qin_cool[1:time_period]>=0)

# Total cost of energy consumed
@objective(m, Min, sum(cost[i]*(Qin_heat[i] + Qin_cool[i])*0.000000277777778 for i = 1:time_period))
# Inital temperature
@constraint(m, T_indoor[1] == 20)
# # Indoor temp lower bound
@constraint(m, T_indoor .>= Tbase-5*0.556)
# # Indoor temp Upper bound
@constraint(m, T_indoor .<= Tbase+5*0.556)
# Thermal model of the house
@constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# # Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# # Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
# # solve model
optimize!(m)

Cost, T_in, Qin_heat, Qin_cool =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)


plot(T_in, label="Indoor Temp ⁰C")
plot!(Tout, label="Indoor Temp ⁰C")
hline!([Tbase-5*0.556], linestyle=:dash, label="Lower limt ⁰C")
hline!([Tbase+5*0.556], linestyle=:dash, label="Upper limt ⁰C")
hline!([Tbase], linestyle=:dash, label="Set point ⁰C")

plot(Qin_heat*0.000277777778, label="Heating Power")
plot!(Qin_cool*0.000277777778, label="Cooling Power")