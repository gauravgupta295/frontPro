/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_UpdateQuotedParts
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quoted Parts to Rentalman (via Mulesoft) when it is updated in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
*********************************************************************************************************************/

public class SBR_3_0_API_UpdateQuotedParts {
    
    private static final String APINAME = 'Update_Quoted_Parts_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static SyncQuotedPartsWrapper requestBody = new SyncQuotedPartsWrapper();
    private Static String relatedToId;
    
    @InvocableMethod(Label = 'UpdateQuotedPartsRMCallout')
    public static void QuotedPartsCreateRMCallout(List<String> input) {
        
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            createQp(input);
        }
    }
    
    @future(Callout = true)
    private static void createQp(List<String> qpId) {
        try{
            Set<String> qpIdSet = new Set<String>(qpId);
            SF_PS_Quoted_Part__c getQp = SBR_3_0_WorkOrderDA.getQuotedParts(qpIdSet)[0];
			relatedToId = getQp.SF_PS_WorkOrderId__c;        
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getQp.SF_PS_WorkOrderId__r.OwnerId].Wynne_User_Name__c;        
            if(getQp != null){
                generateWrapper(getQp);
            }
            
            String payload = generateJSONPayload();
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();
            String rmWoNumber = getQp.SF_PS_WorkOrderId__r.SF_PS_RM_WO_Number__c?.subStringAfter('-');
            HttpRequest req = httpCallout.getRequest();
            req.setMethod('PUT');
            req.setEndpoint(req.getEndpoint()+ rmWoNumber +'/parts/'+getQp.SF_PS_Quoted_Parts_Line_Num__c);
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('requestTimestamp', String.valueOf(getQp.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
            req.setHeader('sourceSystemUserId', getQp.SF_PS_WorkOrderId__r.Owner.alias);
            req.setHeader('sourceSystemName', 'SalesForce');
            req.setHeader('rentalmanUserId', rentalManUserName);
            req.setHeader('sourceWorkOrderNumber',getQp.SF_PS_WorkOrderId__r.WorkOrderNumber );        
            req.setHeader('requestTimeZone', getQp.SF_PS_WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone);
            req.setHeader('pc', getQp.SF_PS_WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c);
            req.setHeader('companyId', getQp.SF_PS_WorkOrderId__r.SF_PS_Company_Code__c);         
            req.setBody(payload);        
            req.setTimeout(119000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();        
            if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
                response.status = 'Complete';
            }else{
                System.debug ('Update callout not successfull');
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request - ' + payload + ' ' +' Response '+response.body;
                exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c= 'createQp';
                exc.RequestJSON__c= payload;
                exc.ResponseJSON__c = response.body;
                exc.RecordID__c = getQp.id;
				exc.Related_To_Number__c=getQp.SF_PS_WorkOrderId__c;
                exc.Class_Name__c= 'SBR_3_0_API_UpdateQuotedParts';
                exc.Stack_Trace__c = 'SBR_3_0_API_UpdateQuotedParts , createQp - line 28 , http.send(req) - Line 58 ';
                insert exc;
            }
            //Logic for response will be done once we know how RM sends the respone (The Format)
        }catch(Exception error){
            try{
                SBR_3_0_LogException.LogIt(error,relatedToId);
            }catch(Exception err){
				SBR_3_0_LogException.LogIt(error);
			}
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log  
        }
    }
    
    private static void generateWrapper(SF_PS_Quoted_Part__c qp) {        
        PartsWrapper pcWrapper = new PartsWrapper();
        QuotedPartsDetailsWrapper qpDetails = new QuotedPartsDetailsWrapper();
        
        qpDetails.sourceReferenceLineNumber = qp.Id;
        qpDetails.itemNumber = qp.SF_PS_Product2Id__r.Item_Number__c;
        qpDetails.stockClass = qp.SF_PS_Stock_Class__c;
        qpDetails.quantity = qp.SF_PS_Quantity__c == null ? 0.0 : Double.valueOf(qp.SF_PS_Quantity__c);
        qpDetails.unitOfMeasure = qp.SF_PS_Product2Id__r.QuantityUnitOfMeasure;
        qpDetails.sellingPrice = qp.SF_PS_Selling_Price__c == null ? 0.0 :(qp.SF_PS_Selling_Price__c).setScale(2) ;
        qpDetails.laborCode = qp.SF_PS_Labor_Code__c== null ? 0 :Integer.valueOf(qp.SF_PS_Labor_Code__c);
        qpDetails.cost = qp.SF_PS_Cost_Price__c == null ? 0.0 : (qp.SF_PS_Cost_Price__c).setScale(2);
        qpDetails.comments = qp.SF_PS_Line_Level_Comment__c;  
        qpDetails.discountPercent = qp.SF_PS_Discount_Percentage__c != null ? Integer.valueOf(qp.SF_PS_Discount_Percentage__c) : 0;
        if ( Integer.valueOf(qp.SF_PS_Discount_Percentage__c) <= 0){
            qpDetails.sellingPrice = (qp.SF_PS_Selling_Price__c).setScale(2);
        }
        else{
            qpDetails.sellingPrice = (qp.SF_PS_Orig_Selling_Price__c).setScale(2);
        }       
        pcWrapper.parts.add(qpDetails);
        requestBody.workOrderQuote.add(pcWrapper);
    }
    
    
    private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody).replace('null', '""');
        return currentWrapper;
        
    }
    
    public class SyncQuotedPartsWrapper{
        public List<PartsWrapper> workOrderQuote =new List<PartsWrapper>();       
    }
    
    public class PartsWrapper{
        public List<QuotedPartsDetailsWrapper> parts = new List<QuotedPartsDetailsWrapper>();
    }
    
    
    public class QuotedPartsDetailsWrapper{
        public String sourceReferenceLineNumber; //productconsumed.Id
        public String itemNumber; //Product2.Item_Number__c
        public String stockClass; //SF_PS_Stock_Class__c
        public Decimal quantity; //SF_PS_Quantity__c
        public String unitOfMeasure; //SF_PS_Unit_Of_Measure__c
        public Decimal sellingPrice; //SF_PS_Selling_Price__c
        public Integer laborCode; //SF_PS_Labor_Code__c
        public Decimal cost; //SF_PS_Cost_Price__c
        public String comments; //SF_PS_Line_Level_Comment__c
        public Decimal discountPercent; // SF_PS_Discount_Percentage__c
    }
    
    public class WrappedResponse{
        public string workOrderQuoteNumber{get;set;}
        public string mode{get;set;} 
        public string message;
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
        public list<WorkOrderQuoteLineItem> workOrderQuoteLineItems{get;set;}
    }
    
    class WorkOrderQuoteLineItem {
        public String workOrderQuoteLineItemNumber; //SF_PS_RM_External_Id__c
        public String uniqueId; //SF_PS_RM_Item_Number__c
        public String referenceLineNumber;
    }   
    
    
    
    
    
}