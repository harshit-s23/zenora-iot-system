/*
 * heart_rate.h
 * MAX30102 Pulse Oximeter & Heart Rate Sensor
 * Library required: SparkFun MAX3010x (install via Arduino Library Manager)
 *   Search: "SparkFun MAX3010x Pulse and Proximity Sensor Library"
 */

#pragma once
#include <Wire.h>
#include "MAX30105.h"       // SparkFun MAX3010x library
#include "heartRate.h"      // Heart rate algorithm (included with SparkFun lib)
#include "spo2_algorithm.h" // SpO2 algorithm (included with SparkFun lib)

MAX30105 particleSensor;

// Rolling buffers for SpO2 algorithm
const byte RATE_SIZE = 4;
byte   rates[RATE_SIZE];
byte   rateSpot    = 0;
long   lastBeat    = 0;
float  beatsPerMinute = 0;
float  beatAvg     = 0;

// SpO2 buffers
const int SPO2_BUFFER_SIZE = 100;
uint32_t irBuffer[SPO2_BUFFER_SIZE];
uint32_t redBuffer[SPO2_BUFFER_SIZE];
int32_t  spo2Value    = 0;
int8_t   validSPO2    = 0;
int32_t  heartRateRaw = 0;
int8_t   validHR      = 0;

bool hrSensorOk = false;

void initHeartRate() {
  Serial.print("Initializing MAX30102... ");
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("FAILED. Check wiring!");
    hrSensorOk = false;
    return;
  }

  // Optimized settings for finger/wrist
  particleSensor.setup(
    60,   // LED brightness (0-255) — increase if no signal
    4,    // Sample average: 1,2,4,8,16,32
    2,    // LED mode: 1=Red only, 2=Red+IR, 3=Red+IR+Green
    200,  // Sample rate: 50,100,200,400,800,1000,1600,3200
    411,  // Pulse width (us): 69,118,215,411
    4096  // ADC range: 2048,4096,8192,16384
  );

  hrSensorOk = true;
  Serial.println("OK (0x57)");
}

void updateHeartRate() {
  if (!hrSensorOk) return;

  long irValue = particleSensor.getIR();

  // Check for finger presence
  if (irValue < 50000) {
    beatsPerMinute = 0;
    beatAvg = 0;
    return;
  }

  if (checkForBeat(irValue)) {
    long delta = millis() - lastBeat;
    lastBeat   = millis();
    beatsPerMinute = 60.0 / (delta / 1000.0);

    if (beatsPerMinute > 20 && beatsPerMinute < 255) {
      rates[rateSpot++] = (byte)beatsPerMinute;
      rateSpot %= RATE_SIZE;
      beatAvg = 0;
      for (byte x = 0; x < RATE_SIZE; x++) beatAvg += rates[x];
      beatAvg /= RATE_SIZE;
    }
  }

  // SpO2 calculation (runs every 100 samples)
  static int sampleCount = 0;
  redBuffer[sampleCount] = particleSensor.getRed();
  irBuffer[sampleCount]  = irValue;
  sampleCount++;

  if (sampleCount >= SPO2_BUFFER_SIZE) {
    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, SPO2_BUFFER_SIZE, redBuffer,
      &spo2Value, &validSPO2,
      &heartRateRaw, &validHR
    );
    sampleCount = 0;
  }
}

float getHeartRate() {
  if (!hrSensorOk) return 0.0;
  // Return averaged BPM; clamp to realistic range
  if (beatAvg < 40 || beatAvg > 200) return 0.0;
  return beatAvg;
}

float getSpO2() {
  if (!hrSensorOk || !validSPO2) return 0.0;
  if (spo2Value < 80 || spo2Value > 100) return 0.0;
  return (float)spo2Value;
}
