require_dependency 'issues_controller'

module  Patches
  module AutoAddIssuesControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        append_before_filter :auto_add_cfs, :only=> [:new, :copy, :update_form]

       def auto_add_cfs
         settings = Setting.send "plugin_redmine_cf_autoadd"
         issues_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('string')").select{|cf| settings[cf.name] == "true" }
         issues_cfs.each do |issue_cfs|
           detect_cf = @issue.visible_custom_field_values.detect{|cf| cf.custom_field == issue_cfs}
           if detect_cf
             max = detect_cf.value
             if detect_cf.value.nil? or detect_cf.value.empty?
               if settings["cf_global_#{issue_cfs.name}"] == "true" # global increment
                 cf = issue_cfs.custom_values.where("value is not null and value <> '' ")
                 .where("value like '#{Time.now.strftime("%y")}_%'") # identify value for this year
                 .order("id DESC").first
               else
                 project = @issue.project
                 issues_id = project.issues.map(&:id)
                 cf = CustomValue.where("customized_type= 'issue' and customized_id in(?) and custom_field_id = ? and (value is not null and value <> '' ) ",
                                        issues_id, issue_cfs.id)
                 .where("value like '#{Time.now.strftime("%y")}_%'") # identify value for this year
                 .order("id DESC").first
               end

               max = cf.value rescue [Time.now.strftime("%y"), 0].join('_')
               if settings["cf_auto_increment_#{issue_cfs.name}"] == "true"
                 arr = max.split('').reverse
                 arr.pop(2)
                 max = [Time.now.strftime("%y"), arr.reverse.join('').succ].join('')
               end
             end
             detect_cf.value = max
           end

         end
       end

      end
    end
  end
  module ClassMethods

  end
  module InstanceMethods

  end

end