# ESP32 pressure therapy firmware

This is the Arduino firmware from the supplied ZIP with the haptic output made
nonblocking. It lets the ESP32 continue handling HTTP requests while D19 is
vibrating, so `/haptic/command` stop requests can turn the motor off promptly.

## Flash and connect

1. Open `esp32_health_monitor.ino` in Arduino IDE and select an ESP32 board.
   This sketch uses ESP32-only `WiFi.h`, `WebServer.h`, and GPIO 19; it will
   not run on an Arduino Uno.
2. Replace the `YOUR_*` Wi-Fi and Firebase placeholders in the sketch with your
   own credentials. The credentials from the ZIP were not copied into this
   workspace.
3. Install the ArduinoJson and Firebase ESP Client libraries, then compile and
   upload the sketch.
4. Open Serial Monitor at 115200 baud. Copy the IP printed after `WiFi
   Connected!`.
5. In the app's Pressure Therapy hardware settings, enter that IP and use
   **Check Connection**. The phone and ESP32 must be on the same reachable
   network. Look for `[HTTP] /ping received from Flutter` in Serial Monitor.

## Sensor data notes

The MAX30102 reader drains fresh FIFO samples before processing them. If there
is no finger/contact, it reports no heart-rate or SpO2 reading instead of
reusing stale samples. The Firebase `gsr` field is conductance in microsiemens
to match the app's `μS` label; `gsr_resistance_kohm` is also sent for the
firmware's resistance-based stress calculation/debugging. The physical divider
must match the comments in `gsr_sensor.h` (10 kΩ from 3.3 V to ADC, GSR element
from ADC to GND); a different divider requires changing the resistance formula.

The motor must be driven through a transistor or MOSFET with a flyback diode
and a shared ground. Do not connect a motor directly to GPIO 19.
