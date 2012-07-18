# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :input_filter
  # Scrub sensitive parameters from your log
	filter_parameter_logging :password, :confirm_password, :phone, :tccontent, :content_year, :content_month, :content_day
	def input_filter
		params.each do |key,value|
     # if it's a hash, we need to check each value inside it...
      if value.is_a?(Hash)
       value.each do |hash_key,hash_value|
           params[key][hash_key] = Sanitize.clean(hash_value)
       end
       params[key].symbolize_keys!
      elsif value.is_a?(String) || value.is_a?(Integer)
       params[key] = Sanitize.clean(value)
      end
    end
    params.symbolize_keys!
  end
  def require_ssl
		@browser_used = users_browser
		logger.info "User agent : #{@browser_used}"
    logger.info "SSL enabled : #{request.ssl?}"
    if request.headers['x-forwarded-proto']
      redirect_to "https://#{request.headers['SERVER_NAME']}#{request.headers['REQUEST_URI']}" unless (request.ssl? or local_request?)
		else
			begin
				customer_mail = CustomerMailer.create_welcome_message
				CustomerMailer.deliver(customer_mail)
			rescue StandardError => e
				logger.error "X-Forwarded-Proto not received from LB, there were some error on seding notification mail for this : #{e.inspect}"
			end
    end
	end
	def users_browser
user_agent =  request.env['HTTP_USER_AGENT'].downcase
@users_agent = user_agent
@users_browser ||= begin
  if user_agent.index('msie') && !user_agent.index('opera') && !user_agent.index('webtv')
                'ie'+user_agent[user_agent.index('msie')+5].chr
    elsif user_agent.index('gecko/')
        'gecko'
    elsif user_agent.index('opera')
        'opera'
    elsif user_agent.index('konqueror')
        'konqueror'
    elsif user_agent.index('ipod')
        'ipod'
    elsif user_agent.index('ipad')
        'ipad'
    elsif user_agent.index('iphone')
        'iphone'
    elsif user_agent.index('chrome/')
        'chrome'
    elsif user_agent.index('applewebkit/')
        'safari'
    elsif user_agent.index('googlebot/')
        'googlebot'
    elsif user_agent.index('msnbot')
        'msnbot'
    elsif user_agent.index('yahoo! slurp')
        'yahoobot'
    #Everything thinks it's mozilla, so this goes last
    elsif user_agent.index('mozilla/')
        'gecko'
    else
        'unknown'
    end
    end

    return @users_browser
