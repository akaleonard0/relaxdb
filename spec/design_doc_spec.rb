require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::DesignDocument do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end

  describe "#save" do
    
    it "should create a corresponding document in CouchDB" do
      RelaxDB::DesignDocument.get("foo").save      
      RelaxDB.load("_design%2Ffoo").should_not be_nil
    end
    
  end

  describe "#destroy" do
    
    it "should delete the corresponding document from CouchDB" do
      dd = RelaxDB::DesignDocument.get("foo").save
      dd.destroy!
      RelaxDB.load("_design%2Ffoo").should be_nil
    end
    
  end

end