// Isotope11 CI-server traffic light
// Arduino Uno with 2 relays attached to pins 4 and 7
// 2-9-12
// upudated for led's using 3 output pins 11/15/12

// declare variables and output pins
int inByte;

int yellow_light = 6;
int green_light = 5;
int red_light = 3;

long lastTx = 0;

int switch_pin = 7;

void setup() {
  // start Arduino serial monitor
  Serial.begin(9600);
  pinMode(yellow_light, OUTPUT);
  pinMode(green_light, OUTPUT);
  pinMode(red_light, OUTPUT);
  pinMode(switch_pin, INPUT);
  digitalWrite(switch_pin, HIGH);
}

void loop() {
  if (digitalRead(switch_pin) == HIGH){
    // check serial buffer
    if (Serial.available() > 0){
      // read serial byte
      inByte = Serial.read();
      // print serial byte
      Serial.println(inByte);
      lastTx = millis();
  
      digitalWrite(red_light, LOW);
      digitalWrite(yellow_light, LOW);
      digitalWrite(green_light, LOW);
      
      switch(inByte){
      // if serial value received is "49", blink yellow light
      case 49:
        blink_yellow();
        Serial.println("Made yellow light blink");
        break;
      // if serial value is "50", turn red light on
      case 50:
        digitalWrite(red_light, HIGH);
        Serial.println("Red Light ON");
        break;
      // if serial value is "51", turn green light on
      case 51:
        digitalWrite(green_light, HIGH);
        Serial.println("Green Light ON");
        break;
      case 52:
        blink_red();
        Serial.println("Server Error");
        break;
      }
      Serial.println(inByte);
    }
    else {
      if ((millis() - lastTx) > 30000) {
        blink_cycle();
      }
    }
  }    
  else {
    Serial.println("Lights are off");
  }
}

void blink_cycle(){
  digitalWrite(red_light, LOW); 
  digitalWrite(green_light, HIGH);
  digitalWrite(yellow_light, LOW);
  delay(1000);
  digitalWrite(red_light, LOW);
  digitalWrite(green_light, LOW);
  digitalWrite(yellow_light, HIGH);
  delay(1000);
  digitalWrite(red_light, HIGH);
  digitalWrite(green_light, LOW);
  digitalWrite(yellow_light, LOW);
  delay(1000);
}

void blink_yellow(){
  digitalWrite(yellow_light, HIGH);
  delay(1000);
  digitalWrite(yellow_light, LOW);
  delay(1000);
}

void blink_red(){
  digitalWrite(red_light, HIGH);
  delay(1000);
  digitalWrite(red_light, LOW);
  delay(1000);
}
