class OnOffNetworkController < ApplicationController
layout 'application'
before_filter :require_ssl
		def off_net_consent_wireless
			flash[:app_name] = params[:login][:app_name]
			flash[:dev_name] = params[:login][:dev_name]
			flash[:app_scope] = params[:login][:app_scope]
			if params[:login][:wireless] && !params[:login][:wireless].blank?
				url = DEFAULT_CONFIG['login']['send_pin']
	      xml_data="<?xml version='1.0' encoding='UTF-8'?><sendPin><sessionId>#{cookies[:sessionId]}</sessionId><msisdn>#{params[:login][:wireless]}</msisdn></sendPin>"
				xml_request_to_be_sent(url, xml_data)		
				if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500"))
					logger.debug "REQUEST SENT sendPin API:- #{xml_data}\n\n"
					if @error_response
						logger.debug "RESPONSE RECEIVED back for sendPin API :- #{@error_response.inspect}"
					else
						logger.debug "RESPONSE RECEIVED back for sendPin API :- #{@result.inspect}" if @result
					end
					flash[:net_error] = t('failure_response')
					redirect_to login_path(:client_id => params[:login][:client_id], :scope => params[:login][:scope], :id => params[:login][:id], :redirect_url => session[:redirect_url])
				else
					if @result['status'].to_s == "success"
						flash[:net_error] = nil
						redirect_to verify_pin_path(:client_id => params[:login][:client_id], :scope => params[:login][:scope], :redirect_url => session[:redirect_url])
					else
						flash[:net_error] = @result['details'].to_s
						redirect_to login_path(:client_id => params[:login][:client_id], :scope => params[:login][:scope], :id => params[:login][:id], :redirect_url => session[:redirect_url])
					end
				end
				else
					flash[:net_error] = "Please enter the wireless number"
					redirect_to login_path(:client_id => params[:login][:client_id], :scope => params[:login][:scope], :id => params[:login][:id], :redirect_url => session[:redirect_url])
				end
		end
		def deny_pin
			url = DEFAULT_CONFIG['application']['cancel_consent']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><cancelAuthorize><sessionId>#{cookies[:sessionId]}</sessionId></cancelAuthorize>"
			xml_request_to_be_sent(url, xml_data)
			if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500"))
				logger.debug "REQUEST SENT cancelAuthorize API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@error_response.inspect}"
				else
					logger.debug "RESPONSE RECEIVED back for cancelAuthorize API :- #{@result.inspect}" if @result
				end
				flash[:net_error] = t('failure_response')
				redirect_to login_path(:client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
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
					redirect_to login_path
				end
			end
		end
		def verify_pin
			@client_id = params[:client_id]
			@display_scope = params[:scope]
		end
		def verify_onpin
			render :update do |page|
				page.replace_html 'on_net_verify_thankyou', :partial => 'verify_onpin'
			end
		end
		
		def off_net_validate_pin
			if params[:login][:phone] && !params[:login][:phone].blank?
				url = DEFAULT_CONFIG['login']['validate_pin']
				xml_data="<?xml version='1.0' encoding='UTF-8'?><validatePin><sessionId>#{cookies[:sessionId]}</sessionId><pin>#{params[:login][:phone]}</pin></validatePin>"
				xml_request_to_be_sent(url, xml_data)		
				if ((@response_failed == true) || (@result && !@result['status']) || (@res_code == "404") || (@res_code == "500"))
					logger.info "Expected success response was not returned back for the validatePin API call\n\n"
					logger.debug "REQUEST SENT validatePin API:- #{xml_data}\n\n"
					if @error_response
						logger.debug "RESPONSE RECEIVED back for validatePin API in off network flow:- #{@error_response.inspect}" 
					else
						logger.debug "RESPONSE RECEIVED back for validatePin API in off network flow :- #{@result.inspect}" if @result
					end
					flash[:net_error] = t('failure_response')
					redirect_to verify_pin_path
				else
					if @result && @result['status'].to_s == "success"
						url = DEFAULT_CONFIG['application']['issue_consent']
						xml_data="<?xml version='1.0' encoding='UTF-8'?><issueConsent><sessionId>#{cookies[:sessionId]}</sessionId></issueConsent>"
						xml_request_to_be_sent(url, xml_data)
						if ((@response_failed == true) || (@result && !@result['authcode']) || (@res_code == "404") || (@res_code == "500"))
							logger.info "Expected success response was not returned back for the issueConsent API call\n\n"
							logger.debug "REQUEST SENT validatePin API:- #{xml_data}\n\n"
							if @error_response
								logger.debug "RESPONSE RECEIVED back for issueConsent API in off network flow:- #{@error_response.inspect}" 
							else
								logger.debug "RESPONSE RECEIVED back for issueConsent API in off network flow :- #{@result.inspect}" if @result
							end
							flash[:net_error] = t('failure_response')
							redirect_to verify_pin_path
						else
							if @result && @result['authcode']
								auth_code = @result['authcode'].to_s
								scope = @result['scope'].to_s
								guid = @result['guid'].to_s
								clientId = @result['clientId'].to_s
								redirect_url = @result['redirectUrl'].to_s
								url = DEFAULT_CONFIG['application']['redirect_url']
								xml_data="<?xml version='1.0' encoding='UTF-8'?><createAuthorize><sessionId>#{cookies[:sessionId]}</sessionId><authcode>#{auth_code}</authcode><scope>#{scope}</scope><clientId>#{clientId}</clientId><guid>#{guid}</guid> <redirectUrl><![CDATA[#{redirect_url}]]></redirectUrl></createAuthorize>"
								xml_request_to_be_sent(url, xml_data)
								if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500"))
									logger.info "Expected success response was not returned back for the redirectUrl API call\n\n"
									logger.debug "REQUEST SENT redirectUrl API:- #{xml_data}\n\n"
									if @error_response
										logger.debug "RESPONSE RECEIVED back for redirectUrl API in off network flow:- #{@error_response.inspect}"
									else
										logger.debug "RESPONSE RECEIVED back for redirectUrl API in off network flow :- #{@result.inspect}" if @result
									end
									flash[:net_error] = t('failure_response')
									redirect_to verify_pin_path
								else
									if @result && @result['redirect_url']
										if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
											@redirect_url =  @result['redirect_url'].to_s
										else
											@redirect_url =  "http://"+ @result['redirect_url'].to_s
										end
									else
										flash[:net_error] = @result['details'].to_s
										redirect_to verify_pin_path
									end
									url = DEFAULT_CONFIG['login']['session_details']
									xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId>#{clientId}</clientId><scope>#{scope}</scope><transactionId></transactionId><redirectUrl></redirectUrl></getSessionDetails>"
									xml_request_to_be_sent(url, xml_data)	
									if ((@response_failed == true) || (@result && !@result['userDetails']) || (@res_code == "404") || (@res_code == "500"))
										logger.error "Expected success response was not returned back for the getSessionDetails API call\n\n"
										logger.error "REQUEST SENT validatePin API:- #{xml_data}\n\n"
										if @error_response
											logger.error "RESPONSE RECEIVED back for getSessionDetails API after pin validation in off network flow:- #{@error_response.inspect}" 
										else
											logger.error "RESPONSE RECEIVED back for getSessionDetails API after pin validation in off network flow :- #{@result.inspect}" if @result
										end
										flash[:net_error] = t('failure_response')
										redirect_to verify_pin_path
									else
										dev_and_app_name
										@wireless = @result['userDetails'][0]['msisdn'].to_s
										display_scope_title
										session[:mc_authenticated] = true
										render 'thank_you'
									end
								end
							else
								flash[:net_error] = t('failure_response')
								redirect_to verify_pin_path
							end
						end
					else
						flash[:net_error] = @result['details'].to_s
						redirect_to verify_pin_path
					end
				end
			else
				flash[:net_error] = "Please enter the Pin"
				redirect_to verify_pin_path
			end
		end
		def resend_pin
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
				flash[:net_error] = t('failure_response')				
			else
				if @result['status'].to_s == "success"
					flash[:net_error] = nil
					flash[:net_success] = @result['details'].to_s
				else
					flash[:net_error] = @result['details'].to_s
				end
			end
			redirect_to verify_pin_path
		end
		def thank_you
	
		end
		def on_net_consent_wireless
			flash[:app_name] = params[:app_name]
			flash[:dev_name] = params[:dev_name]
			flash[:app_scope] = params[:app_scope]
			url = DEFAULT_CONFIG['application']['issue_consent']
			xml_data="<?xml version='1.0' encoding='UTF-8'?><issueConsent><sessionId>#{cookies[:sessionId]}</sessionId></issueConsent>"
			xml_request_to_be_sent(url, xml_data)
			if ((@response_failed == true) || (@result && !@result['authcode']) || (@res_code == "404") || (@res_code == "500"))
				logger.info "Expected success response was not returned back for the issueConsent API call\n\n"
				logger.debug "REQUEST SENT issueConsent API:- #{xml_data}\n\n"
				if @error_response
					logger.debug "RESPONSE RECEIVED back for issueConsent API in on network flow:- #{@error_response.inspect}" if @error_response
				else
					logger.debug "RESPONSE RECEIVED back for issueConsent API in on network flow :- #{@result.inspect}" if @result
				end
				flash[:net_error] = t('failure_response')				
				render :update do |page|
					page.redirect_to login_path(:client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
				end
			else
				if @result && @result['authcode']
					auth_code = @result['authcode'].to_s
					scope = @result['scope'].to_s
					guid = @result['guid'].to_s
					clientId = @result['clientId'].to_s
					redirect_url = @result['redirectUrl'].to_s
					url = DEFAULT_CONFIG['application']['redirect_url']
					xml_data="<?xml version='1.0' encoding='UTF-8'?><createAuthorize><sessionId>#{cookies[:sessionId]}</sessionId><authcode>#{auth_code}</authcode><scope>#{scope}</scope><clientId>#{clientId}</clientId><guid>#{guid}</guid> <redirectUrl><![CDATA[#{redirect_url}]]></redirectUrl></createAuthorize>"
					xml_request_to_be_sent(url, xml_data)
					if ((@response_failed == true) || (@result && !@result['redirect_url']) || (@res_code == "404") || (@res_code == "500"))
						logger.info "Expected success response was not returned back for the createAuthorize API call\n\n"
						logger.debug "REQUEST SENT createAuthorize API:- #{xml_data}\n\n"
						if @error_response
							logger.debug "RESPONSE RECEIVED back for createAuthorize API in on network flow:- #{@error_response.inspect}"
						else
							logger.debug "RESPONSE RECEIVED back for createAuthorize API in on network flow :- #{@result.inspect}" if @result
						end
						flash[:net_error] = t('failure_response')				
						render :update do |page|
							page.redirect_to login_path(:client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
						end
					else
						if @result && @result['redirect_url']
							if @result['redirect_url'].to_s.include?("https") || @result['redirect_url'].to_s.include?("http")
								@redirect_url =  @result['redirect_url'].to_s
							else
								@redirect_url =  "http://"+ @result['redirect_url'].to_s
							end
							url = DEFAULT_CONFIG['login']['session_details']
							xml_data="<?xml version='1.0' encoding='UTF-8'?><getSessionDetails><sessionId>#{cookies[:sessionId]}</sessionId><clientIP>#{request.remote_ip}</clientIP><clientId>#{clientId}</clientId><scope>#{scope}</scope><transactionId></transactionId><redirectUrl></redirectUrl></getSessionDetails>"
							xml_request_to_be_sent(url, xml_data)	
							dev_and_app_name
							if @result && @result['userDetails']
								@wireless = @result['userDetails'][0]['msisdn'].to_s
								display_scope_title
								session[:mc_authenticated] = true
								render :update do |page|
									page.replace_html 'on_net_verify_thankyou', :partial => 'thank_you'
								end
							else
								flash[:net_error] = t('failure_response')				
								render :update do |page|
									page.redirect_to login_path(:client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
								end
							end
						else
							render :update do |page|
								page.redirect_to login_path(:client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
							end
						end
					end
				else
					render :update do |page|
						page.redirect_to login_path(:client_id => session[:client_id], :scope => session[:scope], :redirect_url => session[:redirect_url])
					end
				end
			end
		end
end
