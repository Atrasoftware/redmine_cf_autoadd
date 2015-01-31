Redmine::Plugin.register :redmine_cf_autoadd do
  name 'Redmine Cf Autoadd plugin'
  author 'Bilel KEDIDI'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/Atrasoftware/redmine_cf_autoadd'
  author_url 'https://github.com/Atrasoftware'

  settings :default => {
        'auto_increment_globally'=> true
   }, :partial => 'settings/auto_increment'
  class AutoAddHooks < Redmine::Hook::ViewListener
    def controller_issues_new_before_save(context = {})
      issue = context[:issue]
      settings = Setting.send "plugin_redmine_cf_autoadd"
      issue_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('int', 'string')").detect{|cf| settings[cf.name] == "true" }
      unless issue_cfs.nil?
        if settings['auto_increment_globally'] == "true"
            max = issue_cfs.custom_values.map(&:value).max.to_i.next.to_s
        else
          project = issue.project
          issues_id = project.issues.map(&:id)
          max = CustomValue.where("customized_type= 'issue' and customized_id in(?) and custom_field_id = ?",
                                  issues_id, issue_cfs.id).map(&:value).max.to_i.next.to_s
        end
        detect_cf = issue.visible_custom_field_values.detect{|cf| cf.custom_field == issue_cfs}
        detect_cf.value = max
      end
    end
  end
end
