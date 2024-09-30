/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWorkOrderQuote
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quote WorkOrder to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
*********************************************************************************************************************/
public class SBR_3_0_API_CreateWorkOrderQuote {
    private static final String APINAME = 'API_WorkOrder_Quote_Insert';
    private static final String DATA = 'data';
    private static final String RMWOID = 'rmWOId';
    private static final String ERROR = 'error';
    private static final String WORKORDERNUMBER = 'workOrderNumber';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static SyncWorkOrderWrapper requestBody = new SyncWorkOrderWrapper();
    private static String companyId;
    private static WorkOrder workOrder;
    private SBR_3_0_WrapWorkOrder woWrapper = new SBR_3_0_WrapWorkOrder();
    
    @InvocableMethod(Label = 'CreateQuoteWorkOrderRMCallout')
    public static void CreateWorkOrderRMCallout(List<String> input) {
        
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {            
            createWorkOrder(input);            
        }
    }

    @future(Callout = true)
    private static void createWorkOrder(List<String> woId) {
        try{
            Set<String> woIdSet = new Set<String>(woId);
            WorkOrder getWo = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet)[0];
            if(getWo != null){
                generateWrapper(getWo);
            }
            String payload = generateJSONPayload();
           String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getWo.OwnerId].Wynne_User_Name__c;
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();
            HttpRequest req = httpCallout.getRequest();
            req.setEndpoint(req.getEndpoint());
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', 'application/json');  
            req.setHeader('requestTimestamp', String.valueOf(getWo.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
            req.setHeader('sourceSystemUserId', getWo.CreatedBy.alias);
            req.setHeader('sourceSystemName', 'Salesforce');
            req.setHeader('rentalmanUserId', rentalManUserName);
            req.setHeader('requestTimeZone', getWo.ServiceTerritory.OperatingHours.TimeZone);
            req.setHeader('sourceWorkOrderNumber',getWo.WorkOrderNumber );
            req.setHeader('pc', getWo.ServiceTerritory.Branch_Location_Number__c);
            req.setHeader('companyId', companyId);  
            req.setBody(payload);
            system.debug('Payload '+payload);
            req.setTimeout(20000);
            Http http = new Http();
            HTTPResponse res = http.send(req); 
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();
            String returnPayload = res.getBody();
            if (!Test.isRunningTest()){
                if (res.getStatusCode() == 200 || res.getStatus()== 'OK' ){
                    response = (WrappedResponse)JSON.deserialize(returnPayload, WrappedResponse.class); 
                    getWo.SF_PS_RM_WO_Number__c = companyId+'-'+response.workOrderQuoteNumber;
                    update getWo;
                }else{
                    Exception_Log__c exc = new Exception_Log__c();
                    exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request - ' + payload + ' ' +' Response '+response.body;
                    //exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                    exc.Exception_Type__c = 'SF to RM Outbound Response';
                    exc.Method_Name__c= 'createWorkOrder';
                    exc.RequestJSON__c= payload;
                    exc.ResponseJSON__c = response.body;
                    exc.RecordID__c = getWo.id;
                    exc.Class_Name__c= 'SBR_3_0_API_CreateWorkOrderQuote';
                    exc.Stack_Trace__c = 'SBR_3_0_API_CreateWorkOrderQuote , createWorkOrder - line 32 , http.send(req) - Line 59 ';
                    insert exc;
                }
            }
        }catch(Exception error){
            SBR_3_0_LogException.LogIt(error);
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log          
        }
    }
    
