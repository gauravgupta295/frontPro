@isTest
public class SBR_3_0_API_Web_PurchaseOrderRerent_Test {

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
        
        Id poRerentRecTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByName().get('Rerent').getRecordTypeId();
        integer counter = 0;
        List<PO_Line_Item__c> poLineItems = SBR_3_0_POTestDataFactory.createPurchaseOrderLineItems(3, pos[0].Id, true);
        for(PO_Line_Item__c poli : poLineItems){
            counter++;
            poli.RecordtypeId= poRerentRecTypeId;
            poli.ExternalId__c = pos[0].Company_Code__c + '-' + pos[0].PO_Number__c + '-' + String.valueOf(counter);
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
    private static void createPOLineItemsRerentTest() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Rerent_Line_Item__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJsonSuccess());
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderRerent.createPORerentLineItems();
        Test.stopTest();
         
        System.assertEquals(3, [SELECT COUNT() FROM PO_Rerent_Line_Item__c]); 
    }
    
    @isTest
    private static void createPOLineItemsRerentNegativePOTest() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Rerent_Line_Item__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJsonNotMatchingPO());
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderRerent.createPORerentLineItems();
        Test.stopTest();
         
        System.assertNotEquals(3, [SELECT COUNT() FROM PO_Rerent_Line_Item__c]);  
    }
    
    @isTest
    private static void createPOLineItemsRerentNegativePOLiTest() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Rerent_Line_Item__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJsonNotMatchingPOLineItems());
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderRerent.createPORerentLineItems();
        Test.stopTest();
         
        System.assertNotEquals(3, [SELECT COUNT() FROM PO_Rerent_Line_Item__c]);  
    }
    
    @isTest
    private static void createPOLineItemsRerentNegative() {
        // Mock request
        String applicationType = 'application/json';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/PO_Rerent_Line_Item__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        String requestBody = '{"field1": "value1", "field2": "value2"}';
        request.requestBody = Blob.valueOf(requestBody);
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrderRerent.createPORerentLineItems();
        Test.stopTest();
         
        System.assertNotEquals(3, [SELECT COUNT() FROM PO_Rerent_Line_Item__c]);  
    }
    
     
    private static String getJsonSuccess(){
        return '{'+
            '    "rerentdetails": [                      '+
            '        {                                   '+
            '            "ExternalId": "01-1005432-1",   '+
            '            "Company_Code__c": "01",        '+
            '            "PO_Number__c": 1005432,        '+
            '            "PO_Sequence__c": 1,            '+
            '            "Category__c": 6,               '+
            '            "Class__c": 1,                  '+
            '            "Status__c": "D",               '+
            '            "Vendor_Number__c": 188420,     '+
            '            "Item_Number__c": "*RR0060001", '+
            '            "Stock_Class__c": "NONST",      '+
            '            "Equipment_Num__c": "458712",   '+
            '            "Make__c": "TESTMAKE",          '+
            '            "Model__c": "TESTMODEL",        '+
            '            "Serial_Number__c": "ACOLETEST",'+
            '            "Min_Rate__c": 60.0,            '+
            '            "Day_Rate__c": 60.0,            '+
            '            "Week_Rate__c": 120.0,          '+
            '            "Month_Rate__c": 440.0,         '+
            '            "Current_Mi_Hr__c": 1500.0,     '+
            '            "Total_AP_Cost__c": 0.0,        '+
            '            "System_Date__c": 20240123,     '+
            '            "System_Time__c": 144922,       '+
            '            "CreatedBy__c": "ACOLETRN",     '+
            '            "Last_Maint_Date__c": 20240123, '+
            '            "Last_Maint_Time__c": 150532,   '+
            '            "Last_Maint_By__c": "ACOLETRN", '+
            '            "Location__c": "0142",          '+
            '            "Region_Work_Field__c": 0,      '+
            '            "Currency_Code__c": "",         '+
            '            "Current_Mi_Hr_2__c": 0.0       '+
            '        },                                  '+
            '        {                                   '+
            '            "ExternalId": "01-1005432-2",   '+
            '            "Company_Code__c": "01",        '+
            '            "PO_Number__c": 1005432,        '+
            '            "PO_Sequence__c": 2,            '+
            '            "Category__c": 6,               '+
            '            "Class__c": 2,                  '+
            '            "Status__c": "D",               '+
            '            "Vendor_Number__c": 188420,     '+
            '            "Item_Number__c": "*RR0060001", '+
            '            "Stock_Class__c": "NONST",      '+
            '            "Equipment_Num__c": "458712",   '+
            '            "Make__c": "TESTMAKE",          '+
            '            "Model__c": "TESTMODEL",        '+
            '            "Serial_Number__c": "ACOLETEST",'+
            '            "Min_Rate__c": 60.0,            '+
            '            "Day_Rate__c": 60.0,            '+
            '            "Week_Rate__c": 120.0,          '+
            '            "Month_Rate__c": 440.0,         '+
            '            "Current_Mi_Hr__c": 1500.0,     '+
            '            "Total_AP_Cost__c": 0.0,        '+
            '            "System_Date__c": 20240123,     '+
            '            "System_Time__c": 144922,       '+
            '            "CreatedBy__c": "ACOLETRN",     '+
            '            "Last_Maint_Date__c": 20240123, '+
            '            "Last_Maint_Time__c": 150532,   '+
            '            "Last_Maint_By__c": "ACOLETRN", '+
            '            "Location__c": "0142",          '+
            '            "Region_Work_Field__c": 0,      '+
            '            "Currency_Code__c": "",         '+
            '            "Current_Mi_Hr_2__c": 0.0       '+
            '        },                                  '+
            '        {                                   '+
            '            "ExternalId": "01-1005432-3",   '+
            '            "Company_Code__c": "01",        '+
            '            "PO_Number__c": 1005432,        '+
            '            "PO_Sequence__c": 3,            '+
            '            "Category__c": 6,               '+
            '            "Class__c": 3,                  '+
            '            "Status__c": "D",               '+
            '            "Vendor_Number__c": 188420,     '+
            '            "Item_Number__c": "*RR0060001", '+
            '            "Stock_Class__c": "NONST",      '+
            '            "Equipment_Num__c": "458712",   '+
            '            "Make__c": "TESTMAKE",          '+
            '            "Model__c": "TESTMODEL",        '+
            '            "Serial_Number__c": "ACOLETEST",'+
            '            "Min_Rate__c": 60.0,            '+
            '            "Day_Rate__c": 60.0,            '+
            '            "Week_Rate__c": 120.0,          '+
            '            "Month_Rate__c": 440.0,         '+
            '            "Current_Mi_Hr__c": 1500.0,     '+
            '            "Total_AP_Cost__c": 0.0,        '+
            '            "System_Date__c": 20240123,     '+
            '            "System_Time__c": 144922,       '+
            '            "CreatedBy__c": "ACOLETRN",     '+
            '            "Last_Maint_Date__c": 20240123, '+
            '            "Last_Maint_Time__c": 150532,   '+
            '            "Last_Maint_By__c": "ACOLETRN", '+
            '            "Location__c": "0142",          '+
            '            "Region_Work_Field__c": 0,      '+
            '            "Currency_Code__c": "",         '+
            '            "Current_Mi_Hr_2__c": 0.0       '+
            '        }									 '+
            '    ]                                       '+
            '};                                          ';
    }    
    
    private static String getJsonNotMatchingPO(){
        return '{'+
            '    "rerentdetails": [                      '+
            '        {                                   '+
            '            "ExternalId": "01-5555555-1",   '+
            '            "Company_Code__c": "01",        '+
            '            "PO_Number__c": 5555555,        '+
            '            "PO_Sequence__c": 1,            '+
            '            "Category__c": 6,               '+
            '            "Class__c": 1,                  '+
            '            "Status__c": "D",               '+
            '            "Vendor_Number__c": 188420,     '+
            '            "Item_Number__c": "*RR0060001", '+
            '            "Stock_Class__c": "NONST",      '+
            '            "Equipment_Num__c": "458712",   '+
            '            "Make__c": "TESTMAKE",          '+
            '            "Model__c": "TESTMODEL",        '+
            '            "Serial_Number__c": "ACOLETEST",'+
            '            "Min_Rate__c": 60.0,            '+
            '            "Day_Rate__c": 60.0,            '+
            '            "Week_Rate__c": 120.0,          '+
            '            "Month_Rate__c": 440.0,         '+
            '            "Current_Mi_Hr__c": 1500.0,     '+
            '            "Total_AP_Cost__c": 0.0,        '+
            '            "System_Date__c": 20240123,     '+
            '            "System_Time__c": 144922,       '+
            '            "CreatedBy__c": "ACOLETRN",     '+
            '            "Last_Maint_Date__c": 20240123, '+
            '            "Last_Maint_Time__c": 150532,   '+
            '            "Last_Maint_By__c": "ACOLETRN", '+
            '            "Location__c": "0142",          '+
            '            "Region_Work_Field__c": 0,      '+
            '            "Currency_Code__c": "",         '+
            '            "Current_Mi_Hr_2__c": 0.0       '+
            '        }                                  '+            
            '    ]                                       '+
            '};                                          ';
    }    
    
    private static String getJsonNotMatchingPOLineItems(){
        return '{'+
            '    "rerentdetails": [                      '+
            '        {                                   '+
            '            "ExternalId": "01-1005432-5",   '+
            '            "Company_Code__c": "01",        '+
            '            "PO_Number__c": 1005432,        '+
            '            "PO_Sequence__c": 1,            '+
            '            "Category__c": 6,               '+
            '            "Class__c": 1,                  '+
            '            "Status__c": "D",               '+
            '            "Vendor_Number__c": 188420,     '+
            '            "Item_Number__c": "*RR0060001", '+
            '            "Stock_Class__c": "NONST",      '+
            '            "Equipment_Num__c": "458712",   '+
            '            "Make__c": "TESTMAKE",          '+
            '            "Model__c": "TESTMODEL",        '+
            '            "Serial_Number__c": "ACOLETEST",'+
            '            "Min_Rate__c": 60.0,            '+
            '            "Day_Rate__c": 60.0,            '+
            '            "Week_Rate__c": 120.0,          '+
            '            "Month_Rate__c": 440.0,         '+
            '            "Current_Mi_Hr__c": 1500.0,     '+
            '            "Total_AP_Cost__c": 0.0,        '+
            '            "System_Date__c": 20240123,     '+
            '            "System_Time__c": 144922,       '+
            '            "CreatedBy__c": "ACOLETRN",     '+
            '            "Last_Maint_Date__c": 20240123, '+
            '            "Last_Maint_Time__c": 150532,   '+
            '            "Last_Maint_By__c": "ACOLETRN", '+
            '            "Location__c": "0142",          '+
            '            "Region_Work_Field__c": 0,      '+
            '            "Currency_Code__c": "",         '+
            '            "Current_Mi_Hr_2__c": 0.0       '+
            '        }                                  '+            
            '    ]                                       '+
            '};                                          ';
    }       
  
}