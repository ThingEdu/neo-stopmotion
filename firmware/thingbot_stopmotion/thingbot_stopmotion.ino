// NeoStopMotion ThingBot — 2-button firmware
// Maker Việt × ThingEdu — NEO One stop-motion station
//
// IO1 (D4)  -> "SHOOT\n"   (chụp 1 frame, tương đương phím Space)
// IO2 (D7)  -> "EXPORT\n"  (tạo phim, tương đương phím Enter)
// On boot   -> "READY\n"   (NEO One detect ThingBot via auto-detect handshake)
//
// LED1 (D5)  : feedback IO1 (nháy 1 lần khi capture)
// LED2 (D8)  : feedback IO2 (nháy 3 lần khi export)
// BUZZER (D6): tiếng "tách" 50ms khi capture
//
// Wiring (Arduino Uno hoặc ESP32):
//   IO1 ─── Button NO ─── GND  (INPUT_PULLUP)
//   IO2 ─── Button NO ─── GND  (INPUT_PULLUP)
//   D5  ─── 220Ω ─── LED1 ─── GND
//   D8  ─── 220Ω ─── LED2 ─── GND
//   D6  ──────────── Buzzer ── GND

#define IO1_PIN     4
#define IO2_PIN     7
#define LED1_PIN    5
#define LED2_PIN    8
#define BUZZER_PIN  6

#define BAUD_RATE       115200
#define DEBOUNCE_MS     50
#define READY_DELAY_MS  100

bool io1Down = false;
bool io2Down = false;
unsigned long io1LastChange = 0;
unsigned long io2LastChange = 0;

void blinkLed(int pin, int times, int duration_ms) {
  for (int i = 0; i < times; i++) {
    digitalWrite(pin, HIGH);
    delay(duration_ms / 2);
    digitalWrite(pin, LOW);
    delay(duration_ms / 2);
  }
}

void setup() {
  Serial.begin(BAUD_RATE);

  pinMode(IO1_PIN, INPUT_PULLUP);
  pinMode(IO2_PIN, INPUT_PULLUP);
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);

  // Brief startup blink so operator sees the board boot
  blinkLed(LED1_PIN, 1, 80);
  blinkLed(LED2_PIN, 1, 80);

  delay(READY_DELAY_MS);
  Serial.println("READY");
}

bool readDebounced(int pin, bool &lastDown, unsigned long &lastChange) {
  bool now = (digitalRead(pin) == LOW);
  unsigned long t = millis();
  if (now != lastDown && (t - lastChange) >= DEBOUNCE_MS) {
    lastChange = t;
    lastDown = now;
    return now;  // return true on the press transition
  }
  return false;
}

void loop() {
  // IO1: SHOOT on press transition
  bool was1 = io1Down;
  bool press1 = readDebounced(IO1_PIN, io1Down, io1LastChange);
  if (press1 && !was1) {
    Serial.println("SHOOT");
    blinkLed(LED1_PIN, 1, 60);
    tone(BUZZER_PIN, 1200, 40);
  }

  // IO2: EXPORT on press transition
  bool was2 = io2Down;
  bool press2 = readDebounced(IO2_PIN, io2Down, io2LastChange);
  if (press2 && !was2) {
    Serial.println("EXPORT");
    blinkLed(LED2_PIN, 3, 200);
    tone(BUZZER_PIN, 800, 100);
    delay(50);
    tone(BUZZER_PIN, 1600, 100);
  }
}
