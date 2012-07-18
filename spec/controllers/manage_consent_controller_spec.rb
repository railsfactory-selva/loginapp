require File.dirname(__FILE__) + '/../spec_helper'
require 'fakeweb'
describe ManageConsentController, "Unit testing the login app, mangage consent controller" do    
	before :each do
		FakeWeb.allow_net_connect = false
		controller.stub!(:check_for_logged_in).and_return(:true)
	end
	it "Should able to view the list of applications" do
		req = "#{TEST_CONFIG['consent']['applications']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['applications']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get :applications
	  response.should render_template("manage_consent/applications.html.erb") 		
	end
  it "Should able to view the list of applications, consumer attributes without first name" do
		req = "#{TEST_CONFIG['consent']['applications']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['applications']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_fn']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get :applications
	  response.should render_template("manage_consent/applications.html.erb")
	end
  it "Should able to view the list of applications, consumer attributes without last name" do
		req = "#{TEST_CONFIG['consent']['applications']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['applications']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_ln']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get :applications
	  response.should render_template("manage_consent/applications.html.erb")
	end
  it "Should able to view the list of applications, consumer attributes without first name & last name" do
		req = "#{TEST_CONFIG['consent']['applications']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['applications']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_n']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get :applications
	  response.should render_template("manage_consent/applications.html.erb")
	end
  it "Should able to view the list of applications, kms consumer attributes call error response (consumer not found)" do
		req = "#{TEST_CONFIG['consent']['applications']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['applications']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_error']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get :applications
	  response.should render_template("manage_consent/applications.html.erb")
	end
  it "No applications, should able to view the applications page, without any application listing" do
		req = "#{TEST_CONFIG['consent']['no_applications']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['applications']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		get :applications
	  response.should render_template("manage_consent/applications.html.erb")
	end
	it "Should able to view the particular application" do
		req = "#{TEST_CONFIG['consent']['single_application']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['single_application']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get(:consent_application, {:consent => {:application_name => 'abc'}})		
	  response.should render_template("manage_consent/consent_application.erb")
	end
  it "Should able to view the particular application, consumer attributes without firstname" do
		req = "#{TEST_CONFIG['consent']['single_application']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['single_application']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_fn']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get(:consent_application, {:consent => {:application_name => 'abc'}})
	  response.should render_template("manage_consent/consent_application.erb")
	end
  it "Should able to view the particular application, consumer attributes without lastname" do
		req = "#{TEST_CONFIG['consent']['single_application']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['single_application']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_ln']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get(:consent_application, {:consent => {:application_name => 'abc'}})
	  response.should render_template("manage_consent/consent_application.erb")
	end
  it "Should able to view the particular application, consumer attributes without firstname & lastname" do
		req = "#{TEST_CONFIG['consent']['single_application']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['single_application']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_n']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get(:consent_application, {:consent => {:application_name => 'abc'}})
	  response.should render_template("manage_consent/consent_application.erb")
	end
  it "Should able to view the particular application,  kms consumer attributes call error response (consumer not found)" do
		req = "#{TEST_CONFIG['consent']['single_application']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['single_application']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")
		kms_req1 = "#{TEST_CONFIG['consent']['kms_keyvalidate']}"
		con_name=XmlSimple.xml_in(req)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['key_validate']}?key=#{con_name['apps'][0]['app'][0]['clientId'].to_s}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req1}", :content_type => "application/xml")
		kms_req2 = "#{TEST_CONFIG['consent']['kms_developer_error']}"
		con_name1=XmlSimple.xml_in(kms_req1)
		test_kms_url = "http://apigee:apigee123@#{DEFAULT_CONFIG['kms_site_url']}:#{DEFAULT_CONFIG['kms_port']}#{DEFAULT_CONFIG['kms']['developer_name']}?consumerid=#{con_name1['loginid'][0]}"
		FakeWeb.register_uri(:get, "#{test_kms_url}", :body => "#{kms_req2}", :content_type => "application/xml")
		get(:consent_application, {:consent => {:application_name => 'abc'}})
	  response.should render_template("manage_consent/consent_application.erb")
	end 
	it "Should able to revoke the application" do
		req = "#{TEST_CONFIG['consent']['revoke']}"
		test_url = "http://#{DEFAULT_CONFIG['site_url']}:#{DEFAULT_CONFIG['port']}#{DEFAULT_CONFIG['application']['revoke_consent']}"
		FakeWeb.register_uri(:any, "#{test_url}", :body => "#{req}", :content_type => "application/xml")		
		get(:revoke_application, {:consent => {:application_name => 'abc'}})		
	  response.should redirect_to(applications_path) 		
	end 
end