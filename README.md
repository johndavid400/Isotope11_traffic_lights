## Monitoring your Continuous Integration Server with Traffic Lights and an Arduino
### A way for Isotope11 to visually monitor the testing status of its many software projects.
Today I am going to walk through our recent continuous integration Traffic light
notifier project that we just finished at the office. This project stemmed from
my company's desire to immediately know if a developer has broken a software
project, and what better way to do that than to have a huge red light flashing
in your face. We connected an old salvaged traffic light fixture to our Jenkins
CI-server that monitors the testing status of all of our current software
projects. If all our tests are passing, the light stays green, if any test fails
the light turns red to provide a visual notification of a problem. While Jenkins
is running a test suite on any project, the yellow light will flash to let us
know of the activity.

<iframe width="560" height="315" src="http://www.youtube.com/embed/3T5fEV5YHYo" frameborder="0" allowfullscreen></iframe>

So how does one connect a 48” tall traffic light to a continuous integration
server? With a Ruby script, an Arduino, and a few relays of course.

<a href="http://www.flickr.com/photos/knewter/6853275947/" title="Traffic Light by knewter, on Flickr"><img src="http://farm8.staticflickr.com/7048/6853275947_3331bfd2c2.jpg" width="375" height="500" alt="Traffic Light"></a>

The Ruby code will create a serial connection with the Arduino to send data,
then create a web connection with the CI server to request the build status data
via our CI server's built in API. A quick look through the returned data will
give us a chance to see if there are any problems – if so, we'll send a signal
to the Arduino to change the light status, otherwise it stays green. The Ruby
script requires 3 gem dependencies to run: faraday, json, and serialport – all
available from rubygems.org (eg. `gem install faraday`).

    # Isotope11 continous integration server Traffic-light
    # Ruby script to monitor json output from Jenkins CI-server, and output the status of projects to a Traffic-light. 
    # If all builds are passing, the light is green. 
    # If a job is currently building, the yellow light flashes. 
    # If any job is failing, the red light is turned on and green turned off.
    require "serialport"
    require "json"
    require "faraday"
    require "net/http"

    # create a new Serial port for the Arduino Uno which uses port /dev/ttyACM0. Older Arduinos should use /dev/ttyUSB0
    sp = SerialPort.new("/dev/ttyACM0", 9600)

    # wait for connection
    sleep(1)

    # create a new Faraday connection with the Jenkins server to read the status of each job
    conn = Faraday.new('http://your_Jenkins_server_address.com')
    puts 'go to loop'

    loop do
      begin
        # grab the json from the jenkins api
        response = conn.get('/api/json')
        # parse the response into a list of jobs that are being monitored
        jobs = JSON.parse(response.body)["jobs"]

        # search each job to see if it contains either "anime" (building) or "red" (failing)
        should_blink = jobs.detect{|j| j["color"] =~ /anime/ }
        should_red   = jobs.detect{|j| j["color"] =~ /red/ }
      rescue
        # if no response, assume server is down – turn on Red and Yellow lights solid
        server_down = true
      end

      # check results of job colors
      if should_blink
        # something is building... flash yellow light!
        puts "Something is building... flash yellow light!"
        sp.write("1")
      else
        # nothing is building... turn yellow light Off.
        #sp.write("2")
      end

      if should_red
        # something is red... turn On red light!
        puts "Something is broken... turn On red light!"
        sp.write("3")
      else
        # nothing is red... turn On green light.
        sp.write("4")
      end

      if server_down
        sp.write("5")
      end

      # wait 5 seconds
      sleep(5)
    end

    # close serial data line
    sp.close

The Arduino board is fitted inside of the traffic light housing, and mounts to a
perforated prototyping board from Radio Shack using some male-pin headers. Above
the Arduino, are two small PC mount relays capable of switching up to 1 amp at
120vac – perfect for some low wattage light bulbs. The relay coils are
controlled using a 5v signal, and only consume about 90mA at that voltage level,
so we can use the Arduino's onboard 5v regulator to power the relay coils.
Unfortunately, we cannot simply drive the relays directly from an Arduino pin
because it can only supply around 40mA per pin and the inductive switching
properties present in a relay might cause damage to the Arduino. Instead, we can
use 2 small N-type signal transistors (either bjt or mosfet) to interface
between each relay and the Arduino output pin. Building the relay board might
require some hands-on tinkering, but is a rewarding task when complete (circuit
schematic file included).

