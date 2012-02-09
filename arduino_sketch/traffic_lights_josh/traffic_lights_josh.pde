// Isotope11 CI-server traffic light
// Arduino Uno with 2 relays attached to pins 4 and 7
// 2-9-12

// declare variables and output pins
int inByte;
int red_light = 42;
int yellow_light = 46;
int green_light = 50;

void setup() {
  // start Arduino serial monitor
  Serial.begin(9600);
  pinMode(yellow_light, OUTPUT);
  pinMode(green_light, OUTPUT);
  pinMode(red_light, OUTPUT);
}

void loop() {
  // check serial buffer
  if (Serial.available() > 0){
    // read serial byte
    inByte = Serial.read();
    // print serial byte
    Serial.println(inByte);
  }

  switch(inByte){
  // if serial value received is "49", blink yellow light
  case 49:
    digitalWrite(yellow_light, HIGH);
    delay(1000);
    digitalWrite(yellow_light, LOW);
    break;
  // if serial value is "50", turn yellow light off
  case 50:
    digitalWrite(yellow_light, LOW);
    break;
  // if serial value is "51", turn red light on (green off)
  case 51:
    digitalWrite(red_light, HIGH);
    digitalWrite(green_light, LOW);
    break;
  // if serial value is "52", turn green light on (red off)
  case 52:
    digitalWrite(green_light, HIGH);
    digitalWrite(red_light, LOW);
    break;
  }
}

