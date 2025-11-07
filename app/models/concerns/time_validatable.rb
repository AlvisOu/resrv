module TimeValidatable
    extend ActiveSupport::Concern

    private

    def end_time_after_start_time
        return if start_time.blank? || end_time.blank?

        if end_time <= start_time
            errors.add(:end_time, "must be after the start time")
        end
    end
end