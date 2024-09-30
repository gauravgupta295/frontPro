public with sharing class PPA_ExportPriceListsToCSV {
    
    public class customException extends Exception {}
    
    @AuraEnabled
    public static Integer exportSelectedPriceLists(List<String> priceListIds){
        List<PPA_Price_List__c> PriceList = new List<PPA_Price_List__c>();

        try {
            //Query price list to fetch Verification Status & Id In PriceListId.
            PriceList = [SELECT Id, RecordType.DeveloperName, CurrencyIsoCode, PPA_Customer_No__c, PPA_Rate_Type__c, PPA_CompanyId__c,
                                PPA_Start_Date__c, PPA_End_Date__c, PPA_Export_Status__c, PPA_Rate_Load_Scope__c, PPA_Regions__c,
                                PPA_Customer_Name__c, Owner.Name, PPA_ManagerId__r.Name, PPA_RA_Improvement__c  
                           FROM PPA_Price_List__c
                          WHERE PPA_Verification_Status__c IN ('Verified', 'Overridden')
                            AND Id IN :priceListIds];

            if(PriceList.size() > 0) {
                //Adding price list records into PriceListMaP
                for(PPA_Price_List__c Plist : PriceList){
					Plist.PPA_Export_Status__c = 'Scheduled';
                }

                update PriceList;
                
                // Submit the batch job to process the records and send email, etc.
                PPA_ExportPriceListsToCSVBatch batchJob = new PPA_ExportPriceListsToCSVBatch();
				Database.executeBatch(batchJob);
            }
            else {
                throw new customException('No Price Lists in the list matched the expected criteria');
            }
        }
        catch(Exception e) {            
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_ExportPriceListsToCSV');
            exceptionParams.put('MethodName', 'exportSelectedPriceLists');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
    
            if(!Test.isRunningTest()) {
                throw new AuraHandledException(e.getMessage());                
            }    
        }                   
        
        return PriceList.size();
    }
}