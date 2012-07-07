require 'spec_helper'
require 'tempfile'
require 'web_history/portfolio'

describe WebHistory::Portfolio do
  it "initializes with default values" do
    portfolio = WebHistory::Portfolio.new

    portfolio.filename.should be_nil
    portfolio.folders.should be_empty
  end

  it "initializes with given filename" do
    filename = 'portfolio.yaml'

    portfolio = WebHistory::Portfolio.new(filename)

    portfolio.filename.should == filename
  end

  context "when loading & saving" do
    before(:each) do
      @filename = Tempfile.new('portfolio').path
    end

    it "loads and saves empty content" do
      portfolio = WebHistory::Portfolio.new(@filename)
      portfolio.save

      loaded_portfolio = WebHistory::Portfolio.load(@filename)

      loaded_portfolio.filename.should == portfolio.filename
      loaded_portfolio.folders.should be_empty
    end

    it "respects given filename" do
      portfolio = WebHistory::Portfolio.new(@filename)
      portfolio.save

      filename = Tempfile.new('portfolio').path
      portfolio.save(filename)

      loaded_portfolio = WebHistory::Portfolio.load(filename)

      loaded_portfolio.filename.should == filename
    end

    it "loads and saves simple content" do
      portfolio = WebHistory::Portfolio.new(@filename)
      portfolio.add_folder('folder')
      portfolio.save

      loaded_portfolio = WebHistory::Portfolio.load(@filename)

      loaded_portfolio.filename.should == portfolio.filename
      loaded_portfolio.folders.should have(1).item
      loaded_portfolio.folders[0].name == 'folder'
    end

    it "loads and saves complex content" do
      portfolio = WebHistory::Portfolio.new(@filename)
      folder_1 = portfolio.add_folder('folder_1')
      folder_1.add_document('url_1')
      folder_1.add_document('url_2')
      folder_2 = portfolio.add_folder('folder_2')
      folder_3 = portfolio.add_folder('folder_3')
      folder_3.add_document('url_3')
      portfolio.save

      loaded_portfolio = WebHistory::Portfolio.load(@filename)

      loaded_portfolio.filename.should == portfolio.filename
      loaded_portfolio.folders.should have(3).items
      loaded_portfolio.folders.each_with_index do | folder, id |
        folder.name.should == "folder_#{id + 1}"
        case id
        when 0
          folder.documents.should have(2).items
          folder.documents[0].url.should == 'url_1'
          folder.documents[1].url.should == 'url_2'
        when 1
          folder.documents.should be_empty
        when 2
          folder.documents.should have(1).item
          folder.documents[0].url.should == 'url_3'
        end
      end
    end
  end

  it "adds (unique) folders" do
    portfolio = WebHistory::Portfolio.new

    expect { portfolio.add_folder('folder') }.to change { portfolio.folders.count }.from(0).to(1)
    expect { portfolio.add_folder('folder') }.to_not change { portfolio.folders.count }
  end

  it "removes folders" do
    portfolio = WebHistory::Portfolio.new
    portfolio.add_folder('folder')

    expect { portfolio.remove_folder('wrong_folder') }.to_not change { portfolio.folders.count }
    expect { portfolio.remove_folder('folder') }.to change { portfolio.folders.count }.from(1).to(0)
  end

  context "when updating" do
    before(:each) do
      @portfolio = WebHistory::Portfolio.new(Tempfile.new('portfolio').path)
      @portfolio.add_folder('folder_1')
      @portfolio.add_folder('folder_2')
    end

    it "delegates 'update' to folders" do
      @portfolio.folders.each { |folder| folder.should_receive(:update).once }

      @portfolio.update
    end

    it "delegates 'updated?' to folders" do
      @portfolio.folders.each { |folder| folder.should_receive(:updated?).once }

      @portfolio.updated?
    end
  end
end

