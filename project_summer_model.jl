using LinearAlgebra, JuMP, Clp, Plots, Ipopt

include("project_rev1.jl")

temp_data = (temp_data .- 32)*0.5556

temp_diff = ([i for i = 1:0.5:5])*0.556

function optimize_price(temp_diff)
    m = Model(Ipopt.Optimizer)
    set_optimizer_attribute(m, "max_iter", 6000)
    set_optimizer_attribute(m, "print_level", 0)
    
    @variable(m, T_indoor[1:time_period])
    @variable(m, Qin[1:time_period]>=0)
    
    @objective(m, Min, sum(cost[i]*Qin[i] for i = 1:time_period))
    
    @constraint(m, T_indoor[1] == 21.1)
    @constraint(m, T_indoor[time_period] == 21.1)
    @constraint(m, T_indoor .<= 21.1 + temp_diff )
    @constraint(m, T_indoor .>= 21.1 - temp_diff)
    
    for i = 1:time_period-1
        @NLconstraint(m, M*c*(T_indoor[i+1] - T_indoor[i]) == Qin[i]*3600000 -  (T_indoor[i] - temp_data[i])/Req)
    end    
    optimize!(m)
    plot(hcat(value.(Qin),value.(T_indoor),temp_data), layout = (3,1), label=string("temp diff", temp_diff))
    savefig(string("plot",temp_diff,".png"))
    return objective_value(m)
end


cost_per_temp = zeros(length(temp_diff))
plot()
for i = 1:length(temp_diff)
    cost_per_temp[i] = optimize_price(temp_diff[i])
end


plot(temp_diff,cost_per_temp)



m = Model(Ipopt.Optimizer)
set_optimizer_attribute(m, "max_iter", 6000)
set_optimizer_attribute(m, "print_level", 0)

@variable(m, T_indoor[1:time_period])
@variable(m, Qin[1:time_period]>=0)

@objective(m, Min, sum(cost[i]*Qin[i] for i = 1:time_period))

@constraint(m, T_indoor[1] == 21.1)
@constraint(m, T_indoor[time_period] == 21.1)
@constraint(m, T_indoor .<= 23.9)
@constraint(m, T_indoor .>= 18.33)

for i = 1:time_period-1
    @NLconstraint(m, M*c*(T_indoor[i+1] - T_indoor[i]) == Qin[i]*3600000 - abs(T_indoor[i] - temp_data[i])/Req)
end


optimize!(m)
objective_value(m)
abs.(value.(T_indoor) - temp_data)/Req

plot(abs.(value.(T_indoor) - temp_data)/Req)
plot(value.(T_indoor))
plot(value.(T_indoor))
plot(hcat(value.(Qin),value.(T_indoor),temp_data), layout = (3,1))
