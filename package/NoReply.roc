import Command

## An explicitly unchecked plan for a connection already configured to suppress
## these replies. Ordinary Request values cannot be passed to Execute.no_reply!.
## This type cannot prove server state; establishing that state is the caller's
## responsibility. A successful write does not acknowledge server execution.
NoReply :: { commands : List(Command.Command) }.{

	## Escape hatch: every command here must produce zero replies on this stream.
	## Do not use for commands that reply and subsequently close the connection.
	unsafe_assume_suppressed : List(Command.Command) -> NoReply
	unsafe_assume_suppressed = |commands| NoReply.{ commands: commands }

	commands : NoReply -> List(Command.Command)
	commands = |plan| plan.commands
}
