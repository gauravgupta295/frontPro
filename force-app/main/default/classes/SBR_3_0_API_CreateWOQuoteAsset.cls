/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWOQuoteAsset
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class for Creating Work Order Quote Customer Owned Asset
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Harry Rokad        2023-12-04             Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_CreateWOQuoteAsset {

    private static final String APINAME = 'API_WorkOrder_Quote_Insert';
    private static final String DATA = 'data';
    private static final String RMWOID = 'rmWOId';
    private static final String ERROR = 'error';
    private static final String WORKORDERNUMBER = 'workOrderNumber';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static final String SALESFORCE = 'Salesforce';
    private static String companyId;
    // private static SBR_3_0_WrapWOQuoteAsset woqAssetWrapper;
    // private static SBR_3_0_WrapWOQuoteAsset.WorkOrderQuote woq;
    private static SBR_3_0_WrapWOQuoteAsset.workOrderQuote woq;
    private static WorkOrder wo;

    @InvocableMethod(Label = 'CreateQuoteWOAssetRMCallout')
    public static void CreateQuoteWORMCallout(List<String> input) {

        if (!input.isEmpty()) {            
                createWorkOrder(input);            
        }
    }

    @future(Callout = true)
    private static void createWorkOrder(List<String> woId) {
        Set<String> woIdSet = new Set<String>(woId);
        WorkOrder getWo = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet)[0];
        SBR_3_0_WrapWOQuoteAsset woqAssetWrapper = new SBR_3_0_WrapWOQuoteAsset();
        String payload;
        if(getWo != null){
            payload = generateWrapper(getWo, woqAssetWrapper);
        }
        system.debug('payload+ '+ payload);
        List<User> usWyn=[SELECT Id,Wynne_User_Name__c FROM user WHERE id=:getWo.OwnerId];
        String rentalManUserName;
        if(usWyn.size()>0){
            rentalManUserName = usWyn[0].Wynne_User_Name__c;
        }
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        SBR_3_0_WrapWOQuoteAsset.WrappedResponse response = new SBR_3_0_WrapWOQuoteAsset.WrappedResponse();
        HttpRequest req = httpCallout.getRequest();
        req.setEndpoint(req.getEndpoint()+ '/assets');
        req.setHeader('thresholdWaitTime', '1');
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        req.setHeader('Content-Type', 'application/json');  
        req.setHeader('requestTimestamp', String.valueOf(getWo.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
        req.setHeader('sourceSystemUserId', getWo.CreatedBy.alias);
        req.setHeader('sourceSystemName', SALESFORCE);
        req.setHeader('rentalmanUserId', rentalManUserName);
        req.setHeader('requestTimeZone', getWo.ServiceTerritory.OperatingHours.TimeZone);
        req.setHeader('sourceWorkOrderNumber',getWo.WorkOrderNumber );
        req.setHeader('pc', getWo.ServiceTerritory.Branch_Location_Number__c);
        req.setHeader('companyId', companyId);  
        req.setBody(payload);
        req.setTimeout(20000);
        Http http = new Http(); 
        HTTPResponse res = http.send(req); 
        response.headers = res.getHeaderKeys();
        response.body = res.getBody();
        system.debug('response.headers is ' + response.headers);
        system.debug('response.body is ' + response.body);
        system.debug('res.getStatusCode is ' + res.getStatusCode());
        String returnPayload = res.getBody();
        
        system.debug('response'+response); 
        if (res.getStatusCode() == 200 || res.getStatus()== 'OK' ){
            response = (SBR_3_0_WrapWOQuoteAsset.WrappedResponse)JSON.deserialize(returnPayload, SBR_3_0_WrapWOQuoteAsset.WrappedResponse.class); 
            system.debug('workOrderQuoteNumber '+ response.workOrderQuoteNumber);
                getWo.SF_PS_RM_WO_Number__c = companyId+'-'+response.workOrderQuoteNumber;
                if (!Test.isRunningTest()){
                update getWo;
                }
            }
        }
    

    public static String generateWrapper(WorkOrder workOrder, SBR_3_0_WrapWOQuoteAsset woqAssetWrapper) {
        woqAssetWrapper.workOrderQuote = new List<SBR_3_0_WrapWOQuoteAsset.workOrderQuote>();
        woq = new SBR_3_0_WrapWOQuoteAsset.workOrderQuote();
        woq.customerOwnedAsset = new SBR_3_0_WrapWOQuoteAsset.CustomerOwnedAsset();
        companyId = workOrder.SF_PS_Company_Code__c;
        woq.driverLicenseState = workOrder.SF_PS_License_State__c;
        woq.driverLicenseNumber = workOrder.SF_PS_Drivers_License_Number__c;
        woq.jobNumber = workOrder.SF_PS_Job_Site__r.Job_Number__c;
        woq.poNumber = workOrder.SF_PS_PONumber__c;
        woq.equipmentDescription = workOrder.SF_PS_Cust_Eqp_Description__c;
        String phoneNumber = workOrder.SVMXA360__ContactPhone__c;
        woq.phoneNumber = phoneNumber == null ? null : long.valueOf(phoneNumber);
        String repID = workOrder.SF_PS_Sales_Rep__r.RepID__c;
        woq.salesRepresentativeId = repID == null ? null : Integer.Valueof(repID);
        woq.equipmentNumber = workOrder.Asset.SM_PS_Equipment_Number__c;
        if (workOrder.SF_PS_Due_Date__c != null){
            woq.estimatedCompletionDate = String.valueOf(workOrder.SF_PS_Due_Date__c.format('yyyy-MM-dd'));
        }
        if (workOrder.SF_PS_Date_Opened__c != null){
            woq.openedDateTime = String.valueOf(workOrder.SF_PS_Date_Opened__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\''));
        }
        if (!String.isBlank(workOrder.SF_PS_Major_Repair__c)) {
            woq.majorRepair = String.valueOf(workOrder.SF_PS_Major_Repair__c);
        }
        //woq.majorRepair = String.valueOf(workOrder.SF_PS_Major_Repair__c);
        woq.workOrderDescription = workOrder.SF_PS_Work_Order_Des__c;
        woq.complaint = workOrder.SF_PS_Complaint__c;
        woq.cure = workOrder.SF_PS_Cure__c;
        woq.cause = workOrder.SF_PS_Cause__c;
        woq.laborCode = Integer.valueOf(workOrder.SF_PS_LaborCode__c);
        woq.billTo = workOrder.SF_PS_BillCustOrLoc__c;
        woq.marketSegmentCode = workOrder.SF_SP_Market_Segment__c;
        woq.currencyCode = workOrder.CurrencyIsoCode;
        woq.currentMiHr= workOrder.SF_PS_Current_MiHr__c == null ? null :Integer.valueOf(workOrder.SF_PS_Current_MiHr__c);
        woq.currentMiHr2= workOrder.SF_PS_Current_MiHr2__c == null ? null :Integer.valueOf(workOrder.SF_PS_Current_MiHr2__c);
        woq.expenseToLocation = workOrder.SF_PS_Expense_To_Location__r.Branch_Location_Number__c;
        woq.expenseCode = workOrder.SF_PS_ExpenseCode__c;
        woq.jobLocation = workOrder.SF_PS_Job_Location__c;
        woq.authorizedBy = workOrder.SF_PS_Authorized_By__c;
        woq.serviceCall = workOrder.SF_PS_Service_Call__c;     
        Integer repairTicketNumber = (Integer)workOrder.SF_PS_Repair_Ticket__c;
        woq.repairTicketNumber = repairTicketNumber == null ? null : Integer.valueOf(repairTicketNumber);
        woq.warrantyCode = workOrder.SF_PS_Claim_Type__c;
        woq.claimNumber = workOrder.SF_PS_Claim_Num__c;
        woq.dateClaimFiled = String.valueOf(workOrder.SF_PS_Date_Claim_Filed__c);
        Integer warrantyAmount = (Integer)workOrder.SF_PS_Warranty_Amt_Expected__c;
        woq.warrantyAmount = warrantyAmount == null ? null : Integer.valueOf(warrantyAmount);
        String warrantyPaid = String.valueOf(workOrder.SF_PS_Funded__c);
        if (!String.isBlank(warrantyPaid)){
            if(warrantyPaid == 'true'){
                woq.warrantyPaid = 'Y';
            } 
            else{
                woq.warrantyPaid = 'N';
            }
        }
        woq.mechanicId = workOrder.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c;
        woq.internalComments = workOrder.SF_PS_Labor_Des_Internal__c;
        woq.externalComments = workOrder.SF_PS_Labor_Des_Comments__c;
        woq.warrantyExpiryDate=String.valueOf(workOrder.SF_PS_Warranty_Expiry_Date__c);
        if(workOrder.Account.RM_Account_Number__c != null){
            String accountNumber = workOrder.Account.RM_Account_Number__c;
            if(accountNumber.contains('-')) {
                accountNumber = accountNumber.subStringAfter('-');
            }
            woq.accountNumber = Integer.Valueof(accountNumber);
        }
        else{
            woq.accountNumber=0;
        }    

        woq.customerOwnedAsset.equipmentDescription = workOrder.Asset.SM_PS_Miscellaneous_Options__c;
        woq.customerOwnedAsset.make = workOrder.Asset.SM_PS_Make__c;
        woq.customerOwnedAsset.model = workOrder.Asset.SM_PS_Model__c;
        woq.customerOwnedAsset.serialNumber = workOrder.Asset.SM_PS_Serial_Number__c;
        woq.customerOwnedAsset.category = workOrder.Asset.SM_PS_Category__c;

        Integer subClass = (Integer)workOrder.Asset.SM_PS_Sub_Class__c;
        woq.customerOwnedAsset.subClass = subClass == null? null: subClass;

        woq.customerOwnedAsset.classId = workOrder.Asset.SM_PS_Class__c;
        String modelYear = workOrder.Asset.SM_PS_Model_Year__c;
        woq.customerOwnedAsset.modelYear = modelYear;
        woq.customerOwnedAsset.serviceMaintenanceContractFlag = workOrder.Asset.SM_PS_Maintenance_Contract__c;
        woq.customerOwnedAsset.milesHoursCode = workOrder.SF_PS_Meter_Code_MIHR__c;
        woq.customerOwnedAsset.ownedEquipmentStatus = workOrder.Asset.SM_PS_RentalMan_Status__c; // Status
        woq.customerOwnedAsset.updatedInSF = (workOrder.Asset.SM_PS_Updated_in_SF__c != null && workOrder.Asset.SM_PS_Updated_in_SF__c) ? 'Y' : 'N';

        woqAssetWrapper.workOrderQuote.add(woq);
        String currentWrapper = JSON.serialize(woqAssetWrapper);
        currentWrapper = currentWrapper.replace('"classId"', '"class"');
        Map<String, Object> jsonObject = (Map<String, Object>) JSON.deserializeUntyped(currentWrapper);

        // Clean the map
        jsonObject = SBR_3_0_Clean_Json_Payload.cleanJsonObject(jsonObject);

        // Serialize cleaned map back to JSON
        String cleanedJsonString = JSON.serialize(jsonObject);
        return cleanedJsonString;
    }
}


