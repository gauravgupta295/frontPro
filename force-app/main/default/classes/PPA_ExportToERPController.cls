public with sharing class PPA_ExportToERPController {

    public class customException extends Exception {}
    
    @AuraEnabled(cacheable=true)
    public static List<PPA_Price_List__c> getItemsReadyForExport() {
        return [SELECT Id, Name, PPA_Customer_Name__c, PPA_Customer_No__c, PPA_Record_Type_Name__c, PPA_Verification_Status__c, 
                       PPA_Status__c, PPA_Free_Rental__c, PPA_Free_Transportation__c, PPA_Export_Status__c
                  FROM PPA_Price_List__c 
                 WHERE RecordType.DeveloperName IN ('PPA_Renewal','PPA_Extension')
                   AND PPA_Visible__c = true
                   AND PPA_Export_Status__c = 'Ready'];
    }

    @AuraEnabled
    public static void overrideVerificationStatus(String priceListId, String overrideReason) {
        try {
        	// Query the Price List where Id = Price List Id 
            List<PPA_Price_List__c> priceList = [SELECT Id, PPA_Verification_Status__c, PPA_Export_Override_Comments__c
                                                   FROM PPA_Price_List__c
                                                  WHERE Id = :priceListId];
            
            if(priceList.size() > 0) {
                // Set Verification Status = Overridden if it's Currently Unverified
                if(priceList[0].PPA_Verification_Status__c == 'Unverified') {
                    priceList[0].PPA_Verification_Status__c = 'Overridden';
                    // Set Export Override Comments = comments
                    priceList[0].PPA_Export_Override_Comments__c = overrideReason;
                    // Update Price List
                    update priceList;    
                }
            }
            else {
            	// Handle the case when the Price List is not found.
                throw new customException('Price List not found with the given Id.');                    
            }
        } catch(Exception e) {
        	// Handle any exceptions that occur during the update process.
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_ExportToERPController');
            exceptionParams.put('MethodName', 'overrideVerificationStatus');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);

            if(!Test.isRunningTest()) {
            	throw new AuraHandledException('An error occurred while updating the Price List: ' + e.getMessage());                
            }
        }
    }
}