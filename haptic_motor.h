/*
 * haptic_motor.h
 * Haptic / Vibration Motor — D19
 *
 * Wiring:
 *   Use a NPN transistor (e.g., 2N2222 or BC547):
 *   ESP32 D19 → 1kΩ resistor → Base
 *   Motor +    → 3.3V or 5V
 *   Motor -    → Collector
 *   Emitter    → GND
 *   Add flyback diode across motor (cathode to +, anode to -)
 *
 * Direct connection (if motor draws < 40mA):
 *   ESP32 D19 → Motor → GND
 */

#pragma once
#include "Arduino.h"

#define HAPTIC_PIN 19

void initHaptic() {
  Serial.print("Initializing Haptic Motor (D19)... ");
  pinMode(HAPTIC_PIN, OUTPUT);
  digitalWrite(HAPTIC_PIN, LOW);
  Serial.println("OK");
}

// Single pulse
void hapticPulse(int durationMs) {
  digitalWrite(HAPTIC_PIN, HIGH);
  delay(durationMs);
  digitalWrite(HAPTIC_PIN, LOW);
}

// Fall detected pattern: 3 long buzzes
void hapticPattern_Fall() {
  for (int i = 0; i < 3; i++) {
    hapticPulse(400);
    delay(200);
  }
}

// High stress pattern: 2 short double-pulses
void hapticPattern_Stress() {
  for (int i = 0; i < 2; i++) {
    hapticPulse(100);
    delay(100);
    hapticPulse(100);
    delay(400);
  }
}

// Heartbeat pattern (single soft pulse)
void hapticHeartbeat() {
  hapticPulse(50);
  delay(100);
  hapticPulse(50);
}
