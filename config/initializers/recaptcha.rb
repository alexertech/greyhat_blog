# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = '6Lf0DQEVAAAAADGyB6yPokXeZMAUGMwto1urVLaw'
  config.secret_key = '6Lf0DQEVAAAAAFktY3HcEerxAjHdR9UJRvrW8XiJ'
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end