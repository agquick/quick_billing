module QuickBilling

  module Coupon

    STYLES = {subscription: 1}
    STATES = {active: 1, inactive: 2}

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def quick_billing_coupon_keys_for(db)
        include MongoHelper::Model
        if db == :mongoid
          field :sy, as: :style, type: Integer
          field :cd, as: :code, type: String
          field :st, as: :state, type: Integer
          field :am, as: :amount, type: Integer
          field :pr, as: :percent, type: Integer
          field :mr, as: :max_redemptions, type: Integer
          field :mu, as: :max_uses, type: Integer
        end

        enum_methods! :state, STATES
        enum_methods! :style, STYLES
      end

      def find_with_code(code)
        where(cd: code.strip).first || find(code)
      end

    end

    ## INSTANCE METHODS

    # ACCESSORS

    def redeemable?
      self.max_redemptions.nil? || (self.times_redeemed < self.max_redemptions)
    end

    def redeemable_by_account?(aid)
      return false if !(self.state?(:active) && self.redeemable?)
      if self.style?(:subscription) && self.max_uses == nil
        return true
      else
        return !self.redeemed_by_account?(aid)
      end
    end

    def redeemed_by_account?(aid)
      # check adjustments
      QuickBilling.Entry.invoiced.for_coupon(self.id).for_account(aid).count > 0
    end

    def times_redeemed
      QuickBilling.Entry.invoiced.for_coupon(self.id).count
    end

    def to_api(opt=:default)
      ret = {}
      ret[:id] = self.id.to_s
      ret[:style] = self.style
      ret[:code] = self.code
      ret[:state] = self.state
      ret[:amount] = self.amount
      ret[:percent] = self.percent
      ret[:max_uses] = self.max_uses
      return ret
    end

  end

end
