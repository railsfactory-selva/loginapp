class ManageConsentController < ApplicationController
	layout 'application'
	before_filter :check_for_logged_in, :only => ['applications', 'consent_application', 'revoke_application']
	before_filter :empty_flash
	before_filter :require_ssl, :except => [:http_on_net_manageconsent]
	def manage_consent_home		
		if (session[:mc_authenticated] && session[:mc_authenticated] = true) && (!params[:bookmark])
			redirect_to manage_consent_path
		else
		cookies[:sessionId] = nil
		url = DEFAULT_CONFIG['login']['session_details_mc']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId></clientId><scope></scope><transactionId></transactionId><redirectUrl></redirectUrl></getSessionDetails>"
		xml_request_to_be_sent(url, xml_data)			
		if ((@response_failed == true) || (@result && !@result['userDetails']) || (@res_code == "404") || (@res_code == "500"))
			if @result && @result['details']
				flash[:mc_off_error] = @result['details'][0].to_s
				render 'manage_consent_home'
				flash[:mc_off_error] = nil
			else
				logger.info "Expected success response was not returned back for the getSessionDetails API call\n\n"
				logger.debug "REQUEST SENT getSessionDetails API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for getSessionDetails API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for getSessionDetails API :- #{@result.inspect}" if @result
				end
			end
		else
			@user_id = @result['userId'].to_s
			@authorization = @result['isAuthorizationRequired'].to_s
			network = @result['onNetworkAuthentication'].to_s
			cookies[:sessionId] = {:value => @result['newCookie'].to_s, :http_only => true } if !@result['newCookie'].to_s.blank?
			logger.info "OnNet whitelist check IP = #{request.remote_ip}, allowed = #{network}"
			if network == "true"						
				flash[:mc_on_net_error] = flash[:mc_on_error]  
				if params[:android] && params[:android] == "true"
					redirect_to "http://#{DEFAULT_CONFIG['login_app_url']}:#{DEFAULT_CONFIG['login_app_port']}/user/manageconsent/http_on_net_manageconsent?bookmark=true&android=true", :status => 302
				elsif params[:bookmark] && params[:bookmark] == "true"
					redirect_to "http://#{DEFAULT_CONFIG['login_app_url']}:#{DEFAULT_CONFIG['login_app_port']}/user/manageconsent/http_on_net_manageconsent?bookmark=true", :status => 302
				else
					redirect_to "http://#{DEFAULT_CONFIG['login_app_url']}:#{DEFAULT_CONFIG['login_app_port']}/user/manageconsent/http_on_net_manageconsent", :status => 302
				end
			else
				render 'manage_consent_home'
			end
		end
		end
	end
	
	def http_on_net_manageconsent
		flash[:x_up_subno] = request.headers['HTTP_X_UP_SUBNO']
		flash[:client_ip] = request.remote_ip
		flash[:mc_on_error] = flash[:mc_on_net_error]  
		if params[:android] && params[:android] == "true"
			redirect_to "https://#{DEFAULT_CONFIG['login_app_url']}/user/manageconsent/on_network?bookmark=true&android=true"
		elsif params[:bookmark] && params[:bookmark] == "true"
			redirect_to "https://#{DEFAULT_CONFIG['login_app_url']}/user/manageconsent/on_network?bookmark=true"
		else
			redirect_to "https://#{DEFAULT_CONFIG['login_app_url']}/user/manageconsent/on_network"
		end
	end
	
	def on_network
		header = flash[:x_up_subno]
		if header && !header.blank?
			header_length = header.length
			if header_length && header_length > 4
				sliced_header = header.slice(header_length - 4, header_length)
				first_string ='*' * (header_length-4)
				header  = first_string + sliced_header
			end
			logger.info "OnNet Header IP = #{flash[:client_ip]}, X-Up-Subno = #{header}"
			url = DEFAULT_CONFIG['login']['on_network_auth_mc']
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
				render 'manage_consent_home'
			else
				if @result && @result['userDetails']  && @result['userDetails'][0]['userId']
					@user_id = @result['userDetails'][0]['userId'].to_s
					if  !@user_id.blank?
						if params[:bookmark]
					  	render 'manage_consent_home'
						else
							redirect_to manage_consent_path
						end
					else
						#~ call_off_net_from_on_net_mc
						render 'manage_consent_home'
					end
				else
					logger.info "Expected success response was not returned back for the onNetworkAuth API call\n\n"
					logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@result.inspect}" if @result
					logger.debug "RESPONSE RECEIVED back for onNetworkAuth API :- #{@error_response.inspect}" if @error_response
					#~ call_off_net_from_on_net_mc
					render 'manage_consent_home'
				end
			end
		else
			logger.error "OnNet Header IP = #{flash[:client_ip]}, X-Up-Subno header not received"
			#~ call_off_net_from_on_net_mc
			render 'manage_consent_home'
		end
	end
	
	def mc_verify_onpin
		render :update do |page|
			page.replace_html 'mc_on_net_verify_thankyou', :partial => 'mc_verify_onpin'
		end
	end
	
	def on_net_manage_consent
		render :update do |page|
			page.redirect_to manage_consent_path
		end
	end
		
	def off_net_mc_verify_pin		
		if params[:manage_consent] && params[:manage_consent][:wireless] && !params[:manage_consent][:wireless].blank?
			url = DEFAULT_CONFIG['login']['send_pin']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><sendPin><sessionId>#{cookies[:sessionId]}</sessionId><msisdn>#{params[:manage_consent][:wireless]}</msisdn></sendPin>"
			xml_request_to_be_sent(url, xml_data)		
			if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500"))
				logger.debug "REQUEST SENT sendPin API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for sendPin API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for sendPin API :- #{@result.inspect}" if @result
				end
				flash[:mc_off_error] = t('failure_response')
				redirect_to manage_consent_home_path
			else
				if @result['status'].to_s == "success"
					flash[:mc_off_error] = nil
					render 'off_net_mc_verify_pin'
				else
					flash[:mc_off_error] = @result['details'].to_s
					redirect_to manage_consent_home_path
				end
			end
		else
			flash[:mc_off_error] = "Please enter the wireless number"
			redirect_to manage_consent_home_path
		end
	end
	
	def mc_off_net_validate_pin	
		flash[:mc_net_success] = nil
		flash[:mc_off_error] = nil
		if params[:manage_consent] && params[:manage_consent][:phone] && !params[:manage_consent][:phone].blank?
			url = DEFAULT_CONFIG['login']['validate_pin']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><validatePin><sessionId>#{cookies[:sessionId]}</sessionId><pin>#{params[:manage_consent][:phone]}</pin></validatePin>"
			xml_request_to_be_sent(url, xml_data)		
			if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500"))
				logger.info "Expected success response was not returned back for the validatePin API call\n\n"
				logger.debug "REQUEST SENT validatePin API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for validatePin API in off network flow:- #{@error_response.inspect}" 
				else
					logger.debug "RESPONSE RECEIVED back for validatePin API in off network flow :- #{@result.inspect}" if @result
				end
				flash[:mc_off_error] = t('failure_response')
				render 'off_net_mc_verify_pin'
			else
				if @result['status'].to_s == "success"
					redirect_to manage_consent_path
				else
					flash[:mc_off_error] = @result['details'].to_s
					render 'off_net_mc_verify_pin'
				end
			end
		else
			flash[:mc_off_error] = "Please enter the Pin"
			render 'off_net_mc_verify_pin'
		end
	end
	
	def mc_resend_pin
		flash[:mc_net_success] = nil
		flash[:mc_off_error] = nil
		url = DEFAULT_CONFIG['login']['resend_pin']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><resendPin><sessionId>#{cookies[:sessionId]}</sessionId></resendPin>"
		xml_request_to_be_sent(url, xml_data)		
		if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500"))
			logger.info "Expected success response was not returned back for the resendPin API call\n\n"
			logger.debug "REQUEST SENT resendPin API:- #{xml_data}\n\n"
			if @error_response
				logger.debug "RESPONSE RECEIVED back for resendPin API in off network flow:- #{@error_response.inspect}" 
			else
				logger.debug "RESPONSE RECEIVED back for resendPin API in off network flow :- #{@result.inspect}" if @result
			end
			flash[:mc_off_error] = t('failure_response')				
		else
			if @result['status'].to_s == "success"
				flash[:mc_off_error] = nil
				flash[:mc_net_success] = @result['details'].to_s
			else
				flash[:mc_off_error] = @result['details'].to_s
			end
		end
		render 'off_net_mc_verify_pin'
	end

	def manage_consent 
	end
	
	def applications
		url = DEFAULT_CONFIG['application']['applications']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><listAuthorize><sessionId>#{cookies[:sessionId]}</sessionId></listAuthorize>"
		xml_request_to_be_sent(url, xml_data)
		@app_names = []
		@descriptions = []
		@dev_names = []
		@scopes = []
		if @result['apps'] && @result['apps'][0] && !@result['apps'][0].blank?
			@apps = @result['apps'][0]['app']
			@apps.each do |apps|
				@app_names << apps['name']
				@descriptions << apps['description']
				@scopes << apps['scope']
				client_id = apps['clientId'].to_s
				url = DEFAULT_CONFIG['kms']['key_validate']
				url = url + "?key=#{client_id}"
				request_to_be_sent_to_kms(url)
				if @kms_result && !@kms_result['error']
					login_id = @kms_result['loginid'][0]
					developer_name = @kms_result['developer_name'][0].split(',')[0]
					login_id = URI.escape(login_id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
					developer_name = URI.escape(developer_name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
					if login_id && !login_id.blank?
						url = DEFAULT_CONFIG['kms']['developer_name']
						url = url + "?consumerid=#{login_id}"
						request_to_be_sent_get_kms(url)
						if @kms_result && !@kms_result['error']
							org_name = @kms_result['c_attribute1'][0] if @kms_result && !@kms_result['error'] && !@kms_result['c_attribute1'][0].blank?
							if org_name
								name = org_name
							else
								name = developer_name
							end
						else
							name = login_id
						end
					else
						name = login_id
					end
					@dev_names << name
				end
			end
		end
	end
	def consent_application
		url = DEFAULT_CONFIG['application']['single_application']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><listAuthorize><sessionId>#{cookies[:sessionId]}</sessionId><applicationid>#{params[:consent][:application_name]}</applicationid></listAuthorize>"
		xml_request_to_be_sent(url, xml_data)
		@application_name = @result['apps'][0]['app'][0]['name'].to_s
		@application_scope = @result['apps'][0]['app'][0]['scope'].to_s.split(',')
		@application_desc = @result['apps'][0]['app'][0]['description'].to_s
		@application_status = @result['apps'][0]['app'][0]['status'].to_s
		client_id = @result['apps'][0]['app'][0]['clientId'].to_s
		url = DEFAULT_CONFIG['kms']['key_validate']
		url = url + "?key=#{client_id}"
		request_to_be_sent_to_kms(url)
		if @kms_result && !@kms_result['error']
			login_id = @kms_result['loginid'][0]
			developer_name = @kms_result['developer_name'][0].split(',')[0]
			login_id = URI.escape(login_id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
			developer_name = URI.escape(developer_name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
			if login_id && !login_id.blank?
				url = DEFAULT_CONFIG['kms']['developer_name']
				url = url + "?consumerid=#{login_id}"
				request_to_be_sent_get_kms(url)
				if @kms_result && !@kms_result['error']
					org_name = @kms_result['c_attribute1'][0] if @kms_result && !@kms_result['error'] && !@kms_result['c_attribute1'][0].blank?
					if org_name
						name = org_name
					else
						name = developer_name
					end
				else
					name = login_id
				end
				@developer_name = name
			else
				@developer_name = login_id
			end
		end
	end
	def revoke_application
		url = DEFAULT_CONFIG['application']['revoke_consent']
		xml_data="<?xml version='1.0' encoding='UTF-8'?><revokeAuthorize><sessionId>#{cookies[:sessionId]}</sessionId><applicationid>#{params[:consent][:application_name]}</applicationid></revokeAuthorize>"
		xml_request_to_be_sent(url, xml_data)
		if @result['revoked'].to_s == "true"
			redirect_to applications_path
		else
			#~ @application_name = params[:consent][:application_name]
			#~ @application_scope = params[:consent][:application_scope].split(',')
			#~ render :action => 'consent_application'
		end
	end			
end
