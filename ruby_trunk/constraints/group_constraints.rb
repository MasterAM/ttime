require 'constraints'
require 'set'

GetText::bindtextdomain("ttime", "locale", nil, "utf-8")

module TTime
  module Constraints
    class GroupConstraint < AbstractConstraint
      COLUMNS = [
        [ :text, String ],
        [ :show_checkbox, TrueClass ],
        [ :marked, TrueClass ],
        [ :course, String ],
        [ :group, Fixnum ],
        [ :time, String ],
        [ :lecturer, String ],
      ]

      def col_index(column_name)
        COLUMNS.each_index do |i|
          return i if COLUMNS[i][0] == column_name
        end
        raise Exception("Column not found")
      end

      def column_classes
        COLUMNS.collect { |col| col[1] }
      end

      GROUP_TYPE_NAME = {
        :lecture => _('Lecture'),
        :tutorial => _('Tutorial'),
        # TODO More types?
      }

      def initialize
        super

        Settings.instance[:group_constraints] ||= {
          :enabled => false,
          :forbidden_groups => {}
        }
      end

      def settings
        Settings.instance[:group_constraints]
      end

      def forbidden_groups
        return settings[:forbidden_groups]
      end

      def evaluate_schedule
        true
      end

      def evaluate_group(grp)
        return true unless settings[:enabled]
        return !(group_is_forbidden?(grp.course.number, grp.number))
      end

      def name
        _('Group Constraints')
      end

      def allow_group(course_number, group_number)
        forbidden_groups[course_number].delete group_number
      end

      def update_courses(course_list)
        @model.clear

        for course in course_list
          course_iter = @model.append(nil)
          course_iter[col_index(:text)] = course.name

          for group_type in course.groups.collect { |g| g.type }.uniq
            group_type_iter = @model.append(course_iter)
            group_type_iter[col_index(:text)] = GROUP_TYPE_NAME[group_type] or group_type
            for group in course.groups.select { |g| g.type == group_type }
              group_iter = @model.append(group_type_iter)
              group_iter[col_index(:text)] = group.number.to_s
              group_iter[col_index(:course)] = course.number
              group_iter[col_index(:group)] = group.number
              group_iter[col_index(:show_checkbox)] = true
              group_iter[col_index(:time)] = group.time_as_text
              group_iter[col_index(:lecturer)] = group.lecturer

              if group_is_forbidden?(course.number, group.number)
                group_iter[col_index(:marked)] = false
              else
                group_iter[col_index(:marked)] = true
              end
            end
          end
        end
      end

      def group_is_forbidden?(course_number, group_number)
        return false unless forbidden_groups.include?(course_number)
        return forbidden_groups[course_number].include?(group_number)
      end

      def disallow_group(course_number, group_number)
        forbidden_groups[course_number] ||= Set.new
        forbidden_groups[course_number].add group_number
      end

      def tree_setup
        @model = Gtk::TreeStore.new(*column_classes)
        @treeview = Gtk::TreeView.new(@model)
        @treeview.rules_hint = true
        @treeview.selection.mode = Gtk::SELECTION_MULTIPLE

        cellrend = Gtk::CellRendererToggle.new

        cellrend.signal_connect("toggled") do |renderer, path|
          iter = @model.get_iter(path)
          args = iter[col_index(:course)], iter[col_index(:group)]

          if iter[col_index(:marked)]
            disallow_group *args
          else
            allow_group *args
          end

          iter[col_index(:marked)] ^= true
        end

        @treeview.insert_column(-1, _('Allowed'),
                                cellrend,
                                'visible' => col_index(:show_checkbox),
                                'active' => col_index(:marked))
        @treeview.insert_column(-1, _('Group'),
                                Gtk::CellRendererText.new,
                                'text' => col_index(:text))
        @treeview.insert_column(-1, _('Time'),
                                Gtk::CellRendererText.new,
                                'text' => col_index(:time))
        @treeview.insert_column(-1, _('Lecturer'),
                                Gtk::CellRendererText.new,
                                'text' => col_index(:lecturer))
      end

      def preferences_panel
        vbox = Gtk::VBox.new

        sw = Gtk::ScrolledWindow.new(nil, nil)
        sw.shadow_type = Gtk::SHADOW_ETCHED_IN
        sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

        tree_setup

        @treeview.sensitive = settings[:enabled]

        sw.add(@treeview)

        btn_enabled = Gtk::CheckButton.new(_('Use group constraints'))
        btn_enabled.active = settings[:enabled]

        btn_enabled.signal_connect('toggled') do
          settings[:enabled] = btn_enabled.active?
          @treeview.sensitive = settings[:enabled]
        end

        vbox.pack_start btn_enabled, false, false

        vbox.pack_end sw, true, true, 0

        vbox
      end
    end
  end
end