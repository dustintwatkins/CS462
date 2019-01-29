// module for keys
ruleset io.picolabs.lesson_keys {
	meta {
		key twilio {
			"account_sid": "AC91a8c9b18ab863a9d3b6341210008ccb"
			"auth_token": "c26665da35b3402e717d173989737a89"
		}
	provides keys twilio to io.picolabs.use_twilio_v2
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
  }
}
