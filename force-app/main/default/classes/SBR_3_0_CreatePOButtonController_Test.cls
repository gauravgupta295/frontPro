@isTest
public with sharing class SBR_3_0_CreatePOButtonController_Test {
    @testSetup
    static void createTestData() {
        DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
        Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', '1234567', '01');
        acct.Vendor_Status__c = 'A';
        update acct;
        Purchase_Order__c po= new Purchase_Order__c();
        po.name='testname';
        po.Location__c = '9999';
        po.Vendor_Number__c = '12345';
        po.Vendor__c = acct.Id;
        insert po;

        List<PO_Line_Item__c> lineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            lineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = po.Id,
                Item_Number__c = '10', 
                Quantity__c = 10,
                Unit_Cost__c = 10 ,
                Units__c = '11', 
                Freight_Type__c = 'Delivery', 
                Freight_Reason__c = 'TBD',
                Status__c = 'Draft',                
                RecordTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Rerent').getRecordTypeId()
                
            ));
        }        
        insert lineItems;
        
        List<PO_Rerent_Line_Item__c> reRent = new List<PO_Rerent_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            reRent.add(new PO_Rerent_Line_Item__c(
                PO_Line_Item__c = lineItems.get(i).id,
                Purchase_Order__c = po.Id,
                Min_Rate__c = 10, 
                Day_Rate__c = 10, 
                Week_Rate__c = 10, 
                Month_Rate__c = 10             
            ));
        }
        insert reRent;
        
        Purchase_Order__c tphPO= new Purchase_Order__c();
        tphPO.name='tphpo';
        tphPO.Location__c = '1111';
        tphPO.Vendor_Number__c = '1234';
        tphPO.Vendor__c = acct.Id;
        insert tphPO;

        List<PO_Line_Item__c> tphLineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            string frType = 'D';
            if(i==2) {
                frType = 'S';
            }
            else if(i==3) {
                frType = 'T';
            }
            else if(i==4) {
                frType = 'P';
            }
            tphLineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = tphPO.Id,
                Item_Number__c = '10', 
                Quantity__c = 10,
                Unit_Cost__c = 10 ,
                Units__c = '12', 
                Freight_Type__c = frType, 
                Freight_Reason__c = 'TBD',
                Status__c = 'Draft',
                Transfer_Num__c = 123,
                Contract_Num__c = 123,
                AcctNumber__c = 123,
                RecordTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Third_Party_Hauler').getRecordTypeId()
            ));
        }
        insert tphLineItems;

        Schema.Location loc = new Schema.Location();
        loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        loc.Name = '1799 Innovation Point';
        loc.Street_Address__c = '1799 Innovation Point';
        loc.State__c = 'SC';
        loc.Zip_Code__c = '29715';
        loc.Branch_Location_Number__c = '0411';
        insert loc;

        User_Location__c userLoc = new User_Location__c();
        userLoc.User__c = UserInfo.getUserId();
        userLoc.Branch__c = loc.Id;
        userLoc.ProfileBranche__c = loc.Id;
        insert userLoc;
    }   

    @isTest
    public static void checkRecordCountPos() {
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        Integer poRecCnt = 0;
        Test.startTest();
        poRecCnt = SBR_3_0_CreatePOButtonController.checkRecordCount(po.Id);
        Test.stopTest();
        System.assertEquals(5, poRecCnt, 'Records match');
    }
    @isTest
    public static void checkDraftPOLIStatus() {
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        boolean poRecCnt = false;
        Test.startTest();
            poRecCnt = SBR_3_0_CreatePOButtonController.checkOldPOLI(po.Id);
        Test.stopTest();
        System.assertEquals(true, poRecCnt, 'Records match');
    }
    @isTest
    public static void checkRecordCountNeg() {
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        List<PO_Line_Item__c> lineItems = [SELECT Id, Quantity__c, Unit_Cost__c, Item_Number__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:po.Id];
        delete lineItems;
        Purchase_Order__c tphpo = [SELECT Id FROM Purchase_Order__c WHERE Name = 'tphpo' LIMIT 1];
        List<PO_Line_Item__c> tphLineItems = [SELECT Id, Quantity__c, Unit_Cost__c, Item_Number__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:tphpo.Id];
        delete tphLineItems;
        Integer poRecCnt = 0;
        Test.startTest();
        poRecCnt = SBR_3_0_CreatePOButtonController.checkRecordCount(po.Id);
        Test.stopTest();
        System.assertEquals(0, poRecCnt, 'Records match');
    }
    @isTest
    public static void checkRequiredFieldsRerentNeg() {
        Boolean isValid = true;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        List<PO_Rerent_Line_Item__c> rrLineItems = [SELECT Id, Min_Rate__c, Day_Rate__c, Week_Rate__c, Month_Rate__c FROM PO_Rerent_Line_Item__c WHERE Purchase_Order__c =:po.Id];
        List<PO_Rerent_Line_Item__c> updRRLineItems = new List<PO_Rerent_Line_Item__c>();
        for (PO_Rerent_Line_Item__c rrPOLI : rrLineItems) {
            rrPOLI.Min_Rate__c = null; 
            rrPOLI.Day_Rate__c = null; 
            rrPOLI.Week_Rate__c = null; 
            rrPOLI.Month_Rate__c = null; 
            updRRLineItems.add(rrPOLI);
        }
        update updRRLineItems;
        List<PO_Line_Item__c> lineItems = [SELECT Id, Quantity__c, Unit_Cost__c, Units__c, Item_Number__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:po.Id];
        List<PO_Line_Item__c> updLineItems = new List<PO_Line_Item__c>();
        for (PO_Line_Item__c poLI : lineItems) {
            poLI.Quantity__c = null; 
            poLI.Unit_Cost__c = null; 
            poLI.Units__c = null; 
            poLI.Item_Number__c = null; 
            updLineItems.add(poLI);
        }
        update updLineItems;
        Test.startTest();
        isValid = SBR_3_0_CreatePOButtonController.checkRequiredFields(po.Id);
        Test.stopTest();
        System.assertEquals(false, isValid, 'Value match');
    }
    @isTest
    public static void checkRequiredFieldsRerentNeg2() {
        Boolean isValid = true;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        List<PO_Rerent_Line_Item__c> rrLineItems = [SELECT Id, Min_Rate__c, Day_Rate__c, Week_Rate__c, Month_Rate__c FROM PO_Rerent_Line_Item__c];
        delete rrLineItems;
        Test.startTest();
        isValid = SBR_3_0_CreatePOButtonController.checkRequiredFields(po.Id);
        Test.stopTest();
        System.assertEquals(false, isValid, 'Value match');
    }
    @isTest
    public static void checkRequiredFieldsRerentPos() {
        Boolean isValid = true;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        List<PO_Rerent_Line_Item__c> reRent = [SELECT Id, Min_Rate__c, Day_Rate__c, Week_Rate__c, Month_Rate__c FROM PO_Rerent_Line_Item__c WHERE Purchase_Order__c =:po.Id];
        Test.startTest();
        isValid = SBR_3_0_CreatePOButtonController.checkRequiredFields(po.Id);
        Test.stopTest();
        System.assertEquals(true, isValid, 'Value match');
    }
        @isTest
    public static void checkRequiredFieldsThdPrtyHaulNeg() {
        Id recTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Third_Party_Hauler').getRecordTypeId();
        Boolean isValid = true;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'tphpo' LIMIT 1];
        List<PO_Line_Item__c> lineItems = [SELECT Id, Quantity__c, Unit_Cost__c, Item_Number__c, Units__c, Freight_Type__c, Freight_Reason__c, Contract_Num__c, Transfer_Num__c, AcctNumber__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:po.Id AND RecordTypeId =:recTypeId];
        List<PO_Line_Item__c> updLineItems = new List<PO_Line_Item__c>();
        for (PO_Line_Item__c poLI : lineItems) {
            poLI.AcctNumber__c = null;
            poLI.Contract_Num__c = null;
            poLI.Transfer_Num__c = null;
            poLI.Freight_Reason__c = '';
            updLineItems.add(poLI);
        }
        update updLineItems;
        Test.startTest();
        isValid = SBR_3_0_CreatePOButtonController.checkRequiredFields(po.Id);
        Test.stopTest();
        System.assertEquals(false, isValid, 'Value match');
    }
    @isTest
    public static void checkRequiredFieldsThdPrtyHaulPos() {
        Id recTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Third_Party_Hauler').getRecordTypeId();
        Boolean isValid = true;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = 'tphpo' LIMIT 1];
        List<PO_Line_Item__c> lineItems = [SELECT Id, Quantity__c, Unit_Cost__c, Item_Number__c, Units__c, Freight_Type__c, Freight_Reason__c, Contract_Num__c, Transfer_Num__c, AcctNumber__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:po.Id AND RecordTypeId =:recTypeId];
        Test.startTest();
        isValid = SBR_3_0_CreatePOButtonController.checkRequiredFields(po.Id);
        Test.stopTest();
        System.assertEquals(true, isValid, 'Value match');
    }
    @isTest
    public static void testUpdateStatusOpen() {
        // Create Purchase Order with Status 'Open'
        Purchase_Order__c po = new Purchase_Order__c(Name = 'testnameOpen', Status__c = 'Open');
        insert po;
        // Call the method under test
        Test.startTest();
        String returnVal = SBR_3_0_CreatePOButtonController.updateStatus(po.Id);
        Test.stopTest();
        // Verify the result
        System.assertEquals('Open', returnVal, 'Status not updated properly');
    }
    @isTest
    public static void testUpdateStatusDraft() {
        // Create Purchase Order with Status 'Draft'
        Purchase_Order__c po = new Purchase_Order__c(Name = 'testnameDraft', Status__c = 'Draft');
        insert po;
        // Call the method under test
        Test.startTest();
        String returnVal = SBR_3_0_CreatePOButtonController.updateStatus(po.Id);
        Test.stopTest();
        // Verify the result
        System.assertEquals('Success', returnVal, 'Status updated properly');
    }
    
    
    @isTest
    public static void testUpdateStatusDraftToReceived() {
        // Create Purchase Order with Status 'Draft'
        Id recTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get('Standard_Purchase_Order_One_Step').getRecordTypeId();
		system.debug('recTypeId >>'+ recTypeId);
        
        Purchase_Order__c po = new Purchase_Order__c(Name = 'testnameDraft',recordTypeId=recTypeId, Status__c='Draft',Type__c='Standard Purchase Order - One Step');
        insert po;
        
        // Create PO Line Items related to the Purchase Order
            List<PO_Line_Item__c> polList = new List<PO_Line_Item__c>{
                new PO_Line_Item__c(Purchase_Order__c = po.Id, Status__c = 'Draft', Quantity__c = 10, Unit_Cost__c = 100.00),
                new PO_Line_Item__c(Purchase_Order__c = po.Id, Status__c = 'Draft', Quantity__c = 5, Unit_Cost__c = 50.00)
            };
            insert polList;
        /*
        Purchase_Order__c upStatTest = [SELECT Id, Name, Status__c, Draft_PO_Number__c, Type__c, RecordType.Name
                                        FROM Purchase_Order__c 
                                        WHERE Id =: po.Id 
                                        LIMIT 1];
        system.debug('upStatTest in test >>'+ upStatTest);
        system.debug('upStatTest.Type__c >>'+ upStatTest.Type__c);
        system.debug('po >>'+ po);
        system.debug('po.Type__c >>'+ po.Type__c);
        system.debug('po.Status__c >>'+ po.Status__c);
        system.debug('po.RecordTypeName >>'+ po.RecordType.Name);
        //po.Type__c='Standard Purchase Order - One Step';
        update po;
        */
        Test.startTest();
        String returnVal = SBR_3_0_CreatePOButtonController.updateStatus(po.Id);
        Test.stopTest();
        
            // Verify that the status of PO Line Items has been updated to 'Received'
        List<PO_Line_Item__c> updatedPolList = [SELECT Id, Status__c, Messages__c, Quantity__c,  Unit_Cost__c, Units__c FROM PO_Line_Item__c WHERE Purchase_Order__c = :po.Id];
        for(PO_Line_Item__c pol : updatedPolList){
            system.debug('updatedPolList >> '+updatedPolList);
            System.assertEquals('Received', pol.Status__c);
        }
    
        	// Verify that PO Receipts have been created
        List<PO_Receipt__c> receiptList = [SELECT Id, Purchase_Order__c, PO_Line_Item__c, Messages__c, Quantity_Received__c, Receiver_Seq__c, Receiver_Number__c, Unit_Cost__c, Date_Received__c, Time_Received__c, Units__c, Location__c, Received_Location__c, Status__c, Source__c  
                                            FROM PO_Receipt__c 
                                            WHERE Purchase_Order__c = :po.Id];
        System.assertNotEquals(0, receiptList.size());
     
    }
    
    @isTest
    public static void testGetVendorStatus() {
        Purchase_Order__c po = [SELECT Id, Vendor__r.Vendor_Status__c FROM Purchase_Order__c WHERE Name = 'testname' LIMIT 1];
        string poVenStatus = po.Vendor__r.Vendor_Status__c;
        Test.startTest();
        string venStatus = SBR_3_0_CreatePOButtonController.getVendorStatus(po.Id);
        Test.stopTest();
        System.assertEquals(poVenStatus, venStatus, 'Vendor_Status__c matched properly');
    }
    @isTest
    public static void testGetVendorStatusPicklist() {
        Map<String, string> returnMap = new Map<String, string>();
        // Retrieve the picklist field values from the Schema
        Schema.DescribeFieldResult fieldResult = Account.Vendor_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String, string> venStatusMap = new Map<String, string>();
        for (Schema.PicklistEntry picklist : picklistValues) {
            venStatusMap.put(picklist.getValue(), picklist.getLabel());
        }
        //System.debug('venStatusMap: ' + venStatusMap);
        Test.startTest();
        returnMap = SBR_3_0_CreatePOButtonController.getVendorStatusPicklist('Account', 'Vendor_Status__c');
        Test.stopTest();
        System.assertEquals(venStatusMap.size(), returnMap.size(), 'Vendor_Status__c picklist values matched properly');
    }
}