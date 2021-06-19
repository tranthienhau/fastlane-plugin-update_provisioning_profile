describe Fastlane::Actions::UpdateProvisioningProfileAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The update_provisioning_profile plugin is working!")

      Fastlane::Actions::UpdateProvisioningProfileAction.run(nil)
    end
  end
end
