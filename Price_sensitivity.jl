using LinearAlgebra, JuMP, Gurobi, Plots

include("thermal_unit_data.jl")
include("get_weather_data.jl")

# Tout = temp_data_api
Tout = temp_data

comfort_range = [i*0.556 for i = 0:0.5:10]


function optimize_price(comfort_range)
    m = Model(Gurobi.Optimizer)
    # Indoor temperature
    @variable(m, T_indoor[1:time_period+1])
    # Power consumed heating
    @variable(m, Qin_heat[1:time_period]>=0)
    # # Power consumed cooling
    @variable(m, Qin_cool[1:time_period]>=0)
    # Total cost of energy consumed
    @objective(m, Min, sum(cost[i]*(Qin_heat[i] + Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
    # Inital temperature assuming would be around 20
    @constraint(m, T_indoor[1] == Tbase)
    # # Indoor temp lower bound
    @constraint(m, T_indoor .>= Tbase-comfort_range)
    # # Indoor temp Upper bound
    @constraint(m, T_indoor .<= Tbase+comfort_range)
    # Thermal model of the house
    @constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
    # # Energy from HVAC heating for the thermostat
    @constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
    # # Energy from HVAC cooling for the thermostat
    @constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))

    # Solve model
    optimize!(m)
    return objective_value(m)

end

cost_per_temp = zeros(length(comfort_range))

for i = 1:length(comfort_range)
    cost_per_temp[i] = optimize_price(comfort_range[i])
end

plot(comfort_range./0.556,cost_per_temp./100, title="Cost Sensitvity of HVAC Comfort Range", xlabel="Comfort level range (±ᵒF)", ylabel="Cost per day \$\$", legend = false)
savefig("plots\\Cost_sensitvity.png")

