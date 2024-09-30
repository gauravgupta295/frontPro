public with sharing class PPA_CatClassMassEditController {
    @AuraEnabled
    public static void applyMassEditUpdates(String newValuesStr) {
        List<PPA_Rental_CatClass__c> catClass = new List<PPA_Rental_CatClass__c>();
        List<Object> newValuesObject;

        try {
            if(!String.isBlank(newValuesStr)) {
                newValuesObject = (List<Object>)JSON.deserializeUntyped(newValuesStr);
                
                for(Integer i=0;i<newValuesObject.size();i++) {
                    Map<String,Object> recMap = (Map<String,Object>)newValuesObject[i];
                    
                    catClass.add(new PPA_Rental_CatClass__c(Id=(Id)recMap.get('recordId'),
                                                            PPA_New_Day__c=Decimal.valueOf((String)recMap.get('newDayValue')),
                                                            PPA_New_Week__c=Decimal.valueOf((String)recMap.get('newWeekValue')),
                                                            PPA_New_Month__c=Decimal.valueOf((String)recMap.get('newMonthValue')),
                                                            PPA_UpdatedBy_Mass_Edit__c=true
                                                            ));
                }
    
                if(catClass.size() > 0) {
                    update catClass;
                }                    
            }
        }
        catch (Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_CatClassMassEditController');
            exceptionParams.put('MethodName', 'applyMassEditUpdates');
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