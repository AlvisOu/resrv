require 'rails_helper'

RSpec.describe PurgeExpiredHoldsJob, type: :job do
  describe "#perform" do
    it "calls Reservation.notify_and_purge_expired_holds!" do
      expect(Reservation).to receive(:notify_and_purge_expired_holds!)
      described_class.perform_now
    end
  end

  describe "queuing" do
    it "is in the default queue" do
      expect(PurgeExpiredHoldsJob.new.queue_name).to eq('default')
    end

    it "can be enqueued" do
      expect {
        PurgeExpiredHoldsJob.perform_later
      }.to have_enqueued_job(PurgeExpiredHoldsJob).on_queue("default")
    end
  end
end
