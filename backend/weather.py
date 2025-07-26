import requests
import sys

def get_weather_forecast(city, count=2):
    api_key = '7ea02f0f1e3fcd6d3525d0895ae7d2ca'
    url = f'http://api.openweathermap.org/data/2.5/forecast?q={city}&cnt={count}&units=metric&appid={api_key}'

    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        forecasts = data['list']
        forecast_data = []

        for forecast in forecasts:
            forecast_data.append({
                'time': forecast['dt_txt'],
                'temperature_celsius': forecast['main']['temp'],
                'weather': forecast['weather'][0]['description']
            })

        return forecast_data
    else:
        raise Exception(f"Error fetching data: {response.status_code} - {response.text}")

def convert_celsius_to_fahrenheit(celsius):
    return round(celsius * 9/5 + 32, 2)

if __name__ == "__main__":
    # Usage: python script.py [city] [--fahrenheit]
    city = sys.argv[1] if len(sys.argv) > 1 else "London"
    use_fahrenheit = "--fahrenheit" in sys.argv

    try:
        forecast = get_weather_forecast(city)
        for item in forecast:
            temp_c = item['temperature_celsius']
            temp = convert_celsius_to_fahrenheit(temp_c) if use_fahrenheit else temp_c
            unit = "°F" if use_fahrenheit else "°C"
            print(f"Time: {item['time']} | Temp: {temp}{unit} | Weather: {item['weather']}")
    except Exception as e:
        print(e)
        sys.exit(1)

