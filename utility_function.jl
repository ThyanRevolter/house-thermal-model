using LinearAlgebra, JuMP, Clp, Plots, Gurobi

include("thermal_unit_data.jl")
include("get_weather_data.jl")
Tout = temp_data

function plot_temp_profile_graph(T_in, Tout, Tbase, comfort_range, title)
    plot(T_in, label="Indoor Temp")
    plot!(Tout, label="Outdoor Temp")
    plot!([Tbase - comfort_range[i] for i =1:time_period], label="Lower Limit", linestyle=:dash)
    plot!([Tbase + comfort_range[i] for i =1:time_period], label="Upper Limit", linestyle=:dash)
    hline!([Tbase], linestyle=:dash, title="Temperature vs Time", label="Set point ⁰C", xlabel="Hour of the Day", ylabel="Temperature (⁰C)")
    savefig(title*".png")  
end

# this fucntion saves the heating and cooling power profile throughout the day
function plot_power_profile(Qin_heat,Qin_cool,title)
    plot(Qin_heat*0.000277777778, label="Heating Power")
    plot!(Qin_cool*0.000277777778, label="Cooling Power", title="HVAC power vs Time for ± 5ᵒC", xlabel="Hour of the Day", ylabel="HVAC Power (Watts)")
    savefig(title*".png")
end

function hvac_optimizer_utility(τ,α, power_upper_bound, Tout)
    m = Model(Gurobi.Optimizer) 
    # Decision variables
    # Indoor temperature
    @variable(m, T_indoor[1:time_period+1])
    # Power consumed heating
    @variable(m, Qin_heat[1:time_period]>=0)
    # Power consumed cooling
    @variable(m, Qin_cool[1:time_period]>=0)
    # Total cost of energy consumed
    @objective(m, Min, sum(cost[i]*(η_heat*Qin_heat[i] + η_cool*Qin_cool[i])*joule_watt*0.001  + τ*(T_indoor[i] - Tbase)^(α) for i = 1:time_period))
    # Inital temperature
    @constraint(m, T_indoor[1] == Tbase)
    # Inital temperature
    @constraint(m, T_indoor[end] == Tbase)
    # Thermal model of the house
    @constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
    # Energy from HVAC heating for the thermostat
    @constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
    # Energy from HVAC cooling for the thermostat
    @constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
    # Energy from HVAC heating for the thermostat
    @constraint(m, [t=1:time_period], Qin_heat[t]*joule_watt <= η_heat*power_upper_bound)
    # Energy from HVAC cooling for the thermostat
    @constraint(m, [t=1:time_period], Qin_cool[t]*joule_watt <= η_cool*power_upper_bound)
    # solve model
    optimize!(m)
    if termination_status(m) == OPTIMAL
        Cost, T_in, Qin_heat_value, Qin_cool_value =  objective_value(m), value.(T_indoor)[1:end-1], value.(Qin_heat), value.(Qin_cool)
        return true, Cost, T_in, Qin_heat_value, Qin_cool_value
    else
        return false, 0, [0 for i =1:time_period], [0 for i =1:time_period], [0 for i =1:time_period]
    end
end

stat, objective_val, T_in, Qin_heat, Qin_cool = hvac_optimizer_utility(1, 2, 99999, Tout)
plot_temp_profile_graph(T_in, Tout, Tbase, [0 for i = 1:time_period], string("plots\\Temp_profile_alpha_1_cmfrt"))
plot_power_profile(Qin_heat,Qin_cool,string("plots\\Power_profile_alpha_1_cmfrt"))