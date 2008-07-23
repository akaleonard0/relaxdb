require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:all) do
    RelaxDB::Database.std_db = RelaxDB::Database.new("localhost", 5984, "relaxdb_spec_db")
    begin
      RelaxDB::Database.std_db.delete
    rescue => e
      puts e
    end
    RelaxDB::Database.std_db.put
  end
    
  describe "Primitive Attributes" do
    
    it "object can be saved and resaved" do
      p = Player.new :name => "paul"
      p.save
      p.save
    end
    
    it "loaded object contains the attributes and values it was saved with" do
      p = Player.new :name => "paul", :age => 1812
      p.save
      p = RelaxDB.load_by_id(p._id)
      p.name.should == "paul"
      p.age.should == 1812
    end

    it "loaded object can be resaved" do
      p = Player.new :name => "paul", :shards => 101
      p.save
      p = RelaxDB.load_by_id(p._id)
      p.save
    end    

    it "a new object should be assigned an id" do
      p = Player.new
      p._id.should_not == nil
    end
    
    it "an unsaved object's revision should be nil" do
      p = Player.new
      p._rev.should == nil
    end    
    
    it "a saved object's revision should not be nil" do
      p = Player.new.save
      p._rev.should_not == nil
    end
    
    it "nil attributes should not be output in json" do
      Player.new.to_json.should_not include("rev")
    end
    
    it "created_at attribute is set automatically to creation date" do
      now = Time.now
      p = Post.new.save
      created_at = RelaxDB.load(p._id).created_at
      now.should be_close(created_at, 1)
    end
        
  end
  
  # Test organistion and naming is a mess. Revise.
  # Warnings should be provided when name collisions occur between properties and relationships
  describe "has_one and belongs_to" do
    
    describe "both objects created" do
    end
        
    describe "both objects loaded" do
      it "should be able to load the parent and reference itself via the child" do
        p = Player.new.save
        id = p._id
        r = Rating.new(:player => p).save
        p = RelaxDB.load_by_id(id)
        p.rating.player._id.should == id
      end
      
    end
        
    describe "parent loaded, child created" do
      it "assigning to a has_one relationship should create a reference from the child to the parent" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        r.player._id.should == p._id
      end
      
      it "assigning to a has_one relationship should save the assigned object" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        r._rev.should_not == nil
      end
      
      it "assigning nil to a has_one relationship should set the target to nil" do
        p = Player.new.save
        p.rating = nil
        p.rating.should == nil
      end
      
      it "assigning to a has_one relationship should nullify any existing relationship in the database" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        p.rating = nil
        r.player.should be_nil
        RelaxDB.load(r._id).player.should be_nil
      end
      
      
      it "should provide a warning if constructor hash key name doesn't map to existing property name"
      
      it "should provide a warning if property name or assocations clash"
      
      it "assigning to the parent should cause the parent to be saved"
      # or alternatively the child relationship shouldn't be saved
      # similarly for has_many? yes!
      # >> p = Player.new :name => "Dexter"
      # => #<Player:1724330, _id: 76278, name: Dexter>
      # >> p.rating = Rating.new(:shards => 1001)
      # => #<Rating:1651080, _id: 06704, _rev: 2339049119, shards: 1001, player_id: 76278>
      # >> p
      # => #<Player:1724330, _id: 76278, name: Dexter>      
      
      it "repeated invocations of a has_one relationship should return the same object" do
        p = Player.new.save
        r = Rating.new(:player => p).save
        p = RelaxDB.load_by_id(p._id)
        p.rating.object_id.should == p.rating.object_id
      end
      
      it "repeated invocations of a belongs_to relationship should return the same object" do
        p = Player.new.save
        r = Rating.new(:player => p).save
        r = RelaxDB.load_by_id(r._id)
        r.player.object_id.should == r.player.object_id
      end
      
      it "assigning to a belongs_to relationship establishes the relationship once the object is saved" do
        p = Player.new.save
        r = Rating.new
        r.player = p
        p.rating.should == nil # I'm not saying this is correct - merely codifying how things stand 
        r.save
        p.rating._id.should == r._id
      end
      
      it "accessing a has_one relationship that hasn't yet been created should return nil" do
        p = Player.new
        p.rating.should == nil
      end
      
      it "accessing a belongs_to relationship that hasn't yet been created should return nil" do
        r = Rating.new
        r.player.should == nil
      end

      it "should be able to load the child and access the parent" do
        p = Player.new.save
        r = Rating.new(:player => p).save
        r = RelaxDB.load_by_id r._id
        r.player._id.should == p._id
        
      end
      
      it "should be able to establish a belongs_to relationship via constructor attribute" do
        p = Player.new
        r = Rating.new :player => p
        r.player._id.should == p._id
      end
      
      it "should be able to establish a has_one relationship via a constructor attribute for unsaved" do
        r = Rating.new
        p = Player.new :rating => r
        p.rating.should == r
      end

      it "should be able to establish a has_one relationship via a constructor attribute for saved" do
        r = Rating.new.save
        p = Player.new :rating => r
        p.rating.should == r
      end
      
    end
    
    describe "has_many" do
      
      it "adding an item should link the added item to the parent" do
        p = Player.new
        p.items << Item.new
        p.items[0].player._id.should == p._id
      end
      
      it "should resolve a saved collection on access" do
        p = Player.new.save
        p.items << Item.new
        p = RelaxDB.load p._id
        p.items.size.should == 1
      end
      
      it "should return an enumarable collection" do
        p = Player.new.save
        p.items.is_a?(Enumerable).should be_true
      end
      
      it "should actually be enumerable" do
        p = Player.new.save
        p.items << Item.new(:name => "a")
        p.items << Item.new(:name => "b")
        names = p.items.inject("") { |memo, i| memo << i.name }
        names.length.should == 2
      end
      
      it "deleting an object should nullify the belongs_to relationship" do
        p = Player.new.save
        i = Item.new
        p.items << i
        p.items.delete i
        i.player.should be_nil 
        RelaxDB.load(i._id).player.should be_nil
      end
      
      it "clearing a collection should nullify all relationships and result in an empty collection" do
        p = Player.new.save
        i1, i2 = Item.new, Item.new
        p.items << i1
        p.items << i2
        p.items.clear
        i1.player.should be_nil
        i2.player.should be_nil
      end
      
    end
    
    describe "has_many, with extra bells" do
      
      it "adding an invite_received should set the recipient in an invite" do
        p = Player.new.save
        i = Invite.new
        p.invites_received << i
        i.recipient._id.should == p._id
      end
      
      it "removing an invite_received should nullify the recipient in an invite" do
        p = Player.new.save
        i = Invite.new
        p.invites_received << i
        p.invites_received.clear
        i.recipient.should be_nil
        RelaxDB.load(i._id).recipient.should be_nil
      end
      
    end
    
    describe "parent created, child loaded" do
      # should you be able to save the child without the parent - id not_null - depends
    end
    
    describe "common to all object states" do
      # Implicit in tests that pass as the db is deleted after each invocation - would be nice to confirm though
      # it "accessing has_one relationship should create the associated view if it doesn't exist"      
    end
    
    # split via relationship side e.g. belongs_to for saved and unsaved, has_many for saved and unsaved etc.
                
  end

  # Test database API too
  
  describe "finders" do
    
    it "find_all should find all" do
      
    end
    
  end
      
end
