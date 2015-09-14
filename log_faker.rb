# originally by https://github.com/jtrost

require 'date'

LOGPATH = "./logs/"

def run
  logs = ARGV.empty? ? ['site.access.log', 'site.error.log'] : ARGV

  puts "Opening logs:"
  logs.each do |l|
    puts LOGPATH + l
  end
  
  begin
    loop do
      # Changes to a file wont appear until the file is closed, which is why we have to open/close it each time.
      logs.each do |l|
        write_log(l)
      end
      sleep (1..4).to_a.sample
    end
  rescue SystemExit, Interrupt => e
    puts "\nExiting (and deleting fake logs)..."
    logs.each do |l|
      puts "Deleting " + LOGPATH + l
      File.delete(LOGPATH + l)
    end
  end
end

def write_log(filename)
  File.open(LOGPATH + "#{filename}", "a") do |file|
    ((1..4).to_a.sample).times do
      file.write("#{request}\n")
    end
  end
end

def request
  %Q(127.0.0.1 - - [#{DateTime.now.strftime("%d\/%b\/%Y:%H:%M:%S\s-0700")}] "GET #{path.sample} HTTP/1.1" #{status_codes.sample} #{Random.new.rand(1000..50000)} "#{domains.sample}" "#{user_agents.sample}" "#{random_ip}")
end

def domains
  [
    "http://www.usw.org/",
    "http://www.atu.org/",
    "http://www.trilogyinteractive.com/",
    "http://www.theunion.org/",
    "http://www.cadem.org/",
    "http://www.dickdurbin.com/",
    "http://www.afscme.org/",
  ]
end

def status_codes
  # Common response codes appear more so #sample gives a more realistic distribution of responses.
  [
    "200", "200", "200", "200", "200", "200", "200", "200", "200", "200",
    "404", "404", "404", "404",
    "206", "206", 
    "410", "502", "500", "410",
  ]
end

def random_ip
  random = Random.new
  ip = String.new

  4.times do |i|
    [1,2,3].sample.times do
      ip << random.rand(0..9).to_s
    end

    ip << "." unless i == 3
  end

  ip
end

def path
  [
    "/theme/css/nav.css",
    "/theme/css/style.css",
    "/theme/scripts/site.js",
    "/theme/scripts/jquery.js",
    "/theme/img/logo.png",
    "/theme/img/home.png",
    "/theme/img/blank.gif",
    "/",
    "/about",
    "/about/staff",
    "/about/contact",
    "/blog",
    "/blog/our-first-post",
    "/blog/our-last-post",
    "/issues/some/deeply/nested/issue"
  ]
end

def user_agents
  [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/7.1.7 Safari/537.85.16",
    "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (Android; Tablet; rv:38.0) Gecko/38.0 Firefox/38.0",
    "Mozilla/5.0 (iPad; CPU OS 8_4_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H321 Safari/600.1.4",
    "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36"
  ]
end

### Start running
run
