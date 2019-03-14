ruleset manage_sensors_LAB7 {
  meta {
    shares __testing, sensors, getTemperatures
    use module io.picolabs.subscription alias Subscriptions
    use module manage_subscriptions_LAB7
  }
  global {
    
    defThreshold = 85.1
    
    sensors = function() {
      Subscriptions:established("Rx_role", "temp_sensor").klog("GET SENSORS")
    }
    
    retrieveTemperature = function(val, key) {
      eci = val{"Tx"};
      res = http:get("http://localhost:8080/sky/cloud/" + eci + "/temperature_store/temperatures");
      res{"content"}.decode();
    }
    
    getTemperatures = function() {
      sensors().map(retrieveTemperature)
    }
  }
  
  rule createNewSensor {
    select when sensor new_sensor 
    pre {
      name = event:attr("name").klog("CREATE NEW SENSOR")
      exists = ent:sensors >< name
    }
    
    if not exists then
      noop()
      
    fired {
      raise wrangler event "child_creation" 
      attributes {"name": name, 
                  "color": "#0d915c", 
                  "rids": ["io.picolabs.subscription", "temperature_store", "sensor_profile", "wovyn_base_LAB7"]
      }
    }
  }
  
  rule newSensorDetected {
    select when wrangler new_child_created
    pre {
      eci = event:attr("eci").klog("ECI FOR NEW CHILD")
      name = event:attr("name").klog("NEW CHILD CREATED")
    }

    always {
      name.klog("*** NEW SENSOR DETECTED ***");
      ent:sensors := ent:sensors.defaultsTo({});
      ent:sensors{[name]} := {};
      raise wrangler event "subscription" attributes {
        "name": name,
        "Rx_role": "temp_sensor",
        "Tx_role": "temp_sensor_controller",
        "channel_type": "subscription",
        "wellKnown_Tx": eci
      }
    }
  }
  
  rule subscriptionAdded {
    select when wrangler subscription_added
    pre {
      Tx = event:attr("_Tx").klog("SUBSCRIPTION ADDED Tx")
    }
  }
  
  rule delete_sensor {
    select when sensor unneeded_sensor
    pre {
      name = event:attr("name").klog("DELETE SENSOR")
      exists = ent:sensors >< name
      sensorToDelete = ent:sensors{name}
    }
    
    if exists then
      noop()
      
    fired {
      raise wrangler event "child_deletion" 
        attributes sensorToDelete;
      ent:sensors := ent:sensors.delete([name])
    }
  }
  
  rule introduceSensor {
    select when sensor introduce
    pre {
      eci = event:attr("eci")
      name = event:attr("name").klog("INTRODUCE ZZQQ:")
    }
    always {
      raise wrangler event "subscription" attributes {
        "name": name,
        "Rx_role": "temp_sensor",
        "Tx_role": "temp_sensor_controller",
        "channel_type": "subscription",
        "wellKnown_Tx": eci
      }
    }
  }
  
  rule subscriptionTemperatureViolation {
    select when sensor_manager_LAB7 threshold_violation
    pre {
      message = "Subscription Temperature Violation: " + event:attr("temperature")  + " at " + event:attr("timestamp")
    }
    always {
      manage_subscriptions_LAB7:send_twilio_text(message)
    }
  }
}


