@isTest
private class SBR_3_0_API_Web_PurchaseOrder_Test {
    
    @TestSetup
    private static void dataSetup(){
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'test');
        insert testPurchaseOrder;
        
        Account accountObj = new Account(
            Name = 'test Data', 
            Vendor_Account_Number__c = '235623369',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId()
        );
        insert accountObj;
        
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
        
        Schema.Location newLocation = new Schema.Location();
        newLocation.Name = 'Test Location';
        newLocation.Branch_Location_Number__c = '0040';
        newLocation.Longitude = 28.635308;
        newLocation.Latitude = 28.635308;
        newLocation.Company_Code__c = '01';
        
        Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get(SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH).getRecordTypeId();
        newLocation.RecordTypeId = recordTypeId;
        
        insert newLocation;
        
        List<Product2> productsToInsert = new List<Product2>();
        // Creating records that match the conditions in the query
        for (Integer i = 0; i < 5; i++) {
            Product2 p = new Product2();
            p.Name = 'Test Product' + i;
            p.Product_SKU__c = 'SKU' + i;
            p.Stock_class__c = '';
            p.Item_Number__c = '#15';
            p.Status__c = 'A';
            p.Company_Code__c = '01';
            p.Product_Type__c = 'Cat-Class';
            productsToInsert.add(p);
        }
        