// WorkOrder wo = [SELECT Account.RM_Account_Number__c, SF_PS_Update_Meter__c, SF_PS_Replace_Meter__c,  SF_PS_Put_Into_Shop__c, SF_PS_Make_Available__c, CreatedBy.alias, SF_PS_Labor_Des_Comments__c, status, WorkOrderNumber, Asset.SM_PS_Asset_Id__c, Asset.SM_PS_Equipment_Number__c , ServiceTerritory.Branch_Location_Number__c, SF_PS_Job_Site__r.Job_Number__c , SF_PS_Expense_To_Location__r.Branch_Location_Number__c, SF_PS_Sales_Rep__r.RepID__c, SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, SF_PS_Serial_Number__c,CreatedBy.Name, CurrencyIsoCode, SVMXA360__ContactPhone__c, SF_PS_Company_Code__c, SF_PS_Date_Opened__c, SF_PS_Closed_Date__c, SF_PS_Work_Order_Des__c,  SF_PS_Drivers_License_Number__c, SF_PS_Complaint__c, SF_PS_Cause__c, SF_PS_Cure__c, SF_PS_BillCustOrLoc__c, SF_PS_ExpenseCode__c, SF_PS_LaborCode__c,SF_PS_Job_Location__c, SF_PS_PONumber__c , SF_PS_Authorized_By__c, SF_PS_Cust_Eqp_Description__c, SF_PS_Current_MiHr__c, SF_PS_Current_Loc__c, SF_PS_Service_Call__c, SF_PS_Claim_Type__c, SF_PS_Claim_Num__c, SF_PS_Date_Claim_Filed__c, SF_PS_Due_Date__c, SF_PS_Repair_Ticket__c, OwnerId, SF_PS_Major_Repair__c, SF_PS_Warranty_Amt_Expected__c,SF_SP_Market_Segment__c , SF_PS_License_State__c, SF_PS_Is_Warranty__c, SF_PS_Labor_Des_Internal__c, Description, ServiceTerritory.OperatingHours.TimeZone,  SF_PS_Funded__c, SF_PS_Claim_Paid_Date__c, SF_PS_Actual_Claim_Amt__c, SF_PS_Charge_GST_Tax__c, SF_PS_Charge_PST_Tax__c, SF_PS_Current_MiHr2__c, SF_PS_RM_Last_Maint_By__c, SF_PS_RM_Last_Maint_DateTime__c, SF_PS_RM_WO_Number__c, SF_PS_Inv_Seq_Num__c, LastModifiedDate, CreatedDate,                
// Asset.SM_PS_Miscellaneous_Options__c, Asset.Status, Asset.SM_PS_Serial_Number__c, Asset.SM_PS_Updated_in_SF__c, Asset.SM_PS_Meter_Code_MIHR__c, Asset.SM_PS_Maintenance_Contract__c, Asset.SM_PS_Make__c, Asset.SM_PS_Model__c, Asset.SM_PS_Category__c, SF_PS_Asset_Sub_Class__c, SF_PS_Model_Year__c, SF_PS_Quoted_Labor_Amt__c, SF_PS_Warranty_Expiry_Date__c,SF_PS_Record_Type__c FROM WorkOrder WHERE Id='0WO76000001C6vSGAS'];

// SBR_3_0_WrapWOQuoteAsset woqAssetWrapper = new SBR_3_0_WrapWOQuoteAsset();

// SBR_3_0_API_CreateWOQuoteAsset.generateWrapper(wo, woqAssetWrapper);