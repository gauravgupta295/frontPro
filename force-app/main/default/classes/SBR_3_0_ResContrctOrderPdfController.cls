public with sharing class SBR_3_0_ResContrctOrderPdfController {
    private static final String APINAME = 'Invoices';
    private static final String COMPANY_ID = '01';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);

    private static final String RESERVTION_RECORD_TYPE = 'Reservation Order';
    private static final String LOCKED_RESERVTION_RECORD_TYPE = 'Locked Reservation Order';
    private static final String CONTRACT_RECORD_TYPE ='Contract Order';
    private static final String LOCKED_CONTRACT_RECORD_TYPE ='Locked Contract Order';
    private static final String SALES_RECORD_TYPE ='Sales Order';

    @AuraEnabled
    public static OrderWrapper loadOrderFields(String recordId){
        OrderWrapper orderWrapped = new OrderWrapper();
        Map<Id,String> recordTypeIdsToName = SBR_3_0_RecordTypesForObject.getRecordTypeIdsToName('Order');

        Order order = Database.query('SELECT Id, Reservation_Order_Number__c,RecordTypeId,Contract_Order_Number__c,OrderNumber,RM_Account_Number__c,Company_Code__c,Rentalman_Quote_Id__c  from Order WHERE Id =:recordId WITH SECURITY_ENFORCED LIMIT 1');
        if(order == null ){
            orderWrapped.isValidOrderRecord = 'N';
            return  orderWrapped;
        }
        orderWrapped.orderNumber = order.OrderNumber;
        orderWrapped.seqNum = '0';
        orderWrapped.companyId = order.Company_Code__c;

        if(recordTypeIdsToName.containsKey(order.RecordTypeId) && (recordTypeIdsToName.get(order.RecordTypeId) == RESERVTION_RECORD_TYPE
            || recordTypeIdsToName.get(order.RecordTypeId) == LOCKED_RESERVTION_RECORD_TYPE 
            || recordTypeIdsToName.get(order.RecordTypeId) == CONTRACT_RECORD_TYPE 
            || recordTypeIdsToName.get(order.RecordTypeId) == LOCKED_CONTRACT_RECORD_TYPE )){

            if(order.Contract_Order_Number__c != null){
                orderWrapped.contractNumber = order.Contract_Order_Number__c;
                orderWrapped.isValidOrderRecord = 'Y';
            }else if (order.Reservation_Order_Number__c != null ){
                orderWrapped.contractNumber = order.Reservation_Order_Number__c;
                orderWrapped.isValidOrderRecord = 'Y';
            }else if(order.Rentalman_Quote_Id__c != null){
                String quoteRMID = order.Rentalman_Quote_Id__c;
                orderWrapped.contractNumber = quoteRMID.substring(3);
                orderWrapped.isValidOrderRecord = 'Y';
            }else{
                orderWrapped.isValidOrderRecord = 'N';
            }
        }else if(recordTypeIdsToName.containsKey(order.RecordTypeId) && (recordTypeIdsToName.get(order.RecordTypeId) == SALES_RECORD_TYPE)){
            if(order.Contract_Order_Number__c != null){
                orderWrapped.contractNumber = order.Contract_Order_Number__c;
                orderWrapped.isValidOrderRecord = 'Y';
            }else{
                orderWrapped.isValidOrderRecord = 'N';
            }
            orderWrapped.seqNum = '1';
        }
        else{
            orderWrapped.isValidOrderRecord = 'N';
        }
        return orderWrapped;
    }

    @AuraEnabled(cacheable=false)
    public static WrappedResponse buildRequest(String rentanlManId, String companyCode, String seqNum){
        try {
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            if(String.isEmpty(companyCode)){
                companyCode = COMPANY_ID;
            }
            WrappedResponse response = new WrappedResponse();
                     
            HttpRequest req = httpCallout.getRequest();
            req.setMethod('GET');
            req.setEndpoint(req.getEndpoint()+'/'+rentanlManId+'?sequence='+seqNum);
            req.setHeader('companyId', companyCode);
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', 'application/pdf');  
            req.setTimeout(120000);
			
            Http http = new Http();
            
            HTTPResponse res = http.send(req);
            
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();

            if((res.getStatusCode() == 200 || res.getStatus()== 'OK') &&(response.body.startsWith('%PDF') || res.getHeader('Content-Type').contains('application/pdf'))){
                response.status = 'Complete';
                response.base64Body = EncodingUtil.base64encode(res.getBodyAsBlob());
            }else {
                response.status = 'InComplete';
            }
            return response;      
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class OrderWrapper{
        
        @AuraEnabled
        public String orderNumber{get;set;}
        @AuraEnabled
        public String contractNumber{get;set;}
        @AuraEnabled
        public String isValidOrderRecord{get;set;}
        @AuraEnabled
        public String companyId{get;set;}
        @AuraEnabled
        public String seqNum{get;set;}
        public OrderWrapper(){
        }
    }

    public class WrappedResponse{
        @AuraEnabled
        public string body{get;set;}
        @AuraEnabled
        public string status{get;set;} 
        @AuraEnabled
        public list<String> headers{get;set;}
        @AuraEnabled
        public string base64Body{get;set;}
    }
}