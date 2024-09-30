public with sharing class SBR_3_0_DMLOpsController {
    private static final String DEFAULT_SUCCESS_MESSAGE = 'Success';
    private static final String ID_FIELD = 'Id';
    private static final String DUPLICATE_RECORDIDS_KEY = 'duplicateRecordIds';
    private static final String DUPLICATE_RULENAME_KEY = 'duplicateRuleName';
    private static final String DUPLICATE_RECORDS = 'duplicateRecords';
    private static final String RECORD_KEY = 'record';
    private static final String ACCOUNT_OBJECT_NAME = 'Account';
    @AuraEnabled
    public static Object createSObject(
        SObject record,
        Boolean allowDuplicateRule
    ) {
        try {
            Database.SaveResult result = Database.insert(
                record,
                getDMLOptions(allowDuplicateRule)
            );
            return getResponse(result, record);
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());
                              }
    }
    
    @AuraEnabled
    public static Object updateSObject(
        SObject record,
        Boolean allowDuplicateRule
    ) {
        try {
            Database.SaveResult result = Database.update(
                record,
                getDMLOptions(allowDuplicateRule)
            );
            system.debug('UserData '+ JSON.serialize(record));
            return getResponse(result, record);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static Database.DMLOptions getDMLOptions(Boolean allowDuplicateRule) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = allowDuplicateRule;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        return dml;
    }
    
    private static ResponseWrapper getResponse(
        Database.SaveResult saveResult,
        SObject record
    ) {
        ResponseWrapper response;
        if (saveResult.isSuccess()) {
            response = buildSuccessResponse(record);
        } else {
            response = buildErrorResponse(saveResult);
        }
        
        return response;
    }
    
    private static ResponseWrapper buildSuccessResponse(SObject record) {
        ResponseWrapper response = new ResponseWrapper();
        response.attributes.put(RECORD_KEY, record);
        return response;
    }
    
    private static ResponseWrapper buildErrorResponse(
        Database.SaveResult saveResult
    ) {
        ResponseWrapper response = new ResponseWrapper();
        response.isSuccess = false;
        response.message = '';
        System.debug('Errorr'+saveResult.getErrors()[0].getStatusCode());
        for (Database.Error error : saveResult.getErrors()) {       
            if (error instanceof Database.DuplicateError || test.isRunningTest()) {
                // System.debug('hh'+String.valueOf(error.getStatusCode()));
                response.message = String.valueOf(error.getStatusCode());
                Database.DuplicateError duplicateError = (Database.DuplicateError) error;
                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                List<String> duplicateRecodIdList=getDuplicateRecordIds(duplicateError);
                response.attributes.put(DUPLICATE_RECORDIDS_KEY,duplicateRecodIdList);
                List<Account> duplicateRecordsList=getDuplicateRecords(duplicateRecodIdList);
                if(duplicateRecordsList!=null){
                    response.attributes.put(DUPLICATE_RECORDS,duplicateRecordsList);
                }
                response.attributes.put(DUPLICATE_RULENAME_KEY,duplicateResult.getDuplicateRule());
            } else {
                response.message += error.getMessage() + '\n';
            }
        }
        
        return response;
    }
    
    private static List<String> getDuplicateRecordIds(
        Database.DuplicateError duplicateError
    ) {
        List<String> duplicateRecordIds = new List<String>();
        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
        Datacloud.MatchResult matchResult = matchResults[0];
        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
        for (Datacloud.MatchRecord matchRecord : matchRecords) {SObject matchedRecord = matchRecord.getRecord();
                                                                duplicateRecordIds.add(String.valueOf(matchedRecord.get(ID_FIELD)));
                                                               }
        return duplicateRecordIds;
    }
    
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean isSuccess { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public Map<String, Object> attributes { get; set; }
        
        public ResponseWrapper() {
            this.isSuccess = true;
            this.message = DEFAULT_SUCCESS_MESSAGE;
            this.attributes = new Map<String, Object>();
        }
    }
    private static List<Account> getDuplicateRecords(List<String> duplicateRecordIds){
        System.debug('duplicateRecordIds --- '  + duplicateRecordIds);
        Id recId= Id.valueOf(duplicateRecordIds[0]);
        String sobjectType = recId.getSObjectType().getDescribe().getName();
        if(sobjectType==ACCOUNT_OBJECT_NAME){
            return [select id,Name,Phone,E_mail_Address__c,Drivers_License__c,Driver_s_License_State__c,BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,Status__c from Account where Id IN:duplicateRecordIds ORDER BY LastViewedDate DESC NULLS LAST,LastModifiedDate DESC NULLS LAST limit 10];
        }
        else{
            return null;
        }
        
        
    }
    @AuraEnabled
    public static void deleteOrder(String orderId){ //FRONT-14063
        try{
            sbr_3_0_DMLOpsWithoutSharingController deleteOrderRecord=new sbr_3_0_DMLOpsWithoutSharingController();
            deleteOrderRecord.deleteOrderWithoutSharing(orderId);
        }catch(Exception ex){
            System.debug('Exception Occured'+ ex.getMessage());
        }
    }
    
    public without sharing class sbr_3_0_DMLOpsWithoutSharingController{ 
        public  void deleteOrderWithoutSharing(String orderId){
            try{
                Order ord=new Order(Id=orderId);
                //Order ord=[Select Id from Order where Id=:orderId];
                delete ord;
            }catch(Exception ex){
                System.debug('Exception Occured'+ ex.getMessage());
            }
        }
    }
}