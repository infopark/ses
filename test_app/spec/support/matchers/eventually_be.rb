class EventuallyBe

  def initialize(expected)
    @expected = expected
    @seconds = 20
  end

  def matches?(event_proc)
    (@seconds + 1).to_i.times do
      @last_result = event_proc.call
      return true if @last_result == @expected
      sleep 1
    end
    false
  end

  def failure_message
    "expected #{@last_result.inspect} to be #{@expected}"
  end

  def failure_message_when_negated
    "expected #{@last_result.inspect} not to be #{@expected}"
  end

  def within(seconds)
    @seconds = seconds
    self
  end

end

def eventually_be(expected)
  EventuallyBe.new(expected)
end
