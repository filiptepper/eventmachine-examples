require "rubygems"
require "active_record"
require "eventmachine"
require "evma_httpserver"

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :username => "root",
  :database => "blip_development"
)

class Handler < EM::Connection
  include EM::HttpServer

  def process_http_request
    response = EM::DelegatedHttpResponse.new self

    operation = proc do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute("SELECT SLEEP(1)")

        response.status = 200
        response.content = connection.execute("SELECT SQL_NO_CACHE COUNT(*) FROM users").fetch_row[0]
      end
    end

    callback = proc do |r|
      response.send_response
    end

    EM.defer operation, callback
  end
end

EM.run do
  EM.epoll
  EM.start_server "0.0.0.0", 9876, Handler
end

__END__

~ $ ab -n 50 -c 5 http://127.0.0.1:9876/
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient).....done


Server Software:
Server Hostname:        127.0.0.1
Server Port:            9876

Document Path:          /
Document Length:        4 bytes

Concurrency Level:      5
Time taken for tests:   50.472 seconds
Complete requests:      50
Failed requests:        0
Write errors:           0
Total transferred:      2150 bytes
HTML transferred:       200 bytes
Requests per second:    0.99 [#/sec] (mean)
Time per request:       5047.228 [ms] (mean)
Time per request:       1009.446 [ms] (mean, across all concurrent requests)
Transfer rate:          0.04 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.4      0       3
Processing:  2003 4966 1166.4   5038    8041
Waiting:     2003 4786 1093.7   5038    8041
Total:       2003 4967 1166.3   5038    8041

Percentage of the requests served within a certain time (ms)
  50%   5038
  66%   5048
  75%   5072
  80%   6018
  90%   7045
  95%   7078
  98%   8041
  99%   8041
 100%   8041 (longest request)
