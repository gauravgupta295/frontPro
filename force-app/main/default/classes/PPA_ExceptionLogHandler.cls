public class PPA_ExceptionLogHandler {
    public static void createExceptionLog(Map<String,String> exceptionParams) {
        List<Exception_Log__c> exceptions = new List<Exception_Log__c>();

        exceptions.add(new Exception_Log__c(Class_Name__c=exceptionParams.get('ClassName'),
                                            Exception_Message__c=exceptionParams.get('Message'),
                                            Exception_Type__c=exceptionParams.get('Type'),
                                            Govt_Limit_in_Executing_Code__c=exceptionParams.get('Limit'),
                                            Line_Number__c=Integer.valueOf(exceptionParams.get('LineNumber')),
                                            Method_Name__c=exceptionParams.get('MethodName'),
                                            Stack_Trace__c=exceptionParams.get('StackTrace')
        ));

        insert exceptions;
    }
}