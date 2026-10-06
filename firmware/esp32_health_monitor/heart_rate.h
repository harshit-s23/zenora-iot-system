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
byte   rateCount   = 0;
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
  static int sampleCount = 0;
  // Drain only fresh FIFO samples. Reading getIR()/getRed() once per loop can
  // repeatedly process the same sensor sample and corrupt both BPM and SpO2.
  particleSensor.check();
  while (particleSensor.available()) {
    uint32_t irValue = particleSensor.getIR();
    uint32_t redValue = particleSensor.getRed();
    particleSensor.nextSample();

    if (irValue < 50000) {
      beatsPerMinute = 0;
      beatAvg = 0;
      rateCount = 0;
      sampleCount = 0;
      validSPO2 = 0;
      lastBeat = 0;
      continue;
    }

    if (checkForBeat(irValue)) {
      unsigned long now = millis();
      if (lastBeat != 0 && now > (unsigned long)lastBeat) {
        unsigned long delta = now - (unsigned long)lastBeat;
        beatsPerMinute = 60000.0f / delta;
        if (beatsPerMinute >= 40 && beatsPerMinute <= 200) {
          rates[rateSpot] = (byte)beatsPerMinute;
          rateSpot = (rateSpot + 1) % RATE_SIZE;
          if (rateCount < RATE_SIZE) rateCount++;
          unsigned int total = 0;
          for (byte x = 0; x < rateCount; x++) total += rates[x];
          beatAvg = (float)total / rateCount;
        }
      }
      lastBeat = now;
    }

    redBuffer[sampleCount] = redValue;
    irBuffer[sampleCount] = irValue;
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
