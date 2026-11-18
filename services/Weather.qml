pragma Singleton

import QtQuick
import Quickshell

// Weather from open-meteo.com (free, no key) for Settings.city: now, today's high and low, and the next three
// days. Every 15 minutes.
Singleton {
    id: root

    property var now: null                       // { place, temp, code, day, wind, humidity, hi, lo, days: [...] }
    property string error: ""
    readonly property string unit: Settings.units === "fahrenheit" ? "°F" : "°C"
    readonly property string key: Settings.city.trim().toLowerCase() + "|" + Settings.units
    onKeyChanged: load()
    Timer {
        interval: 15 * 60 * 1000
        running: Settings.city !== ""
        repeat: true
        onTriggered: root.load()
    }

    function get(url, done) {
        const x = new XMLHttpRequest();
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            let r = null;
            try {
                r = x.status === 200 ? JSON.parse(x.responseText) : null;
            } catch (e) {}
            done(r);
        };
        x.open("GET", url);
        x.send();
    }
    function load() {
        const city = Settings.city.trim();
        if (!city)
            return;
        get(`https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&name=${encodeURIComponent(city)}`, g => {
            const p = g?.results?.[0];
            if (!p) {
                error = g ? "city not found" : "offline";
                return;
            }
            get(`https://api.open-meteo.com/v1/forecast?latitude=${p.latitude}&longitude=${p.longitude}`
                + "&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,is_day"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=4&timezone=auto"
                + `&temperature_unit=${Settings.units}`, f => {
                if (!f?.current) {
                    error = "offline";
                    return;
                }
                const d = f.daily;
                error = "";
                now = {
                    place: p.name,
                    temp: Math.round(f.current.temperature_2m),
                    code: f.current.weather_code,
                    day: f.current.is_day === 1,
                    wind: Math.round(f.current.wind_speed_10m),
                    humidity: f.current.relative_humidity_2m,
                    hi: Math.round(d.temperature_2m_max[0]),
                    lo: Math.round(d.temperature_2m_min[0]),
                    days: d.time.slice(1).map((t, i) => ({
                        name: new Date(t + "T12:00").toLocaleDateString(Qt.locale(), "ddd"),
                        code: d.weather_code[i + 1],
                        hi: Math.round(d.temperature_2m_max[i + 1]),
                        lo: Math.round(d.temperature_2m_min[i + 1])
                    }))
                };
            });
        });
    }

    // WMO weather codes → a Material Symbol / words
    function icon(code, day) {
        if (code === 0)
            return day === false ? "clear_night" : "clear_day";
        if (code <= 2)
            return day === false ? "partly_cloudy_night" : "partly_cloudy_day";
        if (code === 3)
            return "cloud";
        if (code <= 48)
            return "foggy";
        if (code <= 67 || (code >= 80 && code <= 82))
            return "rainy";
        if (code <= 77 || (code >= 85 && code <= 86))
            return "weather_snowy";
        return "thunderstorm";
    }
    function words(code) {
        return code === 0 ? "Clear" : code <= 2 ? "Partly cloudy" : code === 3 ? "Cloudy" : code <= 48 ? "Fog"
            : code <= 57 ? "Drizzle" : code <= 67 ? "Rain" : code <= 77 ? "Snow" : code <= 82 ? "Showers"
            : code <= 86 ? "Snow showers" : "Thunderstorm";
    }
}
