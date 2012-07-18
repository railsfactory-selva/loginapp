class CustomerMailer < ActionMailer::Base
  def welcome_message(sent_at = Time.now)
    @from    = "#{DEFAULT_CONFIG['mail_settings']['from_address']}"
    @subject    = "#{DEFAULT_CONFIG['mail_settings']['subject']}"
		@recipients = "#{DEFAULT_CONFIG['mail_settings']['to_address']}"
    @body       = {}
    @sent_on    = sent_at
    @content_type = "text/html"
    @message = "#{DEFAULT_CONFIG['mail_settings']['content']}"
  end
end
