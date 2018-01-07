button_pin = 0
gpio.mode(button_pin, gpio.INPUT)
local buttonpressed = gpio.read(button_pin)
print("buttonpressed: "..(buttonpressed or "?"))

if(buttonpressed==0) then
    print("interrupting autostart")
else
    tmr.alarm(0, 5000, tmr.ALARM_SINGLE, function() 
            dofile("schatztruhe.lua")
        end) 
end
