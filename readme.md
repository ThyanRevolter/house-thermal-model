# Optimizing Residential HVAC Thermostat to Minimize Electricity Cost
## Teammates
Adhithyan Sakthivelu, Mohamed Nijad


## Introduction
By utilizing the flexibility of controlling thermostat set temperature, HVAC unit has a huge potential of decreasing cost and peak load through demand response. To understand the house thermal model and how the set temperature inside the house is maintained, ambient temperature data and house thermal properties will need to be obtained. The house’s thermal properties depends upon the orientation, insulation materials, and the
ambient temperature. After gathering all data and assumption, the energy load profile for heating and cooling will be modeled using thermal equations. The house thermal model will then be built to understand the change of indoor temperature with heating and cooling power and change in ambient temperature.

## Code explanation
### File "thermal_unit_data.jl"
This file contains the data of
* House Physical Structure
* House's thermal properties
* Electricity Prices
* Sample summer temperature data of Portland area

### File "get_weather_data.jl"
The code sends a GET request and receives the day ahead forecasted temperature data. This file requires to have JSON and HTTP package installed. Execute the following code before running the package
```
using Pkg
Pkg.add("JSON")
Pkg.add("HTTP")
```
### File "comfort_range_compare.jl"
This file compares the temperature and power profile of minimum |5| and maximum |0| comfort ranges and saves the figures to the folder */plots/*. 

## File "two_variable_model.jl"
This file
