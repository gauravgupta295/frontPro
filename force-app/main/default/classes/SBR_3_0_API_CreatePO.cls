/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreatePO
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Purchase Order and Purchase Order Line Items to Rentalman (via Mulesoft) when Create PO button is clicked in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Sanket Raj            2024-04-01             Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_CreatePO {
    private static final String APINAME = 'API_Purchase_Order_Test';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    public static Id purchaseOrderId;
    public static Boolean testRun = false;
    
    @AuraEnabled
    public static SBR_3_0_API_CreatePO createPO(Id poId, Boolean test) {
        purchaseOrderId = poId;
        testRun = test;
        return new SBR_3_0_API_CreatePO(purchaseOrderId);
    }

    public SBR_3_0_API_CreatePO(Id purchaseOrderId) {
        try {
            List<Purchase_Order__c> purchaseOrderList = [SELECT Id,	Name,	ExternalId__c,	Vendor__c,	Vendor_Number__c,	Company_Code__c,	Location__c,	Branch_Location__c,	ShipTo_Name__c,	ShipTo_Addr1__c,	ShipTo_Addr2__c,	ShipTo_City__c,	ShipTo_State__c,	ShipTo_Zip__c,	ShipTo_Phone__c,	Status__c,	Issue_Date__c,	Promised_Date__c,	Requested_Date__c,	Closed_Date__c,	OrderedBy_Text__c,	Ordered_From__c,	Ordered_For__c,	PO_Total__c,	PO_Tax__c,	Material_Code__c,	Employee__c,	Taxable__c,	Tax_Pct__c,	Ship_Method__c,	Terms__c,	FOB__c,	ShipTo__c,	Customer_or_Contract_Number__c,	Alternate_AddrNum__c,	Reference_Num__c,	CurrencyISOCode,	CurrencyExchangeRate__c,	Order_Time__c,	Driv_Lic_State__c,	Driv_Lic_Num__c,	Misc_Group3__c,	Third_Party_RefNum__c,	RM_User__c,	RM_Last_Modified_Date__c,	RM_Last_Modified_Time__c,	Term_Days__c,	Disc_Pct__c,	Disc_Days__c,	Reason_Code__c,	Invoice_Due_Date_Code__c,	Job_Num__c,	Account_Num__c,	PhoneNumberType__c,	InternationPhoneNumber__c,	Project_Num__c,	Phase_Num__c, Carrier_Num__c, Terms_Code_Override__c, Pay_By_Date__c, PO_Comments__c, OwnerId, LastModifiedDate FROM Purchase_Order__c WHERE Id =:purchaseOrderId LIMIT 10];
            Map<Id, Purchase_Order__c> poMap = new Map<Id, Purchase_Order__c>(purchaseOrderList);

            if(purchaseOrderList.size() > 0) {
                List<PO_Line_Item__c> poLineItems = [SELECT Id,	Company_Code__c, Item_Desc__c,	Line_Item_Num__c,	Item_Number__c,	Stock_Class__c,	Vendor_Item_Num__c,	Unit_Cost__c,	Open_Order_Qty__c,	Quantity_Rcvd__c,	Quantity__c,	Units__c,	Total_Cost__c,	Total_Disc_Pct__c,	Discount_Pct1__c,	Discount_Pct2__c,	Discount_Pct3__c,	Status__c,	PO_Date__c,	Request_Date__c,	Due_Date__c,	Date_Rcvd__c,	Taxable__c,	Order_Location__c,	ShipTo_Location__c,	Warehouse__c,	GL_Account__c,	Item_Type__c,	Drop_Shipment__c,	AcctNumber__c,	Driver_Lic_State__c,	Driver_Lic_Num__c,	ContractOrWONumberOrCustNumber__c,	Equipment_Num__c,	RM_SystemDate__c,	RM_SystemTime__c,	Config_Num__c,	OrderedBy_Text__c,	Tax_Code__c,	Job_Num__c,	Equipment_Type__c,	Work_Code__c,	Analysis_Code1__c,	Analysis_Code2__c,	Analysis_Code3__c,	Analysis_Code4__c,	Analysis_Code5__c,	Analysis_Code6__c,	Transaction_Cost__c,	Purchase_Reason__c,	Third_Party_DtlNum__c,	Freight_Type__c,	Freight_Reason__c,	Order_Comments_Line_Level__c,	ProductSkuNumber__c,	RM_Item_Type__c, LastModifiedDate  FROM PO_Line_Item__c WHERE Purchase_Order__c =:purchaseOrderId LIMIT 49999];
                Map<Id, PO_Line_Item__c> poLIMap = new Map<Id, PO_Line_Item__c>(poLineItems);
                
                Purchase_Order__c purchaseOrder = purchaseOrderList[0];
                User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
                String rentalManUserName = (loggedInUser != null && loggedInUser.Wynne_User_Name__c != null) ? loggedInUser.Wynne_User_Name__c :'WROHR';
                string emptyString = '';
                SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                WrappedResponse response = new WrappedResponse();
                HttpRequest req = httpCallout.getRequest();
                System.debug('@@req:' + req);
                string poNumber = '';
                string venNumber = '';
                JSONGenerator gen = JSON.createGenerator(false);
                gen.writeStartObject();
                gen.writeFieldName('body');
                gen.writeStartObject();
                //#region Purchase Order
                gen.writeStringField('Salesforce_Id',purchaseOrder.Id);
                gen.writeStringField('Name',purchaseOrder.Name);
                poNumber = purchaseOrder.Name;
                gen.writeStringField('Vendor__c',purchaseOrder.Vendor__c ?? emptyString);
                gen.writeStringField('Vendor_Number__c',purchaseOrder.Vendor_Number__c ?? emptyString);
                venNumber = purchaseOrder.Vendor_Number__c;
                gen.writeStringField('Company_Code__c',purchaseOrder.Company_Code__c);
                gen.writeStringField('Location__c',(purchaseOrder.Location__c == null ? emptyString : purchaseOrder.Location__c));
                gen.writeStringField('Branch_Location__c',(purchaseOrder.Branch_Location__c == null ? emptyString : purchaseOrder.Branch_Location__c));
                gen.writeStringField('ShipTo_Name__c',purchaseOrder.ShipTo_Name__c ?? emptyString);
                gen.writeStringField('ShipTo_Addr1__c',purchaseOrder.ShipTo_Addr1__c ?? emptyString);
                gen.writeStringField('ShipTo_Addr2__c',purchaseOrder.ShipTo_Addr2__c ?? emptyString);
                gen.writeStringField('ShipTo_City__c',purchaseOrder.ShipTo_City__c ?? emptyString);
                gen.writeStringField('ShipTo_State__c',purchaseOrder.ShipTo_State__c ?? emptyString);
                gen.writeStringField('ShipTo_Zip__c',purchaseOrder.ShipTo_Zip__c ?? emptyString);
                gen.writeStringField('ShipTo_Phone__c',purchaseOrder.ShipTo_Phone__c ?? emptyString);
                gen.writeStringField('Status__c',purchaseOrder.Status__c ?? emptyString);
                gen.writeStringField('Issue_Date__c',convertDateToString(purchaseOrder.Issue_Date__c) ?? emptyString);
                gen.writeStringField('Promised_Date__c',convertDateToString(purchaseOrder.Promised_Date__c) ?? emptyString);
                gen.writeStringField('Requested_Date__c',convertDateToString(purchaseOrder.Requested_Date__c) ?? emptyString);
                gen.writeStringField('Closed_Date__c',convertDateToString(purchaseOrder.Closed_Date__c) ?? emptyString);
                gen.writeStringField('OrderedBy_Text__c',purchaseOrder.OrderedBy_Text__c ?? emptyString);
                gen.writeStringField('Ordered_From__c',purchaseOrder.Ordered_From__c ?? emptyString);
                gen.writeStringField('Ordered_For__c',purchaseOrder.Ordered_For__c ?? emptyString);
                gen.writeNumberField('PO_Total__c',purchaseOrder.PO_Total__c ?? 0);
                gen.writeNumberField('PO_Tax__c',purchaseOrder.PO_Tax__c ?? 0);
                gen.writeStringField('Material_Code__c',purchaseOrder.Material_Code__c ?? emptyString);
                gen.writeStringField('Employee__c',purchaseOrder.Employee__c ?? emptyString);
                gen.writeStringField('Taxable__c',purchaseOrder.Taxable__c ?? emptyString);
                gen.writeNumberField('Tax_Pct__c',purchaseOrder.Tax_Pct__c ?? 0);
                gen.writeStringField('Ship_Method__c',purchaseOrder.Ship_Method__c ?? emptyString);
                gen.writeStringField('Terms__c',purchaseOrder.Terms__c ?? emptyString);
                gen.writeStringField('FOB__c',purchaseOrder.FOB__c ?? emptyString);
                gen.writeStringField('ShipTo__c',purchaseOrder.ShipTo__c ?? emptyString);
                gen.writeNumberField('Customer_or_Contract_Number__c',purchaseOrder.Customer_or_Contract_Number__c ?? 0);
                gen.writeStringField('Alternate_AddrNum__c',purchaseOrder.Alternate_AddrNum__c ?? emptyString);
                gen.writeStringField('Reference_Num__c',purchaseOrder.Reference_Num__c ?? emptyString);
                gen.writeStringField('CurrencyISOCode',purchaseOrder.CurrencyISOCode);
                gen.writeNumberField('CurrencyExchangeRate__c',purchaseOrder.CurrencyExchangeRate__c ?? 0);
                gen.writeNumberField('Order_Time__c',purchaseOrder.Order_Time__c ?? 0);
                gen.writeStringField('Driv_Lic_State__c',purchaseOrder.Driv_Lic_State__c ?? emptyString);
                gen.writeStringField('Driv_Lic_Num__c',purchaseOrder.Driv_Lic_Num__c ?? emptyString);
                gen.writeNumberField('Misc_Group3__c',purchaseOrder.Misc_Group3__c ?? 0);
                gen.writeStringField('Third_Party_RefNum__c',purchaseOrder.Third_Party_RefNum__c ?? emptyString);
                gen.writeNumberField('Term_Days__c',purchaseOrder.Term_Days__c ?? 0);
                gen.writeNumberField('Disc_Pct__c',purchaseOrder.Disc_Pct__c ?? 0);
                gen.writeNumberField('Disc_Days__c',purchaseOrder.Disc_Days__c ?? 0);
                gen.writeStringField('Reason_Code__c',purchaseOrder.Reason_Code__c ?? emptyString);
                gen.writeStringField('Invoice_Due_Date_Code__c',purchaseOrder.Invoice_Due_Date_Code__c ?? emptyString);
                gen.writeStringField('Job_Num__c',purchaseOrder.Job_Num__c ?? emptyString);
                gen.writeNumberField('Account_Num__c',purchaseOrder.Account_Num__c ?? 0);
                gen.writeStringField('PhoneNumberType__c',purchaseOrder.PhoneNumberType__c ?? emptyString);
                gen.writeStringField('InternationPhoneNumber__c',purchaseOrder.InternationPhoneNumber__c ?? emptyString);
                gen.writeNumberField('Project_Num__c',purchaseOrder.Project_Num__c ?? 0);
                gen.writeNumberField('Phase_Num__c',purchaseOrder.Phase_Num__c ?? 0);
                gen.writeNumberField('Carrier_Num__c',Integer.valueOf((Object)purchaseOrder.Carrier_Num__c) ?? 0);
                gen.writeStringField('Terms_Code_Override__c',purchaseOrder.Terms_Code_Override__c ?? emptyString);
                gen.writeStringField('Pay_By_Date__c',convertDateToString(purchaseOrder.Pay_By_Date__c) ?? emptyString);
                gen.writeStringField('PO_Comments__c',purchaseOrder.PO_Comments__c ?? emptyString);
                //#endregion
                gen.writeEndObject();
                gen.writeFieldName('details');
                gen.writeStartArray();
                for(PO_Line_Item__c poLI : poLineItems) {
                    gen.writeStartObject();
                    //#region PO Line Item
                    gen.writeStringField('Salesforce_Id',poLI.Id);
                    gen.writeStringField('Company_Code__c',poLI.Company_Code__c);
                    gen.writeStringField('Vendor_Number__c',venNumber ?? emptyString);
                    gen.writeStringField('Item_Number__c',poLI.Item_Number__c ?? emptyString);
                    gen.writeStringField('Stock_Class__c',poLI.Stock_Class__c ?? emptyString);
                    gen.writeStringField('Vendor_Item_Num__c',poLI.Vendor_Item_Num__c ?? emptyString);
                    gen.writeNumberField('Unit_Cost__c',poLI.Unit_Cost__c ?? 0.000);
                    gen.writeNumberField('Open_Order_Qty__c',poLI.Open_Order_Qty__c ?? 0.0);
                    gen.writeNumberField('Quantity_Rcvd__c',poLI.Quantity_Rcvd__c ?? 0.0);
                    gen.writeNumberField('Quantity__c',poLI.Quantity__c ?? 0);
                    gen.writeStringField('Units__c',poLI.Units__c ?? emptyString);
                    gen.writeNumberField('Total_Cost__c',poLI.Total_Cost__c ?? 0.00);
                    gen.writeNumberField('Total_Disc_Pct__c',poLI.Total_Disc_Pct__c ?? 0.0);
                    gen.writeNumberField('Discount_Pct1__c',poLI.Discount_Pct1__c ?? 0.0);
                    gen.writeNumberField('Discount_Pct2__c',poLI.Discount_Pct2__c ?? 0.0);
                    gen.writeNumberField('Discount_Pct3__c',poLI.Discount_Pct3__c ?? 0.0);
                    gen.writeStringField('Status__c',poLI.Status__c ?? emptyString);
                    gen.writeStringField('PO_Date__c',convertDateToString(poLI.PO_Date__c) ?? emptyString);
                    gen.writeStringField('Request_Date__c',convertDateToString(poLI.Request_Date__c) ?? emptyString);
                    gen.writeStringField('Due_Date__c',convertDateToString(poLI.Due_Date__c) ?? emptyString);
                    gen.writeStringField('Date_Rcvd__c',convertDateToString(poLI.Date_Rcvd__c) ?? emptyString);
                    gen.writeStringField('Taxable__c',poLI.Taxable__c ?? emptyString);
                    gen.writeStringField('Order_Location__c',(poLI.Order_Location__c == null ? emptyString : poLI.Order_Location__c));
                    gen.writeStringField('ShipTo_Location__c',(poLI.ShipTo_Location__c == null ? emptyString : poLI.ShipTo_Location__c));
                    gen.writeStringField('Warehouse__c',poLI.Warehouse__c ?? emptyString);
                    gen.writeNumberField('GL_Account__c',poLI.GL_Account__c ?? 0);
                    gen.writeStringField('Item_Type__c',poLI.Item_Type__c ?? emptyString);
                    gen.writeBooleanField('Drop_Shipment__c',poLI.Drop_Shipment__c == 'Yes' ? true : false);
                    gen.writeNumberField('AcctNumber__c',poLI.AcctNumber__c ?? 0);
                    gen.writeStringField('Driver_Lic_State__c',poLI.Driver_Lic_State__c ?? emptyString);
                    gen.writeStringField('Driver_Lic_Num__c',poLI.Driver_Lic_Num__c ?? emptyString);
                    gen.writeNumberField('ContractOrWONumberOrCustNumber__c',poLI.ContractOrWONumberOrCustNumber__c ?? 0);
                    gen.writeStringField('Equipment_Num__c',poLI.Equipment_Num__c ?? emptyString);
                    gen.writeNumberField('Config_Num__c',poLI.Config_Num__c ?? 0);
                    gen.writeStringField('OrderedBy_Text__c',poLI.OrderedBy_Text__c ?? emptyString);
                    gen.writeStringField('Tax_Code__c',poLI.Tax_Code__c ?? emptyString);
                    gen.writeStringField('Job_Num__c',poLI.Job_Num__c ?? emptyString);
                    gen.writeStringField('Equipment_Type__c',poLI.Equipment_Type__c ?? emptyString);
                    gen.writeStringField('Work_Code__c',poLI.Work_Code__c ?? emptyString);
                    gen.writeNumberField('Analysis_Code1__c',poLI.Analysis_Code1__c ?? 0);
                    gen.writeNumberField('Analysis_Code2__c',poLI.Analysis_Code2__c ?? 0);
                    gen.writeNumberField('Analysis_Code3__c',poLI.Analysis_Code3__c ?? 0);
                    gen.writeNumberField('Analysis_Code4__c',poLI.Analysis_Code4__c ?? 0);
                    gen.writeNumberField('Analysis_Code5__c',poLI.Analysis_Code5__c ?? 0);
                    gen.writeNumberField('Analysis_Code6__c',poLI.Analysis_Code6__c ?? 0);
                    gen.writeNumberField('Transaction_Cost__c',poLI.Transaction_Cost__c ?? 0.0);
                    gen.writeStringField('Purchase_Reason__c',poLI.Purchase_Reason__c ?? emptyString);
                    gen.writeStringField('Third_Party_DtlNum__c',poLI.Third_Party_DtlNum__c ?? emptyString);
                    gen.writeStringField('Freight_Type__c',poLI.Freight_Type__c ?? emptyString);
                    gen.writeStringField('Freight_Reason__c',poLI.Freight_Reason__c ?? emptyString);
                    gen.writeStringField('Order_Comments_Line_Level__c',poLI.Order_Comments_Line_Level__c ?? emptyString);
                    gen.writeNumberField('ProductSkuNumber__c',poLI.ProductSkuNumber__c ?? 0);
                    gen.writeStringField('RM_Item_Type__c',poLI.RM_Item_Type__c ?? emptyString);
                    //#endregion
                    gen.writeEndObject();
                }
                gen.writeEndArray();
                gen.writeEndObject();
                String payload = gen.getAsString();
                System.debug('payload: ' + payload);
                req.setMethod('POST');
                if(Test.isRunningTest()) {
                    if(testRun) {
                        req.setEndpoint(req.getEndpoint() + '/test');
                    }
                    else{
                        req.setEndpoint(req.getEndpoint());
                    }
                }
                else {
                    req.setEndpoint(req.getEndpoint());
                }
                System.debug('req endpoint: ' + req.getEndpoint());
                req.setHeader('thresholdWaitTime', '1');
                req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('requestTimestamp', String.valueOf(purchaseOrder.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
                req.setHeader('sourceSystemUserId', purchaseOrder.OwnerId);
                req.setHeader('sourceSystemName', 'SalesForce');
                req.setHeader('rentalmanUserId', rentalManUserName);
                req.setHeader('companyId', purchaseOrder.Company_Code__c);
                req.setBody(payload);        
                req.setTimeout(119000);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                response.headers = res.getHeaderKeys();
                response.body = res.getBody();
                String returnPayload = res.getBody();
                System.debug('returnPayload: ' + returnPayload);
                System.debug('res.getStatusCode: ' + res.getStatusCode());
                response = (WrappedResponse)JSON.deserialize(returnPayload, WrappedResponse.class);
                System.debug('response: ' + response);
                if (res.getStatusCode() == 200 || res.getStatus() == 'OK' ){
                    List<Purchase_Order__c> poUpdateList = new List<Purchase_Order__c>();
                    Purchase_Order__c po = new Purchase_Order__c();
                    po.Id = response.Salesforce_Id;
                    po.Name = string.valueOf(response.poNumber);
                    poUpdateList.add(po);
                    update poUpdateList;
                    List<PO_Line_Item__c> poLIUpdateList = new List<PO_Line_Item__c>();
                    for(POLineItems poLI : response.poLineItems) {
                        PO_Line_Item__c poLineItem = new PO_Line_Item__c();
                        poLineItem.Id = poLI.Salesforce_Id;
                        poLineItem.Line_Item_Num__c = poLI.Line_Item_Number;
                        poLIUpdateList.add(poLineItem);
                    }
                    update poLIUpdateList;
                }
                else {
                    System.debug ('RM callout not successfull');
                    Exception_Log__c exc = new Exception_Log__c();
                    exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request - ' + payload + ' ' +' Response - ' + response.body;
                    exc.Exception_Type__c = 'SF to RM Outbound Response';
                    exc.Method_Name__c= 'SBR_3_0_API_CreatePO';
                    exc.Class_Name__c= 'SBR_3_0_API_CreatePO';
                    exc.Stack_Trace__c = 'SBR_3_0_API_CreatePO , SBR_3_0_API_CreatePO - line 27 , http.send(req) - Line 757 ';
                    insert exc;
                }     
                if((res.getStatusCode() == 200 || res.getStatus() == 'OK')) {
                    response.status = 'Complete';
                }
            }
        } catch (Exception error) {
            SBR_3_0_LogException.LogIt(error, purchaseOrderId);
            System.debug('Error Line -> ' + error.getStackTraceString());
            System.debug('Error Message -> ' + error.getMessage());		
        }
    }
    public String convertDateToString(Date input) {
        if(input == null) {
            return null;
        }
        else {
            return DateTime.newInstance(
                input.year(), input.month(), input.day()
            ).format('yyyyMMdd');
        }
    }
    public class WrappedResponse {
        public string mode{get;set;} 
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
        public String Salesforce_Id{get;set;}
        public Integer poNumber{get;set;}
        public String message;
        public List<POLineItems> poLineItems{get;set;}
    } 
    public class POLineItems {
        public String Salesforce_Id;
        public Integer Line_Item_Number;
    }
}