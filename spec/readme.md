==RSpec framework and FakeWeb Overview:

What is it?
-----------
RSpec framework is a Behaviour-Driven Development tool for Ruby programmers. BDD is an approach to software development that combines Test-Driven Development, Domain Driven Design, and Acceptance Test-Driven Planning. RSpec helps you do the TDD part of that equation, focusing on the documentation and design aspects of TDD.

FakeWeb Gem is a helper for faking web requests in Ruby. It works at a global level, without modifying code or writing extensive stubs. Here for doing the mocks and for skipping the Net::Http in the xml_request_to_be_sent method, we can use 'FakeWeb'.


The Latest Version for RSpec and fakeWEB
----------------------------------------
Details of the latest version and more information can be found from the below url's:
 
 http://rspec.info/
 
 http://fakeweb.rubyforge.org/
 
 
Configuration and run the test cases
------------------------------------- 

Step 1 :-
To install the rspec & fakeweb gems to add in "environment.rb"
  config.gem "fakeweb"
  config.gem "thoughtbot-factory_girl", :lib => 'factory_girl', :source => 'http://gems.github.com'
  config.gem "rspec", :version => '1.2.2', :lib => 'spec'
  config.gem "rspec-rails", :version => '1.2.2', :lib => false

Step 2 :-
Generate the spec using the command "ruby script/generate rspec"

Step 3 :-
Create a test controller "spec/controllers/manage_profiles_controller_spec.rb" and below provided some sample test cases code snippet for reference. 

require File.dirname(__FILE__) + '/../spec_helper'
require 'fakeweb'
describe ManageProfilesController, "Unit testing the login app" do    
	it "Should login successfully, code 200" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_success']['c200']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
  	get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => 'apigeeuser123'}})
	  code=assigns[:result]['statusCode'].to_s
		code.should == '200'
		response.should render_template("manage_profiles/consent_app.html.erb") 
	end	
	it "Should not able to login successfully, code 205" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c205']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
  	get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
	  response.should redirect_to('http://test.host/user/login')
		code=assigns[:result]['statusCode'].to_s
		code.should == '205'
	end 
end

Step5: Add the "TEST_CONFIG" constant in "environment.rb" to invoke the mock responses in the test controller spec as below.

TEST_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/testcase.yml")

Step 6 :-
Create a yml file (config/testcase.yml) for storing the mock responses. 

login_success:
  c200 :  <loginResponse><developerAppDetails><name>abc</name><appname>def</appname></developerAppDetails><userDetails><userId>xxx</userId><userProfile><isMsisdnValidated>Y</isMsisdnValidated><isEmailValidated>Y</isEmailValidated><isDOBValid>Y</isDOBValid></userProfile></userDetails><isAuthorizationRequired>false</isAuthorizationRequired><statusCode>200</statusCode></loginResponse>
  
login_failure:
  c205 :  <loginResponse><developerAppDetails><name>abc</name><appname>def</appname></developerAppDetails><userDetails><userId>xxx</userId><userProfile><isMsisdnValidated>Y</isMsisdnValidated><isEmailValidated>Y</isEmailValidated><isDOBValid>Y</isDOBValid></userProfile></userDetails><isAuthorizationRequired>false</isAuthorizationRequired><statusCode>205</statusCode></loginResponse>

Step 7 :-
Execute the rspec test cases using the command 'rake spec'. This command will execute all the test cases written for the whole application. 
It provided me a following successful result

D:\apigee_workspace_latest\latest\apigee-login>rake spec
(in D:/apigee_workspace_latest/latest/apigee-login)
..
Finished in 1.065107 seconds
2 examples, 0 failures


Licensing
---------

Licensing for RSpec framework:
-----------------------------
(The MIT License)

Copyright (c) 2009, 2010 David Chelimsky, Chad Humphries

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Licensing for FakeWEB:
----------------------
Copyright 2006-2010 Blaine Cook, Chris Kampmeier, and other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
