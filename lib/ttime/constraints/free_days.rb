require 'ttime/constraints'
require 'ttime/gettext_settings'

module TTime
  module Constraints
    class FreeDays < AbstractConstraint
      # This is the number of weekdays which "count" for the purpose of
      # calculating Free Days. Specifically, if n free days are requested,
      # then n days of the first WEEKDAYS days of the week have to be free.
      WEEKDAYS = 5

      def requested_free_days
        Settings.instance[:free_days] ||= 0
        Settings.instance[:free_days]
      end

      def requested_free_days= free_days
        Settings.instance[:free_days] = free_days
      end

      def evaluate_schedule
        return true if requested_free_days == 0

        day_grid = [false] * (WEEKDAYS)
        event_list.each do |ev|
          day_grid[ev.day - 1] = true if ev.day - 1 < WEEKDAYS
        end

        available_free_days = day_grid.select { |x| not x }.length

        return available_free_days >= self.requested_free_days
      end

      def name
        _('Free days')
      end

      def preferences_panel
        vbox = Gtk::VBox.new

        hbox = Gtk::HBox.new

        spin_button = Gtk::SpinButton.new 0, 5, 1
        spin_button.value = self.requested_free_days
        spin_button.signal_connect('changed') do
          self.requested_free_days = spin_button.value.to_i
        end

        hbox.pack_start spin_button, false

        lbl = Gtk::Label.new
        lbl.text = _(' free days please')
        lbl.xalign = 0
        hbox.pack_start lbl

        vbox.pack_start hbox, false, false

        lbl = Gtk::Label.new
        lbl.markup = _(<<-EOF
This constraint makes sure your schedule has <b>at least</b> as many free days
as you requested.
        EOF
        )

        vbox.pack_end lbl

        vbox
      end
    end
  end
end
