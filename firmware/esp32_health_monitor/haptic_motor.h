/*
 * Nonblocking haptic/vibration motor driver for ESP32 GPIO 19.
 *
 * Wiring: drive the motor through a transistor/MOSFET and flyback diode,
 * with the ESP32 and motor supply sharing ground. Do not power a motor from
 * an ESP32 GPIO pin.
 */
#pragma once
#include "Arduino.h"

#define HAPTIC_PIN 19

enum HapticMode : uint8_t { HAPTIC_IDLE, HAPTIC_PULSE, HAPTIC_FALL, HAPTIC_STRESS };

static HapticMode hapticMode = HAPTIC_IDLE;
static uint8_t hapticStep = 0;
static unsigned long hapticDeadline = 0;

inline bool hapticTimeReached(unsigned long deadline) {
  return (long)(millis() - deadline) >= 0;
}

inline void initHaptic() {
  Serial.print("Initializing Haptic Motor (D19)... ");
  pinMode(HAPTIC_PIN, OUTPUT);
  digitalWrite(HAPTIC_PIN, LOW);
  hapticMode = HAPTIC_IDLE;
  Serial.println("OK");
}

inline void hapticStop() {
  hapticMode = HAPTIC_IDLE;
  hapticStep = 0;
  digitalWrite(HAPTIC_PIN, LOW);
}

inline void hapticPulse(int durationMs) {
  hapticMode = HAPTIC_PULSE;
  digitalWrite(HAPTIC_PIN, durationMs > 0 ? HIGH : LOW);
  hapticDeadline = millis() + (unsigned long)max(durationMs, 0);
  if (durationMs <= 0) hapticStop();
}

inline void hapticPattern_Fall() {
  hapticMode = HAPTIC_FALL;
  hapticStep = 0;
  digitalWrite(HAPTIC_PIN, HIGH);
  hapticDeadline = millis() + 400;
}

inline void hapticPattern_Stress() {
  hapticMode = HAPTIC_STRESS;
  hapticStep = 0;
  digitalWrite(HAPTIC_PIN, HIGH);
  hapticDeadline = millis() + 100;
}

inline void hapticHeartbeat() {
  hapticPattern_Stress();
}

// Call on every loop iteration. This lets WebServer handle stop requests
// while a pulse or autonomous alert pattern is playing.
inline void hapticUpdate() {
  if (hapticMode == HAPTIC_IDLE || !hapticTimeReached(hapticDeadline)) return;

  if (hapticMode == HAPTIC_PULSE) {
    hapticStop();
    return;
  }

  if (hapticMode == HAPTIC_FALL) {
    hapticStep++;
    if (hapticStep >= 6) {
      hapticStop();
      return;
    }
    const bool motorOn = (hapticStep % 2) == 0;
    digitalWrite(HAPTIC_PIN, motorOn ? HIGH : LOW);
    hapticDeadline = millis() + (motorOn ? 400 : 200);
    return;
  }

  if (hapticMode == HAPTIC_STRESS) {
    hapticStep++;
    if (hapticStep >= 8) {
      hapticStop();
      return;
    }
    const uint8_t phase = hapticStep % 4;
    const bool motorOn = phase == 0 || phase == 2;
    digitalWrite(HAPTIC_PIN, motorOn ? HIGH : LOW);
    const unsigned long durations[] = {100, 100, 100, 400};
    hapticDeadline = millis() + durations[phase];
  }
}
