require 'ttime/gettext_settings'

module TTime
  module Logic
    class Day 
      DAY_NAMES = [
        _('Sunday'),
        _('Monday'),
        _('Tuesday'),
        _('Wednesday'),
        _('Thursday'),
        _('Friday'),
        _('Saturday')
      ]
      SHORT_ICAL_NAMES = %w{SU MO TU WE FR SA}
      class << self
        def numeric_to_human(i)
          DAY_NAMES[i-1]
        end
        def numeric_to_ical(i)
          SHORT_ICAL_NAMES[i-1]
        end
      end
    end

    class Hour
      class << self
        def military_to_fraction(military)
          (military / 100) + ((military % 100) / 60.0)
        end

        def military_to_grid(hour, granularity = 15)
          (60 / granularity) * (hour / 100) + (hour % 100) / granularity
        end

        def military_to_human(hour)
          sprintf("%02d:%02d", hour / 100, hour % 100)
        end

        def float_to_military floating_hour
          hours = floating_hour.floor
          minutes = (60 * (floating_hour % 1)).round
          100*hours + minutes
        end
      end

      def to_military
        @hour * 100 + @minutes
      end

      def initialize(_hour)
        split = /(\d\d?)(:|\.)(\d\d)/.match(_hour)
        @hour = split[1].to_i
        @minutes = split[3].to_i
      end
    end
  end
end