end
	def check_for_logged_in
		if cookies[:sessionId]
			return true
		else
			redirect_to login_path
		end
	end
  def xml_request_to_be_sent(url, xml_data)
		@response_failed = false
		@crash_error =false
		begin
			site_url=DEFAULT_CONFIG['site_url']
			port_settings=DEFAULT_CONFIG['port']
			@headers = {
				'Content-Type' => 'application/xml'
			}
			req = xml_data
			logger.debug "Request : #{req.inspect}"
			res = Net::HTTP.start(site_url, port_settings) { |http|
				http.post(url, req, @headers)
			}
		rescue Timeout::Error => e
		  logger.error "Timeout Error, Might be response not received"
			logger.error "#{e.inspect}"
			@response_failed = true
			@crash_error =true
		end
		if res
			begin
        if res.code == "302"
						@location = res['Location']
				else
					@res_code=res.code
					@response_code = res.code
					@result=XmlSimple.xml_in(res.body)
					logger.debug "Response code : #{res.code}"
					logger.debug "Response : #{@result.inspect}"
					#~ if @result && @result['detail']
						#~ logger.info "ERROR - Response received - #{@result.inspect}"
					#~ end
			end
			rescue StandardError => e
				logger.error "ERROR received - #{e}"
				#~ logger.info "ERROR - Response received - #{res.body}"
				logger.error "ERROR - Response code - #{res.code}"
				@error_response = "#{res.body}"
				@response_failed = true
				@crash_error =true
			end
		end
	end

  def request_to_be_sent(url)
		site_url=DEFAULT_CONFIG['site_url']
		port_settings=DEFAULT_CONFIG['port']
		begin
			url ="http://#{site_url}:#{port_settings}#{url}"
			uri = URI.parse(url)
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Get.new(uri.request_uri)
			result = http.request(request)
		rescue Timeout::Error => e
		  logger.error "Timeout Error, Might be response not received"
			logger.error "#{e.inspect}"
			@response_failed = true
			@crash_error =true
		end
		if result && result.response && result.response.content_type && !result.response.content_type.include?("html")
			@response_code=result.response.code
			@res_code=result.response.code
			begin
			if url.include?("/registration/termsnconditions")
				@tc_result=XmlSimple.xml_in(result.response.body)
				if @tc_result && @result['detail']
					logger.error "ERROR - Response received - #{@tc_result.inspect}"
				end
			else
				@result=XmlSimple.xml_in(result.response.body)
				if @result && @result['detail']
					logger.error "ERROR - Response received - #{@result.inspect}"
				end
			end
				@response_failed = false
				@captcha_error = false
			rescue StandardError => e
				logger.error "ERROR received - #{e}"
				logger.error "ERROR - Response received - #{result.response.body}"
				logger.error "ERROR - Response code - #{result.response.code}"
				@response_failed = true
			end
		else
			@response_failed = true
			@captcha_error = true
		end
	end
	 def request_to_be_sent_get_kms(url)
		site_url=DEFAULT_CONFIG['kms_site_url']
		port_settings=DEFAULT_CONFIG['kms_port']
		kms_user=DEFAULT_CONFIG['kms_auth_user']
		kms_pwd=DEFAULT_CONFIG['kms_auth_password']
		begin
			url ="http://#{site_url}:#{port_settings}#{url}"
			uri = URI.parse(url)
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Get.new(uri.request_uri)
			request.basic_auth kms_user, kms_pwd
			result = http.request(request)
			if !result.response.content_type.include?("html")
				@response_code=result.response.code
				@res_code=result.response.code
				begin
					@kms_result=XmlSimple.xml_in(result.response.body)
					if @kms_result && @kms_result['detail']
						logger.error "ERROR - Response received - #{@kms_result.inspect}"
					end
					@response_failed = false
					@captcha_error = false
				rescue StandardError => e
					logger.error "ERROR received - #{e}"
					logger.error "ERROR - Response received - #{result.response.body}"
					logger.error "ERROR - Response code - #{result.response.code}"
					@response_failed = true
				end
			else
				@response_failed = true
				@captcha_error = true
			end
		rescue StandardError => e
			logger.info  "Error Received on invoking KMS call - #{e}"
			@crashed = "true"
		end
	end
	def request_to_be_sent_to_kms(url)
		site_url=DEFAULT_CONFIG['kms_site_url']
		port_settings=DEFAULT_CONFIG['kms_port']
		kms_user=DEFAULT_CONFIG['kms_auth_user']
		kms_pwd=DEFAULT_CONFIG['kms_auth_password']
		url ="http://#{site_url}:#{port_settings}#{url}"
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Get.new(uri.request_uri)
		request.basic_auth kms_user, kms_pwd
		result = http.request(request)
		if !result.response.content_type.include?("html")
			@response_code=result.response.code
			@res_code=result.response.code
			begin
				@kms_result=XmlSimple.xml_in(result.response.body)
				if @kms_result && @kms_result['detail']
					logger.error "ERROR - Response received - #{@kms_result.inspect}"
				end
				@response_failed = false
				@captcha_error = false
			rescue StandardError => e
				logger.error "ERROR received - #{e}"
				logger.error "ERROR - Response received - #{result.response.body}"
				logger.error "ERROR - Response code - #{result.response.code}"
				@response_failed = true
			end
		else
			@response_failed = true
			@captcha_error = true
		end
	end
	def empty_flash
		flash=Hash.new
	end
	def error_message(mod, code, flash_name, message)
		if (code == "500" || code == "501" || code == "201" || code == "503" || code == "306")
			error = t("c#{code}")
		elsif message && message == "login_call"
			error =  t("#{mod}.#{message}")
		else
			error = code && !code.nil? ? t("#{mod}.c#{code}")  :  t("#{mod}.#{message}")
		end
		if(error.include?('translation missing: en'))
			flash[:"#{flash_name}"] = message && !message.blank? ?  message  : ""
		else
			flash[:"#{flash_name}"] = error
		end
	end
	def dev_and_app_name
		@app_name = @result['developerAppDetails'][0]['appname'].to_s
		@dev_name = @result['developerAppDetails'][0]['name'].to_s
	end
	def display_scope_title
		if @result && @result['scope']
			scope = @result['scope'][0].to_s
			if (scope && (scope.include?("MOBO") || scope.include?("MIM")))
				@duration = "approved until changed"
			else
				@duration = "approved"
			end
			scopes = []
			scopes << "Device Capabilities" if scope && scope.include?("DC")
			scopes << "Location" if scope && scope.include?("TL")
			scopes << "Messaging" if scope && scope.include?("MOBO") || scope.include?("MIM")
			#~ scopes << "Message Management" if scope.include?("MIM")
			#If any new scopes has been introduced, just add it above
			scopes.each_index do |n|
				if n+1 == scopes.length-1
					scopes[n] = scopes[n] + " and "
				elsif n+1 != scopes.length
					scopes[n] = scopes[n] + ", "
				else
					scopes[n] = scopes[n]
				end
			end
			@scope = scopes.to_s
		else
			@scope = ""
		end
	end
protected
 def handle_unverified_request
	logger.info "Received a invalid AuthenticityToken, and thus redirecing to a error page"
  raise ActionController::InvalidAuthenticityToken
 end
end
