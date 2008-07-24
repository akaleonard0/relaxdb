require 'rubygems'
require 'json'
require 'net/http'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'relaxdb/server'
require 'relaxdb/relaxdb'
require 'relaxdb/has_many_proxy'
require 'relaxdb/has_one_proxy'
require 'relaxdb/belongs_to_proxy'
require 'relaxdb/uuid_generator'
require 'relaxdb/views'
require 'relaxdb/query'
require 'parsedate'
require 'pp'

module RelaxDB
end
