defmodule SentinelTest do
  use Sentinel.UnitCase
  import CompileTimeAssertions
  alias Mix.Config

  test "when using API in router, when using invitable, without configuring the invitable module" do
    Config.persist([sentinel: [invitable: true]])
    Config.persist([sentinel: [invitation_registration_url: nil]])

    assert_compile_time_raise RuntimeError, "Must configure :sentinel :invitation_registration_url when using sentinel invitable API", fn ->
      require Sentinel
      Sentinel.mount_api
    end

    Config.persist([sentinel: [invitable: false]])
  end

  test "should raise when router helper (router) isn't configured" do
    Config.persist([sentinel: [router: nil]])
    Config.persist([sentinel: [endpoint: Sentinel.Endpoint]])

    assert_compile_time_raise RuntimeError, "Must configure :sentinel :router", fn ->
      require Sentinel
      Sentinel.mount_ueberauth
    end

    Config.persist([sentinel: [router: Sentinel.TestRouter]])
  end

  test "should raise when router helper (endpoint) isn't configured" do
    Config.persist([sentinel: [endpoint: nil]])
    Config.persist([sentinel: [router: Sentinel.TestRouter]])

    assert_compile_time_raise RuntimeError, "Must configure :sentinel :endpoint", fn ->
      require Sentinel
      Sentinel.mount_ueberauth
    end

    Config.persist([sentinel: [endpoint: Sentinel.Endpoint]])
  end

  test "should raise when send_address isn't configured" do
    Config.persist([sentinel: [router: Sentinel.TestRouter]])
    Config.persist([sentinel: [endpoint: Sentinel.Endpoint]])
    Config.persist([sentinel: [send_address: nil]])

    assert_compile_time_raise RuntimeError, "Must configure :sentinel :send_address", fn ->
      require Sentinel
      Sentinel.mount_ueberauth
    end
    Config.persist([sentinel: [send_address: "test@example.com"]])
  end
end
