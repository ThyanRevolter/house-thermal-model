using LinearAlgebra
include("thermal_unit_data.jl")
include("get_weather_data.jl")
include("two_variable_model.jl")

# Input min_tol: Type: Int, minimum tolerece in ᵒF
# Input max_tol: Type: Int, maximum tolerece in ᵒF
# Input weekday: Type: Boolean, Weekday or Weekend
function generate_comfort_range(min_tol, max_tol, weekday)
    min_tol = min_tol*0.556
    max_tol = max_tol*0.556
    comfort_range = zeros(24)
    # Weekday
    # 1 - 8 & 17 - 24 = Maximum Comfort
    # 8 - 17 = Maximum Saving
    # Weekend
    # 17 - 22 = Maximum Saving
    # 1 - 17 & 22 - 24 = Maximum Comfort 
    if weekday
        comfort_range[1:8] .=  min_tol
        comfort_range[9:17] .=  max_tol
        comfort_range[18:24] .=  min_tol
    else
        comfort_range[1:17] .=  min_tol
        comfort_range[18:22] .=  max_tol
        comfort_range[23:24] .=  min_tol
    end
    return comfort_range
end

comfort_range_weekday = generate_comfort_range(1,5,true)
comfort_range_weekend = generate_comfort_range(1,5,false)

status, cost, T_in, Qin_heat_value, Qin_cool_value  = hvac_optimizer(comfort_range_weekday, 999999999, Tout)
plot_temp_profile_graph(T_in, Tout, Tbase, comfort_range_weekday, string("plots\\Temp_profile_weekday"))
plot_power_profile(Qin_heat_value, Qin_cool_value, string("plots\\Power_profile_cmfrt_weekday"))


status, cost, T_in, Qin_heat_value, Qin_cool_value  = hvac_optimizer(comfort_range_weekend, 999999999, Tout)
plot_temp_profile_graph(T_in, Tout, Tbase, comfort_range_weekend, string("plots\\Temp_profile_weekend"))
plot_power_profile(Qin_heat_value, Qin_cool_value, string("plots\\Power_profile_cmfrt_weekend"))
