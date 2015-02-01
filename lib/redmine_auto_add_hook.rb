class RedmineAutoAddHook < Redmine::Hook::ViewListener
  def controller_issues_new_before_save(context = {})
    issue = context[:issue]

    settings = Setting.send "plugin_redmine_cf_autoadd"
    issues_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('string')").select{|cf| settings[cf.name] == "true" }
    uniqueness = settings['auto_add_uniquness'] || false
    issues_cfs.each do |issue_cfs|
      detect_cf = issue.visible_custom_field_values.detect{|cf| cf.custom_field == issue_cfs}
      if detect_cf
        max = detect_cf.value
        if detect_cf.value.nil? or detect_cf.value.empty?
          if settings['auto_increment_globally'] == "true"
            cf = issue_cfs.custom_values.where("value is not null and value <> '' ")
                      .where("value like '#{Time.now.strftime("%y")}_%'") # identify value for this year
                     .order("id DESC").first
          else
            project = issue.project
            issues_id = project.issues.map(&:id)
            cf = CustomValue.where("customized_type= 'issue' and customized_id in(?) and custom_field_id = ? and (value is not null and value <> '' ) ",
                                    issues_id, issue_cfs.id)
                     .where("value like '#{Time.now.strftime("%y")}_%'") # identify value for this year
                     .order("id DESC").first
          end

          max = cf.value rescue [Time.now.strftime("%y"), 0].join('_')
          max = max.succ
          if uniqueness
=begin
            check_uniq = CustomValue.where("customized_type= 'issue' and custom_field_id = ? and value = ?",
                               issue_cfs.id, max)
            unless check_uniq.empty?
                # TODO add validation for uniqueness
            end
=end
          end
        end
        detect_cf.value = max
      end
    end
  end

  def view_issues_form_details_bottom(context = {})
    issue = context[:issue]
    if issue.id
      settings = Setting.send "plugin_redmine_cf_autoadd"
      issues_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('string')").select{|cf| settings[cf.name] == "true" }.map(&:id)

      o = '<script> $(function(){'
      issues_cfs.each do |id|
        o<< "$(\"#issue_custom_field_values_#{id}\").attr('readonly', 'readonly');"
      end
      o<< ' }); </script>'
      o
    end
  end
end