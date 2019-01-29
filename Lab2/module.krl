ruleset io.picolabs.twilio_v2 {
  meta {
    configure using account_sid = "AC91a8c9b18ab863a9d3b6341210008ccb"
                    auth_token = "c26665da35b3402e717d173989737a89"
    provides
        send_sms,
        messages
  }

  global {
    send_sms = defaction(to, from, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json", form = {
                "From":from,
                "To":to,
                "Body":message
            })
    }

    messages = function(to, from, pageSize) {
            base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>;
            q = {};
            q = (pageSize.isnull()) => q | q.put({"PageSize":pageSize});
            q = (to.isnull()) => q | q.put({"To":to});
            q = (from.isnull()) => q | q.put({"From":from});
            q.klog("Query string before get request: ");
            res = http:get(base_url + "Messages.json", qs = q).klog("Raw Res: ");
            res{"content"}.decode(){"messages"}.klog("Decoded res");
        }
  }
}

