class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "#{message.to} #{message.subject}"
    message.to = "tu correo_para_desarrollo@gmail.com"
  end
end
