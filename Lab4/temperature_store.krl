
ruleset temperature_store {
    meta {
        provides temperatures, threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
    }
    global {
        temperatures = function() {
            ent:persist_temperatures.defaultsTo([])
        }

        threshold_violations = function() {
            ent:persist_violations.defaultsTo([])
        }

        inrange_temperatures = function() {
          // Set operation difference returns values in temperatures that are not in threshold_violations
          temperatures().difference(threshold_violations()).klog("inrange_temperatures difference:")
        }
    }
    
    rule collect_temperatures {
        select when wovyn new_temperature_reading
        pre {
            temperature = event:attr("temperature").klog("collect_temperatures temperature:")
            timestamp = event:attr("timestamp").klog("collect temperatures timestamp:")
        }

        always {
            ent:persist_temperatures := ent:persist_temperatures.defaultsTo([]); 
            ent:persist_temperatures := ent:persist_temperatures.append({"timestamp": timestamp, "temperature": temperature})
        }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation
        pre {
            temperature = event:attr("temperature").klog("collect_threshold_violations temperature:")
            timestamp = event:attr("timestamp").klog("collect_threshold_violations timestamp:")
        }

        always {
            ent:persist_violations := ent:persist_violations.defaultsTo([]); 
            ent:persist_violations := ent:persist_violations.append({"timestamp": timestamp, "temperature": temperature})
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        always {
            ent:persist_temperatures := [].klog("clear persistent temperatures");
            ent:persist_violations := [].klog("clear persistent temperature violations");
        }
    }
}
