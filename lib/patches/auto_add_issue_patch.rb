require_dependency 'issue'

module  Patches
  module AutoAddIssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        before_create :uniqueness_cf
        before_update :uniqueness_cf_update

        def uniqueness_cf
          settings = Setting.send "plugin_redmine_cf_autoadd"
          issues_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('string')").select{|cf| settings[cf.name] == "true" }
          issues_cfs.each do |issue_cfs|
            uniqueness = settings["cf_uniq_#{issue_cfs.name}"] || false
            detect_cf = visible_custom_field_values.detect{|cf| cf.custom_field == issue_cfs}
            if detect_cf
              if uniqueness == 'true'
                check_uniq = CustomValue.where("customized_type= 'issue' and custom_field_id = ? and value = ?",
                                               issue_cfs.id, detect_cf.value)
              else
                # check uniqueness for that project
                project_issues = project.issues.map(&:id) || []
                check_uniq = CustomValue.where("customized_type= 'issue' and customized_id in (?) and custom_field_id = ? and value = ?  ",
                                       project_issues, issue_cfs.id, detect_cf.value)
              end

              unless check_uniq.empty?
                errors[:base]<< "#{issue_cfs.name} #{l(:value_must_be_uniq)}"
                return false
              end
            end
          end

        end

        def uniqueness_cf_update
          settings = Setting.send "plugin_redmine_cf_autoadd"
          issues_cfs = CustomField.where("type= 'IssueCustomField' and field_format in ('string')").select{|cf| settings[cf.name] == "true" }
          issues_cfs.each do |issue_cfs|
            uniqueness = settings["cf_uniq_#{issue_cfs.name}"] || false
            detect_cf = visible_custom_field_values.detect{|cf| cf.custom_field == issue_cfs}
            if detect_cf
              if uniqueness == 'true'
                check_uniq = CustomValue.where("customized_type= 'issue' and custom_field_id = ? and value = ? and customized_id <> ?",
                                               issue_cfs.id, detect_cf.value, id)
              else
                # check uniqueness for that project
                project_issues = project.issues.map(&:id) || []
                project_issues.delete(id)
                check_uniq = CustomValue.where("customized_type= 'issue' and customized_id in (?) and custom_field_id = ? and value = ?  ",
                                               project_issues, issue_cfs.id, detect_cf.value)
              end

              unless check_uniq.empty?
                errors[:base]<< "#{issue_cfs.name} #{l(:value_must_be_uniq)}"
                return false
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
