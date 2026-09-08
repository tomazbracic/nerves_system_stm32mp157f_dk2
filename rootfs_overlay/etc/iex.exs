NervesMOTD.print()

if RingLogger in Application.get_env(:logger, :backends, []) do
  IO.puts(
    IO.ANSI.light_black() <>
      "RingLogger is collecting log messages from Elixir and Linux. To see the\n" <>
      "temporary messages in the log, run `RingLogger.next` or `RingLogger.viewer`.\n" <>
      "You can also run `log_attach` to be notified of new log messages and `log_detach`\n" <>
      "to go back to only seeing `iex> ` messages.\n" <>
      IO.ANSI.default_color()
  )
end

IO.puts("")
import Toolshed
