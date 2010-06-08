class Waiter
  class TimeoutError < Exception; end

  def initialize
    @fired = false
  end

  def fire
    @fired = true
    Thread.pass
  end

  def wait(timeout = 5)
    started_at = Time.now
    while Time.now <= started_at + timeout
      if @fired
        return
      else
        Thread.pass
      end
    end

    raise TimeoutError
  end
end