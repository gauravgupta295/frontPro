public with sharing class PPA_TransportationLWCController {
    @AuraEnabled(cacheable=true)
    public static List<PPA_Transportation__c> getRecords(Id priceListId, String transType) {
        return [SELECT Id,Name,CurrencyIsoCode,
                       PPA_Price_List__c,
                       PPA_Customer__c,
                       PPA_ExternalId__c,
                       PPA_New_Band1__c,
                       PPA_New_Band2__c,
                       PPA_New_Band3__c,
                       PPA_New_Band4__c,
                       PPA_New_Excess__c,
                       PPA_Old_Band1__c,
                       PPA_Old_Band2__c,
                       PPA_Old_Band3__c,
                       PPA_Old_Band4__c,
                       PPA_Old_Excess__c,
                       PPA_Rates_Loaded__c,
                       PPA_Transportation_Type__c,
                       PPA_Truck_Type__c,
                       PPA_Transportation_Rate_Summary__c
                  FROM PPA_Transportation__c
                 WHERE PPA_Price_List__c = :priceListId
                   AND PPA_Transportation_Type__c = :transType
            	];
    }

    @AuraEnabled
    public static void clearTransportationRates(List<Id> recordIds) {
        List<PPA_Transportation__c> transRecs = new List<PPA_Transportation__c>();

        try {
            for(Id recordId : recordIds) {
                transRecs.add(new PPA_Transportation__c(
                                                        Id=recordId, 
                                                        PPA_New_Band1__c=null, 
                                                        PPA_New_Band2__c=null,
                                                        PPA_New_Band3__c=null,
                                                        PPA_New_Band4__c=null,
                                                        PPA_New_Excess__c=null,
                                                        PPA_Rates_Loaded__c=false
                                                        )
                            );
            }

            if(transRecs.size() > 0) {
                update transRecs;
            }            
        }
        catch (Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_TransportationLWCController');
            exceptionParams.put('MethodName', 'clearTransportationRates');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);

            if(!Test.isRunningTest()) {
	            throw new AuraHandledException(e.getMessage());                
            }
        }
    }
}