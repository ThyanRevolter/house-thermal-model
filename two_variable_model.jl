using LinearAlgebra, JuMP, Clp, Plots

include("thermal_unit_data.jl")
include("get_weather_data.jl")

# Tout get the day ahead input or input you own temp ranges
Tout = temp_data

# this function plots the indoor and outdoor temperature with comfort range band
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


# hvac_optimizer gets input the comfort_range which is a list of size 24 which corresponds to the 
# changing comfort range change throught the day, power_upper_bound  is the maximum wattage possible
# Tout is the outdoor temperture range.
function hvac_optimizer(comfort_range, power_upper_bound, Tout)
    m = Model(Clp.Optimizer) 
    set_optimizer_attribute(m, "LogLevel", 0)
    # Decision variables
    # Indoor temperature
    @variable(m, T_indoor[1:time_period+1])
    # Power consumed heating
    @variable(m, Qin_heat[1:time_period]>=0)
    # Power consumed cooling
    @variable(m, Qin_cool[1:time_period]>=0)
    # Total cost of energy consumed
    @objective(m, Min, sum(cost[i]*(η_heat*Qin_heat[i] + η_cool*Qin_cool[i])*joule_watt*0.001 for i = 1:time_period))
    # Inital temperature
    @constraint(m, T_indoor[1] == Tbase)
    # Inital temperature
    @constraint(m, T_indoor[end] == Tbase)
    # Indoor temp lower bound
    @constraint(m, [i=1:time_period], T_indoor[i] .>= Tbase - comfort_range[i])
    # Indoor temp Upper bound
    @constraint(m, [i=1:time_period], T_indoor[i] .<= Tbase + comfort_range[i])
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



# this sweeps the comfort range from 0-5 F
comfort_range_range = [i*0.556 for i = 0:5]
# this sweeps the comfort range from 500 to 7000 watt in increments of 5
watt_ranges = [i for i = 500:5:7000]
# vector for storing the values
min_power_comfort = zeros(length(comfort_range_range))
min_load_price = zeros(length(comfort_range_range))
min_possible_price = zeros(length(comfort_range_range))

# find the feasible model and the corresponding parameter value for increasing comfort range and maximum wattage
counter = 0
for comfort_range in comfort_range_range
    global counter = counter + 1
    for watt in watt_ranges       
        status, objective_value, T_in, Qin_heat, Qin_cool = hvac_optimizer([comfort_range for i = 1:time_period], watt, Tout)
        if status
            plot_temp_profile_graph(T_in, Tout, Tbase, [comfort_range for i = 1:time_period], string("plots\\Temp_profile_",comfort_range/0.556,"_cmfrt"))
            plot_power_profile(Qin_heat,Qin_cool,string("plots\\Power_profile_",comfort_range/0.556,"_cmfrt") )
            min_load_price[counter] = objective_value
            inf_status, inf_objective_val, T_in, Qin_heat, Qin_cool = hvac_optimizer([comfort_range for i = 1:time_period], 99999999999999999, Tout)
            min_possible_price[counter] = inf_objective_val
            min_power_comfort[counter] = watt
            break;
        end        
    end    
end

# Printing the values
counter = 0
for comfort_range in comfort_range_range
    global counter = counter + 1
    println("Comfort Range (ᵒF): ", comfort_range/0.556, " Minimum peak load in Watt: ", min_power_comfort[counter])
    println("Minimum price for the load: " , min_load_price[counter])
    println("Minimum price possible for the comfort range: " , min_possible_price[counter])
    println()
end