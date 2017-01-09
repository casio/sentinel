defmodule Sentinel.Controllers.Html.AuthController do
  @moduledoc """
  Handles the session create and destroy actions
  """

  require Ueberauth
  use Phoenix.Controller
  alias Plug.Conn
  alias Sentinel.AfterRegistrator
  alias Sentinel.Config
  alias Sentinel.Ueberauthenticator
  alias Sentinel.UserHelper
  alias Sentinel.Util
  alias Ueberauth.Strategy.Helpers

  plug Ueberauth
  plug Guardian.Plug.VerifyHeader when action in [:delete]
  plug Guardian.Plug.EnsureAuthenticated, %{handler: Config.auth_handler} when action in [:delete]
  plug Guardian.Plug.LoadResource when action in [:delete]

  def new(conn, _params) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})
    render(conn, Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end

  #FIXME wtf does this do in the example app
  def request(conn, _params) do
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    Util.send_error(conn, %{error: "Failed to authenticate"}, 401)
  end
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Ueberauthenticator.ueberauthenticate(auth) do
      {:ok, %{user: user, confirmation_token: confirmation_token}} ->
        new_user(conn, user, confirmation_token)
      {:ok, user} -> existing_user(conn, user)
      {:error, errors} ->
        changeset = Sentinel.Session.changeset(%Sentinel.Session{})
        render(conn, Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
    end
  end

  defp new_user(conn, user, confirmation_token) do
    # FIXME ensure we don't login invited users.
    {:ok, _} = AfterRegistrator.confirmable_and_invitable(user, confirmation_token)

    conn
    |> Guardian.Plug.sign_in(user)
    |> put_flash(:info, "Signed up")
    |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
  end

  defp existing_user(conn, user) do
    permissions = UserHelper.model.permissions(user.id)

    conn
    |> Guardian.Plug.sign_in(user)
    |> put_flash(:info, "Logged in")
    |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
  end

  @doc """
  Destroy the active session.
  Will delete the authentication token from the user table.
  """
  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/")
  end

  @doc """
  Log in as an existing user.
  """
  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    auth = %Ueberauth.Auth{
      provider: :identity,
      credentials: %Ueberauth.Auth.Credentials{
        other: %{
          password: password
        }
      },
      uid: email
    }

    case Ueberauthenticator.ueberauthenticate(auth) do
      {:ok, user} ->
        permissions = UserHelper.model.permissions(user.id)

        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Logged in")
        |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
      {:error, errors} ->
        conn
        |> put_flash(:error, "Unknown username or password")
        |> redirect(to: Config.router_helper.auth_path(Config.endpoint, :new))
    end
  end
end
