require "spec_helper"

describe SC::Generator, 'snake_case' do

  test_hashes = [
    { :input => "FooBar", :output => "foo_bar" },
    { :input => "HeadlineCNNNews", :output => "headline_cnn_news" },
    { :input => "CNN", :output => "cnn" },
    { :input => "innerHTML", :output => "inner_html" },
    { :input => "Foo_Bar", :output => "foo_bar" },
    { :input => "Foo-Bar", :output => "foo_bar" },
    { :input => "LOGGED_IN", :output => "logged_in" },
  ]

  test_hashes.each do |test_hash|
    input = test_hash[:input]
    output = test_hash[:output]

    it "should snake_case #{input} to #{output}" do
      a = SC::Generator.new("test")

      a.snake_case(input).should eql(output)
    end
  end

end
