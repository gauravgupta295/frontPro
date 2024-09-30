public without sharing class LogEntryEventTriggerHandler {
    
    public static void insertExceptionLogs(List<LogEntryEvent__e> logEntryEvents){
        
        
        List<Exception_Log__c> logsLst=new List<Exception_Log__c>();
    
        // Iterate through each notification.
        for (LogEntryEvent__e event : logEntryEvents) {
        
            Exception_Log__c log=new Exception_Log__c();
            log.AsyncJobId__c = event.AsycJobId__c;
            log.Class_Name__c = event.Class__c;
            log.Line_Number__c = event.LineNumber__c;
            log.Exception_Message__c = event.Message__c;
            log.Method_Name__c = event.Method__c;
            log.RecordID__c = event.RecordID__c;
            log.RequestJSON__c = event.RequestJSON__c;
            log.ResponseJSON__c = event.ResponseJSON__c;
            log.Stack_Trace__c = event.StackTrace__c;
            log.StatusCode__c = event.StatusCode__c;
            log.Type__c = event.Type__c;
            log.ownerId = event.User__c;
            log.Path__c = event.Path__c;
            log.PlatformEventRaisedTime__c = System.now();
            logsLst.add(log);
        }
        
       Logger.commitLogsInDatabase(logsLst);
    }

}