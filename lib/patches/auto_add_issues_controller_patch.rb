require_dependency 'issues_controller'

module  Patches
  module AutoAddIssuesControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        append_before_filter :auto_add_cfs, :only=> [:new, :copy, :update_form]

       def auto_add_cfs
         if @issue.id.nil?
           settings = Setting.send "plugin_redmine_cf_autoadd"
           issues_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('string')").select{|cf| settings[cf.name] == "true" }
           issues_cfs.each do |issue_cfs|
             detect_cf = @issue.visible_custom_field_values.detect{|cf| cf.custom_field == issue_cfs}
             if detect_cf
               if settings["cf_global_#{issue_cfs.name}"] == "true" # global increment
                   cfs = issue_cfs.custom_values.where("value is not null and value <> '' ").order("id DESC")
               else
                   project = @issue.project
                   issues_id = project.issues.map(&:id)
                   cfs = CustomValue.where("customized_type= 'issue' and customized_id in(?) and custom_field_id = ? and (value is not null and value <> '' ) ",
                                          issues_id, issue_cfs.id).order("id DESC")
               end
               max = cfs.map(&:value).max rescue nil

               if settings["cf_auto_increment_#{issue_cfs.name}"] == "true"
                 max = max.nil? ? issue_cfs.default_value : max.succ
               else
                 max = issue_cfs.default_value if max.nil?
               end
               detect_cf.value = max
             end

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