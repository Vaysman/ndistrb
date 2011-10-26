require File.expand_path('../../ndistro', __FILE__)

describe "ndistrb" do
  describe "abort" do
    before(:each) do
      @io = double("std_out").as_null_object
      @kernel = double("kernel").as_null_object
    end

    it "should print one message to io" do
      msg = "str1"
      @io.should_receive(:puts).with("Error: #{msg}")
      abort(msg, :io => @io, :kernel => @kernel)
    end

    it "should print all messages separated by space to io" do
      msgs = %w( str1 str2 str3 )
      @io.should_receive(:puts).with("Error: #{msgs.join ' '}")
      abort(msgs, :io => @io, :kernel => @kernel)
    end

    it "should exit with error level 1" do
      @kernel.should_receive(:exit).with(1)
      abort("", :io => @io, :kernel => @kernel)
    end
  end

  describe "log" do
    before(:each) do
      @io = double("std_out").as_null_object
    end

    it "should print one message to io" do
      msg = "str1"
      @io.should_receive(:puts).with("... #{msg}")
      log(msg, :io => @io)
    end

    it "should print all messages separated by space to io" do
      msgs = %w( str1 str2 str3 )
      @io.should_receive(:puts).with("... #{msgs.join ' '}")
      log(msgs, :io => @io)
    end
  end

  describe "usage" do
    before(:each) do
      @io = double("std_out").as_null_object
    end

    it "should print help to io" do
      msg = "str1"
      @io.should_receive(:puts).with(/Usage: ndistrb/)
      usage(msg, :io => @io)
    end
  end


end