using LinearAlgebra, JuMP, Clp, Plots

include("thermal_unit_data.jl")
include("get_weather_data.jl")
η_cool = 0.95
η_heat = 0.80
Tout = temp_data_api

# m = Model(Clp.Optimizer)
# # Decision variables
# # Indoor temperature
# @variable(m, T_indoor[1:time_period+1])
# # Power consumed heating
# @variable(m, Qin_heat[1:time_period]>=0)
# # # Power consumed cooling
# @variable(m, Qin_cool[1:time_period]>=0)
# # Total cost of energy consumed
# @objective(m, Min, sum(cost[i]*(Qin_heat[i] + Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
# # Inital temperature
# @constraint(m, T_indoor[1] == 20)
# # # Indoor temp lower bound
# @constraint(m, T_indoor .>= Tbase-comfort)
# # # Indoor temp Upper bound
# @constraint(m, T_indoor .<= Tbase+comfort)
# # Thermal model of the house
# @constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
# # # Energy from HVAC heating for the thermostat
# @constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
# # # Energy from HVAC cooling for the thermostat
# @constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
# # # Energy from HVAC heating for the thermostat
# @constraint(m, [t=1:time_period], Qin_heat[t]*joule_watt <= 1500)
# # # Energy from HVAC cooling for the thermostat
# @constraint(m, [t=1:time_period], Qin_cool[t]*joule_watt <= 1500)
# # # solve model
# optimize!(m)

# Cost, T_in, Qin_heat, Qin_cool =  objective_value(m), value.(T_indoor), value.(Qin_heat), value.(Qin_cool)

# plot(T_in, label="Indoor Temp")
# plot!(Tout, label="Outdoor Temp")
# hline!([Tbase-5*0.556], linestyle=:dash, label="Lower limt")
# hline!([Tbase+5*0.556], linestyle=:dash, label="Upper limt")
# hline!([Tbase], linestyle=:dash, title="Temperature vs Time for ± 5ᵒC", label="Set point ⁰C", xlabel="Hour of the Day", ylabel="Temperature (⁰C)")
# savefig("temperature_profile_comfort_5.png")

# plot(Qin_heat*0.000277777778, label="Heating Power")
# plot!(Qin_cool*0.000277777778, label="Cooling Power", title="HVAC power vs Time for ± 5ᵒC", xlabel="Hour of the Day", ylabel="HVAC Power (Watts)")
# savefig("Power_profile_comfort_5.png")


comfort_range_range = [i*0.556 for i = 0:5]
watt_ranges = [i for i = 500:10:7000]
Tchange_range = LinRange(0.01,5,40)

function hvac_optimizer(comfort_range, power_upper_bound, ΔTchange)
    m = Model(Clp.Optimizer)
    set_optimizer_attribute(m, "LogLevel", 0)
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
    @constraint(m, T_indoor .>= Tbase-comfort_range)
    # # Indoor temp Upper bound
    @constraint(m, T_indoor .<= Tbase+comfort_range)
    # Per hour temperature should not change more than ΔTchange temperature
    @constraint(m, [i=1:time_period], T_indoor[i+1] - T_indoor[i] <=  ΔTchange)
    # Per hour temperature should not change more than ΔTchange temperature
    @constraint(m, [i=1:time_period], T_indoor[i+1] - T_indoor[i] >=  -ΔTchange)
    # Thermal model of the house
    @constraint(m, [i=1:time_period], M*c*T_indoor[i+1] == M*c*T_indoor[i] + (Qin_heat[i] - Qin_cool[i] - (T_indoor[i] - Tout[i])/Req))
    # Energy from HVAC heating for the thermostat   
    @constraint(m, [t=1:time_period], Qin_heat[t] <= Mdot*c*(50 - T_indoor[t]))
    # # Energy from HVAC cooling for the thermostat
    @constraint(m, [t=1:time_period], Qin_cool[t] <= Mdot*c*(T_indoor[t] - 10))
    # # Energy from HVAC heating for the thermostat
    @constraint(m, [t=1:time_period], Qin_heat[t]*joule_watt <= η_heat*power_upper_bound)
    # # Energy from HVAC cooling for the thermostat
    @constraint(m, [t=1:time_period], Qin_cool[t]*joule_watt <= η_cool*power_upper_bound)
    # # solve model
    optimize!(m)
    if termination_status(m) == OPTIMAL
        Cost, T_in, Qin_heat_value, Qin_cool_value =  objective_value(m), value.(T_indoor)[1:end-1], value.(Qin_heat), value.(Qin_cool)
        return true, Cost, T_in, Qin_heat_value, Qin_cool_value
    else
        return false, 0
    end
end


min_power_comfort = zeros(length(comfort_range_range))
min_load_price = zeros(length(comfort_range_range))

min_power_comfort = zeros(length(comfort_range_range))
min_load_price = zeros(length(comfort_range_range))
counter = 0
for comfort_range in comfort_range_range
    global counter = counter + 1
    for watt in watt_ranges       
        status, objective_value, T_in, Qin_heat, Qin_cool = hvac_optimizer([comfort_range for i = 1:time_period], watt, Tout)
        if status
            plot_temp_profile_graph(T_in, Tout, Tbase, [comfort_range for i = 1:time_period], string("plots\\Temp_profile_",comfort_range/0.556,"_cmfrt"))
            plot_power_profile(Qin_heat,Qin_cool,string("plots\\Power_profile_",comfort_range/0.556,"_cmfrt") )
            min_load_price[counter] = objective_value
            println("Comfort Range: ", comfort_range/0.556, " Minimum peak load in Watt ", watt)
            println("Minimum price for the load " , objective_value)
            inf_status, inf_objective_val, T_in, Qin_heat, Qin_cool = hvac_optimizer([comfort_range for i = 1:time_period], 99999999999999999, Tout)
            println("Minimum price possible " , inf_objective_val)
            println()
            min_power_comfort[counter] = watt
            break;
        end        
    end    
end

# plot(comfort_range_range, min_power_comfort, label="Load", linecolor=:red)
# plot!(twinx(), comfort_range_range, min_load_price, label="Price", size=(1800/3,1000/3))
# savefig("Minimum price and minimum load.png")

plot(comfort_range_range, min_power_comfort, label="Load", linecolor=:red)
plot!(twinx(), comfort_range_range, min_load_price, label="Price", size=(1800/3,1000/3))
savefig("Minimum price and minimum load.png")