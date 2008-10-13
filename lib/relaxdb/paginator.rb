module RelaxDB  

  class Paginator
    
    attr_reader :paginate_params

    def initialize(paginate_params, page_params)
      @paginate_params = paginate_params
      @orig_paginate_params = @paginate_params.clone
      
      page_params = page_params.is_a?(String) ? JSON.parse(page_params).to_mash : page_params
      @paginate_params.update(page_params)
    end

    def total_doc_count(design_doc, reduce_view_name)
      result = RelaxDB.view(design_doc, reduce_view_name) do |q|
        q.group(true).group_level(0)
        q.startkey(@orig_paginate_params.startkey).endkey(@orig_paginate_params.endkey).descending(@orig_paginate_params.descending)  
      end
      
      total_docs = RelaxDB.reduce_result(result)
    end
    
    def add_next_and_prev(docs, design_doc, view_name, reduce_view_name, view_keys)
      unless docs.empty?
        no_docs = docs.size
        offset = docs.offset
        orig_offset = orig_offset(Query.new(design_doc, view_name))
        total_doc_count = total_doc_count(design_doc, reduce_view_name)      
      
        next_key = view_keys.map { |a| docs.last.send(a) }
        next_key = next_key.length == 1 ? next_key[0] : next_key
        next_key_docid = docs.last._id
        next_params = { :startkey => next_key, :startkey_docid => next_key_docid, :descending => @orig_paginate_params.descending }
        next_exists = !@paginate_params.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : true
      
        prev_key = view_keys.map { |a| docs.first.send(a) }
        prev_key = prev_key.length == 1 ? prev_key[0] : prev_key
        prev_key_docid = docs.first._id
        prev_params = { :startkey => prev_key, :startkey_docid => prev_key_docid, :descending => !@orig_paginate_params.descending }
        prev_exists = @paginate_params.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : 
          (offset - orig_offset == 0 ? false : true)
      else
        next_exists, prev_exists = false
      end
      
      docs.meta_class.instance_eval do        
        define_method(:next_params) { next_exists ? next_params : false }
        define_method(:next_query) { next_exists ? "page_params=#{::CGI::escape(next_params.to_json)}" : false }
        
        define_method(:prev_params) { prev_exists ? prev_params : false }
        define_method(:prev_query) { prev_exists ? "page_params=#{::CGI::escape(prev_params.to_json)}" : false }
      end      
    end
    
    def orig_offset(query)
      if @paginate_params.order_inverted?
        query.startkey(@orig_paginate_params.endkey).descending(!@orig_paginate_params.descending)
      else
        query.startkey(@orig_paginate_params.startkey).descending(@orig_paginate_params.descending)
      end
      query.count(1)
      RelaxDB.retrieve(query.view_path).offset
    end
    
  end
  
end
