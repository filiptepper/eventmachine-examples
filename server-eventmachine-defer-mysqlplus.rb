require "rubygems"
require "active_record"
require "eventmachine"
require "evma_httpserver"

require "mysqlplus"
class Mysql; alias :query :c_async_query; end

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
Time taken for tests:   10.046 seconds
Complete requests:      50
Failed requests:        0
Write errors:           0
Total transferred:      2150 bytes
HTML transferred:       200 bytes
Requests per second:    4.98 [#/sec] (mean)
Time per request:       1004.616 [ms] (mean)
Time per request:       200.923 [ms] (mean, across all concurrent requests)
Transfer rate:          0.21 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       0
Processing:  1001 1004   4.7   1002    1018
Waiting:     1001 1004   4.6   1002    1018
Total:       1001 1004   4.7   1002    1018

Percentage of the requests served within a certain time (ms)
  50%   1002
  66%   1004
  75%   1004
  80%   1006
  90%   1014
  95%   1016
  98%   1018
  99%   1018
 100%   1018 (longest request)