ruleset wovyn_base {
  meta {
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
      with account_sid = keys:twilio{"acount_sid"}
          auth_token = keys:twilio{"auth_token"}
          
    shares _testing
  }
  
   global {
    _testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                              "attrs": [ "genericThing" ] } ] }
    temperature_threshold = 75.5
    violation_phone_number = "+18016472315"
    from_number = "+13852573278"
  }

  rule threshold_notification {
      select when wovyn threshold_violation
      pre {
          temperature = event:attr("temperature").klog("TEMPERATURE VIOLATION -> sending notification")
      }
      
      twilio:send_sms(violation_phone_number,
                        from_number,
                        "Temperature above 75.5 degrees! " + temperature + event:attr("timestamp")
                        )
  }

  rule find_high_temps {
      select when wovyn new_temperature_reading
      pre {
          temperature = event:attr("temperature").klog("temperature")
          isGreaterThanThreshold = (temperature > temperature_threshold).klog("Broke threshold?")
      }

      if isGreaterThanThreshold then
        send_directive("temp_violation", {"occurred": isGreaterThanThreshold})

      fired {
          raise wovyn event "threshold_violation"
            attributes event:attrs
      }
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing")
    pre {
        temperature = event:attr("genericThing"){"data"}{"temperature"}[0]{"temperatureF"}
        .klog("WOOT")
    }

    send_directive("heartbeat", {"data": temperature})

    fired {
        raise wovyn event "new_temperature_reading"
            attributes {"temperature": temperature, "timestamp": time:now()}
    }
  }
}
