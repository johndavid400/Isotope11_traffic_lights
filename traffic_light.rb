# Isotope11 continous integration server Traffic-light
# Ruby script to monitor json output from Jenkins CI-server, and output the status of projects to a Traffic-light. 
# If all builds are passing, the light is green. 
# If a job is currently building, the yellow light flashes. 
# If any job is failing, the red light is turned on and green turned off.
#
require "serialport"
require "json"
require "faraday"
require "net/http"

# create a new Serial port for the Arduino Uno which uses port /dev/ttyACM0. Older Arduinos should use /dev/ttyUSB0
sp = SerialPort.new("/dev/ttyACM0", 9600)

# wait for connection
sleep(1)

# create a new Faraday connection with the Jenkins server to read the status of each job
api_url = 'http://isotope11.selfip.com:8080'
conn = Faraday.new(:url => api_url)
# grab the json from the jenkins api
puts 'go to loop'

loop do
  begin
    response = conn.get('/api/json')
    # parse the response into a list of jobs that are being monitored
    jobs = JSON.parse(response.body)["jobs"]

    # search each job to see if it contains either "anime" or "red"
    should_blink = jobs.detect{|j| j["color"] =~ /anime/ }
    should_red   = jobs.detect{|j| j["color"] =~ /red/ }
  rescue
    server_down = true
  end

  # check results of job colors
  if should_blink
    # something is building... flash yellow light!
    puts "Something is building... flash yellow light! (Last build @ #{Time.now})"
    sp.write("1")
  end

  if should_red
    # something is red... turn On red light!
    puts "Something is broken... turn On red light! (@ #{Time.now})"
    sp.write("2")
  else
    # nothing is red... turn On green light.
    sp.write("3")
  end

  if server_down
    sp.write("4")
  end

  # wait 5 seconds
  sleep(5)
end

# close serial data line
sp.close

