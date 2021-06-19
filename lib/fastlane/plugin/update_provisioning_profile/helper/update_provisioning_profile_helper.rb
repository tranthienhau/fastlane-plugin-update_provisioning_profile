require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class UpdateProvisioningProfileHelper
      # class methods that you define here become available in your action
      # as `Helper::UpdateProvisioningProfileHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the update_provisioning_profile plugin helper!")
      end
    end
  end
end
