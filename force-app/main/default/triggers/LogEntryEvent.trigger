trigger LogEntryEvent on LogEntryEvent__e (after insert) {
	LogEntryEventTriggerHandler.insertExceptionLogs(Trigger.new);
}