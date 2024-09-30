@RestResource(urlMapping='/Conversion/ApiCreate/v1/*')
global with sharing class SBR_3_0_API_Create_ConversionLog {
    @HttpPost
    global static void create() {
        System.debug('In API ' + RestContext.request.requestBody.toString());

        RestRequest req = RestContext.request;
        Savepoint sp = Database.setSavepoint();

        try {
            RequestBody reqBody = (RequestBody)JSON.deserialize(req.requestBody.toString(), RequestBody.class);
            Conversion_Log__c cLog = new Conversion_Log__c();
            cLog.Type__c = reqBody.conversionType;
            cLog.Payload__c = String.Valueof(reqBody);
            cLog.Event__c = reqBody.event;

            if(reqBody.conversionType == 'CatClass' || reqBody.conversionType == 'ItemClass') {
                cLog.Old_Value__c = String.Valueof(getProduct(reqBody.oldValue, reqBody.conversionType));
                cLog.New_Value__c = String.Valueof(getProduct(reqBody.newValue, reqBody.conversionType));
                insert cLog;
                SBR_3_0_ItemProductUpdateHelper prouctUptHelper = new SBR_3_0_ItemProductUpdateHelper(cLog.Old_Value__c, cLog.New_Value__c, cLog);
                prouctUptHelper.run();
            }
            else if(reqBody.conversionType == 'Account') {
                Map<String,Id> accValues = getAccount(reqBody.oldValue,reqBody.newValue);
                cLog.Old_Value__c = accValues.get('old');
                cLog.New_Value__c = accValues.get('new');
                insert cLog;
                SBR_3_0_AccountConversionMergeHelper.mergeAccounts(cLog.Old_Value__c, cLog.New_Value__c, cLog);
            }
            
            Map<String,String> respMap = new Map<String,String>();         
            respMap.put('Status', 'Success');
            Integer statusCode = 200;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);

        }
        catch (Exception error) {
            Database.rollback(sp);
            system.debug('Error: ' + error.getMessage() + ' - ' + error.getStackTraceString());
            Map<String,String> respMap = new Map<String,String>();
            respMap.put('Status', 'Error');
            respMap.put('Message', error.getMessage() + ' | ' + error.getStackTraceString());
            Integer statusCode = 400;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
            SBR_3_0_LogException.LogIt(error, '', req.requestBody.toString());
            
        }
    }

    public static void logError(Id clogId, String errorMsg){
        Conversion_Log__c clog = [SELECT ID, Error_Message__c FROM Conversion_Log__c WHERE Id =: clogId];
        if(clog <> null){
            clog.Error_Message__c += ' ' + errorMsg;
            update clog;
        }
    }
    
    public class RequestBody {
        public String conversionType {get;set;}
        public Values oldValue {get;set;}
        public Values newValue {get;set;}
        public String eventDate{get;set;}
        public String event{get;set;}
        
    }

    public class values {
		public String itemNumber;
		public String stockClass;
		public String companyCode;
		public String accountNumber;
		public String catClass;
	}

    public static Id getProduct(Values vs, String conversionType) {
        List<Product2> prodList = new List<Product2>();
    
        if(conversionType == 'CatClass') {
            Map<String, Product2> catClassProduct = SBR_3_0_ProductDA.getProductByExternalId(new Set<String>{vs.catClass});
            for(Product2 p: catClassProduct.values()) {
                prodList.add(p);
            }
        }
        else if(conversionType == 'ItemClass') {
            Map<String, Product2> itemClassProduct = SBR_3_0_ProductDA.getItemClassProduct(vs.itemNumber, vs.stockClass, vs.companyCode);
            for(Product2 p: itemClassProduct.values()) {
                prodList.add(p);
            }
        }


        if(!prodList.isEmpty()) {
            return prodList[0].Id;
        }
        else {
            return null;
        }
    }

    public static Map<String,Id> getAccount(Values oldValue, Values newValue) {
        List<Account> accList = new List<Account>();
        Map<String,Id> retAcc = new Map<String,Id>();
        Set<String> rmAccSet = new Set<String>();
        rmAccSet.add(oldValue.accountNumber);
        rmAccSet.add(newValue.accountNumber);

        for(Account a: SBR_3_0_AccountDA.getAccountsByRMNumbers(rmAccSet).values()) {
            if(a.RM_Account_Number__c == oldValue.accountNumber){
                retAcc.put('old',a.Id );
            }
            else if(a.RM_Account_Number__c == newValue.accountNumber){
                retAcc.put('new',a.Id );
            }
        }
        
        return retAcc;
    }

}