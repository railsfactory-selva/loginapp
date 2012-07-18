class ManageProfilesController < ApplicationController
	layout 'application'
	#~ before_filter :check_for_logged_in, :only => ['login_create']
	before_filter :empty_flash, :except => ['login_manage']
	before_filter :require_ssl, :except  => [:http_on_net_consent]
	def index
		redirect_to login_path
	end
	def login_manage
		session[:mc_authenticated] = false
		set_flag = "true"
		unless ((flash[:error] && !flash[:error].blank?) || (flash[:net_error] && !flash[:net_error].blank?))
			session[:redirect_url] = nil
			session[:client_id] = nil
			session[:scope] = nil
			set_flag = "false"
		end
		if params[:mc_registration] && params[:mc_registration] == "true"
			captcha_details
			terms_and_conditions
		end
		if params[:redirect_url] && !params[:redirect_url].blank? && set_flag == "false"
			session[:redirect_url] = URI.escape(params[:redirect_url].to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))			
		end
		if params[:scope] && !params[:scope].blank? && params[:client_id] && !params[:client_id].blank?
			session[:client_id] = params[:client_id].to_s
			session[:scope] = params[:scope].to_s
		end
		if params[:login] && params[:login] == "registration"
			captcha_details
			terms_and_conditions
		else
		if flash[:success] && !flash[:success].blank?
			terms_and_conditions
		else
		if flash[:reg_error] && !flash[:reg_error].blank?
			captcha_details
		end
		if (flash[:error] && !flash[:error].blank?) || (flash[:net_error] && !flash[:net_error].blank? && params[:login] && (params[:login] == "true") || (params[:login] == "mc"))
			terms_and_conditions
		else
			cookies[:sessionId] = nil if ((!flash[:net_error] || (flash[:net_error] && flash[:net_error].blank?))  && ((params[:login] && params[:login] != "pin_cancel") || (!flash[:success] || (flash[:success] && flash[:success].blank?))))
			url = DEFAULT_CONFIG['login']['session_details']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId>#{params[:client_id]}</clientId><scope>#{params[:scope]}</scope><transactionId>#{params[:id]}</transactionId><redirectUrl><![CDATA[#{session[:redirect_url]}]]></redirectUrl></getSessionDetails>"
			xml_request_to_be_sent(url, xml_data)			
			flash[:client_id] = params[:client_id]
			flash[:scope] = params[:scope]
			flash[:redirect_url] = session[:redirect_url]
			@scope = params[:scope]
			@display_scope = params[:scope]
			@redirect_url = session[:redirect_url]
			@client_id = params[:client_id]
			if ((@response_failed == true) || (@result && !@result['developerAppDetails']) || (@res_code == "404") || (@res_code == "500"))
				if @result && @result['details']
					flash[:net_error] = @result['details'][0].to_s
					render 'off_net_consent'
					flash[:net_error] = nil
				else
					logger.info "Expected success response was not returned back for the getSessionDetails API call\n\n"
					logger.debug "REQUEST SENT getSessionDetails API:- #{xml_data}\n\n"
					if @error_response
						logger.debug "RESPONSE RECEIVED back for getSessionDetails API :- #{@error_response.inspect}"
					else
						logger.debug "RESPONSE RECEIVED back for getSessionDetails API :- #{@result.inspect}" if @result
					end
					@app_name = flash[:app_name]
					@dev_name = flash[:dev_name]
					@scope = flash[:app_scope]
					if (params[:login] && params[:login] == "true")
						terms_and_conditions
						#~ flash[:error] = t('failure_response') 					
					else
						#~ flash[:net_error] = t('failure_response')
						render 'off_net_consent'
					end
				end
			else
				dev_and_app_name
				@scope = @result['scope'].to_s.to_s.split(',')
				@display_scope = @result['scope'].to_s
				@user_id = @result['userId'].to_s
				@authorization = @result['isAuthorizationRequired'].to_s
				network = @result['onNetworkAuthentication'].to_s
				cookies[:sessionId] = {:value => @result['newCookie'].to_s, :http_only => true } if !@result['newCookie'].to_s.blank?
				if params[:login] && (params[:login] == "true" || params[:login] == "mc")
					terms_and_conditions
				else
					logger.info "OnNet whitelist check IP = #{request.remote_ip}, allowed = #{network}"
					if network == "true"						
						flash[:on_net_error] = flash[:net_error]  
						redirect_to "http://#{DEFAULT_CONFIG['login_app_url']}:#{DEFAULT_CONFIG['login_app_port']}/http_on_net_consent", :status => 302
					else
						render 'off_net_consent'
					end
				end
			end
		end
		end
		end
	end
	def off_net_consent
	end
	def http_on_net_consent
		flash[:x_up_subno] = request.headers['HTTP_X_UP_SUBNO']
		flash[:client_ip] = request.remote_ip
		flash[:net_error] = flash[:on_net_error]  
		flash[:on_client_id] = flash[:client_id]
		flash[:on_redirect_url] = flash[:redirect_url]
		flash[:on_scope] = flash[:scope]
		redirect_to "https://#{DEFAULT_CONFIG['login_app_url']}/on_net_consent?client_id=#{session[:client_id]}&scope=#{session[:scope]}&redirect_url=#{session[:redirect_url]}"
	end
	def on_net_consent
		@client_id = flash[:on_client_id]
		@scope = flash[:on_scope]
		@redirect_url = flash[:on_redirect_url]
		header = flash[:x_up_subno]
			if header && !header.blank?
				header_length = header.length
				if header_length && header_length > 4
					sliced_header = header.slice(header_length - 4, header_length)
					first_string ='*' * (header_length-4)
					header  = first_string + sliced_header
				end
				logger.info "OnNet Header IP = #{flash[:client_ip]}, X-Up-Subno = #{header}"
				url = DEFAULT_CONFIG['login']['on_network_auth']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><onNetworkAuth><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{flash[:client_ip]}</clientIP><subscriberNumber>#{flash[:x_up_subno]}</subscriberNumber></onNetworkAuth>"
				xml_request_to_be_sent(url, xml_data)
				if ((@response_failed == true) || (@result && !@result['userDetails']) || (@res_code == "404") || (@res_code == "500") || (!@result))
					logger.info "Expected success response was not returned back for the onNetworkAuth API call\n\n"
					logger.debug "REQUEST SENT onNetworkAuth API:- #{xml_data}\n\n"
					if @error_response
						logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@error_response.inspect}" 
					else
						logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@result.inspect}" if @result
					end
					render 'off_net_consent'
				else
					if @result && @result['userDetails']  && @result['userDetails'][0]['userId']
							@user_id = @result['userDetails'][0]['userId'].to_s
							@scope = @result['scope'].to_s.to_s.split(',')
							@display_scope = @result['scope'].to_s
							dev_and_app_name
							if  !@app_name.blank? && !@user_id.blank?
								render 'on_net_consent'
							else
								call_off_net_from_on_net
								render 'off_net_consent'
							end
					else
							logger.info "Expected success response was not returned back for the onNetworkAuth API call\n\n"
							logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@result.inspect}" if @result
							logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@error_response.inspect}" if @error_response
							call_off_net_from_on_net
							render 'off_net_consent'
					end
				end
			else
				logger.error "OnNet Header IP = #{flash[:client_ip]}, X-Up-Subno header not received"
				call_off_net_from_on_net
				render 'off_net_consent'
			end
		end
  def new_user
		captcha_details
		render :update do |page|
			page.hide 'existing_users'
			page.replace_html 'new_user', :partial=>"new_user"
		end
	end
	def login_create
		flash[:error]=nil
		username = params[:login][:username]
		password = params[:login][:password]
		@client_id = params[:login][:client_id]
		@scope = params[:login][:scope]
		@redirectUrl = params[:login][:redirectUrl]
		if !username.blank? && !password.blank?
			if params[:login][:redirect_url] == "Manage Consent"
				url = DEFAULT_CONFIG['application']['manage_consent']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><login><sessionId>#{cookies[:sessionId]}</sessionId><userId>#{username}</userId><password>#{password}</password></login>"
				xml_request_to_be_sent(url, xml_data)
				if @result && !@result['userId'].to_s.blank?
					redirect_to manage_consent_path
				else
					error_message('login', nil, 'error', 'login_call')
					redirect_to login_path(:login => "mc", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
				end
			else
				url = DEFAULT_CONFIG['login']['login_url']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><login><sessionId>#{cookies[:sessionId]}</sessionId><userId>#{username}</userId><password>#{password}</password></login>"
				xml_request_to_be_sent(url, xml_data)		
				if @result && @result['statusCode'] && @result['userDetails'] && @result['userDetails'][0]['userProfile']
					@response_code = @result['statusCode'].to_s		
					@user_id = @result['userDetails'][0]['userId'].to_s
          if @result['userDetails'][0]['userProfile'][0]['isMsisdnValidated'] && @result['userDetails'][0]['userProfile'][0]['isEmailValidated'] && @result['userDetails'][0]['userProfile'][0]['isDOBValid']
            is_mobile = @result['userDetails'][0]['userProfile'][0]['isMsisdnValidated'].to_s
            is_email = @result['userDetails'][0]['userProfile'][0]['isEmailValidated'].to_s
            is_dob = @result['userDetails'][0]['userProfile'][0]['isDOBValid'].to_s
          else
            error_message('login', @response_code, 'error', 'login_call')
          end
					flag = false
					if is_mobile == "Y" && is_email == "Y" && is_dob == "Y"
						flag= true
					end
					if flag == false && @response_code == "200"
						error_message('login', nil, 'error', 'invalid_account')
						redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)
					elsif @response_code != "200"
						if @response_code == "206" ||  @response_code == "240"
							redirect_to change_password_path
						else
							error_message('login', @response_code, 'error', nil)
							redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
						end
					elsif @response_code == "200" && !@user_id.to_s.blank? #&& !@result['developerAppDetails'][0]['name'].to_s.blank? && !@result['developerAppDetails'][0]['appname'].to_s.blank?
						@scope = @result['scope'].to_s.split(',')
						dev_and_app_name
						#~ authorization = @result['isAuthorizationRequired'].to_s
						#~ if authorization == "true"
						if params[:login][:redirect_url] == "Consent Decline"
							decline_app
						else
							consent_app
						end
						#~ else
							#~ redirect_to consent_confirmation_path
						#~ end
					else
						error_message('login', @response_code, 'error', 'login_call')
						redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
					end
				else
          if (@result && @result['statusCode']) && ((!@result['userDetails']) || (@result['userDetails'] && !@result['userDetails'][0]['userProfile']))
            error_message('login', @result['statusCode'], 'error', 'login_call')
          else
            flash[:error] = t('failure_response')            
          end
					redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
				end
			end
		else
			error_message('login', nil, 'error', 'missing_pwd') if password.blank?
			error_message('login', nil, 'error', 'missing_username') if username.blank?
			if params[:login][:redirect_url] == "Manage Consent"
				redirect_to login_path(:login => "mc")
			else
				redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
			end
		end
	end
		def consent_app
