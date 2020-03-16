class ParkingSession
  attr_reader :free_seconds, :paid_at, :exit_at
  attr_writer :paid_at

  def initialize(attributes = {})
    @entry_at = attributes[:entry_at]
    @free_seconds = Ramp::FREE_SECONDS
    @paid_at = attributes[:paid_at]
    @exit_at = attributes[:exit_at]
  end

  def completed?
    !@exit_at.nil?
  end

  def completed!
    @exit_at = Time.now
  end

  def paid?
    !@paid_at.nil?
  end

  def free_exit?
    Time.now <= @entry_at + @free_seconds
  end
end
