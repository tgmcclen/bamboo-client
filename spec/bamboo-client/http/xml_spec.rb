require File.expand_path("../../../spec_helper", __FILE__)

module Bamboo
  module Client
    module Http
      describe Xml do
        let(:url) { "http://example.com" }
        let(:xml) { Xml.new(url) }


        it "does a POST" do
          RestClient.should_receive(:post).
                     with("#{url}/", :some => "data").
                     and_return("<foo><bar></bar></foo>")

          doc = xml.post("/", :some => "data")
          doc.should be_kind_of(Xml::Doc)
        end
      end

      describe Xml::Doc do
        let(:wrapped) {
          m = mock("nokogiri document")
          m.stub!(:css).with("errors error").and_return []
          m
        }
        let(:doc) { Xml::Doc.new(wrapped)}

        it "returns the text of the given CSS selector" do
          wrapped.should_receive(:css).
                  with("some selector").
                  and_return(mock("node", :text => "bar"))

          doc.text_for("some selector").should == "bar"
        end

        it "checks for errors in the given document" do
          wrapped.should_receive(:css).with("errors error").and_return [mock(:text => "error!")]
          lambda { doc.text_for "some selector" }.should raise_error(Bamboo::Client::Error)
        end

        it "returns an instance of the given class for each node matching the selector" do
          wrapped.should_receive(:css).with("selector").and_return(['node1', 'node2'])

          objs = doc.objects_for("selector", SpecHelper::Wrapper)

          objs.size.should == 2
          objs.each { |e| e.should be_instance_of(SpecHelper::Wrapper) }
          objs.map { |e| e.obj }.should == ['node1', 'node2']
        end

        it "returns an instance of the given class for the first node matching the selector" do
          wrapped.should_receive(:css).with("selector").and_return(['node1', 'node2'])

          obj = doc.object_for("selector", SpecHelper::Wrapper)

          obj.should be_instance_of(SpecHelper::Wrapper)
          obj.obj.should == "node1"
        end

        it "#object_for passes extra args to the given class' constructor" do
          wrapped.should_receive(:css).with("selector").and_return(['node1', 'node2'])

          SpecHelper::Wrapper.should_receive(:new).with('node1', "foo")
          doc.object_for("selector", SpecHelper::Wrapper, "foo")
        end

        it "#objects_for passes extra args to the given class' constructor" do
          wrapped.should_receive(:css).with("selector").and_return(['node1', 'node2'])

          SpecHelper::Wrapper.should_receive(:new).with('node1', "foo")
          SpecHelper::Wrapper.should_receive(:new).with('node2', "foo")

          doc.objects_for("selector", SpecHelper::Wrapper, "foo")
        end
      end
    end
  end
end
