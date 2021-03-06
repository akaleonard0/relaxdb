module RelaxDB

  class NotFound < StandardError; end
  class DocumentNotSaved < StandardError; end
  class UpdateConflict < DocumentNotSaved; end
  class ValidationFailure < DocumentNotSaved; end
  
  @@db = nil
  
  class <<self

    def configure(config)
      @@db = CouchDB.new(config)
    end
  
    def db
      @@db
    end
    
    def logger
      @@db.logger
    end
    
    # Creates the named database if it doesn't already exist
    def use_db(name)
      db.use_db name
    end
    
    def db_exists?(name)
      db.db_exists? name
    end
    
    def delete_db(name)
      db.delete_db name
    end
    
    def list_dbs
      db.list_dbs
    end
    
    def replicate_db(source, target)
      db.replicate_db source, target
    end
    
    def bulk_save!(*objs)
      pre_save_success = objs.inject(true) { |s, o| s &= o.pre_save }
      raise ValidationFailure, objs unless pre_save_success
      
      docs = {}
      objs.each { |o| docs[o._id] = o }
      
      begin
        resp = db.post("_bulk_docs", { "docs" => objs }.to_json )
        data = JSON.parse(resp.body)
    
        data["new_revs"].each do |new_rev|
          obj = docs[ new_rev["id"] ]
          obj._rev = new_rev["rev"]
          obj.post_save
        end
      rescue HTTP_409
        raise UpdateConflict, objs
      end
    
      objs
    end
    
    def bulk_save(*objs)
      begin
        bulk_save!(*objs)
      rescue ValidationFailure, UpdateConflict
        false
      end
    end
    
    def reload(obj)
      load(obj._id)
    end
  
    def load(ids)
      # RelaxDB.logger.debug(caller.inject("#{db.name}/#{ids}\n") { |a, i| a += "#{i}\n" })
      
      if ids.is_a? Array
        resp = db.post("_all_docs?include_docs=true", {:keys => ids}.to_json)
        data = JSON.parse(resp.body)
        data["rows"].map { |row| row["doc"] ? create_object(row["doc"]) : nil }
      else
        begin
          resp = db.get(ids)
          data = JSON.parse(resp.body)
          create_object(data)
        rescue HTTP_404
          nil
        end
      end
    end
    
    def load!(ids)
      res = load(ids)
      
      raise NotFound, ids if res == nil
      raise NotFound, ids if res.respond_to?(:include?) && res.include?(nil)
      
      res
    end
    
    # Used internally by RelaxDB
    def retrieve(view_path, design_doc=nil, view_name=nil, map_func=nil, reduce_func=nil)
      begin
        resp = db.get(view_path)
      rescue => e
        dd = DesignDocument.get(design_doc).add_map_view(view_name, map_func)
        dd.add_reduce_view(view_name, reduce_func) if reduce_func
        dd.save
        resp = db.get(view_path)
      end
      
      data = JSON.parse(resp.body)
      ViewResult.new(data)
    end
      
    # Requests the given view from CouchDB and returns a hash.
    # This method should typically be wrapped in one of merge, instantiate, or reduce_result.
    def view(design_doc, view_name)
      q = Query.new(design_doc, view_name)
      yield q if block_given?
      
      resp = q.keys ? db.post(q.view_path, q.keys) : db.get(q.view_path)
      JSON.parse(resp.body)      
    end
    
    # Should be invoked on the result of a join view
    # Merges all rows based on merge_key and returns an array of ViewOject
    def merge(data, merge_key)
      merged = {}
      data["rows"].each do |row|
        value = row["value"]
        merged[value[merge_key]] ||= {}
        merged[value[merge_key]].merge!(value)
      end
      
      merged.values.map { |v| ViewObject.create(v) }
    end
    
    # Creates RelaxDB::Document objects from the result
    def instantiate(data)
      create_from_hash(data)
    end
    
    # Returns a scalar, an object, or an Array of objects
    def reduce_result(data)
      obj = data["rows"][0] && data["rows"][0]["value"]
      ViewObject.create(obj)      
    end
    
    def paginate_view(page_params, design_doc, view_name, *view_keys)
      paginate_params = PaginateParams.new
      yield paginate_params
      raise paginate_params.error_msg if paginate_params.invalid? 
      
      paginator = Paginator.new(paginate_params, page_params)
                  
      query = Query.new(design_doc, view_name)
      query.merge(paginate_params)
      
      docs = ViewResult.new(JSON.parse(db.get(query.view_path).body))
      docs.reverse! if paginate_params.order_inverted?
      
      paginator.add_next_and_prev(docs, design_doc, view_name, view_keys)
      
      docs
    end
        
    def create_from_hash(data)
      data["rows"].map { |row| create_object(row["value"]) }
    end
  
    def create_object(data)
      # revise use of string 'class' - it's a reserved word in JavaScript
      klass = data ? data.delete("class") : nil
      if klass
        k = Module.const_get(klass)
        k.new(data)
      else 
        # data is not of a known class
        ViewObject.create(data)
      end
    end
        
    # Convenience methods - should be in a diffent module?
    
    def get(uri=nil)
      JSON.parse(db.get(uri).body)
    end
    
    def pp_get(uri=nil)
      resp = db.get(uri)
      pp(JSON.parse(resp.body))
    end

    def pp_post(uri=nil, json=nil)
      resp = db.post(uri, json)
      pp(JSON.parse(resp.body))
    end
  
  end
  
end
