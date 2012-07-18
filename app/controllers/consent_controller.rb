class ConsentController < ApplicationController
	layout 'application'
	before_filter :check_for_logged_in, :only => ['consent_app','decline_app']
	before_filter :require_ssl, :except  => [:http_on_net_aoc_consent]
	before_filter :empty_flash
	#~ def consent_app
		#~ @app_name = params[:app_name]
		#~ @scope = params[:scope].split(',')
		#~ @user_id = params[:user_id]
	#~ end
	def consent_accept
	end
	def consent_confirmation
		if !params[:consent] || params[:consent][:consent_status] == "Accept"
			url = DEFAULT_CONFIG['application']['issue_consent']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><issueConsent><sessionId>#{cookies[:sessionId]}</sessionId></issueConsent>"
			xml_request_to_be_sent(url, xml_data)
			auth_code = @result['authcode'].to_s
			scope = @result['scope'].to_s
			guid = @result['guid'].to_s
			clientId = @result['clientId'].to_s
			url = DEFAULT_CONFIG['application']['redirect_url']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><createAuthorize><authcode>#{auth_code}</authcode><scope>#{scope}</scope><clientId>#{clientId}</clientId><guid>#{guid}</guid> <redirectUrl><![CDATA[#{@result['redirectUrl'].to_s}]]></redirectUrl></createAuthorize>"
		else
			url = DEFAULT_CONFIG['application']['cancel_consent']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><cancelAuthorize><sessionId>#{cookies[:sessionId]}</sessionId></cancelAuthorize>"
		end
			xml_request_to_be_sent(url, xml_data)
			redirect_to = @result['redirect_url'].to_s
			redirect_to = URI.unescape(redirect_to)
		if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
			redirect_to redirect_to.to_s, :status => 302
		else
			redirect_to "http://"+redirect_to.to_s, :status => 302
		end
	end
	def payments
		#~ cookies[:sessionId] = nil
		session[:mc_authenticated] = false
		if params[:sessionid] && !params[:sessionid].blank?
			session_id = params[:sessionid]
		else
			session_id = cookies[:sessionId]
		end
		url = DEFAULT_CONFIG['payment']['payment_details']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><getPaymentDetails><sessionId>#{session_id}</sessionId><clientIP>#{request.remote_ip}</clientIP></getPaymentDetails>"
		xml_request_to_be_sent(url, xml_data)
		if ((@response_failed == true) || (@result && !@result['onNetworkAuthentication']) || (@res_code == "404") || (@res_code == "500") || (!@result))
			logger.info "Expected success response was not returned back for the getPaymentDetails API call\n\n"
			logger.debug "REQUEST SENT getPaymentDetails API:- #{xml_data}\n\n"
			if @error_response
				logger.debug "RESPONSE RECEIVED back for getPaymentDetails API :- #{@error_response.inspect}"
			else
				logger.debug "RESPONSE RECEIVED back for getPaymentDetails API :- #{@result.inspect}" if @result
			end			
				@app_name = flash[:app_name]
				@dev_name = flash[:dev_name]
				@scope = flash[:app_scope]
				@organization = flash[:organization]
				@charge = flash[:charge]	
				#~ @session_id = flash[:session_id]
			#~ flash[:net_error] = t('failure_response')
			render 'off_net_aoc_consent'
		else
			logger.debug "Response for getPaymentDetails : #{@result.inspect}"
			network = @result['onNetworkAuthentication'].to_s
			dev_and_app_name
			#~ @organization = @result['organization'].to_s
			charge =  CGI::unescape(@result['chargeDetails'].to_s)
			charge = XmlSimple.xml_in(charge)
			currency = charge['currency'] && !charge['currency'].nil? ? charge['currency'] : charge['Currency']
			amount = charge['amount'] && !charge['amount'].nil? ? charge['amount'] : charge['Amount']
			@charge = "#{currency}  #{amount}"
			@organization = charge['description'][0] if charge['description']
			if charge['SubscriptionRecurringPeriod'] || charge['subscriptionRecurringPeriod']
				@period = charge['SubscriptionRecurringPeriod'][0]  if charge['SubscriptionRecurringPeriod']
				@period = charge['subscriptionRecurringPeriod'][0]  if charge['subscriptionRecurringPeriod']
			end
			cookies[:sessionId] = {:value => @result['newCookie'].to_s, :http_only => true} if !@result['newCookie'].to_s.blank?
			flash[:onnet_session_id] = params[:sessionid]
			logger.info "Payment - OnNet whitelist check IP = #{request.remote_ip}, allowed = #{network}"
			if network == "true"
				redirect_to "http://#{DEFAULT_CONFIG['login_app_url']}:#{DEFAULT_CONFIG['login_app_port']}/user/payments/http_on_net_aoc_consent", :status => 302
			else
				render 'off_net_aoc_consent'
			end
		end
	end
	def off_net_aoc_consent
	end
	def http_on_net_aoc_consent
		flash[:x_up_subno] = request.headers['HTTP_X_UP_SUBNO']
		flash[:client_ip] = request.remote_ip
		flash[:on_session_id] = flash[:onnet_session_id]
		redirect_to "https://#{DEFAULT_CONFIG['login_app_url']}/user/payments/on_net_aoc_consent"
	end
	def on_net_aoc_consent
		flash[:app_name] = params[:app_name]
		flash[:dev_name] = params[:dev_name]
		flash[:app_scope] = params[:app_scope]
		flash[:organization] = params[:organization]
		flash[:charge] = params[:charge]
		flash[:session_id] = params[:sessionid]
		header = flash[:x_up_subno]
		if header && !header.blank?
			header_length = header.length
			if header_length && header_length > 4
				sliced_header = header.slice(header_length - 4, header_length)
				first_string ='*' * (header_length-4)
				header  = first_string + sliced_header
			end
			logger.info "Payment OnNet Header IP = #{flash[:client_ip]}, X-Up-Subno = #{header}"
			url = DEFAULT_CONFIG['payment']['payment_network']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><onNetworkAuth><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{flash[:client_ip]}</clientIP><subscriberNumber>#{flash[:x_up_subno]}</subscriberNumber></onNetworkAuth>"
			xml_request_to_be_sent(url, xml_data)
			if ((@response_failed == true) || (@result && !@result['chargeDetails']) || (@res_code == "404") || (@res_code == "500") || (!@result))
				logger.info "Expected success response was not returned back for the onNetworkAuth payment API call\n\n"
				logger.debug "REQUEST SENT onNetworkAuth API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@result.inspect}" if @result
				end
				off_net_aoc_from_on_net_aoc
				render 'off_net_aoc_consent'
			else
				dev_and_app_name
				#~ @organization = @result['organization'].to_s
				charge =  CGI::unescape(@result['chargeDetails'].to_s)
				charge = XmlSimple.xml_in(charge)
				currency = charge['currency'] && !charge['currency'].nil? ? charge['currency'] : charge['Currency']
				amount = charge['amount'] && !charge['amount'].nil? ? charge['amount'] : charge['Amount']
				@charge = "#{currency}  #{amount}"
				@organization = charge['description'][0] if charge['description']
				if charge['SubscriptionRecurringPeriod'] || charge['subscriptionRecurringPeriod']
					@period = charge['SubscriptionRecurringPeriod'][0]  if charge['SubscriptionRecurringPeriod']
					@period = charge['subscriptionRecurringPeriod'][0]  if charge['subscriptionRecurringPeriod']
				end
				@user_id = @result['userDetails'][0]['userId'].to_s
				if  !@app_name.blank? && !@user_id.blank?
					render 'on_net_aoc_consent'
				else
					off_net_aoc_from_on_net_aoc
					render 'off_net_aoc_consent'
				end
			end
		else
			logger.info "Payment OnNet Header IP = #{flash[:client_ip]}, X-Up-Subno header not received"
			off_net_aoc_from_on_net_aoc
			render 'off_net_aoc_consent'
		end
	end
	def aoc_verify_pin
	end
	def off_net_aoc_validate_pin
		if params[:login][:phone] && !params[:login][:phone].blank?
			url = DEFAULT_CONFIG['login']['validate_pin']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><validatePin><sessionId>#{cookies[:sessionId]}</sessionId><pin>#{params[:login][:phone]}</pin></validatePin>"
			xml_request_to_be_sent(url, xml_data)		
			if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500") || (!@result))
				logger.info "Expected success response was not returned back for the validatePin payment API call\n\n"
				logger.debug "REQUEST SENT validatePin API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for validatePin API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for validatePin API :- #{@result.inspect}" if @result
				end
				
				flash[:net_error] = t('failure_response')
				redirect_to aoc_verify_pin_path
			else
				if @result && @result['status'].to_s == "success"
					url = DEFAULT_CONFIG['payment']['payment_consent']
					xml_data="<?xml version='1.0' encoding='UTF-8'?><issuePaymentConsent><sessionId>#{cookies[:sessionId]}</sessionId></issuePaymentConsent>"
					xml_request_to_be_sent(url, xml_data)
					if @location && !@location.blank?
						redirect_to @location
					else
						if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500") || (!@result))
							logger.info "Expected success response was not returned back for the issuePaymentConsent API call\n\n"
							logger.debug "REQUEST SENT issuePaymentConsent API:- #{xml_data}\n\n"
							if @error_response
								logger.debug "RESPONSE RECEIVED back for issuePaymentConsent API :- #{@error_response.inspect}"
							else
								logger.debug "RESPONSE RECEIVED back for issuePaymentConsent API :- #{@result.inspect}" if @result
							end
							flash[:net_error] = t('failure_response')
							redirect_to aoc_verify_pin_path
						else
							logger.debug "Response for paymentConsent, off network : #{@result.inspect}"
							if @result && @result['redirect_url'] &&  !@result['redirect_url'].to_s.blank?
								if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
									@redirect_url =  @result['redirect_url'].to_s
								else
									@redirect_url =  "http://"+ @result['redirect_url'].to_s
								end
								url = DEFAULT_CONFIG['payment']['payment_details']
								xml_data="<?xml version='1.0' encoding='UTF-8'?><getPaymentDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP></getPaymentDetails>"
								xml_request_to_be_sent(url, xml_data)	
								dev_and_app_name
								#~ @organization = @result['organization'].to_s
								charge =  CGI::unescape(@result['chargeDetails'].to_s)
								charge = XmlSimple.xml_in(charge)
								currency = charge['currency'] && !charge['currency'].nil? ? charge['currency'] : charge['Currency']
								amount = charge['amount'] && !charge['amount'].nil? ? charge['amount'] : charge['Amount']
								@charge = "#{currency}  #{amount}"
								@wireless = @result['userDetails'][0]['msisdn'].to_s
								@organization = charge['description'][0] if charge['description']
								if charge['SubscriptionRecurringPeriod'] || charge['subscriptionRecurringPeriod']
									@period = charge['SubscriptionRecurringPeriod'][0]  if charge['SubscriptionRecurringPeriod']
									@period = charge['subscriptionRecurringPeriod'][0]  if charge['subscriptionRecurringPeriod']
								end
								session[:mc_authenticated] = true
								render 'aoc_thank_you'
							else
								flash[:net_error] = t('failure_response')
								redirect_to aoc_verify_pin_path
							end
						end
					end
				else
					flash[:net_error] = @result['details'].to_s
					redirect_to aoc_verify_pin_path
				end
			end
		else
			flash[:net_error] = "Please enter the Pin"
			redirect_to aoc_verify_pin_path
		end
	end
	def aoc_resend_pin
		url = DEFAULT_CONFIG['login']['resend_pin']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><resendPin><sessionId>#{cookies[:sessionId]}</sessionId></resendPin>"
		xml_request_to_be_sent(url, xml_data)		
		if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500") || (!@result))
			logger.info "Expected success response was not returned back for the resendPin API call\n\n"
			logger.debug "REQUEST SENT resendPin API:- #{xml_data}\n\n"
			if @error_response
				logger.debug "RESPONSE RECEIVED back for resendPin API :- #{@error_response.inspect}"
			else
				logger.debug "RESPONSE RECEIVED back for resendPin API :- #{@result.inspect}" if @result
			end
			flash[:net_error] = t('failure_response')
			redirect_to aoc_verify_pin_path
		else
			if @result['status'].to_s == "success"
				flash[:net_success] = @result['details'].to_s
			else
				flash[:net_error] = @result['details'].to_s
			end
		end
		redirect_to aoc_verify_pin_path
	end
	def off_net_aoc_consent_wireless
		flash[:app_name] = params[:login][:app_name]
		flash[:dev_name] = params[:login][:dev_name]
		flash[:app_scope] = params[:login][:app_scope]
		flash[:organization] = params[:login][:organization]
		flash[:charge] = params[:login][:charge]
		if params[:login][:wireless] && !params[:login][:wireless].blank?
			url = DEFAULT_CONFIG['login']['send_pin']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><sendPin><sessionId>#{cookies[:sessionId]}</sessionId><msisdn>#{params[:login][:wireless]}</msisdn></sendPin>"
			xml_request_to_be_sent(url, xml_data)		
			if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500") || (!@result))
				logger.info "Expected success response was not returned back for the sendPin API call\n\n"
				logger.debug "REQUEST SENT sendPin API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for sendPin API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for sendPin API :- #{@result.inspect}" if @result
				end
				flash[:net_error] = t('failure_response')
				redirect_to payments_path
			else
				if @result['status'].to_s == "success"
					flash[:net_error] = nil
					redirect_to aoc_verify_pin_path
				else
					flash[:net_error] = @result['details'].to_s
					redirect_to payments_path
				end
			end
		else
			flash[:net_error] = "Please enter the wireless number"
			redirect_to payments_path
		end
	end
	def on_net_aoc_consent_wireless
		url = DEFAULT_CONFIG['payment']['payment_consent']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><issuePaymentConsent><sessionId>#{cookies[:sessionId]}</sessionId></issuePaymentConsent>"
		xml_request_to_be_sent(url, xml_data)
		logger.debug "Response for paymentConsent, on network : #{@result.inspect}"
		#~ @result = "<issuePaymentConsentResponse><redirect_url>http://www.google.com</redirect_url></issuePaymentConsentResponse>"
		#~ @result=XmlSimple.xml_in(@result)
		if @location && !@location.blank?
			render :update do |page|
					page.redirect_to @location
				end
		else
			if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500") || (!@result))
				logger.info "Expected success response was not returned back for the issuePaymentConsent API call\n\n"
				logger.debug "REQUEST SENT issuePaymentConsent API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for issuePaymentConsent API :- #{@error_response.inspect}" if @error_response
				else
					logger.debug "RESPONSE RECEIVED back for issuePaymentConsent API :- #{@result.inspect}" if @result
				end
				flash[:net_error] = t('failure_response')
				render :update do |page|
						page.redirect_to payments_path
				end
			else
				if @result && @result['redirect_url'] &&  !@result['redirect_url'].to_s.blank?
					if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
						@redirect_url =  @result['redirect_url'].to_s
					else
						@redirect_url =  "http://"+ @result['redirect_url'].to_s
					end
					url = DEFAULT_CONFIG['payment']['payment_details']
					xml_data="<?xml version='1.0' encoding='UTF-8'?><getPaymentDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP></getPaymentDetails>"
					xml_request_to_be_sent(url, xml_data)	
					if @result && @result['chargeDetails']
						dev_and_app_name
						#~ @organization = @result['organization'].to_s
						charge =  CGI::unescape(@result['chargeDetails'].to_s)
						charge = XmlSimple.xml_in(charge)
						currency = charge['currency'] && !charge['currency'].nil? ? charge['currency'] : charge['Currency']
						amount = charge['amount'] && !charge['amount'].nil? ? charge['amount'] : charge['Amount']
						@charge = "#{currency}  #{amount}"
						@wireless = @result['userDetails'][0]['msisdn'].to_s
						@organization = charge['description'][0] if charge['description']
						if charge['SubscriptionRecurringPeriod'] || charge['subscriptionRecurringPeriod']
							@period = charge['SubscriptionRecurringPeriod'][0]  if charge['SubscriptionRecurringPeriod']
							@period = charge['subscriptionRecurringPeriod'][0]  if charge['subscriptionRecurringPeriod']
						end
						session[:mc_authenticated] = true
						render :update do |page|
							page.replace_html 'on_net_aoc_verify_thankyou', :partial => 'aoc_thank_you'
						end
					else
						render :update do |page|
							page.redirect_to payments_path
						end
					end
				else
					flash[:net_error] = t('failure_response')
					render :update do |page|
						page.redirect_to payments_path
					end
				end
			end
		end
	end
	
	def deny_pin
		url = DEFAULT_CONFIG['payment']['cancel_payment']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><cancelPayment><sessionId>#{cookies[:sessionId]}</sessionId></cancelPayment>"
		xml_request_to_be_sent(url, xml_data)
		if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500") || (!@result))
			logger.info "Expected success response was not returned back for the cancelAuthorize payment API call\n\n"
			logger.debug "REQUEST SENT cancelAuthorize API:- #{xml_data}\n\n"
			if @error_response
				logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@error_response.inspect}"
			else
				logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@result.inspect}" if @result
			end
			flash[:net_error] = t('failure_response')
			redirect_to payments_path
		else
			redirect_to = @result['redirect_url'].to_s
			redirect_to = URI.unescape(redirect_to)
			if @result && @result['redirect_url']
				if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
					redirect_to redirect_to.to_s, :status => 302
				else
					redirect_to "http://"+redirect_to.to_s, :status => 302
				end
			else
				flash[:net_error] = t('failure_response')
				redirect_to payments_path
			end
		end
	end 
	def aoc_verify_onpin
		render :update do |page|
			page.replace_html 'on_net_aoc_verify_thankyou', :partial => 'aoc_verify_onpin'
		end
	end
	def on_net_consent_wireless
	end
	def login_manage
		terms_and_conditions
	end
		def login_create
		flash[:error]=nil
		username = params[:login][:username]
		password = params[:login][:password]
		if !username.blank? && !password.blank?
			if params[:login][:redirect_url] == "Manage Consent"
				url = DEFAULT_CONFIG['application']['manage_consent']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><login><sessionId>#{cookies[:sessionId]}</sessionId><userId>#{username}</userId><password>#{password}</password></login>"
				xml_request_to_be_sent(url, xml_data)
				if @result && !@result['userId'].to_s.blank?
					redirect_to manage_consent_path
				else
					error_message('login', nil, 'error', 'login_call')
					redirect_to payment_login_path(:login => "true")		
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
						redirect_to payment_login_path(:login => "true")		
					elsif @response_code != "200"
						if @response_code == "206" ||  @response_code == "240"
							redirect_to change_password_path
						else
							error_message('login', @response_code, 'error', nil)
							redirect_to payment_login_path(:login => "true")		
						end
					elsif @response_code == "200" && !@user_id.to_s.blank? # && !@result['developerAppDetails'][0]['name'].to_s.blank? && !@result['developerAppDetails'][0]['appname'].to_s.blank?
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
						redirect_to payment_login_path(:login => "true")		
					end
				else
          if (@result && @result['statusCode']) && ((!@result['userDetails']) || (@result['userDetails'] && !@result['userDetails'][0]['userProfile']))
            error_message('login', @result['statusCode'], 'error', 'login_call')
          else
            flash[:error] = t('failure_response')            
          end
					redirect_to payment_login_path(:login => "true")		
				end
			end
		else
			error_message('login', nil, 'error', 'missing_pwd') if password.blank?
			error_message('login', nil, 'error', 'missing_username') if username.blank?
			redirect_to payment_login_path(:login => "true")		
		end
	end
	def consent_app
				url = DEFAULT_CONFIG['payment']['payment_consent']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><issuePaymentConsent><sessionId>#{cookies[:sessionId]}</sessionId></issuePaymentConsent>"
			xml_request_to_be_sent(url, xml_data)
			if @location && !@location.blank?
				redirect_to @location
			else
				if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500") || (!@result))
					logger.info "Expected success response was not returned back for the issuePaymentConsent payment API call\n\n"
					logger.debug "REQUEST SENT issuePaymentConsent API:- #{xml_data}\n\n"
					if @error_response
						logger.debug "RESPONSE RECEIVED back for issuePaymentConsent API :- #{@error_response.inspect}"
					else
						logger.debug "RESPONSE RECEIVED back for issuePaymentConsent API :- #{@result.inspect}" if @result
					end
					flash[:error] = t('failure_response')
					redirect_to payment_login_path(:login => "true")	
				else
					if @result && @result['redirect_url'] &&  !@result['redirect_url'].to_s.blank?
						if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
							@redirect_url =  @result['redirect_url'].to_s
						else
							@redirect_url =  "http://"+ @result['redirect_url'].to_s
						end
						url = DEFAULT_CONFIG['payment']['payment_details']
						xml_data="<?xml version='1.0' encoding='UTF-8'?><getPaymentDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP></getPaymentDetails>"
						xml_request_to_be_sent(url, xml_data)	
						dev_and_app_name
						#~ @organization = @result['organization'].to_s
						charge =  CGI::unescape(@result['chargeDetails'].to_s)
						charge = XmlSimple.xml_in(charge)
						currency = charge['currency'] && !charge['currency'].nil? ? charge['currency'] : charge['Currency']
						amount = charge['amount'] && !charge['amount'].nil? ? charge['amount'] : charge['Amount']
						@charge = "#{currency}  #{amount}"
						@organization = charge['description'][0] if charge['description']
						if charge['SubscriptionRecurringPeriod'] || charge['subscriptionRecurringPeriod']
							@period = charge['SubscriptionRecurringPeriod'][0]  if charge['SubscriptionRecurringPeriod']
							@period = charge['subscriptionRecurringPeriod'][0]  if charge['subscriptionRecurringPeriod']
						end
						#~ render 'aoc_thank_you'
						session[:mc_authenticated] = true
						render 'login_thank_you'
					else
							flash[:error] = t('failure_response')    
							redirect_to payment_login_path(:login => "true")		
					end					
				end
			end
	end
	def decline_app
		url = DEFAULT_CONFIG['payment']['cancel_payment']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><cancelPayment><sessionId>#{cookies[:sessionId]}</sessionId></cancelPayment>"
		xml_request_to_be_sent(url, xml_data)
		if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500") || (!@result))
			logger.info "Expected success response was not returned back for the cancelAuthorize payment API call\n\n"
			logger.debug "REQUEST SENT cancelAuthorize API:- #{xml_data}\n\n"
			if @error_response
				logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@error_response.inspect}" 
			else
				logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@result.inspect}" if @result
			end
			flash[:net_error] = t('failure_response')
			redirect_to payment_login_path(:login => "true")	
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
				redirect_to payment_login_path(:login => "true")		
			end
		end
	end
	def login_thank_you
	end
	def terms_and_conditions
		url = DEFAULT_CONFIG['login']['get_terms_and_conditions']
		request_to_be_sent(url)
     if @tc_result && @tc_result['tc'] && @tc_result['responseStatus'] && @tc_result['responseStatus'][0]['statusCode'].to_s == "200"
			@tc_id = @tc_result['tc'][0]['tcId'].to_s
			@tc_content = @tc_result['tc'][0]['tcContent'].to_s 
			@tc_status = @tc_result['responseStatus'][0]['statusCode'].to_s 			
		#~ else
			#~ flash[:error] = t('failure_response')
		end
	end
	def off_net_aoc_from_on_net_aoc
		url = DEFAULT_CONFIG['payment']['payment_details']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><getPaymentDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP></getPaymentDetails>"
			xml_request_to_be_sent(url, xml_data)	
			if ((@response_failed == true) || (@result && !@result['chargeDetails']) || (@res_code == "404") || (@res_code == "500") || (!@result))
				logger.info "Expected success response was not returned back for the onNetworkAuth payment API call\n\n"
				logger.debug "REQUEST SENT onNetworkAuth API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@result.inspect}" if @result
				end				
			else
				dev_and_app_name
				#~ @organization = @result['organization'].to_s
				charge =  CGI::unescape(@result['chargeDetails'].to_s)
				charge = XmlSimple.xml_in(charge)
				currency = charge['currency'] && !charge['currency'].nil? ? charge['currency'] : charge['Currency']
				amount = charge['amount'] && !charge['amount'].nil? ? charge['amount'] : charge['Amount']
				@charge = "#{currency}  #{amount}"
				@organization = charge['description'][0] if charge['description']
			end
	end
	end