    private static void generateWrapper(WorkOrder workOrder) {
        woDetailsClass wo = new woDetailsClass();
        companyId = workOrder.SF_PS_Company_Code__c;
        wo.driverLicenseState = workOrder.SF_PS_License_State__c;
        wo.driverLicenseNumber = workOrder.SF_PS_Drivers_License_Number__c;
        wo.jobNumber = workOrder.SF_PS_Job_Site__r?.Job_Number__c;
        wo.poNumber = workOrder.SF_PS_PONumber__c;
        String phoneNumber = workOrder.SVMXA360__ContactPhone__c;
        //String pn = phoneNumber.replaceAll('[^0-9]', '');
        wo.phoneNumber = phoneNumber == null ? 0 : long.valueOf(phoneNumber);
        wo.salesRepresentativeId = workOrder.SF_PS_Sales_Rep__r?.RepID__c == null ? null : Integer.valueOf(workOrder.SF_PS_Sales_Rep__r?.RepID__c);
        wo.equipmentNumber = workOrder.Asset?.SM_PS_Equipment_Number__c;
        if (workOrder.SF_PS_Due_Date__c != null){
            wo.estimatedCompletionDate = String.valueOf(workOrder.SF_PS_Due_Date__c.format('yyyy-MM-dd'));
        }
        if (workOrder.SF_PS_Date_Opened__c != null){
            wo.openedDateTime = String.valueOf(workOrder.SF_PS_Date_Opened__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\''));
        }
        wo.majorRepair = workOrder.SF_PS_Major_Repair__c != null ? String.valueOf(workOrder.SF_PS_Major_Repair__c):'N';
        wo.workOrderDescription = workOrder.SF_PS_Work_Order_Des__c;
        wo.complaint = workOrder.SF_PS_Complaint__c;
        wo.cure = workOrder.SF_PS_Cure__c;
        wo.cause = workOrder.SF_PS_Cause__c;
        wo.laborCode = workOrder.SF_PS_LaborCode__c!=null?Integer.valueOf(workOrder.SF_PS_LaborCode__c):null;
        wo.billTo = workOrder.SF_PS_BillCustOrLoc__c;
        wo.marketSegmentCode = workOrder.SF_SP_Market_Segment__c;
        wo.currencyCode = workOrder.CurrencyIsoCode;
        //wo.currentMiHr= workOrder.SF_PS_Current_MiHr__c != null ? Integer.valueOf(workOrder.SF_PS_Current_MiHr__c) :null;
        wo.expenseToLocation = workOrder.SF_PS_Expense_To_Location__r?.Branch_Location_Number__c;
        wo.expenseCode = workOrder.SF_PS_ExpenseCode__c;
        wo.jobLocation = workOrder.SF_PS_Job_Location__c;
        wo.authorizedBy = workOrder.SF_PS_Authorized_By__c;
        wo.serviceCall = workOrder.SF_PS_Service_Call__c;     
        //Integer repairTicketNumber = workOrder.SF_PS_Repair_Ticket__c == null ? '0' : (Integer)workOrder.SF_PS_Repair_Ticket__c;
        wo.repairTicketNumber = workOrder.SF_PS_Repair_Ticket__c != null ? Integer.valueOf(workOrder.SF_PS_Repair_Ticket__c) : null;
        wo.warrantyCode = workOrder.SF_PS_Claim_Type__c;
        wo.claimNumber = workOrder.SF_PS_Claim_Num__c;
        wo.dateClaimFiled = workOrder.SF_PS_Date_Claim_Filed__c != null ?  String.valueOf(workOrder.SF_PS_Date_Claim_Filed__c) : '';
        //Integer warrantyAmount = workOrder.SF_PS_Warranty_Amt_Expected__c == null ? 0.0 :(Integer)workOrder.SF_PS_Warranty_Amt_Expected__c;
        wo.warrantyAmount = workOrder.SF_PS_Warranty_Amt_Expected__c != null ? Double.valueOf(workOrder.SF_PS_Warranty_Amt_Expected__c) : null;
        String warrantyPaid = workOrder.SF_PS_Funded__c !=  null ? String.valueOf(workOrder.SF_PS_Funded__c) : '';
        if (!String.isBlank(warrantyPaid)){
            if(warrantyPaid == 'true'){
                wo.warrantyPaid = 'Y';
            } 
            else{
                wo.warrantyPaid = 'N';
            }
        }
        wo.mechanicId = workOrder.SF_PS_Service_Resource__r?.SF_PS_Mechanic_Id__c;
        wo.internalComments = workOrder.SF_PS_Labor_Des_Internal__c;
        wo.externalComments = workOrder.SF_PS_Labor_Des_Comments__c;
        wo.warrantyExpiryDate = workOrder.SF_PS_Warranty_Expiry_Date__c != null ?  String.valueOf(workOrder.SF_PS_Warranty_Expiry_Date__c) :'';
        if(workOrder.Account.RM_Account_Number__c != null){
            String accountNumber = workOrder.Account.RM_Account_Number__c;
            if(accountNumber.contains('-')) {
                accountNumber = accountNumber.subStringAfter('-');
            }
            wo.accountNumber = Integer.Valueof(accountNumber);
        }
        else{
            wo.accountNumber=null;
        }    
        requestBody.workOrderQuote.add(wo);
     }
    
     private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody);
        Map<String, Object> jsonObject = (Map<String, Object>) JSON.deserializeUntyped(currentWrapper);


        // Clean the map
        jsonObject=SBR_3_0_Clean_Json_Payload.cleanJsonObject(jsonObject);
    
        // Serialize cleaned map back to JSON
        String cleanedJsonString = JSON.serialize(jsonObject);
        return cleanedJsonString;
    }

    public class SyncWorkOrderWrapper{
        public List<woDetailsClass> workOrderQuote=new List<woDetailsClass>();       
    }
    
    class woDetailsClass {
        public string driverLicenseState; //SF_PS_License_State__c
        public string driverLicenseNumber; //SF_PS_Drivers_License_Number__c
        public String jobNumber; // SF_PS_Job_Site__r.Job_Number__c 
        public string poNumber; //SF_PS_PONumber__c
        public long phoneNumber; // SVMXA360__ContactPhone__c
        public Integer salesRepresentativeId; // SF_PS_Sales_Rep__r.RepID__c
        public String equipmentNumber;  //  Asset.SM_PS_Equipment_Number__c 
        public String estimatedCompletionDate; // SF_PS_Due_Date__c
        public String openedDateTime; // SF_PS_Date_Opened__c
        public String majorRepair; // SF_PS_Major_Repair__c
        public String workOrderDescription; // SF_PS_Work_Order_Des__c
        public Integer laborCode; // SF_PS_LaborCode__c
        public string billTo; //SF_PS_BillCustOrLoc__c
        public String marketSegmentCode; //	SF_SP_Market_Segment__c
        public String currencyCode; // CurrencyIsoCode
        public String expenseToLocation; // SF_PS_Expense_To_Location__r.Branch_Location_Number__c
        public String expenseCode; // SF_PS_ExpenseCode__c
        public String jobLocation; // SF_PS_Job_Location__c
        public String authorizedBy; // SF_PS_Authorized_By__c
        public String serviceCall; // SF_PS_Service_Call__c
        public Integer repairTicketNumber; // SF_PS_Repair_Ticket__c
        public string warrantyCode; //SF_PS_Claim_Type__c
        public string claimNumber; //SF_PS_Claim_Num__c
        public string dateClaimFiled; //SF_PS_Date_Claim_Filed__c
        public Double warrantyAmount; //SF_PS_Warranty_Amt_Expected__c
        public string warrantyPaid; // SF_PS_Funded__c
        public String warrantyExpiryDate;
        public String mechanicId; // SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c
        public Integer accountNumber; //Account.RM_Account_Number__c
        public string internalComments; //SF_PS_Labor_Des_Internal__c
        public string externalComments; //SF_PS_Labor_Des_Comments__c  
        public string cure; 
        public string cause;
        public string complaint;
        //public Double currentMiHr;
    }
    
    public class WrappedResponse{
        public string workOrderNumber{get;set;}
        public string workOrderQuoteNumber{get;set;}
        public string mode{get;set;} 
        public string message;
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
        public list<WorkOrderLineItem> workOrderLineItems{get;set;}
    }
}