        // Inserting records
        insert productsToInsert;
    }
    
    @isTest
    private static void createOrderStandard_Test() {
        // Test data setup
        String caseType = 'Standard';
        String expectedResponseBody = '{"success": true, "message": "PO created successfully."}';
        String applicationType = 'application/json';
        
        // Mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Purchase_Order__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJSONBody(caseType));
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrder.createOrder();
        Test.stopTest();
        
        System.assertEquals(2, [SELECT COUNT() FROM Purchase_Order__c]); 
        System.assertEquals(1, [SELECT COUNT() FROM PO_Line_Item__c]); 
    }
    
    @isTest
    private static void createOrderStandardNoFreight_Test() {
        // Test data setup
        String caseType = 'StandardNoFreight';
        String expectedResponseBody = '{"success": true, "message": "PO created successfully."}';
        String applicationType = 'application/json';
        
        // Mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Purchase_Order__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJSONBody(caseType));
        
        // Mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrder.createOrder();
        Test.stopTest();
        
        System.assertEquals(2, [SELECT COUNT() FROM Purchase_Order__c]); 
        System.assertEquals(1, [SELECT COUNT() FROM PO_Line_Item__c]); 
    }
    
    @isTest
    private static void createOrderStandard_400_Test() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/Purchase_Order__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response = response;
        
        String requestBody = '{"field1": "value1", "field2": "value2"}';
        RestContext.request.requestBody = Blob.valueOf(requestBody);
        
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrder.createOrder();
        Test.stopTest();        
        
        System.assertEquals(1, [SELECT COUNT() FROM Purchase_Order__c]); 
        System.assertEquals(0, [SELECT COUNT() FROM PO_Line_Item__c]); 
    }
    
    @isTest
    private static void createOrderRerent_Test() {
        // Test data setup
        String caseType = 'Rerent';
        String expectedResponseBody = '{"success": true, "message": "PO created successfully."}';
        String applicationType = 'application/json';
        
        // Set up mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Purchase_Order__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJSONBody(caseType)); // Add your JSON payload here
        
        // Set up mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the method to be tested
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrder.createOrder();
        Test.stopTest();
        
        System.assertEquals(2, [SELECT COUNT() FROM Purchase_Order__c]); 
        System.assertEquals(1, [SELECT COUNT() FROM PO_Line_Item__c]); 
    }
    
    @isTest
    private static void createOrderRerentNoFreightType_Test() {
        // Test data setup
        String caseType = 'RerentNoFreight';
        String expectedResponseBody = '{"success": true, "message": "PO created successfully."}';
        String applicationType = 'application/json';
        
        // Set up mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Purchase_Order__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJSONBody(caseType)); // Add your JSON payload here
        
        // Set up mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the method to be tested
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrder.createOrder();
        Test.stopTest();
        
        System.assertEquals(2, [SELECT COUNT() FROM Purchase_Order__c]); 
        System.assertEquals(1, [SELECT COUNT() FROM PO_Line_Item__c]); 
    }
    
    @isTest
    private static void createOrder3rdPartyHaulerData_Test() {
        // Test data setup
        String caseType = '3rdPartyHaulerData';
        String expectedResponseBody = '{"success": true, "message": "PO created successfully."}';
        String applicationType = 'application/json';
        
        // Set up mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Purchase_Order__c/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(getJSONBody(caseType)); // Add your JSON payload here
        
        // Set up mock response
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the method to be tested
        Test.startTest();
        SBR_3_0_API_Web_PurchaseOrder.createOrder();
        Test.stopTest();
        
        System.assertEquals(2, [SELECT COUNT() FROM Purchase_Order__c]); 
        System.assertEquals(1, [SELECT COUNT() FROM PO_Line_Item__c]); 
    }
    
    /* Helper Methods */
    private static String getJSONBody(String caseType){
        String jsonBody = '';
        if(caseType.contains('Standard')){
            jsonBody = caseType == 'StandardNoFreight' ? getStandardDataNoFreightType() : getStandardDataFull();
        } else if(caseType.contains('Rerent')){
            jsonBody = caseType == 'RerentNoFreight' ? getRerentDataNoFreightType() : getRerentDataFull();
        } else if(caseType.contains('3rdPartyHaulerData')){
            jsonBody = get3rdPartyHaulerData();
        } else {
            jsonBody = '{"key": "value"}';
        }
        return jsonBody;
    }
    
    private static String get3rdPartyHaulerData(){
        return '{"pobody": {"Name": "1000007","ExternalId__c": "01-1000013","Vendor__c": "235623369","Vendor_Number__c": "235623369","Company_Code__c": "01","Location__c": "0040","Branch_Location__c": "","ShipTo_Name__c": "INDIAN TRAIL PC040","ShipTo_Addr1__c": "1009 TECHNOLOGY DR","ShipTo_Addr2__c": "","ShipTo_City__c": "INDIAN TRAIL","ShipTo_State__c": "NC","ShipTo_Zip__c": "28079 7523","ShipTo_Phone__c": "9088213800","Status__c": "Draft","Issue_Date__c": "20200101","Promised_Date__c": "20200101","Requested_Date__c": "20200101","Closed_Date__c": "20221231","OrderedBy_Text__c": "MWILKINSON","Ordered_From__c": "LAST,FIRST","Ordered_For__c": "","PO_Total__c": 6.48,"PO_Tax__c": 0,"Material_Code__c": "RR","Employee__c": "AKULKARNI","Taxable__c": "Y","Tax_Pct__c": 0,"Ship_Method__c": "Option1","Terms__c": "NET 30 DAYS - 2","FOB__c": "","ShipTo__c": "0040","Customer_or_Contract_Number__c": 0,"Alternate_AddrNum__c": "0","Reference_Num__c": "0","CurrencyISOCode": "USD","CurrencyExchangeRate__c": 0,"Order_Time__c": 110500,"Driv_Lic_State__c": "","Driv_Lic_Num__c": "","Misc_Group3__c": 0,"Third_Party_RefNum__c": "","RM_User__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Term_Days__c": 30,"Disc_Pct__c": 0,"Disc_Days__c": 0,"Reason_Code__c": "","Invoice_Due_Date_Code__c": "","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"PhoneNumberType__c": "","InternationPhoneNumber__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Terms_Code_Override__c": "","Pay_By_Date__c": "20221231","PO_Comments__c": ""},"podetails": [{"Company_Code__c": "01","PO_Number__c": 1000007,"ExternalId": "01-1000013-01","Item_Desc__c": "01-PALME-15","Line_Item_Num__c": 1,"Vendor_Number__c": "235623369","Freight_Type__c": "abcd","Item_Number__c": "#15","Stock_Code__c": "","Ship_After__c": "","Ship_Before__c": "","Ship_Quantity__c": 1,"Price__c": 6.48,"Line_Tax__c": 0,"UM__c": "EA","UM_Conversion_Factor__c": 1,"Item_Desc1__c": "","Item_Desc2__c": "","Item_Desc3__c": "","Item_Desc4__c": "","UM_Conversion__c": "","Taxable__c": "Y","Order_Time__c": 110500,"Third_Party_RefNum__c": "","Cost_Center__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Third_Party_RefNum2__c": "","Inventory_Branch__c": "","Misc_Group3__c": 0,"Reference_Num__c": "0","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"InternationPhoneNumber__c": "","PhoneNumberType__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Pay_By_Date__c": "20221231","PO_Comments__c": ""}]}';
    }
    
    private static String getRerentDataFull(){
        return '{"pobody": {"Name": "1000007","ExternalId__c": "01-1000013","Vendor__c": "235623369","Vendor_Number__c": "235623369","Company_Code__c": "01","Location__c": "0040","Branch_Location__c": "","ShipTo_Name__c": "INDIAN TRAIL PC040","ShipTo_Addr1__c": "1009 TECHNOLOGY DR","ShipTo_Addr2__c": "","ShipTo_City__c": "INDIAN TRAIL","ShipTo_State__c": "NC","ShipTo_Zip__c": "28079 7523","ShipTo_Phone__c": "9088213800","Status__c": "Draft","Issue_Date__c": "20200101","Promised_Date__c": "20200101","Requested_Date__c": "20200101","Closed_Date__c": "20221231","OrderedBy_Text__c": "MWILKINSON","Ordered_From__c": "LAST,FIRST","Ordered_For__c": "","PO_Total__c": 6.48,"PO_Tax__c": 0,"Material_Code__c": "RR","Employee__c": "AKULKARNI","Taxable__c": "Y","Tax_Pct__c": 0,"Ship_Method__c": "Option1","Terms__c": "NET 30 DAYS - 2","FOB__c": "","ShipTo__c": "0040","Customer_or_Contract_Number__c": 0,"Alternate_AddrNum__c": "0","Reference_Num__c": "0","CurrencyISOCode": "USD","CurrencyExchangeRate__c": 0,"Order_Time__c": 110500,"Driv_Lic_State__c": "","Driv_Lic_Num__c": "","Misc_Group3__c": 0,"Third_Party_RefNum__c": "","RM_User__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Term_Days__c": 30,"Disc_Pct__c": 0,"Disc_Days__c": 0,"Reason_Code__c": "","Invoice_Due_Date_Code__c": "","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"PhoneNumberType__c": "","InternationPhoneNumber__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Terms_Code_Override__c": "","Pay_By_Date__c": "20221231","PO_Comments__c": ""},"podetails": [{"Company_Code__c": "01","PO_Number__c": 1000007,"ExternalId": "01-1000013-01","Item_Desc__c": "01-PALME-15","Line_Item_Num__c": 1,"Vendor_Number__c": "235623369","Freight_Type__c": "","Item_Number__c": "#15","Stock_Code__c": "","Ship_After__c": "","Ship_Before__c": "","Ship_Quantity__c": 1,"Price__c": 6.48,"Line_Tax__c": 0,"UM__c": "EA","UM_Conversion_Factor__c": 1,"Item_Desc1__c": "","Item_Desc2__c": "","Item_Desc3__c": "","Item_Desc4__c": "","UM_Conversion__c": "","Taxable__c": "Y","Order_Time__c": 110500,"Third_Party_RefNum__c": "","Cost_Center__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Third_Party_RefNum2__c": "","Inventory_Branch__c": "","Misc_Group3__c": 0,"Reference_Num__c": "0","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"InternationPhoneNumber__c": "","PhoneNumberType__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Pay_By_Date__c": "20221231","PO_Comments__c": ""}]}';
    }
    
    private static String getRerentDataNoFreightType(){
        return '{"pobody": {"Name": "1000007","ExternalId__c": "01-1000013","Vendor__c": "235623369","Vendor_Number__c": "235623369","Company_Code__c": "01","Location__c": "0040","Branch_Location__c": "","ShipTo_Name__c": "INDIAN TRAIL PC040","ShipTo_Addr1__c": "1009 TECHNOLOGY DR","ShipTo_Addr2__c": "","ShipTo_City__c": "INDIAN TRAIL","ShipTo_State__c": "NC","ShipTo_Zip__c": "28079 7523","ShipTo_Phone__c": "9088213800","Status__c": "Draft","Issue_Date__c": "20200101","Promised_Date__c": "20200101","Requested_Date__c": "20200101","Closed_Date__c": "20221231","OrderedBy_Text__c": "MWILKINSON","Ordered_From__c": "LAST,FIRST","Ordered_For__c": "","PO_Total__c": 6.48,"PO_Tax__c": 0,"Material_Code__c": "RR","Employee__c": "AKULKARNI","Taxable__c": "Y","Tax_Pct__c": 0,"Ship_Method__c": "Option1","Terms__c": "NET 30 DAYS - 2","FOB__c": "","ShipTo__c": "0040","Customer_or_Contract_Number__c": 0,"Alternate_AddrNum__c": "0","Reference_Num__c": "0","CurrencyISOCode": "USD","CurrencyExchangeRate__c": 0,"Order_Time__c": 110500,"Driv_Lic_State__c": "","Driv_Lic_Num__c": "","Misc_Group3__c": 0,"Third_Party_RefNum__c": "","RM_User__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Term_Days__c": 30,"Disc_Pct__c": 0,"Disc_Days__c": 0,"Reason_Code__c": "","Invoice_Due_Date_Code__c": "","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"PhoneNumberType__c": "","InternationPhoneNumber__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Terms_Code_Override__c": "","Pay_By_Date__c": "20221231","PO_Comments__c": ""},"podetails": [{"Company_Code__c": "01","PO_Number__c": 1000007,"ExternalId": "01-1000013-01","Item_Desc__c": "01-PALME-15","Line_Item_Num__c": 1,"Vendor_Number__c": "235623369","Freight_Type__c": "","Item_Number__c": "*RR1231234","Stock_Code__c": "","Ship_After__c": "","Ship_Before__c": "","Ship_Quantity__c": 1,"Price__c": 6.48,"Line_Tax__c": 0,"UM__c": "EA","UM_Conversion_Factor__c": 1,"Item_Desc1__c": "","Item_Desc2__c": "","Item_Desc3__c": "","Item_Desc4__c": "","UM_Conversion__c": "","Taxable__c": "Y","Order_Time__c": 110500,"Third_Party_RefNum__c": "","Cost_Center__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Third_Party_RefNum2__c": "","Inventory_Branch__c": "","Misc_Group3__c": 0,"Reference_Num__c": "0","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"InternationPhoneNumber__c": "","PhoneNumberType__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Pay_By_Date__c": "20221231","PO_Comments__c": ""}]}';
    }
    
    private static String getStandardDataFull() {
        return '{"pobody": {"Name": "1000007","ExternalId__c": "01-1000013","Vendor__c": "235623369","Vendor_Number__c": "235623369","Company_Code__c": "01","Location__c": "0040","Branch_Location__c": "","ShipTo_Name__c": "INDIAN TRAIL PC040","ShipTo_Addr1__c": "1009 TECHNOLOGY DR","ShipTo_Addr2__c": "","ShipTo_City__c": "INDIAN TRAIL","ShipTo_State__c": "NC","ShipTo_Zip__c": "28079 7523","ShipTo_Phone__c": "9088213800","Status__c": "Draft","Issue_Date__c": "20200101","Promised_Date__c": "20200101","Requested_Date__c": "20200101","Closed_Date__c": "20221231","OrderedBy_Text__c": "MWILKINSON","Ordered_From__c": "LAST,FIRST","Ordered_For__c": "","PO_Total__c": 6.48,"PO_Tax__c": 0,"Material_Code__c": "RR","Employee__c": "AKULKARNI","Taxable__c": "Y","Tax_Pct__c": 0,"Ship_Method__c": "Option1","Terms__c": "NET 30 DAYS - 2","FOB__c": "","ShipTo__c": "0040","Customer_or_Contract_Number__c": 0,"Alternate_AddrNum__c": "0","Reference_Num__c": "0","CurrencyISOCode": "USD","CurrencyExchangeRate__c": 0,"Order_Time__c": 110500,"Driv_Lic_State__c": "","Driv_Lic_Num__c": "","Misc_Group3__c": 0,"Third_Party_RefNum__c": "","RM_User__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Term_Days__c": 30,"Disc_Pct__c": 0,"Disc_Days__c": 0,"Reason_Code__c": "","Invoice_Due_Date_Code__c": "","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"PhoneNumberType__c": "","InternationPhoneNumber__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Terms_Code_Override__c": "","Pay_By_Date__c": "20221231","PO_Comments__c": ""},"podetails": [{"Company_Code__c": "01","PO_Number__c": 1000007,"ExternalId": "01-1000013-01","Item_Desc__c": "01-PALME-15","Line_Item_Num__c": 1,"Vendor_Number__c": "235623369","Freight_Type__c": "abcd","Item_Number__c": "#15","Stock_Code__c": "","Ship_After__c": "","Ship_Before__c": "","Ship_Quantity__c": 1,"Price__c": 6.48,"Line_Tax__c": 0,"UM__c": "EA","UM_Conversion_Factor__c": 1,"Item_Desc1__c": "","Item_Desc2__c": "","Item_Desc3__c": "","Item_Desc4__c": "","UM_Conversion__c": "","Taxable__c": "Y","Order_Time__c": 110500,"Third_Party_RefNum__c": "","Cost_Center__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Third_Party_RefNum2__c": "","Inventory_Branch__c": "","Misc_Group3__c": 0,"Reference_Num__c": "0","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"InternationPhoneNumber__c": "","PhoneNumberType__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Pay_By_Date__c": "20221231","PO_Comments__c": ""}]}';
    }
    
    private static String getStandardDataNoFreightType() {
        return '{"pobody": {"Name": "1000007","ExternalId__c": "01-1000013","Vendor__c": "235623369","Vendor_Number__c": "235623369","Company_Code__c": "01","Location__c": "0040","Branch_Location__c": "","ShipTo_Name__c": "INDIAN TRAIL PC040","ShipTo_Addr1__c": "1009 TECHNOLOGY DR","ShipTo_Addr2__c": "","ShipTo_City__c": "INDIAN TRAIL","ShipTo_State__c": "NC","ShipTo_Zip__c": "28079 7523","ShipTo_Phone__c": "9088213800","Status__c": "Draft","Issue_Date__c": "20200101","Promised_Date__c": "20200101","Requested_Date__c": "20200101","Closed_Date__c": "20221231","OrderedBy_Text__c": "MWILKINSON","Ordered_From__c": "LAST,FIRST","Ordered_For__c": "","PO_Total__c": 6.48,"PO_Tax__c": 0,"Material_Code__c": "RR","Employee__c": "AKULKARNI","Taxable__c": "Y","Tax_Pct__c": 0,"Ship_Method__c": "Option1","Terms__c": "NET 30 DAYS - 2","FOB__c": "","ShipTo__c": "0040","Customer_or_Contract_Number__c": 0,"Alternate_AddrNum__c": "0","Reference_Num__c": "0","CurrencyISOCode": "USD","CurrencyExchangeRate__c": 0,"Order_Time__c": 110500,"Driv_Lic_State__c": "","Driv_Lic_Num__c": "","Misc_Group3__c": 0,"Third_Party_RefNum__c": "","RM_User__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Term_Days__c": 30,"Disc_Pct__c": 0,"Disc_Days__c": 0,"Reason_Code__c": "","Invoice_Due_Date_Code__c": "","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"PhoneNumberType__c": "","InternationPhoneNumber__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Terms_Code_Override__c": "","Pay_By_Date__c": "20221231","PO_Comments__c": ""},"podetails": [{"Company_Code__c": "01","PO_Number__c": 1000007,"ExternalId": "01-1000013-01","Item_Desc__c": "01-PALME-15","Line_Item_Num__c": 1,"Vendor_Number__c": "235623369","Freight_Type__c": "","Item_Number__c": "#15","Stock_Code__c": "","Ship_After__c": "","Ship_Before__c": "","Ship_Quantity__c": 1,"Price__c": 6.48,"Line_Tax__c": 0,"UM__c": "EA","UM_Conversion_Factor__c": 1,"Item_Desc1__c": "","Item_Desc2__c": "","Item_Desc3__c": "","Item_Desc4__c": "","UM_Conversion__c": "","Taxable__c": "Y","Order_Time__c": 110500,"Third_Party_RefNum__c": "","Cost_Center__c": "","RM_Last_Modified_Date__c": "20200101","RM_Last_Modified_Time__c": "144000","Third_Party_RefNum2__c": "","Inventory_Branch__c": "","Misc_Group3__c": 0,"Reference_Num__c": "0","Job_Num__c": "LAMPASAS","Account_Num__c": 0,"InternationPhoneNumber__c": "","PhoneNumberType__c": "","Project_Num__c": 0,"Phase_Num__c": 0,"Carrier_Num__c": 0,"Pay_By_Date__c": "20221231","PO_Comments__c": ""}]}';
    }
}