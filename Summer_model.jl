using LinearAlgebra, JuMP, Clp, Plots, Ipopt

include("thermal_unit_data.jl")
include("get_weather_data.jl")
Tout = temp_data



# Build optimization model
m = Model(Ipopt.Optimizer)
set_optimizer_attribute(m, "max_iter", 6000)
set_optimizer_attribute(m, "print_level", 0)

# Decision variables
# Indoor temperature
@variable(m, T_indoor[1:time_period])
# Power consumed
@variable(m, Qin[1:time_period]>=0)
# Set temperature
@variable(m, Ts[1:time_period]>=0)

# Total cost of energy consumed
@objective(m, Min, sum(cost[i]*Qin[i]/1000 for i = 1:time_period))

@constraint(m, T_indoor[1] == 20)
@constraint(m, T_indoor[end] == 20)
@constraint(m, Ts .>= 20-5*0.556)
@constraint(m, Ts .<= 20+5*0.556)
@NLconstraint(m, [i=1:time_period-1], T_indoor[i+1] == T_indoor[i] + Qin[i]*3600 - (1/(M*c))*((T_indoor[i] - Tout[i])/Req))
@constraint(m, Qin[1] == 0)
@NLconstraint(m, [t=1:time_period-1], Qin[t] == mdot*c*abs(Ts[t] - T_indoor[t]))



# solve model
optimize!(m)



Cost = objective_value(m)
T_in = value.(T_indoor)
Q_in = value.(Qin)
Ts = value.(Ts)

plot(hcat(T_in, Tout), layout = (2,1))

plot(T_in, label = "T_indoor")
plot!(Tout, label = "T_outdoor")
plot!(Ts, label = "Set temperature")
hline!([20-5*0.556], linestyle=:dash)
hline!([20+5*0.556], linestyle=:dash)
hline!([20], linestyle=:dash)
plot(Q_in)
plot(Ts, label = "Set temperature")
