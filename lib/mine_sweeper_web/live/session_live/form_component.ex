defmodule MineSweeperWeb.SessionLive.FormComponent do
  use MineSweeperWeb, :live_component

  alias MineSweeper.Game

  def handle_event("start", %{"session" => session_params}, socket) do
    save_session(socket, socket.assigns.action, session_params)
  end

  defp save_session(socket, :new, session_params) do
    case Game.create_session(session_params) do
      {:ok, _session} ->
        {:noreply,
         socket
         |> put_flash(:info, "Session created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, _} ->
        {:noreply, put_flash(socket, :warn, "Failed to create session")}
    end
  end
end
