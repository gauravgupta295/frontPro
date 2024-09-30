public class sbr_3_0_drfDMLServiceDelegator {

    static Map<string,string> objectServiceClassMap;

    static{
        objectServiceClassMap=new map<string,string>();
        objectServiceClassMap.put('Order','SBR_3_0_drfOrderService');
        objectServiceClassMap.put('SBQQ__Quote__c','SBR_3_0_drfQuoteService');
    }

    @AuraEnabled(cacheable=false)
    public static void updateRecord(String objectApiName, SObject fields, String actionType)
    {
		SBR_3_0_drfDMLOpsInterface serviceInterfaceObj = (SBR_3_0_drfDMLOpsInterface) Type.forName(getInstance(objectApiName)).newInstance();
        serviceInterfaceObj.updateRecord(fields, ActionType);
    }

    @AuraEnabled(cacheable=false)
    public static Object submitRecordToRM(String objectApiName, string recordId, string transactionId, string recordDetails)
    {   
        if(objectApiName == 'Order'){
            SBR_3_0_Generic_Callout.sourceTransactionId = transactionId;
            SBR_3_0_OrderServicePayloadGenerator.makeADepositDetails = recordDetails;
        }
		SBR_3_0_drfDMLOpsInterface serviceInterfaceObj = (SBR_3_0_drfDMLOpsInterface) Type.forName(getInstance(objectApiName)).newInstance();
        return serviceInterfaceObj.submitRecord(recordId);
    }

    private static string getInstance(string sObjectName)
    {
        return objectServiceClassMap.get(sObjectName);
    }

}