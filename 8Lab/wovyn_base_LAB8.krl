ruleset wovyn_base_LAB8 {
  meta {
    use module io.picolabs.subscription alias Subscriptions
    use module sensor_profile
    use module temperature_store

    shares _testing
  }

   global {
    _testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                              "attrs": [ "genericThing" ] } ] }
    temperature_threshold = sensor_profile:get_profile(){"high"}.as("Number").defaultsTo(72)
    violation_phone_number = "+18016472315"
    from_number = "+13852573278"
  }
  
    rule start_gen_report {
      select when report generate_report
      pre {
          temps = temperature_store:temperatures().klog("STEP 2 Part b, sensor calling its own temperatures function")
      }
       event:send(
            { "eci": event:attr("Rx"), "eid": "finishedProcessingReport",
            "domain": "report", "type": "report_generated",
            "attrs": {"temps": temps, "Tx": event:attr("Tx"), "correlation_Id": event:attr("correlation_Id")} }
        )
  }

  rule threshold_notification {
      select when wovyn threshold_violation
       foreach Subscriptions:established("Rx_role","temp_sensor_controller") setting (subscription)
      pre {
          subs = subscription.klog("Subscriptions:")
      }
      event:send({
        "eci": subsctiption{"Tx"},
        "eid": "threshold-violation",
        "domain": "sensor_manager_LAB7",
        "type": "sub_threshold_violation",
        "attrs": event:attrs
      })
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
    select when wovyn heartbeat
    // select when wovyn heartbeat where event:attr("genericThing")
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

  rule accept_sub {
    select when wrangler inbound_pending_subscription_added
    fired {
      raise wrangler event "pending_subscription_approval"
      attributes event:attrs
    }
  }
}

