# plong
A real-time log monitoring, parsing, and storage script. Or at least it will be.

* Start your local mongodb service.
* Create a domains.yml with the list of domains you want to fake logs for. Each domain will have its own *.access.log file. The faker will create a codex file that the watcher will read in order to know what needs watching.
* Run the log faker and let it fake logs.
* Run the watcher and either let it look for ./data/codex.yml or tell it what files to look at (and where).
* Watch your mongo "parsed_logs" db fill up with the parsed output of each log in its own collection.

You're probably gonna need a few CPAN modules.

TODO: 

* Benchmarking! It is yet to be determined if this method is going to be better/faster/easier than forking processes directly.
* A frontend! Maybe use POE to run a lil' webserver or just use Node or Sinatra or something.
* other stuff as I think of it.