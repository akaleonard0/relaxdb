require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end
        
  describe ".create_object" do
    
    it "should return an instance of a known object if passed a hash with a class key" do
      data = { "class" => "Item" }
      obj = RelaxDB.create_object(data)
      obj.should be_instance_of(Item)
    end
    
    it "should return an instance of a dynamically created object if no class key is provided" do
      data = { "name" => "tesla coil", "strength" => 5000 }
      obj = RelaxDB.create_object(data)
      obj.name.should == "tesla coil"
      obj.strength.should == 5000
    end
    
  end  
      
  describe ".bulk_save" do
    
    it "should be invokable multiple times" do
      t1 = Tag.new(:name => "t1")
      t2 = Tag.new(:name => "t2")
      RelaxDB.bulk_save(t1, t2)
      RelaxDB.bulk_save(t1, t2)
    end
    
    it "should succeed when passed no args" do
      RelaxDB.bulk_save
    end
    
  end
  
  describe ".replicate_db" do
    
    it "should replicate the named database" do
      orig = "relaxdb_spec_db"
      replica = "relaxdb_spec_db_replica"
      RelaxDB.delete_db replica rescue "ok"
      Atom.new.save # implicitly saved to orig
      RelaxDB.replicate_db orig, replica
      RelaxDB.use_db replica
      Atom.all.size.should == 1
    end
    
  end
  
  it "should offer an example where behaviour is different with caching enabled and caching disabled" do
    # if caching is added
  end
            
end
