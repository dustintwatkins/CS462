ruleset manage_sensors_LAB8 {
  meta {
    shares sensors, getLast5Reports
    use module io.picolabs.subscription alias Subscriptions
    use module manage_subscriptions_LAB7
  }
  global {
     sensors = function() {
            Subscriptions:established("Rx_role", "temp_sensor").klog("wassup")
        }
        
     getLast5Reports = function() {
            reportsInReverseOrder = ent:completedReports.defaultsTo([]).reverse();
            len = reportsInReverseOrder.length() > 5 => 5 | reportsInReverseOrder.length();
            reportsInReverseOrder.slice(len)
        }
  }
  
   rule startReporting {
        select when report start
        pre {
            correlation_Id = random:uuid().klog("start reporting... STEP 1")
        }
        always {
            ent:pendingReports := ent:pendingReports.defaultsTo({}).klog("reports in progre$$");
            ent:pendingReports := ent:pendingReports.put([correlation_Id], {"temperature_sensors": sensors().length(), "temperatures": []});
            raise report event "inform_sensors" attributes {"correlation_Id": correlation_Id}.klog("raised event:inform sensors")
        }
    }
  
    rule sendEventToSensors {
        select when report inform_sensors
        foreach sensors() setting(sensor)
            pre {
                attrs = {"Rx": sensor{"Rx"}, "Tx": sensor{"Tx"}, "correlation_Id": event:attr("correlation_Id")}.klog("attrs:")
                .klog("STEP 2 Part a... Sending event to this sensor!")
            }
            event:send(
                { "eci": sensor{"Tx"}, "eid": "reportStart",
                "domain": "report", "type": "generate_report",
                "attrs": attrs }
            )
    }
    
    rule sensorReceivedReport {
        select when report report_generated
          pre {
            correlation_Id = event:attr("correlation_Id").klog("report received: correlation_Id")
            report = ent:pendingReports{correlation_Id}
            reports = report{"temperatures"}.append({"tx": event:attr("Tx"), "temps": event:attr("temps")})
            .klog("STEP 3... Sensor gen report")
          }
          if (report["temperature_sensors"] == reports.length()) then noop()
            fired {
              ent:pendingReports := ent:pendingReports.put([correlation_Id], {"temperature_sensors": report["temperature_sensors"], "temperatures": reports});
              ent:completedReports := ent:completedReports.defaultsTo([]).append({
                  "temperature_sensors": ent:pendingReports{[correlation_Id, "temperature_sensors"]},
                  "responding": ent:pendingReports{[correlation_Id, "temperatures"]}.length(),
                  "temperatures": ent:pendingReports{[correlation_Id, "temperatures"]}
            })
          } else {
              ent:pendingReports := ent:pendingReports.put([correlation_Id], {"temperature_sensors": report["temperature_sensors"], "temperatures": reports});
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
      eci = event:attr("eci").klog("INTRODUCE ECI:")
      name = event:attr("name").klog("INTRODUCE ZZQQ:")
    }
    always {
      raise wrangler event "subscription" attributes {
        "name": name,
        "Rx_role": "NOT SENSOR",
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

