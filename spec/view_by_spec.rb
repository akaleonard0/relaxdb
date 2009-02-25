require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "RelaxDB Pagination" do
    
  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"    
  end
    
  describe "view_by" do
    
    before(:each) do
      RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
      RelaxDB.use_db "relaxdb_spec_db"

      class ViewBySpec < RelaxDB::Document
        property :foo
        view_by :foo, :descending => true
      end

    end
    
    it "should create corresponding views" do
      dd = RelaxDB::DesignDocument.get "spec_doc"
      dd.data["views"]["ViewBySpec_by_foo"].should be
    end
      
    it "should create a by_ att list method" do
      ViewBySpec.new(:foo => :bar).save!
      res = ViewBySpec.by_foo
      res.first.foo.should == "bar"
    end
        
    it "should create a paginate_by_ att list method" do
      ViewBySpec.new(:foo => :bar).save!      
      res = ViewBySpec.paginate_by_foo :page_params => {}, :startkey => {}, :endkey => nil
      res.first.foo.should == "bar"
    end
        
    it "should apply query defaults to by_" do
      ViewBySpec.new(:foo => "a").save!
      ViewBySpec.new(:foo => "b").save!
      
      ViewBySpec.by_foo.map{ |o| o.foo }.should == ["b", "a"]
    end
    
    it "should apply query defaults to paginate_by_" do
      ViewBySpec.new(:foo => "a").save!
      ViewBySpec.new(:foo => "b").save!
      
      res = ViewBySpec.paginate_by_foo :page_params => {}, :startkey => {}, :endkey => nil
      res.map{ |o| o.foo }.should == ["b", "a"]
    end
    
    it "should allow query defaults to be overridden for paginate_by_" do
      ViewBySpec.new(:foo => :bar).save!      
      res = ViewBySpec.paginate_by_foo :page_params => {}, :startkey => nil, :endkey => {}, :descending => false
      res.first.foo.should == "bar"      
    end
    
    it "should allow query defaults to be overridden for by_" do
      ViewBySpec.new(:foo => :bar).save!      
      res = ViewBySpec.by_foo :key => "bar"
      res.first.foo.should == "bar"
    end
        
  end
  
  describe "view_by no_create enabled" do
    
    before(:each) do
      RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc", :create_views => false
      
      RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
      RelaxDB.use_db "relaxdb_spec_db"

      class ViewBySpec < RelaxDB::Document
        property :foo
        view_by :foo
      end
    end
    
    it "should not create the views if a given switch is on" do
      dd = RelaxDB::DesignDocument.get "spec_doc"
      dd.data["views"].should be_nil
    end    
    
  end
  
end