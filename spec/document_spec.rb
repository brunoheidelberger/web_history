require 'spec_helper'
require 'web_history/document'

describe WebHistory::Document do
  it "initializes with default values" do
    document = WebHistory::Document.new

    document.url.should be_nil
    document.approved_digest.should == nil
    document.approved_time.should == nil
    document.versions.should be_empty
  end

  it "initializes with given url and options" do
    url = 'url'
    approved_digest = Digest::SHA1.hexdigest('abc')
    approved_time = Time.parse('12:34')

    document = WebHistory::Document.new(url, :approved_digest => approved_digest, :approved_time => approved_time)

    document.url.should == url
    document.approved_digest.should == approved_digest
    document.approved_time.should == approved_time
  end

  context "when updating & approving" do
    before(:each) do
      @document_path = Dir.mktmpdir
      @document = WebHistory::Document.new('http://www.example.com', :settings => { :document_path => @document_path })
      @html = FactoryGirl.build(:html_document)
      stub_request(:get, 'http://www.example.com').to_return(:body => @html.body)
    end

    after(:each) do
      WebMock.reset!
      FileUtils.remove_entry_secure @document_path
    end

    it "fetches a new version" do
      expect { @document.update }.to change { @document.versions.count }.from(0).to(1)
      @document.versions.first[:digest].should == @html.digest 
    end

    it "fetches the same version only once" do
      @document.update

      expect { @document.update }.to_not change { @document.versions.count }
    end

    it "reports update after fetching new version" do
      @document.update

      @document.should be_updated
    end

    it "approves document version" do
      time = Time.now
      Time.stub(:now).and_return(time)

      @document.update
      @document.approve

      @document.approved_digest.should == @html.digest
      @document.approved_time.should == time
      @document.should_not be_updated
    end
  end
end

