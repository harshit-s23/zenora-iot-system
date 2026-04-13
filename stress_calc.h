/*
 * stress_calc.h
 * Stress Score Calculation (0-100)
 *
 * Formula uses weighted combination of:
 *   1. Heart Rate    (40% weight) — Elevated BPM = more stress
 *   2. GSR           (35% weight) — Lower resistance = more stress
 *   3. Temperature   (15% weight) — Slightly elevated temp = stress
 *   4. Movement      (10% weight) — Sudden movement patterns
 *
 * Stress Levels:
 *   0-25  : Relaxed
 *   26-50 : Mild Stress
 *   51-70 : Moderate Stress
 *   71-85 : High Stress
 *   86-100: Severe Stress
 */

#pragma once

// Heart rate stress score
// Normal resting: 60-80 BPM
// Stressed: >90 BPM
int hrStressScore(float bpm) {
  if (bpm <= 0) return 30; // No reading → assume mild
  if (bpm < 50)  return 10;
  if (bpm < 60)  return 15;
  if (bpm <= 75) return 20; // Relaxed zone
  if (bpm <= 85) return 35; // Normal active
  if (bpm <= 95) return 55; // Mildly elevated
  if (bpm <= 110) return 75;
  if (bpm <= 130) return 88;
  return 100; // Very high
}

// Movement stress score
// High sudden movement may indicate stress or anxiety
int movementStressScore(float accelMag) {
  // Normal standing/sitting: ~1.0g
  float deviation = abs(accelMag - 1.0);
  if (deviation < 0.1) return 5;  // Very still
  if (deviation < 0.3) return 15; // Normal movement
  if (deviation < 0.6) return 40; // Active
  if (deviation < 1.0) return 65; // Agitated
  return 85; // Extreme movement
}

// GSR stress score (from gsr_sensor.h)
int gsrStressScore(float gsr_kOhm);
// Temp stress score (from lm35_temp.h)
int tempStressScore(float tempC);

// Main stress calculator
int calculateStress(float bpm, float gsr_kOhm, float tempC, float accelMag) {
  int hrScore   = hrStressScore(bpm);
  int gsrScore  = gsrStressScore(gsr_kOhm);
  int tmpScore  = tempStressScore(tempC);
  int movScore  = movementStressScore(accelMag);

  // Weighted average
  float stress = (hrScore  * 0.40) +
                 (gsrScore * 0.35) +
                 (tmpScore * 0.15) +
                 (movScore * 0.10);

  return (int)constrain(stress, 0, 100);
}

String getStressLevel(int score) {
  if (score <= 25) return "Relaxed 😌";
  if (score <= 50) return "Mild Stress 😐";
  if (score <= 70) return "Moderate 😟";
  if (score <= 85) return "High Stress 😰";
  return "Severe! 🚨";
}
