@isTest
public class SBR_3_0_API_Web_PurchaseOrderRcpt_Test {

    @TestSetup
    private static void dataSetup(){
        DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
        String rm_acc = '1234567';
        Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', rm_acc, '01');
        List<Purchase_Order__c> pos = SBR_3_0_POTestDataFactory.createPurchaseOrders(1, acct, true);  
        pos[0].Name = '1005432';
        pos[0].Company_Code__c = '01';
        pos[0].PO_Number__c = '1005432';
        update pos[0];
        
        integer counter = 0;
        List<PO_Line_Item__c> poLineItems = SBR_3_0_POTestDataFactory.createPurchaseOrderLineItems(3, pos[0].Id, true);
        for(PO_Line_Item__c poli : poLineItems){
            counter++;
            poli.ExternalId__c = pos[0].Company_Code__c + '-' + pos[0].PO_Number__c + '-' + String.valueOf(counter);
            poli.PO_Number__c = decimal.valueOf(pos[0].PO_Number__c);
            poli.Company_Code__c = pos[0].Company_Code__c;
            poli.Line_Item_Num__c = counter;
        }
        update poLineItems;
        system.debug('Value of poLineItems---> ' +poLineItems);
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testdatauser@example.com',
            Wynne_User_Name__c = 'MWILKINSON',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
    }
    
