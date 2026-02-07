#include <U8g2lib.h>

//Define the size of the screen
#define WIDTH 128
#define HEIGHT 64
#define BPP 1
#define WIDTH_BYTE (WIDTH/(8/BPP))
#define BUFFER_SIZE (WIDTH_BYTE * HEIGHT)

byte buffer_bmp[BUFFER_SIZE] = {0};

// For Arduino Nano 33 BLE
//U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/U8X8_PIN_NONE);
// OR for ESP32:
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/U8X8_PIN_NONE, /* clock=*/3, /* data=*/4);

void setup(void) {
  Serial.begin(200000);
  
  u8g2.begin();
  u8g2.setBusClock(400000);  // Try 400kHz instead of 3.4MHz
  
  // Clear display
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.drawStr(0, 10, "Waiting for data...");
  u8g2.sendBuffer();
  
  Serial.println("Arduino ready");
}

void loop(void) {
  if (Serial.available() > 0) {
    downloadImage(BUFFER_SIZE);
    
    // Debug: Print first few bytes received
    Serial.print("First 10 bytes: ");
    for(int i=0; i<10 && i<BUFFER_SIZE; i++) {
      Serial.print(buffer_bmp[i], HEX);
      Serial.print(" ");
    }
    Serial.println();
    
    u8g2.clearBuffer();
    u8g2.drawBitmap(0, 0, WIDTH_BYTE, HEIGHT, buffer_bmp);
    u8g2.sendBuffer();
    
    Serial.println("Display updated");
  }
  delay(10);  // Small delay to prevent blocking
}

void downloadImage(int len) {
  int i = 0;
  
  // Wait for sync pattern
  bool gotR = false;
  bool gotDot = false;
  
  while (!gotR || !gotDot) {
    if (Serial.available()) {
      byte inByte = Serial.read();
      if (!gotR && inByte == 'R') {
        gotR = true;
      } else if (gotR && !gotDot && inByte == '.') {
        gotDot = true;
      }
    }
  }
  
  // Read brightness
  while (Serial.available() < 1);  // Wait for brightness byte
  byte brightness = Serial.read();
  u8g2.setContrast(brightness);
  
  // Read image data
  i = 0;
  while (i < len) {
    if (Serial.available()) {
      buffer_bmp[i] = Serial.read();
      i++;
    }
  }
  
  Serial.print("Received ");
  Serial.print(i);
  Serial.println(" bytes");
}