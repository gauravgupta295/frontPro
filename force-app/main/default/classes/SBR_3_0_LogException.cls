public without sharing class SBR_3_0_LogException extends Exception{
    
    public static void LogIt(Exception e) {
        Exception_Log__c exc = createException(e);
        database.insert(exc);  
    }
    
    public static void LogIt(Exception e, String relatedToId) {
        Exception_Log__c exc = createException(e);
        exc.Related_To_Number__c=relatedToId;
        database.insert(exc);       
    } 

    public static void LogIt(Exception e, String relatedToId, String payload) {
        Exception_Log__c exc = createException(e);
        exc.Related_To_Number__c=relatedToId;
        exc.RequestJSON__c = payload;
        database.insert(exc);    
    }

    public static Exception_Log__c createException (Exception e) {
        try {
		    String stackTrace = e.getStackTraceString().substringBefore('\n');
		    String className = stackTrace.substringAfter('.').substringBefore('.');	
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            
            //Governer Limit of executingQuery 
            String queryLimit = 'SOQL: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries();
            String dMLimit = 'Records: ' + Limits.getDmlRows() + ' of ' + Limits.getLimitDmlRows();
            String dMLStat = 'DML Stmts' +  Limits.getDmlStatements() + ' of ' + Limits.getLimitDmlStatements();   
            String cPUT = 'CPU time (in ms): ' + Limits.getCpuTime() + ' of ' + Limits.getLimitCpuTime();
            
            //Log information in object
            Exception_Log__c exc = new Exception_Log__c();
            exc.Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}',new List<Object> {queryLimit, dMLimit, dMLStat, cPUT});
            exc.Exception_Message__c = e.getMessage();
            exc.Exception_Type__c = e.getTypeName();
            exc.Line_Number__c = e.getLineNumber();
            exc.Stack_Trace__c = e.getStackTraceString();
            exc.Method_Name__c= methodName;
            exc.Class_Name__c= className;
            return exc;
        } 
        catch(Exception ex) {
            //do nothing
            return null;
        }

        finally {
        }          
    }

}