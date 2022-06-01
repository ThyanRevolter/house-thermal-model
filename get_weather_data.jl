using HTTP, JSON

location = "portland"

function get_temp_data(location)
    api_key = "fcb14e024ffc438a92440849222605"
    api_url = "http://api.weatherapi.com/v1/forecast.json?key="*api_key*"&q="*location*"&days=1&aqi=no&alerts=no"
    r = HTTP.request("GET", api_url)
    body_string = (String(r.body))
    parsed_data = JSON.parse(body_string)
    day_data = parsed_data["forecast"]["forecastday"][1]["hour"]
    temp_data = zeros(length(day_data))
    for d in 1:length(day_data)
        temp_data[d] = day_data[d]["temp_c"]
    end
    return temp_data    
end

temp_data_api = get_temp_data(location)
