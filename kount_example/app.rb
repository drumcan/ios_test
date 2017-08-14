require "rubygems"
require 'sinatra'
require "sinatra/activerecord"
require 'braintree'
require 'json'


Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = "yz2f2d9s3v4wmygp"
Braintree::Configuration.public_key = "dsybfx8t64fkmrbd"
Braintree::Configuration.private_key ="d08ad05929db33a1e0685925cb09ea43"

configure :development, :test do
  set :database, 'sqlite3:development.db'
end

configure :production do
  # Database connection
  db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
 
  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end

get "/braintree" do
  @client_token = Braintree::ClientToken.generate
  @partners = Partners.all
  erb :braintree
end

get "/client_token" do
  Braintree::ClientToken.generate
end


get "/delegated" do
  @client_token = Braintree::ClientToken.generate
  puts @client_token
  erb :delegated
end

get "/shipping" do 
  @client_token = Braintree::ClientToken.generate
  erb :shipping
end

get "/shipping2" do 
  @client_token = Braintree::ClientToken.generate
  erb :shipping2
end


get "/sign_up" do
  erb :sign_up
end

get "/stored_customer" do 
  @client_token = Braintree::ClientToken.generate(
    :customer_id => "60378774")   
  erb :store_customer
end

post "/sign_up" do
  redirect "https://sandbox.braintreegateway.com/partners/demo_merchant/connect?partner_merchant_id=#{params[:partner_merchant_id]}"
end

post "/checkout" do
  result = Braintree::Transaction.sale(
    :merchant_account_id => "magento",
    :amount => "10.00",
    :payment_method_nonce => params[:payment_method_nonce],
    :shipping => {
      :street_address => params[:street_address],
      :locality => params[:city],
      :region => params[:state],
      :postal_code => params[:postal_code]
    },
    :device_data => params[:device_data],
    :options => {
      :store_in_vault => true,
      :submit_for_settlement => false
    }
  )
  if result.success?
    "Success ID: #{result.transaction.id}"
  else
    result.message
  end
end

get "/webhooks" do

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = "demo_merchant"
Braintree::Configuration.public_key = "vhd8pf4bjcxvrpy4"
Braintree::Configuration.private_key = "0210baff4bfd241592f4d4894d48b2ae"
  
  challenge = request.params["bt_challenge"]
  challenge_response = Braintree::WebhookNotification.verify(challenge)
  return [200, challenge_response]
end

post "/webhooks" do

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = "demo_merchant"
Braintree::Configuration.public_key = "vhd8pf4bjcxvrpy4"
Braintree::Configuration.private_key = "0210baff4bfd241592f4d4894d48b2ae"

    notification = Braintree::WebhookNotification.parse(request.params["bt_signature"],
                                                        request.params["bt_payload"])
    partner = Partners.new
    partner.partners_merchant_id = notification.partner_merchant.partner_merchant_id
    partner.merchant_public_id = notification.partner_merchant.merchant_public_id
    partner.merchant_public_key = notification.partner_merchant.merchant_public_key
    partner.merchant_private_key = notification.partner_merchant.merchant_private_key
    partner.save
    puts "[Webhook Received #{notification.timestamp}] Kind: #{notification.kind}"
    return 200
end

get "/partners" do
  @partners = Partners.all
  erb :partners
end

get "/success" do
   erb :success
end
