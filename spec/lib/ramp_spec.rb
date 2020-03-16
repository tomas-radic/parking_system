require "ramp"
require "parking_session"

describe Ramp, type: :model do
  describe "#complete_parking_session!" do
    subject(:method_call) { @ramp.complete_parking_session!(@parking_session) }

    before do
      @ramp = described_class.new
    end

    context "Exiting session has free exit" do
      before do
        @parking_session = ParkingSession.new(entry_at: Time.now - (Ramp::FREE_SECONDS) + 5)
      end

      it "Marks given parking_session completed" do
        method_call
        expect(@parking_session.completed?).to be(true)
      end
    end

    context "Exiting session is supposed to have paid" do
      before do
        @parking_session = ParkingSession.new(entry_at: Time.now - Ramp::FREE_SECONDS - 5)
      end

      context "And it has been paid" do
        context "Exiting within after payment time limit" do
          before do
            @parking_session.paid_at = Time.now - Ramp::SECONDS_AFTER_PAYMENT + 5
          end

          it "Marks given parking_session completed" do
            method_call
            expect(@parking_session.completed?).to be(true)
          end
        end

        context "Exiting exceeding after payment time limit" do
          before do
            @parking_session.paid_at = Time.now - Ramp::SECONDS_AFTER_PAYMENT - 5
          end

          context "When there is overload of requests" do
            before do
              @current_time = Time.now
              @previous_session1 = ParkingSession.new(
                  exit_at: @current_time - Ramp::REQUESTS_OVERLOAD_PARAMETERS[:max_seconds_between_requests] + 5)
              @previous_session2 = ParkingSession.new(
                  exit_at: @previous_session1.exit_at - Ramp::REQUESTS_OVERLOAD_PARAMETERS[:max_seconds_between_requests] + 5)
              @previous_session3 = ParkingSession.new(
                  exit_at: @previous_session2.exit_at - Ramp::REQUESTS_OVERLOAD_PARAMETERS[:max_seconds_between_requests] + 5)
              @previous_session4 = ParkingSession.new(
                  exit_at: @previous_session3.exit_at - Ramp::REQUESTS_OVERLOAD_PARAMETERS[:max_seconds_between_requests] + 5)
              @ramp.completed_sessions = [
                  @previous_session1, @previous_session2, @previous_session3, @previous_session4
              ]
            end

            it "Marks given parking_session completed" do
              method_call
              expect(@parking_session.completed?).to be(true)
            end
          end

          context "When there is NOT overload of requests" do
            it "Does not mark given parking_session completed" do
              method_call
              expect(@parking_session.completed?).to be(false)
            end
          end
        end
      end

      context "And it has not been paid" do
        context "Exiting within time limit" do
          it "Does not mark given parking_session completed" do
            method_call
            expect(@parking_session.completed?).to be(false)
          end
        end
      end
    end
  end
end
