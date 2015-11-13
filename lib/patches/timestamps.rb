# See https://github.com/mongodb/mongoid/pull/4110, fixed in 5.0.1
raise 'This patch is for mongoid v4.0.2, update it.' unless Mongoid::VERSION == '4.0.2'

module Mongoid
  module Timestamps
    module Created
      def set_created_at
        if !timeless? && !created_at
          time = Time.now.utc
          self.updated_at = time if is_a?(Updated) && !updated_at_changed?
          self.created_at = time
        end

        # modified
        clear_timeless_option
      end
    end

    module Updated
      def set_updated_at
        if able_to_set_updated_at?
          self.updated_at = Time.now.utc unless updated_at_changed?
        end

        # modified
        clear_timeless_option
      end
    end

    module Timeless
      # modified
      def clear_timeless_option
        if self.persisted?
          self.class.clear_timeless_option_on_update
        else
          self.class.clear_timeless_option
        end
        true
      end

      module ClassMethods
        def clear_timeless_option
          if counter = Timeless[name]
            counter -= 1
            # modified
            set_timeless_counter(counter)
          end
          true
        end

        # added
        def clear_timeless_option_on_update
          if counter = Timeless[name]
            counter -= 1 if self < Mongoid::Timestamps::Created
            counter -= 1 if self < Mongoid::Timestamps::Updated
            set_timeless_counter(counter)
          end
        end

        # added
        def set_timeless_counter(counter)
          Timeless[name] = (counter == 0) ? nil : counter
        end
      end
    end
  end
end
