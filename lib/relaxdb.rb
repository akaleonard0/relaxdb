require 'rubygems'
require 'extlib'
require 'json'
require 'uuid'

require 'cgi'
require 'net/http'
require 'logger'
require 'parsedate'
require 'pp'
require 'tempfile'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'relaxdb/all_delegator'
require 'relaxdb/belongs_to_proxy'
require 'relaxdb/design_doc'
require 'relaxdb/document'
require 'relaxdb/extlib'
require 'relaxdb/has_many_proxy'
require 'relaxdb/has_one_proxy'
require 'relaxdb/query'
require 'relaxdb/references_many_proxy'
require 'relaxdb/relaxdb'
require 'relaxdb/server'
require 'relaxdb/sorted_by_view'
require 'relaxdb/uuid_generator'
require 'relaxdb/view_object'
require 'relaxdb/view_uploader'
require 'relaxdb/views'

module RelaxDB
end
