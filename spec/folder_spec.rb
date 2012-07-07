require 'spec_helper'
require 'time'
require 'web_history/folder'

describe WebHistory::Folder do
  it "initializes with default values" do
    time = Time.now
    Time.stub(:now).and_return(time)

    folder = WebHistory::Folder.new

    folder.name.should be_nil
    folder.update_time.should == time
    folder.update_interval.should == 24 * 60 * 60
    folder.documents.should be_empty
  end

  it "initializes with given filename and options" do
    name = 'folder'
    update_time = Time.parse('12:34')
    update_interval = 5 * 60

    folder = WebHistory::Folder.new(name, :update_time => update_time, :update_interval => update_interval)

    folder.name.should == name
    folder.update_time.should == update_time
    folder.update_interval.should == update_interval
  end

  it "adds (unique) documents" do
    folder = WebHistory::Folder.new

    expect { folder.add_document('document') }.to change { folder.documents.count }.from(0).to(1)
    expect { folder.add_document('document') }.to_not change { folder.documents.count }
  end

  it "removes documents" do
    folder = WebHistory::Folder.new
    folder.add_document('document')

    expect { folder.remove_document('wrong_document') }.to_not change { folder.documents.count }
    expect { folder.remove_document('document') }.to change { folder.documents.count }.from(1).to(0)
  end

  context "when updating" do
    before(:each) do
      @folder = WebHistory::Folder.new('folder')
      @folder.add_document('http://www.example.com')
      @folder.add_document('http://www.example.com/foo.html')
      @folder.add_document('http://www.example.com/bar.html')
    end

    it "delegates 'update' to documents" do
      @folder.documents.each { |document| document.should_receive(:update).once }

      @folder.update
    end

    it "adjusts 'update_time'" do
      time = Time.now
      Time.stub(:now).and_return(time)

      WebHistory::Document.any_instance.stub(:update)

      update_time = @folder.update_time
      expect { @folder.update }.to change { @folder.update_time }.from(update_time).to(time + @folder.update_interval)
    end

    it "skips update if 'update_time' is not reached yet" do
      time = @folder.update_time - 1
      Time.stub(:now).and_return(time)

      @folder.documents.each { | document| document.should_receive(:update).never }

      @folder.update
    end

    it "forces update if ':force => true' options is set" do
      time = @folder.update_time - 1
      Time.stub(:now).and_return(time)

      @folder.documents.each { | document| document.should_receive(:update).once }

      @folder.update(:force => true)
    end

    it "delegates 'updated?' to documents" do
      @folder.documents.each { |document| document.should_receive(:updated?).once }

      @folder.updated?
    end
  end
end

