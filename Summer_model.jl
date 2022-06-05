using LinearAlgebra, JuMP, Clp, Plots, Ipopt

include("thermal_unit_data.jl")
include("get_weather_data.jl")

function optimize_hvac_power(comfort_range)
    # Build optimization model
    m = Model(Ipopt.Optimizer)
    set_optimizer_attribute(m, "max_iter", 6000)
    set_optimizer_attribute(m, "print_level", 0)
    # Decision variables
    # Indoor temperature
    @variable(m, T_indoor[1:time_period+1])
    # Power consumed
    @variable(m, Qin[1:time_period]>=0)
    # Set temperature
    # @variable(m, Ts[1:time_period]>=0)
    # Total cost of energy consumed
    @objective(m, Min, sum(cost[i]*Qin[i]/1000 for i = 1:time_period))
    # Inital temperature
    @constraint(m, T_indoor[1] == 20)
    # Indoor temp lower bound
    @constraint(m, T_indoor .>= 20-comfort_range)
    # Indoor temp Upper bound
    @constraint(m, T_indoor .<= 20+comfort_range)
    # Thermal model of the house
    @NLconstraint(m, [i=1:time_period], T_indoor[i+1] == T_indoor[i] + (1/(M*c))*(Qin[i] - (T_indoor[i] - Tout[i])/Req))
    # Energy from HVAC for the thermostat
    @NLconstraint(m, [t=1:time_period-1], Qin[t] == Mdot*c*(50 - T_indoor[t]))
    # solve model
    optimize!(m)
    return objective_value(m), value.(T_indoor), value.(Qin)
end



# # Build optimization model
# m = Model(Ipopt.Optimizer)
# set_optimizer_attribute(m, "max_iter", 6000)
# set_optimizer_attribute(m, "print_level", 0)

# # Decision variables
# # Indoor temperature
# @variable(m, T_indoor[1:time_period])
# # Power consumed
# @variable(m, Qin[1:time_period]>=0)
# # Set temperature
# @variable(m, Ts[1:time_period]>=0)

# # Total cost of energy consumed
# @objective(m, Min, sum(cost[i]*Qin[i]/1000 for i = 1:time_period))

# @constraint(m, T_indoor[1] == 20)
# @constraint(m, T_indoor[end] == 20)
# @constraint(m, Ts .>= 20-5*0.556)
# @constraint(m, Ts .<= 20+5*0.556)
# @NLconstraint(m, [i=1:time_period-1], T_indoor[i+1] == T_indoor[i] + Qin[i]*3600 - (1/(M*c))*((T_indoor[i] - Tout[i])/Req))
# @constraint(m, Qin[1] == 0)
# @NLconstraint(m, [t=1:time_period-1], Qin[t] == mdot*c*abs(Ts[t] - T_indoor[t]))
# # solve model
# optimize!(m)
# Cost = objective_value(m)
# T_in = value.(T_indoor)
# Q_in = value.(Qin)
# Ts = value.(Ts)

Cost, T_in, Q_in = optimize_hvac_power(5*0.556)

# plot(hcat(T_in, Tout), layout = (2,1))
plot(T_in, label = "T_indoor")
plot!(Tout, label = "T_outdoor")
# plot!(Ts, label = "Set temperature")
hline!([20-5*0.556], linestyle=:dash)
hline!([20+5*0.556], linestyle=:dash)
hline!([20], linestyle=:dash)
savefig("temp_plot.png")
plot(Q_in)
savefig("Qout.png")
