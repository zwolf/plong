# plong
A real-time log monitoring, parsing, and storage script.

* Start your local mongodb service.
* Run the log faker and tell it what filenames you want to use for your fake logs. By default they'll go to ./logs, so create that or decide where they should go instead.
* Run the watcher and either tell it what files to look at (and where) or let it use it's defaults (hopefully the same as your fake logs).
* Watch your mongo "parsed_logs" db fill up with the parsed output of each log in its own collection.

You're probably gonna need a few CPAN modules.
