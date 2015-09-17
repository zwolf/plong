# originally by https://github.com/jtrost

require 'date'
require 'fileutils'
require 'yaml'
require 'pp'

LOGPATH = "./logs/"
DATAPATH = "./data/"
SAMPLESIZE = 300
PAGELOADS_PER_SECOND = 30
MAX_REQUESTS_PER_PAGELOAD = 4

@logs = []
@domains = ARGV.empty? ? YAML.load_file(DATAPATH + "domains.yml") : ARGV

def run
  begin
    puts "Faking logs..."
    loop do
      # A random log will get written to however many times per second you define
      (1..PAGELOADS_PER_SECOND).each do |s|
        write_log(@logs.sample)
      end
      sleep (1)
    end
  rescue SystemExit, Interrupt => e
    puts "\nExiting (and deleting fake logs)..."
    delete_logs(@logs)
  end
end

def write_log(filename)
  File.open(LOGPATH + filename, "a") do |file|
    # Models between 1 and your max requests per pageload
    ((1..MAX_REQUESTS_PER_PAGELOAD).to_a.sample).times do
      file.write("#{request}\n")
    end
  end
end

def delete_logs(logs)
  @logs.each {|log| File.delete(LOGPATH + log)}
  File.delete(DATAPATH + "codex.yml")
end

def create_files
  Dir.mkdir "./logs" unless Dir.exist?("./logs")
  
  @domains.sample(SAMPLESIZE).each do |domain|
    FileUtils.touch(LOGPATH + "#{domain}.access.log")
    @logs << "#{domain}.access.log"
  end
  
  # Save a list of files for the watcher to read
  File.open(DATAPATH + "codex.yml", "a") do |file|
    file.write("---\ndomains:\n")
    @logs.each {|log| file.write("  - #{log}\n")}
  end
  
end

def request
  %Q(127.0.0.1 - - [#{DateTime.now.strftime("%d\/%b\/%Y:%H:%M:%S\s-0700")}] "GET #{path.sample} HTTP/1.1" #{status_codes.sample} #{Random.new.rand(1000..50000)} "#{@domains.sample}" "#{user_agents.sample}" "#{random_ip}")
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
create_files
run
