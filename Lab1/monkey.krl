ruleset hello_world {
	meta {
		name "Hello World"
		description << A first ruleset for the Quickstart >>
		author "Dustin Watkins"
		logging on
		shares monkey, hello
	}

	global {
		hello = function(obj) {
			msg = "Hello " + obj;
			msg
		}
	}

	rule hello_world {
		select when echo hello
		send_directive("say", {"something": "Hello World"})
	}
	
	rule hello_monkey {
	  select when echo monkey
	  pre {
	    attribute = event:attr("name")
	    messageBody = {"something": "Hello " + (attribute => attribute | "Monkey")}
	  }
	  send_directive("say", messageBody)
	}
}