url = DEFAULT_CONFIG['application']['issue_consent']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><issueConsent><sessionId>#{cookies[:sessionId]}</sessionId></issueConsent>"
			xml_request_to_be_sent(url, xml_data)
			if ((@response_failed == true) || (@result && !@result['authcode']) || (@res_code == "404") || (@res_code == "500"))
				logger.info "Expected success response was not returned back for the issueConsent API call\n\n"
				logger.debug "REQUEST SENT issueConsent API during login oauth flow :- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for issueConsent API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for issueConsent API :- #{@result.inspect}" if @result
				end
				flash[:error] = t('failure_response')
				redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)
			else
				if @result && @result['authcode'] && !@result['authcode'].to_s.blank?
					auth_code = @result['authcode'].to_s
					scope = @result['scope'].to_s
					guid = @result['guid'].to_s
					clientId = @result['clientId'].to_s
					url = DEFAULT_CONFIG['application']['redirect_url']
					xml_data="<?xml version='1.0' encoding='UTF-8'?><createAuthorize><sessionId>#{cookies[:sessionId]}</sessionId><authcode>#{auth_code}</authcode><scope>#{scope}</scope><clientId>#{clientId}</clientId><guid>#{guid}</guid> <redirectUrl><![CDATA[#{session[:redirect_url]}]]></redirectUrl></createAuthorize>"
					xml_request_to_be_sent(url, xml_data)
					if @result && @result['redirect_url'] && !@result['redirect_url'].to_s.blank?
						redirect_to = @result['redirect_url'].to_s
						redirect_to = URI.unescape(redirect_to)
						if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
							@redirect_url = redirect_to.to_s
						else
							@redirect_url = "http://"+redirect_to.to_s
						end
						url = DEFAULT_CONFIG['login']['session_details']
						xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId>#{clientId}</clientId><scope>#{scope}</scope><transactionId></transactionId><redirectUrl></redirectUrl></getSessionDetails>"
						xml_request_to_be_sent(url, xml_data)	
						if ((@response_failed == true) || (@result && !@result['userDetails']) || (@res_code == "404") || (@res_code == "500"))
							logger.info "Expected success response was not returned back for the getSessionDetails API call\n\n"
							logger.debug "REQUEST SENT validatePin API:- #{xml_data}\n\n"
							if @error_response
								logger.debug "RESPONSE RECEIVED back for getSessionDetails API after OAuth login:- #{@error_response.inspect}" 
							else
								logger.debug "RESPONSE RECEIVED back for getSessionDetails API after OAuth login:- #{@result.inspect}" if @result
							end
							flash[:error] = t('failure_response')    
							redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)
						else
							dev_and_app_name
							display_scope_title
							session[:mc_authenticated] = true
							render 'login_thank_you'
						end						
					else
						flash[:error] = t('failure_response')    
						redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)
					end
				else
					flash[:error] = t('failure_response') 
					redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
				end
			end
	end
	def decline_app
		url = DEFAULT_CONFIG['application']['cancel_consent']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><cancelAuthorize><sessionId>#{cookies[:sessionId]}</sessionId></cancelAuthorize>"
		xml_request_to_be_sent(url, xml_data)
		if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500"))
			logger.info "Expected success response was not returned back for the cancelAuthorize API call\n\n"
			logger.debug "REQUEST SENT cancelAuthorize API:- #{xml_data}\n\n"
			if @error_response
				logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@error_response.inspect}"
			else
				logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@result.inspect}" if @result
			end
			flash[:error] = t('failure_response')
			redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
		else
			if @result && @result['redirect_url'] && !@result['redirect_url'].to_s.blank?
				redirect_to = @result['redirect_url'].to_s
				redirect_to = URI.unescape(redirect_to)
				if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
					redirect_to redirect_to.to_s, :status => 302
				else
					redirect_to "http://"+redirect_to.to_s, :status => 302
				end
			else
				flash[:error] = t('failure_response') 
				redirect_to login_path(:login => "true", :client_id => @client_id, :scope => @scope, :redirect_url => @redirectUrl)		
			end
		end
	end
	def login_thank_you
	end
	def registration
		@new_user=true
		if !params[:login][:captcha_phrase].blank? && !params[:login][:phone].blank?
			url = DEFAULT_CONFIG['login']['validate_number']
			xml_data = "<?xml version='1.0' encoding='UTF-8'?><getSubscriberStatus><sessionId>#{cookies[:sessionId]}</sessionId></getSubscriberStatus>"
			url = url + "/#{params[:login][:phone]}/#{params[:login][:captcha_id]}/#{params[:login][:captcha_phrase]}"
			xml_request_to_be_sent(url,xml_data)
			@wireless_number = params[:login][:phone]
			if @result && @result['responseStatus']
			  @message = @result['responseStatus'][0]['statusMessage'].to_s
			  @code = @result['responseStatus'][0]['statusCode'].to_s
				if @result['subscriberStatus'].to_s=="A"
					captcha_details
					if @captcha_id && @captcha_content
						terms_and_conditions	
						#~ url = DEFAULT_CONFIG['login']['get_terms_and_conditions']
						#~ request_to_be_sent(url)
						#~ if @tc_result && @tc_result['tc'] && @tc_result['responseStatus'] && @tc_result['responseStatus'][0]['statusCode'].to_s == "200"
							#~ @tc_id = @tc_result['tc'][0]['tcId'].to_s
							#~ @tc_content = @tc_result['tc'][0]['tcContent'].to_s 
							#~ @tc_status = @tc_result['responseStatus'][0]['statusCode'].to_s 		
						#~ end	
					else
						redirect_to login_path(:login => "registration")
					end
				else
					if  @result['subscriberStatus'] && @result['subscriberStatus'].to_s !="A"
						error_message('subscriber', nil, 'reg_error', 'invalid_wireless')
					else
						error_message('subscriber', @code, 'reg_error', @message)
					end
					redirect_to login_path(:login => "registration")
				end
			else
				flash[:reg_error] = t('failure_response')
				redirect_to login_path(:login => "registration")
			end
		else
			error_message('subscriber', nil, 'reg_error', 'missing_captcha') if params[:login][:captcha_phrase].blank?
			error_message('subscriber', nil, 'reg_error', 'missing_wireless') if params[:login][:phone].blank?			
			redirect_to login_path(:login => "registration")
		end
	end
	def off_network_registration
		@wireless_number = params[:login][:wireless]
		captcha_details
		terms_and_conditions
		#~ url = DEFAULT_CONFIG['login']['get_terms_and_conditions']
		#~ request_to_be_sent(url)
    #~ if @tc_result && @tc_result['tc'] && @tc_result['responseStatus'] && @tc_result['responseStatus'][0]['statusCode'].to_s == "200"
			#~ @tc_id = @tc_result['tc'][0]['tcId'].to_s
			#~ @tc_content = @tc_result['tc'][0]['tcContent'].to_s 
			#~ @tc_status = @tc_result['responseStatus'][0]['statusCode'].to_s 		
		#~ end
		render 'registration'
	end
	
	def signup_create
		if !params[:tcid].blank?
			@wireless_number = params[:signup][:phone]
			@email = params[:signup][:email]
			@confirm_email = params[:signup][:confirm_email]
			@content_day = params[:content_day]
			@content_month = params[:content_month]
			content_month = params[:content_month]
			@content_year = params[:content_year]
			@email_valid = validate_email(params[:signup][:email])
			@email_equal = @email == @confirm_email
			year = {:Jan=>[1], :Feb=>[2], :Mar=>[3], :Apr=>[4], :May=>[5], :Jun=>[6], :Jul=>[7], :Aug=>[8], :Sep=>[9], :Oct=>[10], :Nov=>[11], :Dec=>[12]}
			@tc_id = params[:tcid]
			#@tc_content = params[:tccontent]
      #~ terms_and_conditions
			url = DEFAULT_CONFIG['login']['get_terms_and_conditions']
			request_to_be_sent(url)
      if @tc_result && @tc_result['tc'] && @tc_result['responseStatus'] && @tc_result['responseStatus'][0]['statusCode'].to_s == "200"
				@tc_id = @tc_result['tc'][0]['tcId'].to_s
				@tc_content = @tc_result['tc'][0]['tcContent'].to_s 
				@tc_status = @tc_result['responseStatus'][0]['statusCode'].to_s 		
			end
			if params[:signup][:password] == params[:signup][:confirm_password]  && @email_valid && @email_equal && @content_year != "Select Year" && !params[:signup][:captcha].blank?
				url = DEFAULT_CONFIG['login']['password_url']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><createUser><sessionId>#{cookies[:sessionId]}</sessionId><isAttId>false</isAttId><emailAddress>#{params[:signup][:email]}</emailAddress><gender>M</gender><zip></zip><birthYear>#{params[:content_year]}</birthYear><birthMonth>#{year[:"#{content_month}"]}</birthMonth><birthDate>#{@content_day}</birthDate><mobilePhoneNumber>#{params[:signup][:phone]}</mobilePhoneNumber><userId>#{params[:signup][:email]}</userId><password>#{params[:signup][:password]}</password><captcha><captchaId>#{params[:catcha_id]}</captchaId><phrase>#{params[:signup][:captcha]}</phrase></captcha><tc><tcId>#{params[:tcid]}</tcId><action>Accept</action></tc></createUser>"
				xml_request_to_be_sent(url, xml_data)		
			@content_day = "Jan" if (!params[:content_day] || (params[:content_day] && params[:content_day].blank?))
			@content_month = "1" if (!params[:content_month] || (params[:content_month] &&  params[:content_month].blank?))
				if @result && @result['responseStatus']
					@response_code = @result['responseStatus'][0]['statusCode'].to_s
					@response_message = @result['responseStatus'][0]['statusMessage'].to_s		
					if @response_code != "200"
						error_message('register', @response_code, 'reg_error', @response_message)
						captcha_details
						render 'registration'
					else	
						@wireless_number = params[:signup][:phone]
						url = DEFAULT_CONFIG['login']['resend_mobile_pin']
						xml_data="<?xml version='1.0' encoding='UTF-8'?><sendValidationPIN><sessionId>#{cookies[:sessionId]}</sessionId></sendValidationPIN>"
						xml_request_to_be_sent(url, xml_data)
						render 'activation'
					end
				else
					flash[:reg_error] = t('failure_response')
					captcha_details
					render 'registration'
				end
			else
				if !@email_valid
					params[:signup][:email] && !params[:signup][:email].blank? ? error_message('register', nil, 'reg_error', 'invalid_email') : error_message('register', nil, 'reg_error', 'missing_email')
				elsif !@email_equal
					error_message('register', nil, 'reg_error', 'email_match')
				elsif params[:signup][:password] && params[:signup][:password].blank?
					error_message('register', nil, 'reg_error', 'missing_pwd')
				elsif params[:signup][:password] != params[:signup][:confirm_password]
					error_message('register', nil, 'reg_error', 'pwd_match')
				elsif @content_year == "Select Year"
					error_message('register', nil, 'reg_error', 'missing_dob')
				elsif params[:signup][:captcha] && params[:signup][:captcha].blank?
					error_message('register', nil, 'reg_error', 'missing_captcha')
			 end
				captcha_details
				render 'registration'
			end
		else
			flash[:reg_error] = t('failure_response')
			captcha_details
			render 'registration'
		end
	end	
	def login_reset_password
		url = DEFAULT_CONFIG['login']['captcha_url']
		request_to_be_sent(url)
		if @result && @result['responseStatus']
			@response_code = @result['responseStatus'][0]['statusCode'].to_s		
			@response_message = @result['responseStatus'][0]['statusMessage'].to_s		
			if @response_code == "200"
				@captcha_id = @result['captcha'][0]['captchaId'].to_s
				@captcha_content = @result['captcha'][0]['content'].to_s
				@captcha_type = @result['captcha'][0]['contentType'].to_s
			else
				flash[:reset_error] = t('failure_response')
			end
		else
			flash[:reset_error] = t('failure_response')
		end
	end
	def reset_password		
	end
	def change_password
  email = params[:reset][:username] 
  captcha = params[:reset][:captcha_phrase] 
	if email && !email.blank? && captcha && !captcha.blank?
			url = DEFAULT_CONFIG['login']['reset_password']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><resetPassword><sessionId>#{cookies[:sessionId]}</sessionId><userId>#{email}</userId><captcha><captchaId>#{params[:reset][:captcha_id]}</captchaId><phrase>#{captcha}</phrase><contentType>#{params[:reset][:captcha_type]}</contentType></captcha></resetPassword>"
			xml_request_to_be_sent(url, xml_data)
			if @result && @result['responseStatus']
				@response_code = @result['responseStatus'][0]['statusCode'].to_s 
				@response_message = @result['responseStatus'][0]['statusMessage'].to_s		
				if @result && @response_code == "200"
					error_message('reset_pwd', @response_code, 'success', @response_message)
					redirect_to login_path(:login => "true")
				else
					error_message('reset_pwd', @response_code, 'reset_error', @response_message)
					redirect_to login_reset_password_path
				end
			else
				flash[:reset_error] = t('failure_response')
				redirect_to login_reset_password_path
			end
		else
			error_message('reset_pwd', nil, 'reset_error', 'missing_captcha') if captcha && captcha.blank?
			error_message('reset_pwd', nil, 'reset_error', 'missing_email') if email && email.blank?
			redirect_to login_reset_password_path
		end
	end
	
	def reset_create
		if params[:reset][:current_password].blank?
			error_message('change_pwd', nil, 'error', 'missing_current_pwd')
			redirect_to change_password_path 
		elsif params[:reset][:password].blank?
			error_message('change_pwd', nil, 'error', 'missing_new_pwd')
			redirect_to change_password_path
		elsif params[:reset][:confirm_password].blank?
			error_message('change_pwd', nil, 'error', 'missing_confirm_pwd')
			redirect_to change_password_path
		elsif params[:reset][:password] != params[:reset][:confirm_password]
			error_message('change_pwd', nil, 'error', 'pwd_match')
			redirect_to change_password_path
		else
			url = DEFAULT_CONFIG['login']['change_password']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><changePassword><sessionId>#{cookies[:sessionId]}</sessionId><currentPassword>#{params[:reset][:current_password]}</currentPassword><newPassword>#{params[:reset][:password]}</newPassword></changePassword>"
			xml_request_to_be_sent(url, xml_data)
			if @result && @result['responseStatus']
				@response_code = @result['responseStatus'][0]['statusCode'].to_s
				@response_message = @result['responseStatus'][0]['statusMessage'].to_s
				if @response_code == "200"
					error_message('change_pwd', @response_code, 'success', @response_message)
					redirect_to login_path(:login => "true")
				else
					error_message('change_pwd', @response_code, 'error', @response_message)
					redirect_to change_password_path
				end
			else
				flash[:error] = t('failure_response')
				redirect_to change_password_path
			end
		end
		#~   redirect_to change_password_path if flash[:error]
	end
	def activation
	end
	
	
	def resend_mobile_pin
		@wireless_number = params[:mobile_number]
		@email = params[:email]
		url = DEFAULT_CONFIG['login']['resend_mobile_pin']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><sendValidationPIN><sessionId>#{cookies[:sessionId]}</sessionId></sendValidationPIN>"
		xml_request_to_be_sent(url, xml_data)
		if @result && @result['responseStatus']
			@response_code = @result['responseStatus'][0]['statusCode'].to_s
			@response_message = @result['responseStatus'][0]['statusMessage'].to_s			
			if @response_code != "200"		
				error_message('activation', @response_code, 'error_mpin', @response_message)
				error_message('success_mobilePIN', @response_code, 'success_mpin', @response_message) if flash[:success_mpin]
			else
				error_message('success_mobilePIN', @response_code, 'success_mpin', @response_message)
				flash[:error_mpin] = nil if flash[:error_mpin]
			end
		else
			flash[:error_mpin] = t('failure_response')
		end
		render 'activation'
	end
	
	def resend_email_pin
		@wireless_number = params[:mobile_number]
		@email = params[:email]		
		url = DEFAULT_CONFIG['login']['resend_email_pin']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><sendValidationEmail><sessionId>#{cookies[:sessionId]}</sessionId></sendValidationEmail>"
		xml_request_to_be_sent(url, xml_data)
		if @result && @result['responseStatus']
			@response_code = @result['responseStatus'][0]['statusCode'].to_s
			@response_message = @result['responseStatus'][0]['statusMessage'].to_s			
			if @response_code != "200"		
				error_message('activation', @response_code, 'error_epin', @response_message)
				 flash[:success_epin] = nil if flash[:success_epin]
			else
				error_message('success_emailPIN', @response_code, 'success_epin', @response_message)
				flash[:error_epin] = nil 
			end
		else
			flash[:error_epin] = t('failure_response')
		end
		render 'activation'
	end
	
	
	def validate_pin
		@mobile = params[:validate][:phone]
		@email = params[:validate][:email]
		success = false
		url = DEFAULT_CONFIG['login']['reg_validate_pin']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><validatePIN><sessionId>#{cookies[:sessionId]}</sessionId><PIN>#{@mobile}</PIN><Destination>1#{params[:mobile_number]}</Destination></validatePIN>"
		xml_request_to_be_sent(url, xml_data)
		if @result && @result['responseStatus']
			@response_code_mobile = @result['responseStatus'][0]['statusCode'].to_s
			@response_message_mobile = @result['responseStatus'][0]['statusMessage'].to_s	
			@result = nil
			url = DEFAULT_CONFIG['login']['validate_email']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><validateEmail><sessionId>#{cookies[:sessionId]}</sessionId><token>#{@email}</token></validateEmail>"
			xml_request_to_be_sent(url, xml_data)
			if @result && @result['responseStatus']
				@response_code_email = @result['responseStatus'][0]['statusCode'].to_s
				@response_message_email = @result['responseStatus'][0]['statusMessage'].to_s			
				@mobile_valid = false
				@emailpin_valid = false
				if @response_code_mobile == "220" || @response_code_mobile == "200"
					@mobile_valid = true
				end
				if @response_code_email == "231" || @response_code_email == "236" || @response_code_email == "200"
					@emailpin_valid = true
				end
				if ((@response_code_mobile == "200" || @mobile_valid == true) && (@response_code_email == "200" || @emailpin_valid == true))
					url = DEFAULT_CONFIG['login']['session_details']
					xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId></clientId><scope></scope><transactionId></transactionId><redirectUrl></redirectUrl></getSessionDetails>"
					xml_request_to_be_sent(url, xml_data)	
					 #~ @redirect_url = @result['redirect_url'].to_s
					#~ if @redirect_url && @redirect_url.blank?
							@redirect_url = login_path(:login => "true", :client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
					#~ end
					render 'signup_confirmation'
				else
					error_message('activation', @response_code_mobile, 'error_mpin', @response_message_mobile) if @response_code_mobile != "200" || @mobile_valid != true
					error_message('activation', @response_code_email, 'error_epin', @response_message_email) if @response_code_email != "200" || @emailpin_valid != true
					if flash[:error_mpin] == "Success"
						flash[:success_mpin] = "Success"
						flash[:error_mpin] = nil
					end
					if flash[:error_epin] == "Success"
						flash[:success_epin] = "Success"
						flash[:error_epin] = nil
					end
					render 'activation'
				end
			else
			 flash[:error_epin] = t('failure_response')
			 render 'activation'
		  end
		else
			flash[:error_mpin] = t('failure_response')
			render 'activation'
		end
	end
	
	def routing
    render  "#{Rails.root}/public/404.html", :status => 404, :layout =>true
  end
	def captcha_details
		url = DEFAULT_CONFIG['login']['captcha_url']
		request_to_be_sent(url)
		if ((@response_failed == true) || (@result && !@result['responseStatus']) || (@res_code == "404") || (@res_code == "500"))
				flash[:reg_error] = t('failure_response')
		else
			@response_code = @result['responseStatus'][0]['statusCode'].to_s		
			@response_message = @result['responseStatus'][0]['statusMessage'].to_s			
			if @result['captcha'] && @response_code == "200"
				@captcha_id = @result['captcha'][0]['captchaId'].to_s
				@captcha_content = @result['captcha'][0]['content'].to_s
			else
				flash[:reg_error] = t('failure_response')
			end
		end
	end
	def terms_and_conditions
			url = DEFAULT_CONFIG['login']['get_terms_and_conditions']
			request_to_be_sent(url)
      if @tc_result && @tc_result['tc'] && @tc_result['responseStatus'] && @tc_result['responseStatus'][0]['statusCode'].to_s == "200"
				@tc_id = @tc_result['tc'][0]['tcId'].to_s
				@tc_content = @tc_result['tc'][0]['tcContent'].to_s 
				@tc_status = @tc_result['responseStatus'][0]['statusCode'].to_s 			
			#~ else
				#~ flash[:reg_error] = t('failure_response')
				#~ flash[:error] = t('failure_response')
        #~ redirect_to login_path
			#~ render :update do |page|
					#~ page.call 'terms_and_conditions', @tc_content
				#~ end

			end
		end
		
		def call_off_net_from_on_net
			set_flag = "true"
			unless ((flash[:error] && !flash[:error].blank?) || (flash[:net_error] && !flash[:net_error].blank?))
				session[:redirect_url] = nil
				session[:client_id] = nil
				session[:scope] = nil
				set_flag = "false"
			end
			if params[:redirect_url] && !params[:redirect_url].blank? && set_flag == "false"
				session[:redirect_url] = URI.escape(params[:redirect_url].to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))			
			end
			if params[:scope] && !params[:scope].blank? && params[:client_id] && !params[:client_id].blank?
				session[:client_id] = params[:client_id].to_s
				session[:scope] = params[:scope].to_s
			end
			@scope = params[:scope]
			@display_scope = params[:scope]
			@redirect_url = session[:redirect_url]
			@client_id = params[:client_id]
			url = DEFAULT_CONFIG['login']['session_details']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId>#{session[:client_id]}</clientId><scope>#{session[:scope]}</scope><transactionId></transactionId><redirectUrl><![CDATA[#{session[:redirect_url]}]]></redirectUrl></getSessionDetails>"
				xml_request_to_be_sent(url, xml_data)	
				if ((@response_failed == true) || (@result && !@result['userDetails']) || (@res_code == "404") || (@res_code == "500"))
					logger.info "Expected success response was not returned back for the getSessionDetails API call\n\n"
					logger.debug "REQUEST SENT validatePin API:- #{xml_data}\n\n"
					if @error_response
						logger.debug "RESPONSE RECEIVED back for getSessionDetails API after pin validation in on network, header missing flow:- #{@error_response.inspect}" 
					else
						logger.debug "RESPONSE RECEIVED back for getSessionDetails API after pin validation in on network, header missing flow:- #{@result.inspect}" if @result
					end
				else
					dev_and_app_name
					@scope = @result['scope'].to_s.to_s.split(',')
					@display_scope = @result['scope'].to_s
					@user_id = @result['userId'].to_s
				end
			end
		
	protected

def validate_email(email)
  
  email_regex = %r{
    ^ # Start of string
    [0-9a-z] # First character
    [0-9a-z._-]+ # Middle characters
    [0-9a-z] # Last character
    @ # Separating @ character
    [0-9a-z] # Domain name begin
    [0-9a-z.-]+ # Domain name middle
    [0-9a-z] # Domain name end
    $ # End of string
  }xi # Case insensitive
  
  if (email =~ email_regex) == 0
    return true
  else
    return false
  end
end
end
