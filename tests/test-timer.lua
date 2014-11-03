return require('lib/tap')(function (test)

  -- This tests using timers for a simple timeout.
  -- It also tests the handle close callback and
  -- makes sure self is passed in properly to callbacks.
  test("simple timeout", function (print, p, expect, uv)
    local timer = uv.new_timer()
    local function onclose(self)
      assert(self == timer)
      p("closed", timer)
    end
    local function ontimeout(self)
      assert(self == timer)
      p("timeout", timer)
      uv.close(timer, expect(onclose))
    end
    uv.timer_start(timer, 10, 0, expect(ontimeout))
  end)

  -- This is like the previous test, but using repeat.
  test("simple interval", function (print, p, expect, uv)
    local timer = uv.new_timer()
    local count = 3
    local onclose = expect(function (self)
      assert(self == timer)
      p("closed", timer)
    end)
    local function oninterval(self)
      assert(self == timer)
      p("interval", timer)
      count = count - 1
      if count == 0 then
        uv.close(timer, onclose)
      end
    end
    uv.timer_start(timer, 10, 10, oninterval)
  end)

  -- Test two concurrent timers
  -- There is a small race condition, but there are 50ms of wiggle room.
  -- 250ms is halfway between 2x100ms and 3x100ms
  test("timeout with interval", function (print, p, expect, uv)
    local a = uv.new_timer()
    local b = uv.new_timer()
    uv.timer_start(a, 250, 0, expect(function ()
      p("timeout", a)
      uv.timer_stop(b)
      uv.close(a)
      uv.close(b)
    end))
    uv.timer_start(b, 100, 100, expect(function ()
      p("interval", b)
    end, 2))
  end)

  -- This advanced test uses the rest of the uv_timer_t functions
  -- to create an interval that shrinks over time.
  test("shrinking interval", function (print, p, expect, uv)
    local timer = uv.new_timer()
    uv.timer_start(timer, 10, 0, expect(function ()
      local r = uv.timer_get_repeat(timer)
      p("interval", timer, r)
      if r == 0 then
        uv.timer_set_repeat(timer, 8)
        uv.timer_again(timer)
      elseif r == 2 then
        uv.timer_stop(timer)
        uv.close(timer)
      else
        uv.timer_set_repeat(timer, r / 2)
      end
    end, 4))
  end)

end)