# frozen_string_literal: true

require_relative "./socat"

RSpec.describe AmstradGpt::Simulation::Socat do
  let(:subject) do
    described_class.new(amstrad_simulated_tty:, mac_simulated_tty:)
  end

  let(:amstrad_simulated_tty) { "/tmp/tty.amstrad_simulated_tty" }
  let(:mac_simulated_tty) { "/tmp/tty.mac_simulated_tty" }

  describe "#setup" do
    context "when socat is installed" do
      before do
        allow(subject).to receive(:socat_installed?).and_return(true)
      end

      context "when socat is correctly set up" do
        it "checks and sets up socat without error" do
          expect(subject).to receive(:check_and_setup_socat).and_return(true)
          expect { subject.setup }.not_to raise_error
        end
      end

      context "when socat setup fails" do
        it "displays a setup failure message and exits" do
          expect(subject).to receive(:check_and_setup_socat).and_return(false)

          expect { subject.setup }.not_to raise_error
        end
      end
    end

    context "when socat is not installed" do
      it "displays an installation message and exits" do
        allow(subject).to receive(:socat_installed?).and_return(false)
        expect(subject).to receive(:socat_install_message).and_call_original
        expect { subject.setup }.to raise_error(SystemExit)
      end
    end
  end

  describe "#socat_installed?" do
    it "checks if socat is installed" do
      expect(subject).to receive(:system).with("which socat > /dev/null 2>&1")
      subject.socat_installed?
    end
  end

  describe "#check_and_setup_socat" do
    before do
      allow(File).to receive(:exist?).with(anything).and_return(true)
    end

    it "prints configuration check message" do
      expect { subject.check_and_setup_socat }.to output(/Checking socat configuration/).to_stdout
    end

    it "returns true after checking configurations" do
      expect(subject.check_and_setup_socat).to be true
    end
  end

  describe "#setup_socat" do
    it "sets up socat and outputs the setup command" do
      allow(subject).to receive(:system).with(anything)
      expect { subject.setup_socat }.to output(/Configuring socat/).to_stdout
      expect { subject.setup_socat }.to output(/socat setup/).to_stdout
    end
  end
end
