/*
 * lm35_temp.h
 * LM35 Temperature Sensor — D4 (ADC)
 * LM35 outputs: 10mV per °C
 * At 25°C → 250mV output
 *
 * Wiring:
 *   LM35 VCC  → 3.3V
 *   LM35 GND  → GND
 *   LM35 VOUT → D4
 *
 * NOTE: Add 100nF ceramic capacitor between VOUT and GND
 *       close to LM35 to reduce noise.
 */

#pragma once
#include "Arduino.h"

#define LM35_PIN       4
#define LM35_SAMPLES   20
#define LM35_VREF      3.3
#define LM35_ADC_MAX   4095

float lm35Buffer[LM35_SAMPLES];
int   lm35Idx = 0;

void initLM35() {
  Serial.print("Initializing LM35 (D4)... ");
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db); // Full 0-3.3V range
  pinMode(LM35_PIN, INPUT);

  // Pre-fill buffer
  for (int i = 0; i < LM35_SAMPLES; i++) {
    float raw     = analogRead(LM35_PIN);
    float voltage = (raw / (float)LM35_ADC_MAX) * LM35_VREF;
    lm35Buffer[i] = voltage * 100.0; // 10mV/°C → °C
    delay(5);
  }
  Serial.println("OK");
}

// Returns temperature in Celsius
float readLM35() {
  int   raw     = analogRead(LM35_PIN);
  float voltage = (raw / (float)LM35_ADC_MAX) * LM35_VREF;
  float tempC   = voltage * 100.0; // LM35: 10mV = 1°C

  // Rolling average for stable reading
  lm35Buffer[lm35Idx] = tempC;
  lm35Idx = (lm35Idx + 1) % LM35_SAMPLES;

  float sum = 0;
  for (int i = 0; i < LM35_SAMPLES; i++) sum += lm35Buffer[i];
  float avg = sum / LM35_SAMPLES;

  // Sanity clamp: skin temp usually 28-40°C
  if (avg < 10.0 || avg > 50.0) avg = 36.0; // Default if out of range

  return avg;
}

// Returns 0-100 stress contribution from skin temp
// Elevated skin temp can indicate stress
int tempStressScore(float tempC) {
  // Normal: 33-36°C  Stressed: >37°C
  if (tempC < 33.0) return 20;
  if (tempC > 38.0) return 70;
  float score = ((tempC - 33.0) / (38.0 - 33.0)) * 70.0;
  return (int)constrain(score, 0, 100);
}
