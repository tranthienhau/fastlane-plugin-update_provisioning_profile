require "fastlane/action"
require_relative "../helper/update_provisioning_profile_helper"

module Fastlane
  module Actions
    class UpdateProvisioningProfileAction < Action
      def self.run(params)
        require "xcodeproj"
        require "plist"

        # assign folder from the parameter or search for an .xcodeproj file
        pdir = params[:xcodeproj] || Dir["*.xcodeproj"].first
        target = params[:target]
        configuration = params[:configuration]

        project_file_path = File.join(pdir, "project.pbxproj")
        UI.user_error!("Could not find path to project config '#{project_file_path}'. Pass the path to your project (NOT workspace!)") unless File.exist?(project_file_path)

        provisioning_profile = params[:provisioning_profile]
        profile_plist_file = "profile.plist"
        certificate_file = "cert.crt"
        sh("security cms -D -i #{provisioning_profile} > #{profile_plist_file}")
        profile_plist = Plist.parse_xml(profile_plist_file)
        porfile_uuid = profile_plist["UUID"]
        profile_specifier = profile_plist["Name"]
        team_id = profile_plist["TeamIdentifier"].first

        certificateIO = profile_plist["DeveloperCertificates"].first
        certificateIO.set_encoding("UTF-8")
        File.open(certificate_file, "w:UTF-8") do |f|
          f.puts(certificateIO.read)
        end
        full_certificate_CN = sh("cat #{certificate_file} | openssl x509 -noout -inform DER -subject | sed 's/^.*CN=\\([^\\/]*\\)\\/.*$/\\1/'")
        code_sign_identity = full_certificate_CN.split(":").first

        project = Xcodeproj::Project.open(pdir)
        project.targets.each do |t|
          if !target || t.name == target
            UI.success("Updating target #{t.name}")
          else
            UI.important("Skipping target #{t.name} as it doesn't match the filter '#{target}'")
            next
          end
          t.build_configurations.each do |config|
            if !configuration || config.name.match(configuration)
              UI.success("Updating configuration #{config.name}")
            else
              UI.important("Skipping configuration #{config.name} as it doesn't match the filter '#{configuration}'")
              next
            end
            config.build_settings["DEVELOPMENT_TEAM"] = team_id
            config.build_settings["CODE_SIGN_IDENTITY[sdk=iphoneos*]"] = code_sign_identity
            config.build_settings["PROVISIONING_PROFILE"] = porfile_uuid
            config.build_settings["PROVISIONING_PROFILE_SPECIFIER"] = profile_specifier
          end
        end
        project.save

        #Remove temp files
        sh("rm -rf #{profile_plist_file} #{certificate_file}")

        UI.message("Finish update xcodeproj with extracted values from provisioning profile!")
      end

      def self.description
        "This action will update xcodeproj with values extracted from your provisioning profile."
      end

      def self.authors
        ["Duy Nguyen"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :xcodeproj,
            env_name: "SPECIFIER_XCODEPROJ",
            description: "Path to the .xcodeproj file",
            optional: true,
            verify_block: proc do |value|
              UI.user_error!("Path to Xcode project file is invalid") unless File.exist?(value)
            end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :target,
            env_name: "SPECIFIER_TARGET",
            description: "The target for which to update Provisioning Profile. If unspecified the change will be applied to all targets",
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :configuration,
            env_name: "SPECIFIER_CONFIGURATION",
            description: "The configuration for which to update Provisioning Profile. If unspecified the change will be applied to all configurations",
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(key: :provisioning_profile,
                                       env_name: "PROVISIONING_PROFILE",
                                       description: "Provisioning profile",
                                       optional: false,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        [:ios, :mac].include?(platform)
      end
    end
  end
end
