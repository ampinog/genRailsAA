require "#{Rails.root.to_s}/lib/development_mail_interceptor"

ActionMailer::Base.default_url_options = {host: "https://sistemas.logisticabyv.cl"}
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.gmail.com',
    :port           => 587,
    :domain         => 'gmail.com',
    :user_name      => 'tucorreo@gmail.com',
    :password       => 'password',
    :authentication => :plain,
    :enable_starttls_auto => true,
    :openssl_verify_mode => 'none'
  }
ActionMailer::Base.register_interceptor( DevelopmentMailInterceptor ) if Rails.env.development?
