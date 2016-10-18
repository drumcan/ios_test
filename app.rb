require 'braintree'
require "rubygems"
require 'sinatra'
require 'webrick'
require 'webrick/https'
require 'openssl'




 Braintree::Configuration.environment = :sandbox
 Braintree::Configuration.merchant_id = 'yxb4zvxjdctbbppt'
 Braintree::Configuration.public_key = 'xktj76v3mb4nt7wx'
 Braintree::Configuration.private_key = '2632842e6df4fff163c877944980da46'

get "/" do
  erb :index
end

get "/apple_pay" do
  erb :apple_pay
end

get "/.well-known/apple-developer-merchantid-domain-association" do
  send_file "apple-developer-merchantid-domain-association"
end

post "/ios_checkout" do
p params
result = Braintree::Transaction.sale(
  :amount => "100.00",
  :payment_method_nonce => params[:payment_method_nonce],
  :options => {
  	:submit_for_settlement => true,

  }
)

if result.success?
  content_type :json
  return {:result => "Success ID: #{result.transaction.id}"}.to_json
  else
   p result.message
  end
end
