module QuickBilling

  module Product

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def quick_billing_product_keys_for(db)
        if db == :mongoid
          include MongoHelper::Model

          field :nm, as: :name, type: String
          field :ky, as: :key, type: String
          field :pr, as: :price, type: Integer
          field :pi, as: :period_interval, type: Integer, default: 1   # period in months
          field :pu, as: :period_unit, type: String, default: 'month'   # period in months
          field :av, as: :is_available, type: Boolean, default: true
          field :pb, as: :is_public, type: Boolean, default: true
          field :mrh, as: :metrics, type: Hash, default: Hash.new

          mongoid_timestamps!

          scope :available, lambda {
            where(av: true)
          }
          scope :is_public, lambda {
            where(pb: true)
          }
        end
      end

      def add_product!(key, name, price)
        if self.with_key(key).count > 0
          raise "Product with key already created"
        end
        product = self.new
        product.key = key.to_s
        product.name = name
        product.price = price
        product.save
        return product
      end

      def with_key(key)
        self.find_with_key(key)
      end

      def find_with_key(key)
        self.where(ky: key).first
      end

    end

    ## INSTANCE METHODS

    def period_length
      case self.period_unit
      when 'month'
        return self.period_interval.months
      when 'year'
        return self.period_interval.years
      else
        return nil
      end
    end

    def period_length_hash
      {interval: self.period_interval, unit: self.period_unit}
    end

    def has_period?
      !self.period.nil?
    end

    def to_api(opt=:full)
      ret = {}
      ret[:id] = self.id.to_s
      ret[:name] = self.name
      ret[:key] = self.key
      ret[:price] = self.price
      ret[:metrics] = self.metrics
      ret[:period_unit] = self.period_unit
      ret[:period_interval] = self.period_interval

      return ret
    end

  end

end
