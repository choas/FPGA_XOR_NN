// Source adapted from https://github.com/wd5gnr/VidorFPGA
#include <wiring_private.h>
#include "jtag.h"
#include "defines.h"

// Pin definitions for clarity
const int INPUT_X1_PIN   = 3;   // D3
const int INPUT_X2_PIN   = 4;   // D4
const int START_PIN      = 5;   // D5
const int OUT_Y_PIN      = 6;   // D6

void setup() {
  setup_fpga(); // Initialize FPGA

  Serial.begin(9600);

  // Set pin modes
  pinMode(INPUT_X1_PIN, OUTPUT);
  pinMode(INPUT_X2_PIN, OUTPUT);
  pinMode(START_PIN, OUTPUT);
  pinMode(OUT_Y_PIN, INPUT);

  // Start the calculation engine on the FPGA
  digitalWrite(START_PIN, HIGH);
  delay(100);
  digitalWrite(START_PIN, LOW);

  Serial.println("FPGA and MCU started!");
}

void loop() {
  static int inputPattern = 0;

  // Set input pins based on bits of inputPattern
  digitalWrite(INPUT_X1_PIN, inputPattern & 0x01);           // LSB to INPUT_X1_PIN
  digitalWrite(INPUT_X2_PIN, (inputPattern & 0x02) >> 1);    // Next bit to INPUT_X2_PIN

  delay(1000);

  // Cycle through 0, 1, 2, 3
  inputPattern = (inputPattern + 1) % 4;

  // Read result from FPGA
  int xorResult = digitalRead(OUT_Y_PIN);

  // Print input and output states
  Serial.print("INPUT_X2_PIN (D4) = "); Serial.print(digitalRead(INPUT_X2_PIN));
  Serial.print(" | INPUT_X1_PIN (D3) = "); Serial.print(digitalRead(INPUT_X1_PIN));
  Serial.print(" | XOR Result (OUTPUT_PIN/D6) = "); Serial.println(xorResult);
}
