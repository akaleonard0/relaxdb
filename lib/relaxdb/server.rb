module RelaxDB

  class Server
        
    def initialize(host, port)
      @host = host
      @port = port
    end

    def delete(uri)
      request(Net::HTTP::Delete.new(uri))
    end

    def get(uri)
      request(Net::HTTP::Get.new(uri))
    end

    def put(uri, json)
      req = Net::HTTP::Put.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def post(uri, json)
      req = Net::HTTP::Post.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def request(req)
      res = Net::HTTP.start(@host, @port) {|http|
        http.request(req)
      }
      if (not res.kind_of?(Net::HTTPSuccess))
        handle_error(req, res)
      end
      res
    end
    
    private

    def handle_error(req, res)
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
      raise e
    end
  end
    
  class CouchDB
    
    attr_accessor :get_count
    attr_reader :cache
    attr_reader :url
    
    def initialize(config)
      @server = RelaxDB::Server.new(config[:host], config[:port])
      @db = config[:db]
      @url = "http://#{config[:host]}:#{config[:port]}/#{config[:db]}"

      if config[:logger]
        @logger = config[:logger]
      else
        # Revise the Tempfile idea - it's not great
        log_dev = config[:log_dev] || Tempfile.new('couchdb.log')
        log_level = config[:log_level] || Logger::INFO
        @logger = Logger.new(log_dev)
        @logger.level = log_level
      end
      
      @get_count = 0
    end
    
    def delete(uri=nil)
      puri = uri ? ::CGI::unescape(uri) : ""
      @logger.info("DELETE /#{@db}/#{puri}")
      @server.delete("/#{@db}/#{uri}")
    end
    
    def get(uri=nil)
      @get_count +=1 
      puri = uri ? ::CGI::unescape(uri) : ""
      @logger.debug("GET /#{@db}/#{puri}")
      @server.get("/#{@db}/#{uri}")
    end
    
    def put(uri=nil, json=nil)
      puri = uri ? ::CGI::unescape(uri) : ""
      @logger.info("PUT /#{@db}/#{puri} #{json}")
      @server.put("/#{@db}/#{uri}", json)
    end
    
    def post(uri=nil, json=nil)
      puri = uri ? ::CGI::unescape(uri) : ""
      @logger.info("POST /#{@db}/#{puri} #{json}")
      @server.post("/#{@db}/#{uri}", json)
    end

  end
        
end