    @isTest
    private static void createPOLineItemsReceiptTest() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Receipt__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJsonSuccess());
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderReceipts.createPOReceipts();
        Test.stopTest();
         
        System.assertEquals(3, [SELECT COUNT() FROM PO_Receipt__c]); 
    }
    
    @isTest
    private static void createPOLiRcptNegativePOTest() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Receipt__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJsonNotMatchingPO());
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderReceipts.createPOReceipts();
        Test.stopTest();
         
        System.assertNotEquals(3, [SELECT COUNT() FROM PO_Receipt__c]);  
    }
    
    @isTest
    private static void createPOLiRcptNegativePOLiTest() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Receipt__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJsonNotMatchingPOLineItems());
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderReceipts.createPOReceipts();
        Test.stopTest();
         
        System.assertNotEquals(3, [SELECT COUNT() FROM PO_Receipt__c]);  
    }
    
    @isTest
    private static void createPOLiRcptNegative() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Receipt__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        String requestBody = '{"field1": "value1", "field2": "value2"}';
        request.requestBody = Blob.valueOf(requestBody);
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderReceipts.createPOReceipts();
        Test.stopTest();
         
        System.assertNotEquals(3, [SELECT COUNT() FROM PO_Receipt__c]);  
    }
    
    
    private static String getJsonSuccess(){
        return '{                                       ' +
                '	"poreceipts" : [                     ' +
                '		{                                ' +
                '		  "ExternalId__c":"01-1005432-1",' +
                '		  "Company_Code__c": "01",       ' +
                '		  "Location__c": "0001",         ' +
                '		  "PO_Number__c": 1005432,       ' +
                '		  "Receiver_Number__c": 989898,  ' +
                '		  "Line_Item__c": 1,             ' +
                '		  "Stock_Class__c": "NEWHC",     ' +
                '		  "Equipment__c": "",            ' +
                '		  "Quantity_Received__c": 15,    ' +
                '		  "Unit_Cost__c": 1,             ' +
                '		  "Units__c": "EA",              ' +
                '		  "Received_Location__c": "",    ' +
                '		  "Vendor_Number__c": 0,         ' +
                '		  "Overage__c": "",              ' +
                '		  "Date_Received__c": 0,         ' +
                '		  "Time_Received__c": 0,         ' +
                '		  "Received_By__c": "",          ' +
                '		  "Status__c": "",               ' +
                '		  "Reason_Code__c": "",          ' +
                '		  "Created_From__c": "",         ' +
                '		  "RM_System_Date__c": 0,        ' +
                '		  "RM_System_Time__c": 0,        ' +
                '		  "Last_Maint_Date__c": 0,       ' +
                '		  "Last_Maint_Time__c": 0,       ' +
                '		  "Last_Maint_By__c": "",        ' +
                '		  "Pgm_Defined_Flag__c": "",     ' +
                '		  "AP_Invoice_Num__c": "",       ' +
                '		  "AP_Invoice_Seq__c": 0,        ' +
                '		  "AP_Check_Date__c": 0,         ' +
                '		  "AP_Check_Number__c": 0,       ' +
                '		  "Check_Amount__c": 0,          ' +
                '		  "Qty_On_Hand__c": 0,           ' +
                '		  "Last_Cost__c": 0,             ' +
                '		  "Average_Cost__c": 0,          ' +
                '		  "New_Average_Cost__c": 0,      ' +
                '		  "Requisition_Num__c": 0,       ' +
                '		  "Sequence_Num__c": 0,          ' +
                '		  "Currency_Code__c": "",        ' +
                '		  "Curr_Exchange_Rate__c": 0,    ' +
                '		  "Contract_Number__c": 0,       ' +
                '		  "Contract_Inv_Seq__c": 0,      ' +
                '		  "Receiver_Seq__c": 0,          ' +
                '		  "Adj_Receiver_Seq__c": 0,      ' +
                '		  "Tax_Code__c": "",             ' +
                '		  "Tax_Amount__c": 0,            ' +
                '		  "Equipment_Type__c": "",       ' +
                '		  "Delivery_Note_Number__c": "", ' +
                '		  "Inventory_Loss_Amt__c": 0,    ' +
                '		  "Transaction_Cost__c": 0,      ' +
                '		  "Item_History_Id__c": 0,       ' +
                '		  "Messages__c":"item number 3"  ' +
                '		},                               ' +
                '		{                                ' +
                '		  "ExternalId__c":"01-1005432-2",' +
                '		  "Company_Code__c": "01",       ' +
                '		  "Location__c": "0001",         ' +
                '		  "PO_Number__c": 1005432,       ' +
                '		  "Receiver_Number__c": 989898,  ' +
                '		  "Line_Item__c": 2,             ' +
                '		  "Stock_Class__c": "NEWHC",     ' +
                '		  "Equipment__c": "",            ' +
                '		  "Quantity_Received__c": 12,    ' +
                '		  "Unit_Cost__c": 1,             ' +
                '		  "Units__c": "EA",              ' +
                '		  "Received_Location__c": "",    ' +
                '		  "Vendor_Number__c": 0,         ' +
                '		  "Overage__c": "",              ' +
                '		  "Date_Received__c": 0,         ' +
                '		  "Time_Received__c": 0,         ' +
                '		  "Received_By__c": "",          ' +
                '		  "Status__c": "",               ' +
                '		  "Reason_Code__c": "",          ' +
                '		  "Created_From__c": "",         ' +
                '		  "RM_System_Date__c": 0,        ' +
                '		  "RM_System_Time__c": 0,        ' +
                '		  "Last_Maint_Date__c": 0,       ' +
                '		  "Last_Maint_Time__c": 0,       ' +
                '		  "Last_Maint_By__c": "",        ' +
                '		  "Pgm_Defined_Flag__c": "",     ' +
                '		  "AP_Invoice_Num__c": "",       ' +
                '		  "AP_Invoice_Seq__c": 0,        ' +
                '		  "AP_Check_Date__c": 0,         ' +
                '		  "AP_Check_Number__c": 0,       ' +
                '		  "Check_Amount__c": 0,          ' +
                '		  "Qty_On_Hand__c": 0,           ' +
                '		  "Last_Cost__c": 0,             ' +
                '		  "Average_Cost__c": 0,          ' +
                '		  "New_Average_Cost__c": 0,      ' +
                '		  "Requisition_Num__c": 0,       ' +
                '		  "Sequence_Num__c": 0,          ' +
                '		  "Currency_Code__c": "",        ' +
                '		  "Curr_Exchange_Rate__c": 0,    ' +
                '		  "Contract_Number__c": 0,       ' +
                '		  "Contract_Inv_Seq__c": 0,      ' +
                '		  "Receiver_Seq__c": 0,          ' +
                '		  "Adj_Receiver_Seq__c": 0,      ' +
                '		  "Tax_Code__c": "",             ' +
                '		  "Tax_Amount__c": 0,            ' +
                '		  "Equipment_Type__c": "",       ' +
                '		  "Delivery_Note_Number__c": "", ' +
                '		  "Inventory_Loss_Amt__c": 0,    ' +
                '		  "Transaction_Cost__c": 0,      ' +
                '		  "Item_History_Id__c": 0,       ' +
                '		  "Messages__c": "item number 3" ' +
                '		},                               ' +
                '		{                                ' +
                '		  "ExternalId__c":"01-1005432-3",' +
                '		  "Company_Code__c": "01",       ' +
                '		  "Location__c": "0001",         ' +
                '		  "PO_Number__c": 1005432,       ' +
                '		  "Receiver_Number__c": 989898,  ' +
                '		  "Line_Item__c": 3,             ' +
                '		  "Stock_Class__c": "NEWHC",     ' +
                '		  "Equipment__c": "",            ' +
                '		  "Quantity_Received__c": 4,     ' +
                '		  "Unit_Cost__c": 1,             ' +
                '		  "Units__c": "EA",              ' +
                '		  "Received_Location__c": "",    ' +
                '		  "Vendor_Number__c": 0,         ' +
                '		  "Overage__c": "",              ' +
                '		  "Date_Received__c": 0,         ' +
                '		  "Time_Received__c": 0,         ' +
                '		  "Received_By__c": "",          ' +
                '		  "Status__c": "",               ' +
                '		  "Reason_Code__c": "",          ' +
                '		  "Created_From__c": "",         ' +
                '		  "RM_System_Date__c": 0,        ' +
                '		  "RM_System_Time__c": 0,        ' +
                '		  "Last_Maint_Date__c": 0,       ' +
                '		  "Last_Maint_Time__c": 0,       ' +
                '		  "Last_Maint_By__c": "",        ' +
                '		  "Pgm_Defined_Flag__c": "",     ' +
                '		  "AP_Invoice_Num__c": "",       ' +
                '		  "AP_Invoice_Seq__c": 0,        ' +
                '		  "AP_Check_Date__c": 0,         ' +
                '		  "AP_Check_Number__c": 0,       ' +
                '		  "Check_Amount__c": 0,          ' +
                '		  "Qty_On_Hand__c": 0,           ' +
                '		  "Last_Cost__c": 0,             ' +
                '		  "Average_Cost__c": 0,          ' +
                '		  "New_Average_Cost__c": 0,      ' +
                '		  "Requisition_Num__c": 0,       ' +
                '		  "Sequence_Num__c": 0,          ' +
                '		  "Currency_Code__c": "",        ' +
                '		  "Curr_Exchange_Rate__c": 0,    ' +
                '		  "Contract_Number__c": 0,       ' +
                '		  "Contract_Inv_Seq__c": 0,      ' +
                '		  "Receiver_Seq__c": 0,          ' +
                '		  "Adj_Receiver_Seq__c": 0,      ' +
                '		  "Tax_Code__c": "",             ' +
                '		  "Tax_Amount__c": 0,            ' +
                '		  "Equipment_Type__c": "",       ' +
                '		  "Delivery_Note_Number__c": "", ' +
                '		  "Inventory_Loss_Amt__c": 0,    ' +
                '		  "Transaction_Cost__c": 0,      ' +
                '		  "Item_History_Id__c": 0,       ' +
                '		  "Messages__c": "item number 3" ' +
                '		}    ' +
                '	]        ' +
                '}';
    }    
    
    private static String getJsonNotMatchingPO(){
        // Not matching PO Number so no POs retrieved.
        return '{                                        ' +
                '	"poreceipts" : [                     ' +
                '		{                                ' +
                '		  "ExternalId__c":"01-5555555-1",' +
                '		  "Company_Code__c": "01",       ' +
                '		  "Location__c": "0001",         ' +
                '		  "PO_Number__c": 5555555,       ' +
                '		  "Receiver_Number__c": 989898,  ' +
                '		  "Line_Item__c": 1,             ' +
                '		  "Stock_Class__c": "NEWHC",     ' +
                '		  "Equipment__c": "",            ' +
                '		  "Quantity_Received__c": 15,    ' +
                '		  "Unit_Cost__c": 1,             ' +
                '		  "Units__c": "EA",              ' +
                '		  "Received_Location__c": "",    ' +
                '		  "Vendor_Number__c": 0,         ' +
                '		  "Overage__c": "",              ' +
                '		  "Date_Received__c": 0,         ' +
                '		  "Time_Received__c": 0,         ' +
                '		  "Received_By__c": "",          ' +
                '		  "Status__c": "",               ' +
                '		  "Reason_Code__c": "",          ' +
                '		  "Created_From__c": "",         ' +
                '		  "RM_System_Date__c": 0,        ' +
                '		  "RM_System_Time__c": 0,        ' +
                '		  "Last_Maint_Date__c": 0,       ' +
                '		  "Last_Maint_Time__c": 0,       ' +
                '		  "Last_Maint_By__c": "",        ' +
                '		  "Pgm_Defined_Flag__c": "",     ' +
                '		  "AP_Invoice_Num__c": "",       ' +
                '		  "AP_Invoice_Seq__c": 0,        ' +
                '		  "AP_Check_Date__c": 0,         ' +
                '		  "AP_Check_Number__c": 0,       ' +
                '		  "Check_Amount__c": 0,          ' +
                '		  "Qty_On_Hand__c": 0,           ' +
                '		  "Last_Cost__c": 0,             ' +
                '		  "Average_Cost__c": 0,          ' +
                '		  "New_Average_Cost__c": 0,      ' +
                '		  "Requisition_Num__c": 0,       ' +
                '		  "Sequence_Num__c": 0,          ' +
                '		  "Currency_Code__c": "",        ' +
                '		  "Curr_Exchange_Rate__c": 0,    ' +
                '		  "Contract_Number__c": 0,       ' +
                '		  "Contract_Inv_Seq__c": 0,      ' +
                '		  "Receiver_Seq__c": 0,          ' +
                '		  "Adj_Receiver_Seq__c": 0,      ' +
                '		  "Tax_Code__c": "",             ' +
                '		  "Tax_Amount__c": 0,            ' +
                '		  "Equipment_Type__c": "",       ' +
                '		  "Delivery_Note_Number__c": "", ' +
                '		  "Inventory_Loss_Amt__c": 0,    ' +
                '		  "Transaction_Cost__c": 0,      ' +
                '		  "Item_History_Id__c": 0,       ' +
                '		  "Messages__c":"item number 3"  ' +
                '		}								 ' +           
            '    ]                                       '+
            '}                                           ';
    }    
    
    private static String getJsonNotMatchingPOLineItems(){
        // Not matching Line_Item__c - no Po LIne items retrieved.
        return '{                                        ' +
                '	"poreceipts" : [                     ' +
                '		{                                ' +
                '		  "ExternalId__c":"01-1005432-1",' +
                '		  "Company_Code__c": "01",       ' +
                '		  "Location__c": "0001",         ' +
                '		  "PO_Number__c": 1005432,       ' +
                '		  "Receiver_Number__c": 989898,  ' +
                '		  "Line_Item__c": 5,             ' +
                '		  "Stock_Class__c": "NEWHC",     ' +
                '		  "Equipment__c": "",            ' +
                '		  "Quantity_Received__c": 15,    ' +
                '		  "Unit_Cost__c": 1,             ' +
                '		  "Units__c": "EA",              ' +
                '		  "Received_Location__c": "",    ' +
                '		  "Vendor_Number__c": 0,         ' +
                '		  "Overage__c": "",              ' +
                '		  "Date_Received__c": 0,         ' +
                '		  "Time_Received__c": 0,         ' +
                '		  "Received_By__c": "",          ' +
                '		  "Status__c": "",               ' +
                '		  "Reason_Code__c": "",          ' +
                '		  "Created_From__c": "",         ' +
                '		  "RM_System_Date__c": 0,        ' +
                '		  "RM_System_Time__c": 0,        ' +
                '		  "Last_Maint_Date__c": 0,       ' +
                '		  "Last_Maint_Time__c": 0,       ' +
                '		  "Last_Maint_By__c": "",        ' +
                '		  "Pgm_Defined_Flag__c": "",     ' +
                '		  "AP_Invoice_Num__c": "",       ' +
                '		  "AP_Invoice_Seq__c": 0,        ' +
                '		  "AP_Check_Date__c": 0,         ' +
                '		  "AP_Check_Number__c": 0,       ' +
                '		  "Check_Amount__c": 0,          ' +
                '		  "Qty_On_Hand__c": 0,           ' +
                '		  "Last_Cost__c": 0,             ' +
                '		  "Average_Cost__c": 0,          ' +
                '		  "New_Average_Cost__c": 0,      ' +
                '		  "Requisition_Num__c": 0,       ' +
                '		  "Sequence_Num__c": 0,          ' +
                '		  "Currency_Code__c": "",        ' +
                '		  "Curr_Exchange_Rate__c": 0,    ' +
                '		  "Contract_Number__c": 0,       ' +
                '		  "Contract_Inv_Seq__c": 0,      ' +
                '		  "Receiver_Seq__c": 0,          ' +
                '		  "Adj_Receiver_Seq__c": 0,      ' +
                '		  "Tax_Code__c": "",             ' +
                '		  "Tax_Amount__c": 0,            ' +
                '		  "Equipment_Type__c": "",       ' +
                '		  "Delivery_Note_Number__c": "", ' +
                '		  "Inventory_Loss_Amt__c": 0,    ' +
                '		  "Transaction_Cost__c": 0,      ' +
                '		  "Item_History_Id__c": 0,       ' +
                '		  "Messages__c":"item number 3"  ' +
                '		}								 ' +           
                '    ]                                    '+
            '}                                           ';
    }    
    
}