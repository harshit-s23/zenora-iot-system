/*
 * mpu6050_fall.h
 * MPU6050 Accelerometer + Gyroscope — Fall Detection
 * Library required: "MPU6050" by Electronic Cats (Arduino Library Manager)
 *   OR: Adafruit MPU6050
 * This file uses the raw I2C approach for reliability.
 */

#pragma once
#include <Wire.h>

#define MPU6050_ADDR 0x68

// Accelerometer raw data
int16_t ax_raw, ay_raw, az_raw;
int16_t gx_raw, gy_raw, gz_raw;

float ax_g, ay_g, az_g;
float accelMag = 1.0;

// Fall detection state
bool   fallDetected   = false;
bool   inFreefall     = false;
unsigned long freefallStart = 0;
unsigned long fallClearTime = 0;

const float FREEFALL_THRESHOLD = 0.4;  // g — below this = freefall
const float IMPACT_THRESHOLD   = 2.5;  // g — above this = impact
const unsigned long FREEFALL_MIN_MS = 80;   // min freefall duration
const unsigned long FALL_CLEAR_MS   = 3000; // auto-clear fall flag after 3s

bool mpuOk = false;

void initMPU6050() {
  Serial.print("Initializing MPU6050... ");

  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x6B); // PWR_MGMT_1
  Wire.write(0x00); // Wake up (clear sleep bit)
  uint8_t err = Wire.endTransmission(true);

  if (err != 0) {
    Serial.printf("FAILED (I2C error %d). Check wiring!\n", err);
    mpuOk = false;
    return;
  }

  // Set accelerometer range to ±4g (better fall sensitivity)
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x1C); // ACCEL_CONFIG
  Wire.write(0x08); // ±4g (AFS_SEL=1)
  Wire.endTransmission(true);

  // Set gyro range to ±500°/s
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x1B); // GYRO_CONFIG
  Wire.write(0x08); // ±500°/s
  Wire.endTransmission(true);

  // Set DLPF to 44Hz bandwidth for smoother readings
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x1A); // CONFIG
  Wire.write(0x03); // DLPF_CFG=3
  Wire.endTransmission(true);

  mpuOk = true;
  Serial.println("OK (0x68)");
}

void readMPU6050Raw() {
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x3B); // Starting register for accel data
  Wire.endTransmission(false);
  Wire.requestFrom(MPU6050_ADDR, 14, true);

  ax_raw = (Wire.read() << 8) | Wire.read();
  ay_raw = (Wire.read() << 8) | Wire.read();
  az_raw = (Wire.read() << 8) | Wire.read();
  Wire.read(); Wire.read(); // Temperature (skip)
  gx_raw = (Wire.read() << 8) | Wire.read();
  gy_raw = (Wire.read() << 8) | Wire.read();
  gz_raw = (Wire.read() << 8) | Wire.read();

  // Convert to g (±4g range → 8192 LSB/g)
  ax_g = ax_raw / 8192.0;
  ay_g = ay_raw / 8192.0;
  az_g = az_raw / 8192.0;

  // Total acceleration magnitude
  accelMag = sqrt(ax_g*ax_g + ay_g*ay_g + az_g*az_g);
}

void updateMPU6050() {
  if (!mpuOk) return;
  readMPU6050Raw();

  unsigned long now = millis();

  // Auto-clear fall flag after timeout
  if (fallDetected && now - fallClearTime > FALL_CLEAR_MS) {
    fallDetected = false;
  }

  // Fall detection algorithm:
  // Phase 1 — Freefall: magnitude drops below threshold
  if (!inFreefall && accelMag < FREEFALL_THRESHOLD) {
    inFreefall   = true;
    freefallStart = now;
  }

  // Phase 2 — Impact: after freefall, magnitude spikes above impact threshold
  if (inFreefall) {
    if (accelMag > IMPACT_THRESHOLD &&
        (now - freefallStart) > FREEFALL_MIN_MS) {
      fallDetected  = true;
      fallClearTime = now;
      inFreefall    = false;
    }
    // Cancel freefall if stayed normal
    if (accelMag >= FREEFALL_THRESHOLD &&
        accelMag <= IMPACT_THRESHOLD &&
        (now - freefallStart) > 500) {
      inFreefall = false;
    }
  }
}

bool isFallDetected() {
  return fallDetected;
}

float getAccelMagnitude() {
  return accelMag;
}