<a href="http://www.flickr.com/photos/knewter/6853273913/" title="Arduino mounted inside Traffic Light by knewter, on Flickr"><img src="http://farm8.staticflickr.com/7036/6853273913_b78deae1c1.jpg" width="500" height="375" alt="Arduino mounted inside Traffic Light"></a>
<a href="http://www.flickr.com/photos/knewter/6853377099/" title="traffic_light schematic by knewter, on Flickr"><img src="http://farm8.staticflickr.com/7053/6853377099_d7ed759e60.jpg" width="500" height="368" alt="traffic_light schematic"></a>

The Arduino code is simple, basically listening on the serial port for 1 of
about 5 signals. If the Arduino detects a recognized serial byte, it will carry
out a function to control the Traffic lights - there is no extra fluff, just
what is needed. If you are having trouble locating an old Traffic light, or
would like to build a smaller desktop version of the notifier, you can do so
with only an Arduino and a few LEDs (red, yellow, and green) - you don't even
have to solder anything!

<a href="http://www.flickr.com/photos/knewter/6853546789/" title="Poor man's traffic light by knewter, on Flickr"><img src="http://farm8.staticflickr.com/7151/6853546789_d2b5540d8f.jpg" width="500" height="281" alt="Poor man's traffic light"></a>

    // Isotope11 CI-server traffic light
    // Arduino Uno with 2 relays (SPDT) attached to pins 4 and 7
    // isotope11.com 2-9-12

    // declare variables and output pins:
    int inByte; // create a variable to hold the serial input byte
    long lastTx = 0; // create a “long” variable type to hold the millisecond timer value
    int yellow_light = 4; // create an output variable attached to pin 4
    int red_green_light = 7; // create an output variable attached to pin 7

    void setup() {
      Serial.begin(9600);   // start Arduino serial monitor at 9600bps
      pinMode(yellow_light, OUTPUT); // set up pin 4 as an output
      pinMode(red_green_light, OUTPUT); // set up pin 7 as an output
    }

    void loop() {
      // check serial buffer
      if (Serial.available() > 0){
        inByte = Serial.read();    // read serial byte
        Serial.println(inByte);     // print serial byte
        lastTx = millis(); // set the lastTx time-stamp variable equal to the current system timer value

        // the serial bits “49” - “53” are detected when the numeric buttons “1” – “5” are pressed on the keyboard.
        switch(inByte){
        case 49:  // if serial value received is "49" (number 1), blink yellow light
          digitalWrite(yellow_light, HIGH);
          delay(1000);
          digitalWrite(yellow_light, LOW);
          break;
        case 50:  // if serial value is "50" (number 2), turn yellow light off
          digitalWrite(yellow_light, LOW);
          break;
        case 51:  // if serial value is "51" (number 3), turn red light on (green off)
          digitalWrite(red_green_light, HIGH);
          break;
        case 52:  // if serial value is "52" (number 4), turn green light on (red off)
          digitalWrite(red_green_light, LOW);
          break;
        case 53:  // if serial value is "53" (number 5), turn green and yellow lights on solid (api error)
          digitalWrite(red_green_light, LOW);
          digitalWrite(yellow_light, HIGH);  
        }    
      }
      else {
        if ((millis() - lastTx) > 10000) {
           // it has been more than 10 seconds (10000 milliseconds) since any serial information has been received
           // assume there is a break in the PC connection, and turn red and yellow lights on solid.
          digitalWrite(red_green_light, HIGH);
          digitalWrite(yellow_light, HIGH);
        }
      }
    }


### Repo
[The github repository is here.](http://github.com/johndavid400/Isotope11_traffic_lights)

### Parts list:
1. an old Traffic light
2. Arduino Uno, Radio Shack part # 276-128 - $34.99
3. PC prototyping board, Radio Shack part #276-168 - $3.19
4. (2) PC pin relays, Radio Shack part #275-240 - $4.69 ea
5. (2) NPN transistors or mosfets, Radio Shack part #276-2016 - $1.19 ea
6. (2) 10kohm resistors, Radio Shack part #271-1335 - $1.19 pk
7. (2) 100kohm resistors, Radio Shack part #271-1347 - $1.19 pk
8. (20) male-pin breakaway headers, Sparkfun part#PRT-00116 - $1.50
9. (4) 8mm bolts, 1” long (with nuts) - $1.00

### Tools needed:
1. wire/wire snips
2. solder/soldering iron
3. drill/drill bit
