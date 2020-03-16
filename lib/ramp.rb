require "pry"

class Ramp
  FREE_SECONDS = 3600
  SECONDS_AFTER_PAYMENT = 600
  REQUESTS_OVERLOAD_PARAMETERS = { consequent_requests_count: 4, max_seconds_between_requests: 30 }

  attr_writer :completed_sessions

  def initialize
    @completed_sessions = []
  end

  def complete_parking_session!(parking_session)
    condition_met = parking_session.free_exit? ||
        parking_session.paid? && (within_time_limit?(parking_session) || request_overload?)

    mark_completed!(parking_session) if condition_met
  end

  private

  def mark_completed!(parking_session)
    parking_session.completed!
    @completed_sessions << parking_session
  end

  def within_time_limit?(parking_session)
    Time.now <= parking_session.paid_at + SECONDS_AFTER_PAYMENT
  end

  def request_overload?
    return false if @completed_sessions.empty?

    last_parking_sessions = @completed_sessions.sort_by { |s| s.exit_at }
        .reverse.last(REQUESTS_OVERLOAD_PARAMETERS[:consequent_requests_count])

    last_exit_at = nil

    conditions_met = last_parking_sessions.map do |ps|
      if last_exit_at.nil?
        last_exit_at = ps.exit_at
        Time.now <= ps.exit_at + REQUESTS_OVERLOAD_PARAMETERS[:max_seconds_between_requests]
      else
        overloaded = last_exit_at <= ps.exit_at + REQUESTS_OVERLOAD_PARAMETERS[:max_seconds_between_requests]
        last_exit_at = ps.exit_at
        overloaded
      end
    end

    !conditions_met.include?(false)
  end
end
