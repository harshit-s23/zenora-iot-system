/*
 * gsr_sensor.h
 * GSR (Galvanic Skin Response) Sensor — D34 (ADC)
 * Higher resistance = lower conductance = lower stress/calm
 * Lower resistance = higher conductance = higher stress/arousal
 *
 * Typical values:
 *   > 200 kOhm : Very relaxed / dry skin
 *   50-200 kOhm: Normal
 *   10-50 kOhm : Mild stress
 *   < 10 kOhm  : High stress / elevated arousal
 */

#pragma once
#include "Arduino.h"

#define GSR_PIN       34
#define GSR_SAMPLES   10    // Averaging samples
#define ADC_VREF      3.3   // ESP32 reference voltage
#define ADC_MAX       4095  // 12-bit ADC
#define SERIES_R      10000.0  // 10kΩ series resistor (connect between 3.3V and GSR pin)

// Smoothing buffer
float gsrBuffer[GSR_SAMPLES];
int   gsrIdx = 0;
bool  gsrBufferFull = false;

void initGSR() {
  Serial.print("Initializing GSR (D34)... ");
  analogReadResolution(12);   // ESP32: 12-bit ADC
  analogSetAttenuation(ADC_11db); // 0-3.3V range
  pinMode(GSR_PIN, INPUT);
  // Pre-fill buffer
  for (int i = 0; i < GSR_SAMPLES; i++) {
    float raw = analogRead(GSR_PIN);
    float voltage = (raw / ADC_MAX) * ADC_VREF;
    if (voltage < 0.01) voltage = 0.01;
    gsrBuffer[i] = (SERIES_R * (ADC_VREF - voltage)) / voltage / 1000.0;
    delay(5);
  }
  gsrBufferFull = true;
  Serial.println("OK");
}

// Returns GSR resistance in kOhm
float readGSR() {
  int   raw     = analogRead(GSR_PIN);
  float voltage = (raw / (float)ADC_MAX) * ADC_VREF;
  if (voltage < 0.01) voltage = 0.01; // Prevent div/0
  if (voltage >= ADC_VREF) voltage = ADC_VREF - 0.01;

  // Calculate skin resistance using voltage divider formula
  // Vout = Vin * R_skin / (R_series + R_skin)
  // R_skin = R_series * Vout / (Vin - Vout)
  float resistance_ohm = SERIES_R * voltage / (ADC_VREF - voltage);
  float resistance_k   = resistance_ohm / 1000.0;

  // Rolling average
  gsrBuffer[gsrIdx] = resistance_k;
  gsrIdx = (gsrIdx + 1) % GSR_SAMPLES;

  float sum = 0;
  for (int i = 0; i < GSR_SAMPLES; i++) sum += gsrBuffer[i];
  float avg = sum / GSR_SAMPLES;

  // Clamp to realistic range
  if (avg < 1.0)    avg = 1.0;
  if (avg > 2000.0) avg = 2000.0;

  return avg;
}

// Returns 0-100 stress contribution from GSR
// Lower resistance = higher stress
int gsrStressScore(float gsr_kOhm) {
  // Map: 200kOhm+ = 0 stress, 5kOhm = 100 stress
  float clamped = constrain(gsr_kOhm, 5.0, 200.0);
  // Inverse mapping
  float score = (1.0 - (clamped - 5.0) / (200.0 - 5.0)) * 100.0;
  return (int)constrain(score, 0, 100);
}
