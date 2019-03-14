ruleset manage_subscriptions_LAB7 {
  meta {

  }
  global {
    account_sid = ""
    auth_token = ""
    violation_number = "+18016472315"
    from_number = "+13852573278"
    
    send_sms = defaction(to, from, message) {
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
      http:post(base_url + "Messages.json", form = {
                "From":from,
                "To":to,
                "Body":message
      })
    }
  }
  
  rule send_twilio_txt {
    select when manage_subscriptions_LAB7 send_message
    pre {
      message = event:attr("message")
    }
    send_sms(violation_number, from_number, message)
  }
}

