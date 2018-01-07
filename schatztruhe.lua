-- this is a comment
print("Schatztruhe Anne & Felix")

--------------------------------------------
-- GPIO Setup
--------------------------------------------
print("Setting Up GPIO...")

pwm_frequency = 50
pwm_state1 = 48
pwm_state2 = 90
pwm_traveltime_timer_id = 0
pwm_traveltime_timeout_millis = 500
pwm_servo_pin = 1
tmr_openstate = 1
tmr_openstate_timeout = 1250

relais_out_pin = 2
led_red_pin = 3
led_green_pin = 4
gpio.mode(relais_out_pin, gpio.OUTPUT)
gpio.mode(led_red_pin, gpio.OUTPUT)
gpio.mode(led_green_pin, gpio.OUTPUT)
gpio.write(relais_out_pin, gpio.LOW)
gpio.write(led_red_pin, gpio.HIGH)
gpio.write(led_green_pin, gpio.LOW)
gpio.mode(pwm_servo_pin, gpio.OUTPUT)
gpio.write(pwm_servo_pin, gpio.LOW)
pwm.setup(pwm_servo_pin, pwm_frequency, pwm_state2)
pwm.stop(pwm_servo_pin)

----------------
-- Timers     --
----------------
tmr.register(pwm_traveltime_timer_id, pwm_traveltime_timeout_millis, tmr.ALARM_SEMI, function()
    pwm.stop(pwm_servo_pin)
    print("...pwm disabled.")
end)

------------------
-- Reset servo  --
------------------
print("driving servo to open state...")
pwm.setduty(pwm_servo_pin, pwm_state2)
tmr.start(pwm_traveltime_timer_id)

----------------
-- Init Wifi  --
----------------
print("Wifi Station Setup")
cfg={}
 cfg.ssid="Schatztruhe"
 cfg.pwd="12345678"
 wifi.ap.config(cfg)
 
wifi.setmode(wifi.SOFTAP)
wifi.ap.dhcp.start()

print("IP: "..wifi.ap.getip())
 
----------------
-- Web Server --
----------------
print("Starting Web Server...")
-- a simple HTTP server
if srv~=nil then
  print("found an open server. closing it...")
  srv:close()
  print("done. now tyring to start...")
end

function Sendfile(sck, filename, sentCallback)
    print("opening file "..filename.."...")
    if not file.open(filename, "r") then
        sck:close()
        return
    end
    local function sendChunk()
        local line = file.read(512)
        if (line and #line>0) then 
            sck:send(line, sendChunk) 
        else
            file.close()
            collectgarbage()
            if sentCallback then
                sentCallback()
            else
                sck:close()
            end
        end
    end
    sendChunk()
end

srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", function(sck, request_payload)
        local payload = ""
        if request_payload == nil or request_payload == "" then
            payload = ""
        else
            payload = request_payload
        end
        print(payload)
        
        -- extract passcode digits --
        local pw1 = string.match(payload, "pw1=(%d)")
        local pw2 = string.match(payload, "pw2=(%d)")
        local pw3 = string.match(payload, "pw3=(%d)")
        local pw4 = string.match(payload, "pw4=(%d)")
        local pw5 = string.match(payload, "pw5=(%d)")
        local pw6 = string.match(payload, "pw6=(%d)")
        local pw7 = string.match(payload, "pw7=(%d)")
        local pw8 = string.match(payload, "pw8=(%d)")
        all_digits_given = pw1 and pw2 and pw3 and pw4 and pw5 and pw6 and pw7 and pw8
        pw_correct = pw1=="2" and pw2=="5" and pw3=="0" and pw4=="2" and pw5=="2" and pw6=="0" and pw7=="1" and pw8=="3"

        print("all_digits_given: "..(all_digits_given and "yes" or "no"))
        print("pw_correct: "..(pw_correct and "yes" or "no"))

        file.open("table.html", "w+")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw1\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw1 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw2\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw2 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw3\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw3 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw4\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw4 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw5\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw5 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw6\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw6 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw7\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw7 or "").."\"></td>")
        file.writeline("<td><input class=\"digit\" type=\"text\" name=\"pw8\" maxlength=\"1\" onclick=\"this.value='';\" value=\""..(pw8 or "").."\"></td>")
        file.flush()
        file.close()

        function handle_post()
            print("### handle_post() ###")
            print("pw1= "..(pw1 or "?"))
            print("pw2= "..(pw2 or "?"))
            print("pw3= "..(pw3 or "?"))
            print("pw4= "..(pw4 or "?"))
            print("pw5= "..(pw5 or "?"))
            print("pw6= "..(pw6 or "?"))
            print("pw7= "..(pw7 or "?"))
            print("pw8= "..(pw8 or "?"))
        
            if( pw_correct ) then
                print("correct password!")
                print("opening...")
                gpio.write(relais_out_pin, gpio.HIGH)
                gpio.write(led_green_pin, gpio.HIGH)
                gpio.write(led_red_pin, gpio.LOW)

                pwm.setduty(pwm_servo_pin, pwm_state1)
                pwm.start(pwm_servo_pin)
                tmr.start(pwm_traveltime_timer_id)
                print("pwm started for travel...")
                
                tmr.alarm(tmr_openstate, tmr_openstate_timeout, tmr.ALARM_SINGLE, function() 
                                                        print("...CLOSE")
                                                        gpio.write(relais_out_pin, gpio.LOW)
                                                        gpio.write(led_green_pin, gpio.LOW)
                                                        gpio.write(led_red_pin, gpio.HIGH)

                                                        pwm.setduty(pwm_servo_pin, pwm_state2)
                                                        pwm.start(pwm_servo_pin)
                                                        tmr.start(pwm_traveltime_timer_id)
                                                     end)
            else 
                print("wrong password!")
            end
        end
        
        --parse position POST value from header
        postparse = { string.find(payload,"unlockcodesent=") }
        local submissionPerformed = postparse[2]~=nil
        if submissionPerformed then 
            handle_post() 
        end

        sck:send("HTTP/1.1 200 OK\r\n" ..
            "Server: NodeMCU on ESP8266\r\n" ..
            "Content-Type: text/html; charset=UTF-8\r\n\r\n", 
            function()
                Sendfile(sck, "1.html", function() 
                    local fileName = "2_input.html"
                    if(all_digits_given) then
                        if(pw_correct) then
                            fileName = "2_ok.html"
                        else
                            fileName = "2_fail.html"
                        end
                    end
                    Sendfile(sck, "table.html", function() 
                        Sendfile(sck, fileName, function() 
                            --Sendfile(sck, "3.html", function() 
                                sck:close()
                            --end)
                        end)
                    end)
                end)
            end)
        end)
    end)
