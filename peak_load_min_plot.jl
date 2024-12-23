using LinearAlgebra, JuMP, Gurobi, Plots

include("thermal_unit_data.jl")
include("get_weather_data.jl")

# Tout get the day ahead input or input you own temp ranges
Tout = temp_data

comfort = 5*0.556

# upper limit value from two_variable_model code
power_upper_bound = 1655
# Model where comfort level is ± 5ᵒC
m = Model(Gurobi.Optimizer)
# Decision variables
# Indoor temperature
@variable(m, T_indoor[1:time_period+1])
# Power consumed heating
@variable(m, Qin_heat[1:time_period]>=0)
# Power consumed cooling
@variable(m, Qin_cool[1:time_period]>=0)
# Total cost of energy consumed
@objective(m, Min, sum(cost[i]*(η_heat*Qin_heat[i] + η_cool*Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
# Inital temperature assuming would be around 20
@constraint(m, T_indoor[1] == Tbase)
# Indoor temp lower bound
@constraint(m, T_indoor .>= Tbase-comfort)
# Indoor temp Upper bound
@constraint(m, T_indoor .<= Tbase+comfort)
# Thermal model of the house
@constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))

@constraint(m, [t=1:time_period], Qin_heat[t]*joule_watt <= η_heat*power_upper_bound)
# Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t]*joule_watt <= η_cool*power_upper_bound)


# solve model
optimize!(m)

Cost_min, T_in_min, Qin_heat_min, Qin_cool_min =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)


# Model without upper limit
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
# Indoor temp lower bound
@constraint(m, T_indoor .>= Tbase-comfort)
# Indoor temp Upper bound
@constraint(m, T_indoor .<= Tbase+comfort)
# Thermal model of the house
@constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# Energy from HVAC heating for the thermostat
@constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# Energy from HVAC cooling for the thermostat
@constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
# solve model
optimize!(m)
Cost5, T_in5, Qin_heat5, Qin_cool5 =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)


# Plotting both optimal and peak minimized load profile
plot(Qin_heat5*0.000277777778, label="Heating Power - Optimal", color=:orange)
plot!(Qin_cool5*0.000277777778, label="Cooling Power - Optimal", color=:Cyan)
plot!(Qin_heat_min*0.000277777778, label="Heating Power - Min Peak", color=:red)
plot!(Qin_cool_min*0.000277777778, label="Cooling Power - Min Peak", color=:blue, legend=:topleft, title="HVAC power vs Time for ± 5ᵒC", xlabel="Hour of the Day", ylabel="HVAC Power (Watts)")
savefig("plots\\Peak_minimized_comfort_5.png")
