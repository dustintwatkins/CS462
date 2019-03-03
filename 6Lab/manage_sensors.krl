ruleset manage_sensors {
  meta {
    shares sensors, getTemperatures
  }
  global {
    
    defThreshold = 85.1
    
    sensors = function() {
      ent:sensors.klog("GET SENSORS")
    }
    
    retrieveTemperature = function(val, key) {
      eci = val{"eci"};
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
                  "rids": ["temperature_store", "sensor_profile", "wovyn_base"]
      }
    }
  }
  
  rule newSensorDetected {
    select when wrangler new_child_created
    pre {
      sensor_obj = {"id": event:attr("id"), "eci": event:attr("eci")}
      name = event:attr("name").klog("NEW CHILD CREATED")
    }
    
    event:send({ 
        "eci": sensor_obj{"eci"}, "eid": "set_profile",
        "domain": "sensor", "type": "profile_updated",
        "attrs": { "name": name, "high": defThreshold } 
      }
    )

    always {
      name.klog("*** NEW SENSOR DETECTED ***");
      ent:sensors := ent:sensors.defaultsTo({});
      ent:sensors{[name]} := sensor_obj
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
}

