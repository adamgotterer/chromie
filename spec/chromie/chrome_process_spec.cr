require "../spec_helper"

describe Chromie::ChromeProcess do
  describe "#initialize" do
    it "assigns a port" do
      process = Chromie::ChromeProcess.new(5000)
      process.port.should eq 5000
    end
  end
end
