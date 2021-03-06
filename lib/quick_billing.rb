require "money"
require "quick_billing/version"
require "quick_billing/account"
require "quick_billing/payment"
require "quick_billing/product"
require "quick_billing/transaction"
require "quick_billing/subscription"
require "quick_billing/entry"
require "quick_billing/coupon"
require "quick_billing/invoice"
require "quick_billing/adapters/braintree_adapter"

module QuickBilling
  # Your code goes here...

  PAYMENT_PLATFORMS = {paypal: 1, braintree: 2}
  PAYMENT_TYPES = {credit_card: 1}

  ## CONFIGURATION

  if defined?(Rails)
    # load configuration
    class Railtie < Rails::Railtie
      initializer "quick_billing.configure" do
        config_file = Rails.root.join("config", "quick_billing.yml")
        if File.exists?(config_file)
          QuickBilling.configure(YAML.load_file(config_file)[Rails.env])
        else
          QuickBilling.configure
        end
      end
    end
  end

  def self.configure(opts={})
    @options = opts.with_indifferent_access
    self.setup_classes

    case @options[:platform]
    when :braintree
      require 'braintree'
      self.setup_braintree
    end

    return @options
  end

  def self.setup_classes
    @options[:classes] = (@options[:classes] || {}).with_indifferent_access
    mm = @options[:class_module] || ""
    @options[:classes][:account] ||= "#{mm}::Account"
    @options[:classes][:transaction] ||= "#{mm}::Transaction"
    @options[:classes][:payment] ||= "#{mm}::Payment"
    @options[:classes][:subscription] ||= "#{mm}::Subscription"
    @options[:classes][:product] ||= "#{mm}::Product"
    @options[:classes][:entry] ||= "#{mm}::Entry"
    @options[:classes][:coupon] ||= "#{mm}::Coupon"
    @options[:classes][:invoice] ||= "#{mm}::Invoice"
  end

  def self.setup_braintree
    Braintree::Configuration.environment = @options[:environment]
    Braintree::Configuration.merchant_id = @options[:merchant_id]
    Braintree::Configuration.public_key = @options[:merchant_public_key]
    Braintree::Configuration.private_key = @options[:merchant_private_key]
  end

  def self.options
    @options ||= {}
  end

  def self.platform
    case self.options[:platform]
    when :braintree
      Adapters::BraintreeAdapter
    end
  end

  def self.models
    @models ||= begin
      ret = {}
      @options[:classes].each do |k,v|
        ret[k.to_sym] = v.constantize
      end
      ret
    end
  end

  def self.Account
    self.models[:account]
  end
  def self.Transaction
    self.models[:transaction]
  end
  def self.Payment
    self.models[:payment]
  end
  def self.Product
    self.models[:product]
  end
  def self.Subscription
    self.models[:subscription]
  end
  def self.Entry
    self.models[:entry]
  end
  def self.Coupon
    self.models[:coupon]
  end
  def self.Invoice
    self.models[:invoice]
  end

  ## HELPERS

  class Helpers

    def self.amount_usd_str(amt)
      "$ #{'%.2f' % self.amount_usd(amt)}"
    end

    def self.amount_usd(amt)
      amt / 100.0
    end

  end

  ## CLASSES

  class PaymentMethod

    attr_accessor :platform, :customer_id, :type, :token, :number, :expiration_date, :card_type

    def self.from_braintree_credit_card(card)
      pm = PaymentMethod.new(
        platform: :braintree,
        customer_id: card.customer_id,
        type: QuickBilling::PAYMENT_TYPES[:credit_card],
        token: card.token,
        number: card.masked_number,
        expiration_date: card.expiration_date,
        card_type: card.card_type
      )
      return pm
    end

    def initialize(opts={})
      opts.each do |key, val|
        self.send("#{key}=", val) if self.respond_to? key
      end
    end

    def [](field)
      return self.send(field.to_s)
    end

    def type?(val)
      self.type == QuickBilling::PAYMENT_TYPES[val.to_sym]
    end

    def to_hash
      {
        "platform" => self.platform,
        "customer_id" => self.customer_id,
        "type" => self.type,
        "token" => self.token,
        "number" => self.number,
        "expiration_date" => self.expiration_date,
        "card_type" => self.card_type
      }
    end

    def to_api
      self.to_hash.symbolize_keys
    end

  end

end
