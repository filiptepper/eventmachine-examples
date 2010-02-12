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

    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.execute("SELECT SLEEP(1)")

      response.status = 200
      response.content = connection.execute("SELECT SQL_NO_CACHE COUNT(*) FROM users").fetch_row[0]
    end
    response.send_response
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
Time taken for tests:   50.258 seconds
Complete requests:      50
Failed requests:        0
Write errors:           0
Total transferred:      2150 bytes
HTML transferred:       200 bytes
Requests per second:    0.99 [#/sec] (mean)
Time per request:       5025.832 [ms] (mean)
Time per request:       1005.166 [ms] (mean, across all concurrent requests)
Transfer rate:          0.04 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       1
Processing:  5005 5026  15.1   5030    5046
Waiting:     2002 4904 598.6   5029    5045
Total:       5005 5026  15.1   5030    5046

Percentage of the requests served within a certain time (ms)
  50%   5030
  66%   5035
  75%   5037
  80%   5045
  90%   5046
  95%   5046
  98%   5046
  99%   5046
 100%   5046 (longest request)
