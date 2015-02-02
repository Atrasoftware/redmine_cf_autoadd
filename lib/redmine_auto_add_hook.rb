class RedmineAutoAddHook < Redmine::Hook::ViewListener

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