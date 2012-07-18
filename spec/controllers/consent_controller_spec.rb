require File.dirname(__FILE__) + '/../spec_helper'
require 'fakeweb'
describe ConsentController, "Unit testing the login app, consent controller" do    
	before :each do
		FakeWeb.allow_net_connect = false
		controller.stub!(:check_for_logged_in).and_return(:true)
	end
	it "Should able to successfully consent the application, redirect_url includes http" do
		req = "#{TEST_CONFIG['consent']['issue_consent']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['issue_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		req2 = "#{TEST_CONFIG['consent']['redirect_url_http']}"
		test_url2 = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['redirect_url']}"
		FakeWeb.register_uri(:any, "#{test_url2}", :body => "#{req2}", :content_type => "application/xml")		
		get(:consent_confirmation, :consent => {:consent_status => 'Accept'})
		response.should redirect_to(assigns[:result]['redirect_url'].to_s)
	end 
	it "Should able to successfully consent the application, redirect_url includes https" do
		req = "#{TEST_CONFIG['consent']['issue_consent']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['issue_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		req2 = "#{TEST_CONFIG['consent']['redirect_url_https']}"
		test_url2 = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['redirect_url']}"
		FakeWeb.register_uri(:any, "#{test_url2}", :body => "#{req2}", :content_type => "application/xml")		
		get(:consent_confirmation, :consent => {:consent_status => 'Accept'})
		response.should redirect_to(assigns[:result]['redirect_url'].to_s)
	end 
	it "Should able to successfully consent the application, redirect_url not includes either http nor https" do
		req = "#{TEST_CONFIG['consent']['issue_consent']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['issue_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		req2 = "#{TEST_CONFIG['consent']['redirect_url_other']}"
		test_url2 = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['redirect_url']}"
		FakeWeb.register_uri(:any, "#{test_url2}", :body => "#{req2}", :content_type => "application/xml")		
		get(:consent_confirmation, :consent => {:consent_status => 'Accept'})
		response.should redirect_to("http://"+assigns[:result]['redirect_url'].to_s)		
	end 
	it "Should able to successfully decline the application, redirect_url includes http" do
		req = "#{TEST_CONFIG['consent']['cancel_consent_http']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['cancel_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		get(:consent_confirmation, :consent => {:consent_status => 'Decline'})
		response.should redirect_to(assigns[:result]['redirect_url'].to_s)
	end 
	it "Should able to successfully decline the application, redirect_url includes https" do
		req = "#{TEST_CONFIG['consent']['cancel_consent_https']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['cancel_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		get(:consent_confirmation, :consent => {:consent_status => 'Decline'})
		response.should redirect_to(assigns[:result]['redirect_url'].to_s)
	end 
	it "Should able to successfully decline the application, redirect_url not includes either http nor https" do
		req = "#{TEST_CONFIG['consent']['cancel_consent_other']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['cancel_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		get(:consent_confirmation, :consent => {:consent_status => 'Decline'})
		response.should redirect_to("http://"+assigns[:result]['redirect_url'].to_s)		
	end 
	it "Checking for the session details, should get redirected to the redirect_url" do
		req = "#{TEST_CONFIG['Session_response']['c200']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :payments
		response.should redirect_to(assigns[:redirect_url])
	end 
	it "Checking for the session details, user id missing, should get redirected to payment login page" do
		req = "#{TEST_CONFIG['Session_response']['user_id_missing']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :payments
		response.should redirect_to(payment_login_path)
	end 
	it "Checking for the session details, redirect_url missing, should get redirected to payment login page" do
		req = "#{TEST_CONFIG['Session_response']['redirect_url_missing']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :payments
		response.should redirect_to(payment_login_path)
	end
	it "Checking for the session details, both user id and redirect_url missing, should get redirected to payment login page" do
		req = "#{TEST_CONFIG['Session_response']['user_and_redirect_url_missing']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :payments
		response.should redirect_to(payment_login_path)
	end
  it "Checking for the session details, fault XML, should get redirected to payment login page" do
		req = "#{TEST_CONFIG['fault_xml']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :payments
		response.should redirect_to(payment_login_path)
	end
	it "Username not enterted, should get redirected to payment login page with a error message" do       
		get(:login_create, {:login => {:username => '', :password => 'apigeeuser123'}})
		flash[:error].should == ERROR_CONFIG['en']['login']['missing_username']
		response.should redirect_to(payment_login_path)
	end
	it "Password not enterted, should get redirected to payment login page with a error message" do       
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => ''}})
		flash[:error].should == ERROR_CONFIG['en']['login']['missing_pwd']
		response.should redirect_to(payment_login_path)
	end
	it "Should login successfully, code 200, should get redirected to the redirect_url" do
		req = "#{TEST_CONFIG['login_success']['c200']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
	 	get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => 'apigeeuser123'}})
	  code=assigns[:result]['statusCode'].to_s
		code.should == '200'
		response.should redirect_to(assigns[:redirect_url])
	end
	it "Should not able to login successfully, status code 500, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c500']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		code=assigns[:result]['statusCode'].to_s
		code.should == '500'
		flash[:error].should == ERROR_CONFIG['en']['c500']
		response.should redirect_to(payment_login_path)
	end
	it "Should not able to login successfully, status code 501, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c501']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		code=assigns[:result]['statusCode'].to_s
		code.should == '501'
		flash[:error].should == ERROR_CONFIG['en']['c500']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, status code 205, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c205']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		code=assigns[:result]['statusCode'].to_s
		code.should == '205'
		flash[:error].should == ERROR_CONFIG['en']['login']['login_call']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, status code 204, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c204']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		code=assigns[:result]['statusCode'].to_s
		code.should == '204'
		flash[:error].should == ERROR_CONFIG['en']['login']['login_call']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, status code 240, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c240']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		code=assigns[:result]['statusCode'].to_s
		code.should == '240'
		flash[:error].should == ERROR_CONFIG['en']['login']['c240']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, status code 210, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['c210']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		code=assigns[:result]['statusCode'].to_s
		code.should == '210'
		flash[:error].should == ERROR_CONFIG['en']['login']['c210']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, timeout error, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{}")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		flash[:error].should == ERROR_CONFIG['en']['failure_response']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, html response, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['html_content']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		flash[:error].should == ERROR_CONFIG['en']['failure_response']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, invalid xml, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['login_failure']['invalid_xml']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		flash[:error].should == ERROR_CONFIG['en']['failure_response']
		response.should redirect_to(payment_login_path)
	end
  it "Should not able to login successfully, fault xml, payment login page to be displayed" do
		controller.stub!(:check_for_logged_in).and_return(:true)
		req = "#{TEST_CONFIG['fault_xml']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['payment']['login_url']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get(:login_create, {:login => {:username => 'ajose@apigee.com', :password => '123qwe'}})
		flash[:error].should == ERROR_CONFIG['en']['failure_response']
		response.should redirect_to(payment_login_path)
	end
	it "Checking for the session details, invalid XML, should get redirected to payment login page" do
		req = "#{TEST_CONFIG['Session_response']['invalid_xml']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :payments
		response.should redirect_to(payment_login_path)
	end
end