public without sharing class SBR_3_0_Log {
                    
    /*
    Set the related record for logger. This is used in cases where the record ID may not be available at the point where logging occurs.
    */
    public static Id relatedRecordId;
    public static void setRelatedRecordId(Id relatedRecordId) {
        SBR_3_0_Log.relatedRecordId = relatedRecordId;
    }
    
    /*
    Log exception to Logger.
    */
    public static void logException(System.Exception caughtException) {
        // Log to Logger
        if (caughtException != null) {
            Logger.error(caughtException, SBR_3_0_Log.relatedRecordId);
        }
    }
    
    /*
    Log Debug to Logger.
    */
    public static void logInfo(String message) {
        // Log to Logger
        if (message != null) {
            Logger.debug(message, SBR_3_0_Log.relatedRecordId);
        }
    }
    
    /*
    Log API Details to Logger.
    */
    public static void logAPIDetails(String requestBody, String responseBody) {
        logAPIDetails(requestBody, responseBody,null);
    }
    
    public static void logAPIDetails(String requestBody, String responseBody,String message) {  
        Logger.calloutLog(message,null,SBR_3_0_Log.relatedRecordId,null,requestBody,responseBody,null);
    }
    
    public static void saveLog(){
        try{
            Logger.saveLog();
        }
        catch(System.Exception e){
            System.debug('Logger.saveLog() failed: ' + e.getMessage());
        }
    }
}