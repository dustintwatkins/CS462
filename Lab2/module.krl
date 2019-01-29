
send_sms = defaction(to, from message, account_sid, auth_token) {
	base_url = <<https://#AC91a8c9b18ab863a9d3b6341210008ccb:#c26665da35b3402e717d173989737a89@api.twilio.com/2019-01-01/Accounts/##AC91a8c9b18ab863a9d3b6341210008ccb>>
	http:post(base_url + "Messages.json", form =
		{ "From": from,
		  "To": to,
		  "Body": message
		})
}


rule test_send_sms {
	select when test new_message
	send_sms(event:attr("to"),
		event:attr("from"),
		event:attr("message"),
		event:attr("account_sid"),
		event:attr("auth_token"))
}


ruleset io.picolabs.lesson_keys {
	meta {
		key twilio {
			"account_sid": "AC91a8c9b18ab863a9d3b6341210008ccb"
			"auth_token": "c26665da35b3402e717d173989737a89"
		}
	provides keys twilio to io.picolabs.use_twilio_v2
	}
}

ruleset io.picolabs.use_twilio_v2 {
	meta {
		use module io.pciolabs.lesson_keys
		use module io.picolabs.twilio_v2 alias twilio
			with account_sid = keys:twilio{"account_sid "}
			     auth_token = keys:twilio{"auth_token"}
	}
}

rule test_send_sms {
        select when test new_message
        send_sms(event:attr("to"),
                event:attr("from"),
                event:attr("message")
}
