@isTest
public class SBR_3_0_AssetRequisitionsController_Test {

    @testSetup
    static void createTestData() {
        // Test the getAssetReqs method
        List<PO_Requisition__c> reqList = new List<PO_Requisition__c>();
        // Populate reqList with test data (create PO_Requisition__c records)
        Purchase_Order__c po= new Purchase_Order__c();
        po.name='testname';
        po.Location__c = '9999';
        insert po;
        po.Vendor_Number__c = '123456789';
        update po;
        
        Product2 testProd = new Product2();
        testProd.Name = 'TEST';
        testProd.Company_Code__c = '01';
        testProd.Item_Number__c = '75';
        testProd.Stock_class__c = 'TEST';
        testProd.Product_Type__c = 'Merchandise';
        testProd.Status__c = 'A';
        insert testProd;
        
        PO_Requisition__c req = new PO_Requisition__c();
        req.Company_Code__c = '01';
        req.Item_Number__c= '75';
        req.Stock_Class__c = 'TEST';
        req.Order_Location__c = '9999';
        req.Vendor_Number__c = '123456789';
        req.Requisition_Num__c= '23';
        req.Item_Number__c= '75';
        req.Status__c= 'MH'; 
        req.Driv_Lic_State__c= 'MH';
        req.Discount_Pct1__c=8;
        req.Discount_Pct2__c=78;
        req.Discount_Pct3__c=89;
        req.Driv_Lic_Num__c='87';
        //Drop_Shipment__c
        //Due_Date__c,
        req.Equipment_Num__c='787';
        req.Equipment_Type__c = 'E';
        req.GL_Account__c= 8;
        req.Quantity__c= 88;
        req.Unit_Cost__c=78;
        req.Status__c='O';
        req.Added_By__c='TestEmp';
        insert req;        
    }

    @isTest
    static void testGetAssetReqs() {
    	List<Purchase_Order__c> purchOrds = [SELECT Id, Location__c, Vendor_Number__c FROM Purchase_Order__c LIMIT 1];
        List<PO_Requisition__c> reqs = new List<PO_Requisition__c>();
        
        Test.startTest();
        reqs = SBR_3_0_AssetRequisitionsController.getAssetReqs(purchOrds[0].Id);
        Test.stopTest();
        
        system.assertEquals(1, reqs.size());
    }
    
    @isTest
    static void testcreatePOLineItem() {
        String poId = [SELECT Id FROM Purchase_Order__c LIMIT 1].Id;
		String reqId = [SELECT Id FROM PO_Requisition__c LIMIT 1].Id;
		Test.startTest();        
    	SBR_3_0_AssetRequisitionsController.createPOLineItem(reqId, poId);
        Test.stopTest();
        
        List<PO_Line_Item__c> items = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :poId];
        
        system.assertEquals(1, items.size());
    }
}