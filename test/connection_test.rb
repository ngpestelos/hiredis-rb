require 'test/unit'
require 'rubygems'
require 'hiredis'

class ConnectionTest < Test::Unit::TestCase
  def setup
    @conn = Hiredis::Connection.new
  end

  def test_connect_wrong_host
    assert_raise RuntimeError, /can't resolve/i do
      @conn.connect("nonexisting", 6379)
    end
  end

  def test_connect_wrong_port
    assert_raise Errno::ECONNREFUSED do
      @conn.connect("localhost", 6380)
    end
  end

  def test_connected?
    assert !@conn.connected?
    @conn.connect("localhost", 6379)
    assert @conn.connected?
    @conn.disconnect
    assert !@conn.connected?
  end

  def test_read_when_disconnected
    assert_raise RuntimeError, "not connected" do
      @conn.read
    end
  end

  def test_timeout_when_disconnected
    assert_raise RuntimeError, "not connected" do
      @conn.timeout = 1
    end
  end

  def test_wrong_value_for_timeout
    @conn.connect("localhost", 6379)
    assert_raise RuntimeError, /setsockopt/ do
      @conn.timeout = -10
    end
  end

  def test_read_against_eof
    @conn.connect("localhost", 6379)
    @conn.write(["QUIT"])
    assert_equal "OK", @conn.read

    assert_raise Errno::ECONNRESET do
      @conn.read
    end
  end

  def test_read_against_timeout
    @conn.connect("localhost", 6379)
    @conn.timeout = 10_000

    assert_raise Errno::EAGAIN do
      @conn.read
    end
  end
end
