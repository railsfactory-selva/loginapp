require File.dirname(__FILE__) + '/../spec_helper'
require 'fakeweb'
describe ManageProfilesController, "Unit testing the login app" do    
	before :each do
		FakeWeb.allow_net_connect = false
    #~ controller.stub!(:check_for_logged_in).and_return(:true)
	end
	it "User successfully seeing the OAuth off network page" do
		res = "#{TEST_CONFIG['auth_success']['off_net']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{res}", :content_type => "application/xml")		
		get(:login_manage)
		app_name = assigns[:result]['developerAppDetails'][0]['appname'].to_s		  
		network = assigns[:result]['isAuthorizationRequired'].to_s		  
		app_name.should == "abcd"
		network.should == "false"
		response.should render_template("manage_profiles/off_net_consent.html.erb")
	end
	
	it "OAuth off net failure without having app name, broken page displayed" do
		res = "#{TEST_CONFIG['auth_failure']['off_net_failure_missing_app_name']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{res}", :content_type => "application/xml")		
		get(:login_manage)
		app_name = assigns[:result]['developerAppDetails'][0]['appname'].to_s
		app_name.should == ""
		response.should render_template("manage_profiles/off_net_consent.html.erb")
	end
	
	
	it "OAuth off net failure without having developer name, broken page displayed" do
		res = "#{TEST_CONFIG['auth_failure']['off_net_failure_missing_dev_name']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{res}", :content_type => "application/xml")		
		get(:login_manage)
		 dev_name = assigns[:result]['developerAppDetails'][0]['name'].to_s	
		dev_name.should == ""
		response.should render_template("manage_profiles/off_net_consent.html.erb")
	end
	
	it "OAuth off net failure without having any scope name, broken page displayed" do
		res = "#{TEST_CONFIG['auth_failure']['off_net_failure_missing_dev_name']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{res}", :content_type => "application/xml")		
		get(:login_manage)
		 scope = assigns[:result]['developerAppDetails'][0]['scope'].to_s	
		scope.should == ""
		response.should render_template("manage_profiles/off_net_consent.html.erb")
	end
	
	
	it "OAuth off net failure saying invalid_client error" do
	res = "#{TEST_CONFIG['auth_failure']['off_net_invalid_clientid']}"
	test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{res}", :content_type => "application/xml")		
		get(:login_manage)
		 status = assigns[:result]['details'][0].to_s	
		status.should == "invalid_client"
		response.should render_template("manage_profiles/off_net_consent.html.erb")
	end
	
	
	#On  Network
	it "User successfully seeing the OAuth on network page" do
		res = "#{TEST_CONFIG['auth_success']['on_net']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['session_details']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{res}", :content_type => "application/xml")		
		get(:login_manage)
		network =assigns[:result]['onNetworkAuthentication'].to_s
		network.should == "true"
		response.should redirect_to ("http://#{DEFAULT_CONFIG['login_app_url']}:#{DEFAULT_CONFIG['login_app_port']}/http_on_net_consent")
		#flash[:on_redirect_url] = flash[:redirect_url]
		get(:http_on_net_consent)
		response.should redirect_to("https://#{DEFAULT_CONFIG['login_app_url']}/on_net_consent?client_id=#{session[:client_id]}&scope=#{session[:scope]}&redirect_url=#{session[:redirect_url]}")
	      #  response.should redirect_to("http://localhost:3000/http_on_net_consent")
		 #response.should redirect_to(dummy_page)  
		res1 = "#{TEST_CONFIG['auth_success']['on_net_final']}"
		test_url1 = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['login']['on_network_auth']}"
		FakeWeb.register_uri(:any, "#{test_url1}", :body => "#{res1}", :content_type => "application/xml")		
		flash[:x_up_subno] = "dskjhdsjkhdskjhdskjhdskjh"
		get(:on_net_consent)
		
		#header = assigns[:flash][:x_up_subno]
		#app_name = assigns[:result]['onNetworkAuth'][0]['appname'].to_s
		#app_name.should="apiconsole_s6_v2"
		user_id=assigns[:result]['userDetails'][0]['userId'].to_s
		
		response.should render_template("manage_profiles/on_net_consent.html.erb")
	end
	
	
end