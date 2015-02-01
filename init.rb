Redmine::Plugin.register :redmine_cf_autoadd do
  name 'Redmine Cf Autoadd plugin'
  author 'Bilel KEDIDI'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/Atrasoftware/redmine_cf_autoadd'
  author_url 'https://github.com/Atrasoftware'

  settings :default => {
        'auto_increment_globally'=> true,
        'auto_add_uniquness' => false
   }, :partial => 'settings/auto_increment'
end
require 'redmine_auto_add_hook'

Rails.application.config.to_prepare do
  Issue.send(:include, Patches::AutoAddIssuePatch)
end