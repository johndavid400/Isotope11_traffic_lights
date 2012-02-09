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
#sp = SerialPort.new("/dev/ttyACM0", 9600)
sp = SerialPort.new("/dev/ttyUSB0", 9600)

# wait for connection
sleep(1)

# create a new Faraday connection with the Jenkins server to read the status of each job
#  you need to create this url in your .bashrc
api_url = ENV['JENKINS_URL']
conn = Faraday.new(:url => api_url)
# grab the json from the jenkins api

loop do
  response = conn.get('/api/json')
  # parse the response into a list of jobs that are being monitored
  #
  jobs = JSON.parse(response.body)["jobs"]

  # search each job to see if it contains either "anime" or "red"
  should_blink = jobs.select{|j| j["color"] =~ /anime/ }
  should_red   = jobs.select{|j| j["color"] =~ /red/ }

  # check results of job colors
  if !should_blink.empty?
    # something is building... flash yellow light!
    sp.write("1")
    puts "Something is building... flash yellow light!"
  else
    # nothing is building... turn yellow light Off.
    # sp.write("2")
  end

  if !should_red.empty?
    # something is red... turn On red light!
    sp.write("3")
    puts "Something is broken... turn On red light!"
  else
    # nothing is red... turn On green light.
    sp.write("4")
  end

  # wait 5 seconds
  sleep(5)
end

# close serial data line
sp.close

