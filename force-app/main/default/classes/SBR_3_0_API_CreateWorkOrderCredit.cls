/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWorkOrderCredit
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quote WorkOrder to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                	DETAIL FEATURES
1.0             Mayank Jain         	2023-12-22             	Initial version
*********************************************************************************************************************/
public class SBR_3_0_API_CreateWorkOrderCredit {
    private static final String APINAME = 'API_WorkOrder_Credit_Insert';
    private static final String DATA = 'data';
    private static final String RMWOID = 'rmWOId';
    private static final String ERROR = 'error';
    private static final String WORKORDERNUMBER = 'workOrderNumber';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static SyncWorkOrderWrapper requestBody = new SyncWorkOrderWrapper();
    private static String companyId;
    private static WorkOrder workOrder;
    //private SBR_3_0_WrapWorkOrder woWrapper = new SBR_3_0_WrapWorkOrder();
    @InvocableMethod(Label = 'CreateQuoteWorkOrderRMCallout')
    public static void CreateWorkOrderRMCallout(List<String> input) {
        System.debug( 'In Credit Work order' );
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch() ) {            
            createWorkOrder(input);            
        }
    }
    
    @future(Callout = true)
    private static void createWorkOrder(List<String> woId) {
        try{
            System.debug( 'In Credit Work order future' );
            Set<String> woIdSet = new Set<String>(woId);
            WorkOrder getWo = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet)[0];
            WorkOrder getWoParent;
            if(!Test.isRunningTest()){
                getWoParent = [Select Id, SF_PS_RM_WO_Number__c, SF_PS_RM_Credited_WO_Number__c FROM workorder where id =:getWo.ParentWorkOrderId LIMIT 1 ];
                System.debug('getWoParent is ' + getWoParent?.SF_PS_RM_WO_Number__c?.subStringAfter('-') );
            }
            
            List<SF_PS_Credit_Line_Item__c> cliList = [SELECT Id, WorkOrderId__c, SF_PS_Line_Type__c, SF_PS_Labor_Code__c, 
                                                       WorkOrderId__r.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c,
                                                       SF_PS_Mechanic_Name__c, SF_PS_Mechanic_ID__c, SF_PS_Credited_PO_Amount__c,
                                                       SF_PS_Duration__c, SF_PS_Vendor_PO_Num__c, SF_PS_PO_Amount__c, SF_PS_PO_Cost__c, 
                                                       SF_PS_Outside_Labor_Des__c,SF_PS_Credit_Rate_Hr_Mi__c, SF_PS_Hr_Mi_To_Credit__c, SF_PS_RM_Orig_Line_Item_Num__c 
                                                       FROM SF_PS_Credit_Line_Item__c 
                                                       WHERE WorkOrderId__c  =: getWo.Id];
            system.debug('cliList si ' + cliList);
            Map<ID,SF_PS_Credit_Line_Item__c> mapIDLineItems = new Map<ID,SF_PS_Credit_Line_Item__c>(cliList);
            List<SF_PS_Credit_Line_Item__c> cliInsideLineItemList = new List<SF_PS_Credit_Line_Item__c>();
            List<SF_PS_Credit_Line_Item__c> cliOutsideLineItemList = new List<SF_PS_Credit_Line_Item__c>();
            List<SF_PS_Credit_Line_Item__c> cliMilageLineItemList = new List<SF_PS_Credit_Line_Item__c>();
            
            For (SF_PS_Credit_Line_Item__c cli : cliList ){
                system.debug('CLI si ' + cli);
                if(cli.SF_PS_Line_Type__c == 'LI' ) {
                    cliInsideLineItemList.add(cli);
                }else if(cli.SF_PS_Line_Type__c == 'LO'){
                    cliOutsideLineItemList.add(cli);
                }else{
                    cliMilageLineItemList.add(cli);
                }
            }
            system.debug('cliInsideLineItemList is ' + cliInsideLineItemList);
            system.debug('cliOutsideLineItemList is ' + cliOutsideLineItemList);
            system.debug('cliMilageLineItemList is ' + cliMilageLineItemList);
            
            List<SF_PS_Credited_Part__c> woliPCList = [Select Id, SF_PS_Work_Order__c, SF_PS_Product__r.Item_Number__c, 
                                                       SF_PS_Stock_Class__c,SF_PS_Parts_To_Credit__c,SF_PS_Labor_Code__c,
                                                       SF_PS_Product__r.QuantityUnitOfMeasure, SF_PS_Selling_Price__c,
                                                       SF_PS_Cost_Price__c, SF_PS_Line_Level_Comment__c, SF_PS_Product2Id__c,
                                                       SF_PS_Unit_Of_Measure__c, SF_PS_Restock__c, SF_PS_RM_Orig_Line_Item_Num__c
                                                       FROM  SF_PS_Credited_Part__c 
                                                       WHERE SF_PS_Work_Order__c =: getWo.Id  ];
            system.debug('woliPCList is ' + woliPCList);
            Map<ID,SF_PS_Credited_Part__c> mapIDParts = new Map<ID,SF_PS_Credited_Part__c>(woliPCList);
            if(getWo != null){
                generateWrapper(getWo,cliInsideLineItemList,cliOutsideLineItemList,cliMilageLineItemList,woliPCList);
            }
            String payload = generateJSONPayload();
            system.debug('payload+ '+ payload);
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getWo.OwnerId].Wynne_User_Name__c;
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();
            HttpRequest req = httpCallout.getRequest();
            req.setEndpoint(req.getEndpoint());
            System.debug('End Point is ' + req.getEndpoint());
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
            if(!Test.isRunningTest()){
                req.setHeader('workOrderNumberToBeCredited', getWoParent?.SF_PS_RM_WO_Number__c?.subStringAfter('-'));
            }
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
            //   if (!Test.isRunningTest()){
            system.debug('response'+response); 
            if (res.getStatusCode() == 200 || res.getStatus()== 'OK' ){
                response = (WrappedResponse)JSON.deserialize(returnPayload, WrappedResponse.class); 
                system.debug('workOrderCreditNumber  '+ response.workOrderCreditNumber );
                if (!Test.isRunningTest()){
                    getWo.SF_PS_RM_WO_Number__c = companyId+'-'+response.workOrderCreditNumber ;
                    //getWo.SF_PS_RM_Credited_WO_Number__c = companyId+'-'+response.workOrderCreditNumber;
                    update getWo;
                    getWoParent.SF_PS_RM_Credited_WO_Number__c = companyId+'-'+response.workOrderCreditNumber;
                    update getWoParent;
                }
                if(response.workOrderCreditLineItems.size()> 0){
                    System.debug('in Response');
                    List<SF_PS_Credit_Line_Item__c> cliListUpdate = new List<SF_PS_Credit_Line_Item__c>();
                    List<SF_PS_Credited_Part__c> woliPCListUpdate = new List<SF_PS_Credited_Part__c>();
                    for(workOrderCreditLineItemsWrapper responseCli :  response.workOrderCreditLineItems){
                        SF_PS_Credit_Line_Item__c cli  = null;
                        cli  = mapIDLineItems.get(responseCli.sourceReferenceLineNumber);
                        if(cli != null){
                            cli.SF_PS_RM_Credit_Line_Item_Num__c = responseCli.workOrderCreditLineItemNumber;
                            cli.SF_PS_RM_External_Id__c =  responseCli.uniqueId;
                            cliListUpdate.add(cli);
                        }
                        SF_PS_Credited_Part__c cp = null;
                        cp = mapIDParts.get(responseCli.sourceReferenceLineNumber);
                        if(cp != null){
                            cp.SF_PS_RM_Item_Number__c = responseCli.workOrderCreditLineItemNumber;
                            cp.SF_PS_RM_External_Id__c = responseCli.uniqueId; 
                            woliPCListUpdate.add(cp); 
                        }
                        
                    }
                    if(cliListUpdate.size()> 0 ){
                        update cliListUpdate;
                    }
                    if(woliPCListUpdate.size()> 0){
                        update woliPCListUpdate;
                    }
                }    
            }else{
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request -'+payload +' ' +' Response '+response.body;
                //exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c= 'createWorkOrder';
                ////exc.RequestJSON__c= payload;
                //exc.ResponseJSON__c = response.body;
                //exc.RecordID__c = getWo.id;
                exc.Class_Name__c= 'SBR_3_0_API_CreateWorkOrderCredit';
                exc.Stack_Trace__c = 'SBR_3_0_API_CreateWorkOrderCredit , createWorkOrder - line 31 , http.send(req) - Line 106 ';
                insert exc;
            }
        }
        catch(Exception error){
            SBR_3_0_LogException.LogIt(error);
            // system.debug('WorkOrder ID' +  workOrder.id);
            // System.debug('Payload '+)
            //SBR_3_0_LogException.LogIt(error, workOrder.id, payload);
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log
        }
    }
    private static void generateWrapper(WorkOrder workOrder , 
                                        List<SF_PS_Credit_Line_Item__c> cliInsideLineItemList,
                                        List<SF_PS_Credit_Line_Item__c>   cliOutsideLineItemList,
                                        List<SF_PS_Credit_Line_Item__c>   cliMilageLineItemList,
                                        List<SF_PS_Credited_Part__c>  woliPCList)
    {
        woDetailsClass wo = new woDetailsClass();
        companyId = workOrder.SF_PS_Company_Code__c;
        wo.driverLicenseState = workOrder.SF_PS_License_State__c;
        wo.driverLicenseNumber = workOrder.SF_PS_Drivers_License_Number__c;
        wo.jobNumber = workOrder.SF_PS_Job_Site__r.Job_Number__c;
        wo.poNumber = workOrder.SF_PS_PONumber__c;
        String phoneNumber = workOrder.SVMXA360__ContactPhone__c;
        //String pn = phoneNumber.replaceAll('[^0-9]', '');
        wo.phoneNumber = phoneNumber == null ? 0 : long.valueOf(phoneNumber);
        String repID = workOrder.SF_PS_Sales_Rep__r.RepID__c;
        wo.salesRepresentativeId = repID == null ? 0 : Integer.Valueof(repID);
        wo.equipmentNumber = workOrder.Asset.SM_PS_Equipment_Number__c;
        if (workOrder.SF_PS_Due_Date__c != null){
            wo.estimatedCompletionDate = String.valueOf(workOrder.SF_PS_Due_Date__c.format('yyyy-MM-dd'));
        }
        if (workOrder.SF_PS_Date_Opened__c != null){
            wo.openedDateTime = String.valueOf(workOrder.SF_PS_Date_Opened__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\''));
        }
        wo.majorRepair = String.valueOf(workOrder.SF_PS_Major_Repair__c);
        wo.workOrderDescription = workOrder.SF_PS_Work_Order_Des__c;
        wo.complaint = workOrder.SF_PS_Complaint__c;
        wo.cure = workOrder.SF_PS_Cure__c;
        wo.cause = workOrder.SF_PS_Cause__c;
        wo.laborCode = Integer.valueOf(workOrder.SF_PS_LaborCode__c);
        wo.billTo = workOrder.SF_PS_BillCustOrLoc__c;
        wo.marketSegmentCode = workOrder.SF_SP_Market_Segment__c;
        wo.currencyCode = workOrder.CurrencyIsoCode;
        wo.currentMiHr= workOrder.SF_PS_Current_MiHr__c == null ? 0 :Integer.valueOf(workOrder.SF_PS_Current_MiHr__c);
        wo.expenseToLocation = workOrder.SF_PS_Expense_To_Location__r.Branch_Location_Number__c;
        wo.expenseCode = workOrder.SF_PS_ExpenseCode__c;
        wo.jobLocation = workOrder.SF_PS_Job_Location__c;
        wo.authorizedBy = workOrder.SF_PS_Authorized_By__c;
        wo.serviceCall = workOrder.SF_PS_Service_Call__c;     
        Integer repairTicketNumber = (Integer)workOrder.SF_PS_Repair_Ticket__c;
        wo.repairTicketNumber = repairTicketNumber == null ? 0 : Integer.valueOf(repairTicketNumber);
        wo.warrantyCode = workOrder.SF_PS_Claim_Type__c;
        //wo.claimNumber = workOrder.SF_PS_Claim_Num__c;
        //wo.dateClaimFiled = String.valueOf(workOrder.SF_PS_Date_Claim_Filed__c);
        Integer warrantyAmount = (Integer)workOrder.SF_PS_Warranty_Amt_Expected__c;
        wo.warrantyAmount = warrantyAmount == null ? 0 : Integer.valueOf(warrantyAmount);
        String warrantyPaid = String.valueOf(workOrder.SF_PS_Funded__c);
        if (!String.isBlank(warrantyPaid)){
            if(warrantyPaid == 'true'){
                wo.warrantyPaid = 'Y';
            } 
            else{
                wo.warrantyPaid = 'N';
            }
        }
        //wo.gst = workOrder.SF_PS_Charge_GSTTax__c;  
        //wo.pst = workOrder.SF_PS_Charge_PSTTax__c;
        wo.mechanicId = workOrder.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c;
        wo.internalComments = workOrder.SF_PS_Labor_Des_Internal__c;
        wo.externalComments = workOrder.SF_PS_Labor_Des_Comments__c;
        wo.warrantyExpiryDate=String.valueOf(workOrder.SF_PS_Warranty_Expiry_Date__c);
        if(workOrder.Account.RM_Account_Number__c != null){
            String accountNumber = workOrder.Account.RM_Account_Number__c;
            if(accountNumber.contains('-')) {
                accountNumber = accountNumber.subStringAfter('-');
            }
            wo.accountNumber = Integer.Valueof(accountNumber);
        }
        else{
            wo.accountNumber=0;
        }
        
        wo.creditReason = workOrder.SF_PS_Credit_Reason__c;
        wo.makeAvailable = workOrder.SF_PS_Make_Available__c;
        wo.currentMiHr2 = workOrder.SF_PS_Current_MiHr2__c == null ? 0.0 : workOrder.SF_PS_Current_MiHr2__c;
        if(cliInsideLineItemList.size() > 0 ){
            wo.insideLabor  = woCliInsideLaborgenerateWrapper(cliInsideLineItemList);
        }
        if(cliOutsideLineItemList.size() > 0 ){
            wo.outsideLabor = woCliOutsideLaborgenerateWrapper(cliOutsideLineItemList);
        }
        
        if(cliMilageLineItemList.size() > 0 ){
            wo.mileage = woCliMileageWrapper(cliMilageLineItemList[0]);
        }
        if(woliPCList.size() > 0 ){
            wo.parts = woCliPartsgenerateWrapper(woliPCList);  
        }        
        requestBody.workOrder.add(wo);
        System.debug('request body' +requestBody);                                        
        
    }
    
    private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody).replace('null', '""');
        system.debug('currentWrapper in line 209' + currentWrapper );
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(currentWrapper);
        System.debug('jsonMap in line 211 is ' + jsonMap);
        // Check if "mileage" key exists and is empty
        if (jsonMap.containsKey('workOrder')) {
            List<Object> workOrders = (List<Object>)jsonMap.get('workOrder');
            System.debug('workOrders line 213 +' + workOrders);
            if (!workOrders.isEmpty()) {
                Map<String, Object> workOrder = (Map<String, Object>)workOrders[0];
                System.debug('workOrder line 216 +' + workOrder);
                if (workOrder.containsKey('mileage')) {
                    System.debug('mileage line 215 +');
                    if((String)(workOrder.get('mileage')+'' )=='' ){
                        String mil = (String)workOrder.get('mileage');
                        // Check if the "mileage" key is empty
                        if (mil == null || mil == '' ) {
                            // Remove the "mileage" key
                            workOrder.remove('mileage');
                        }
                    }
                }
                list<Object> finalParts= new List<Object>();
                if(workOrder.containsKey('parts'))
                {
                    system.debug('workOrder.get(parts)'+workOrder.get('parts'));
                    if((String)(workOrder.get('parts')+'' )=='' ){
                        String part = (String)workOrder.get('parts');
                        // Check if the "mileage" key is empty
                        if (part == null || part == '' ) {
                            // Remove the "mileage" key
                            workOrder.remove('parts');
                        }
                    }else {
                        list<Object> parts=(list< Object>)JSON.deserializeUntyped( JSON.serialize(workOrder.get('parts')));
                        for(Object part:parts)
                        {
                            system.debug(part);
                            Map<String, Object>partMap =(Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(part));
                            system.debug('partmap '+partMap);
                            system.debug('discount '+ partMap.get('discountPercent'));
                            if(partMap.containsKey('discountPercent') && partMap.get('discountPercent')+''=='' )
                            {
                                system.debug('discountPercent removed');
                                partMap.remove('discountPercent');
                            }
                            finalParts.add(partMap);
                        }
                        workOrder.put('parts',finalParts);
                    }
                    
                }
                if (workOrder.containsKey('insideLabor')) {
                    if((String)(workOrder.get('insideLabor')+'' )=='' ){
                        String insideLabor = (String)workOrder.get('insideLabor');
                        // Check if the "mileage" key is empty
                        if (insideLabor == null || insideLabor == '' ) {
                            // Remove the "mileage" key
                            workOrder.remove('insideLabor');
                        }
                    }
                }
                if (workOrder.containsKey('outsideLabor')) {
                    if((String)(workOrder.get('outsideLabor')+'' )=='' ){
                        String outsideLabor = (String)workOrder.get('outsideLabor');
                        // Check if the "mileage" key is empty
                        if (outsideLabor == null || outsideLabor == '' ) {
                            // Remove the "mileage" key
                            workOrder.remove('outsideLabor');
                        }
                    }
                }
            }
        }
        
        // Serialize the Map back to JSON
        currentWrapper = JSON.serialize(jsonMap);
        Map<String, Object> jsonObject = (Map<String, Object>) JSON.deserializeUntyped(currentWrapper);

        //Clean the map
        jsonObject = SBR_3_0_Clean_Json_Payload.cleanJsonObject(jsonObject);

    
        // Serialize cleaned map back to JSON
        String cleanedJsonString = JSON.serialize(jsonObject);
        return cleanedJsonString;
    }
    
    public class SyncWorkOrderWrapper{
        public List<woDetailsClass> workOrder =new List<woDetailsClass>();       
    }
    
    class woDetailsClass {
        public string driverLicenseState; //SF_PS_License_State__c 
        public string driverLicenseNumber; //SF_PS_Drivers_License_Number__c
        public String jobNumber; // SF_PS_Job_Site__r.Job_Number__c (AssociatedLocation) 
        public string poNumber; //SF_PS_PONumber__c 
        public long phoneNumber; // SVMXA360__ContactPhone__c 
        public Integer salesRepresentativeId; // SF_PS_Sales_Rep__r.RepID__c
        public String marketSegmentCode; //SF_SP_Market_Segment__c 
        public String equipmentNumber;  //  Asset.SM_PS_Equipment_Number__c 
        public String estimatedCompletionDate; // SF_PS_Due_Date__c
        public String creditReason; //SF_PS_Credit_Reason__c
        public String openedDateTime; // SF_PS_Date_Opened__c
        public String majorRepair; // SF_PS_Major_Repair__c
        public String workOrderDescription; // SF_PS_Work_Order_Des__c
        public Integer laborCode; // SF_PS_LaborCode__c
        public string billTo; //SF_PS_BillCustOrLoc__c
        public String currencyCode; // CurrencyIsoCode
        public String expenseToLocation; // SF_PS_Expense_To_Location__r.Branch_Location_Number__c
        public String expenseCode; // SF_PS_ExpenseCode__c
        public String jobLocation; // SF_PS_Job_Location__c
        public String authorizedBy; // SF_PS_Authorized_By__c
        public String serviceCall; // SF_PS_Service_Call__c
        public Integer repairTicketNumber; // SF_PS_Repair_Ticket__c
        public string warrantyCode; //SF_PS_Claim_Type__c
        public Double warrantyAmount; //SF_PS_Warranty_Amt_Expected__c
        public string warrantyPaid; // SF_PS_Funded__c
        public String warrantyExpiryDate;
        //public String gst; //SF_PS_Charge_GST_Tax__c;
        //public String pst; //SF_PS_Charge_PST_Tax__c
        public String makeAvailable ;//SF_PS_Make_Available__c
        public String mechanicId; // SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c
        public Integer accountNumber; //Account.RM_Account_Number__c
        public string internalComments; //SF_PS_Labor_Des_Internal__c
        public string externalComments; //SF_PS_Labor_Des_Comments__c  
        public string cure; 
        public string cause;
        public string complaint;
        public Double currentMiHr; //SF_PS_Current_MiHr__c
        public Double currentMiHr2 ;//SF_PS_Current_MiHr2__c
        public List<woCliInsideLaborDetailsClass> insideLabor;
        
        public List<woCliOutsideLaborDetailsClass> outsideLabor;
        public woCliMilegeDetailsClass mileage ;
        public List<woCliPartsDetailsClass> parts;
        
    }
    
    private static List<woCliInsideLaborDetailsClass> woCliInsideLaborgenerateWrapper(List<SF_PS_Credit_Line_Item__c>  cliList) {       
        List<woCliInsideLaborDetailsClass> woCliInsideWrapper = new List<woCliInsideLaborDetailsClass>();
        for (SF_PS_Credit_Line_Item__c cli : cliList){
            woCliInsideLaborDetailsClass woCliDetails = new woCliInsideLaborDetailsClass();
            woCliDetails.sourceReferenceLineNumber = cli.Id;
            //woCliDetails.mechanicId =cli.WorkOrderId__r?.SF_PS_Service_Resource__r?.SF_PS_Mechanic_Id__c;
            woCliDetails.mechanicId = cli.SF_PS_Mechanic_ID__c;
            woCliDetails.laborCode = cli.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(cli.SF_PS_Labor_Code__c);
            woCliDetails.insideLaborRate = cli.SF_PS_Credit_Rate_Hr_Mi__c== null ? 0.0 : cli.SF_PS_Credit_Rate_Hr_Mi__c;
            woCliDetails.insideLaborHours = cli.SF_PS_Hr_Mi_To_Credit__c == null ? 0.0 : cli.SF_PS_Hr_Mi_To_Credit__c; 
            woCliDetails.workOrderLineNumber = cli.SF_PS_RM_Orig_Line_Item_Num__c;
            woCliInsideWrapper.add(woCliDetails);
        }
        return woCliInsideWrapper;
    }
    
    class woCliInsideLaborDetailsClass {   
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public String mechanicId;	    //SF_PS_Mechanic_Name__c
        public Integer laborCode;	//SF_PS_Labor_Code__c
        public Double insideLaborRate; //SF_PS_Credit_Rate_Hr_Mi__c
        public Double insideLaborHours; //SF_PS_Hr_Mi_To_Credit__c
        public String workOrderLineNumber; //SF_PS_RM_Orig_Line_Item_Num__c
    }
    
    
    
    private static List<woCliOutsideLaborDetailsClass> woCliOutsideLaborgenerateWrapper(List<SF_PS_Credit_Line_Item__c>  cliList){ 
        List<woCliOutsideLaborDetailsClass> woCliOutsideWrapper = new List<woCliOutsideLaborDetailsClass>();
        for (SF_PS_Credit_Line_Item__c  cli : cliList){
            woCliOutsideLaborDetailsClass cliOutsideLaborDetails = new woCliOutsideLaborDetailsClass();
            cliOutsideLaborDetails.sourceReferenceLineNumber=cli.Id;
            cliOutsideLaborDetails.laborCode=cli.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(cli.SF_PS_Labor_Code__c);
            cliOutsideLaborDetails.outsideLaborPoNumber= cli.SF_PS_Vendor_PO_Num__c == null ? '' : String.valueOf(cli.SF_PS_Vendor_PO_Num__c);
            cliOutsideLaborDetails.outsideLaborPrice=cli.SF_PS_PO_Amount__c == null ? 0.0 : cli.SF_PS_PO_Amount__c;
            cliOutsideLaborDetails.outsideLaborCost=cli.SF_PS_Credited_PO_Amount__c == null ? 0.0 : cli.SF_PS_Credited_PO_Amount__c; //should not be 0
            cliOutsideLaborDetails.outsideLaborDescription = cli.SF_PS_Outside_Labor_Des__c;
            cliOutsideLaborDetails.workOrderLineNumber = cli.SF_PS_RM_Orig_Line_Item_Num__c;
            woCliOutsideWrapper.add(cliOutsideLaborDetails);
        }
        return woCliOutsideWrapper;    
    } 
    
    class woCliOutsideLaborDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public Integer laborCode;	//9999 //SF_PS_Labor_Code__c
        public String outsideLaborPoNumber;	//'99999999' //SF_PS_Vendor_PO_Num__c
        public Double outsideLaborPrice;	//99999999.99 //SF_PS_PO_Amount__c
        public Double outsideLaborCost; // SF_PS_Credited_PO_Amount__c
        public String outsideLaborDescription; //SF_PS_Outside_Labor_Des__c;
        public String workOrderLineNumber; //SF_PS_RM_Orig_Line_Item_Num__c
    } 
    
    
    
    private static List<woCliPartsDetailsClass> woCliPartsgenerateWrapper (List<SF_PS_Credited_Part__c > cpList ) {
        List<woCliPartsDetailsClass> woCliPartsWrapper = new List<woCliPartsDetailsClass>();
        for (SF_PS_Credited_Part__c  cp : cpList){
            woCliPartsDetailsClass cliPartsDetails = new woCliPartsDetailsClass(); 
            cliPartsDetails.sourceReferenceLineNumber = cp.Id;
            cliPartsDetails.itemNumber = cp.SF_PS_Product2Id__c;
            cliPartsDetails.stockClass = cp.SF_PS_Stock_Class__c;
            cliPartsDetails.quantity = cp.SF_PS_Parts_To_Credit__c == null ? 0.0 : Double.valueOf(cp.SF_PS_Parts_To_Credit__c) ;
            cliPartsDetails.unitOfMeasure = cp.SF_PS_Unit_Of_Measure__c;
            cliPartsDetails.sellingPrice = cp.SF_PS_Selling_Price__c == null ? 0.0 : (cp.SF_PS_Selling_Price__c).setScale(2) ;
            cliPartsDetails.laborCode = cp.SF_PS_Labor_Code__c== null ? 0 :Integer.valueOf(cp.SF_PS_Labor_Code__c);
            cliPartsDetails.cost = cp.SF_PS_Cost_Price__c == null ? 0.0 : (cp.SF_PS_Cost_Price__c).setScale(2);
            cliPartsDetails.comments = cp.SF_PS_Line_Level_Comment__c;
            cliPartsDetails.restockYN = cp.SF_PS_Restock__c;
            cliPartsDetails.workOrderSequenceNumber = cp.SF_PS_RM_Orig_Line_Item_Num__c;
            woCliPartsWrapper.add(cliPartsDetails);
        }
        return woCliPartsWrapper;
    }
    
    class woCliPartsDetailsClass{
        public String sourceReferenceLineNumber; //productconsumed.Id
        public String itemNumber; //SF_PS_Product2Id__c
        public String stockClass; //SF_PS_Stock_Class__c
        public Decimal quantity;  //SF_PS_Parts_To_Credit__c
        public String unitOfMeasure; //SF_PS_Unit_Of_Measure__c
        public Decimal sellingPrice; //SF_PS_Selling_Price__c SF_PS_Selling_Price__c
        public Integer laborCode;  //SF_PS_Labor_Code__c
        public Decimal cost; //SF_PS_Cost_Price__c //
        public String comments; //SF_PS_Line_Level_Comment__c
        public String restockYN; //SF_PS_Restock__c
        public String workOrderSequenceNumber; //SF_PS_RM_Orig_Line_Item_Num__c
    }
    
    
    
    private static woCliMilegeDetailsClass woCliMileageWrapper(SF_PS_Credit_Line_Item__c  cli) {        
        woCliMilegeDetailsClass cliMilegeDetails = new woCliMilegeDetailsClass(); 
        cliMilegeDetails.sourceReferenceLineNumber = cli.Id;
        cliMilegeDetails.mileageMiles = cli.SF_PS_Hr_Mi_To_Credit__c == null ? 0.0 : cli.SF_PS_Hr_Mi_To_Credit__c;
        cliMilegeDetails.mileageRate =cli.SF_PS_Credit_Rate_Hr_Mi__c == null ? 0.0 : cli.SF_PS_Credit_Rate_Hr_Mi__c;
        cliMilegeDetails.laborCode = cli.SF_PS_Labor_Code__c== null ? 0 :Integer.valueOf(cli.SF_PS_Labor_Code__c);
        cliMilegeDetails.workOrderLineNumber = cli.SF_PS_RM_Orig_Line_Item_Num__c;
        return cliMilegeDetails;
    } 
    class woCliMilegeDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public Decimal mileageMiles;  // SF_PS_Hr_Mi_To_Credit__c
        public Decimal mileageRate;   // SF_PS_Credit_Rate_Hr_Mi__c
        public Integer laborCode;	//SF_PS_Labor_Code__c
        public String workOrderLineNumber; //SF_PS_RM_Orig_Line_Item_Num__c
    } 
    
    public class WrappedResponse{
        public string workOrderNumber{get;set;}
        public string workOrderCreditNumber{get;set;}
        public string mode{get;set;} 
        public string message;
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
        public list<workOrderCreditLineItemsWrapper> workOrderCreditLineItems{get;set;}
        public list<partsWrapper> parts{get;set;}
    }
    public class workOrderCreditLineItemsWrapper{
        public string workOrderCreditLineItemNumber;
        public string uniqueId;
        public string sourceReferenceLineNumber;
    } 
    public class partsWrapper{
        public string workOrderCreditLineItemNumber;
        public string uniqueId;
        public string sourceReferenceLineNumber;
    }    
}