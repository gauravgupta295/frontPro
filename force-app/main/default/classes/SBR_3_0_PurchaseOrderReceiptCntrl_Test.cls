@isTest
public class SBR_3_0_PurchaseOrderReceiptCntrl_Test {
    @TestSetup
    static void makeData() {
        // Create PO
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;

        // Create PO Line Item
        PO_Line_Item__c poLineItem = new PO_Line_Item__c();
        poLineItem.Purchase_Order__c = testPurchaseOrder.Id;
        poLineItem.Item_Number__c = '10';
        poLineItem.Quantity__c = 5;
        poLineItem.Unit_Cost__c = 10;
        poLineItem.Units__c = '11';
        poLineItem.Status__c = 'Draft';                
        poLineItem.RecordTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Standard_Purchase_Order').getRecordTypeId();
        insert poLineItem;
        
        // Create PO Receipt
        PO_Receipt__c poRec = new PO_Receipt__c();
        poRec.Receiver_Number__c = 123;
        poRec.Receiver_Seq__c = 1;
        poRec.Quantity_Received__c = 5;
        poRec.Unit_Cost__c = 10;
        poRec.PO_Line_Item__c = poLineItem.Id;
        poRec.Purchase_Order__c = testPurchaseOrder.Id;
        insert poRec;

        // Create Product
        Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996',QuantityUnitOfMeasure = 'EA');
        insert pd;

        // Create Location
        Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
        insert loc;

        // Create Product Item
        ProductItem pi = new ProductItem();
        pi.Product2Id = pd.Id;
        pi.QuantityOnHand = 1;
        pi.LocationId = loc.Id;
        pi.CurrencyIsoCode='USD';
        insert pi; 
    }
    @isTest
    public static void testGetReceiptRecords() {
        Purchase_Order__c testPO = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        Test.startTest();
        System.assert(SBR_3_0_PurchaseOrderReceiptCntrl.getReceiptRecords(testPO.Id) != null);
        Test.stopTest();
    }
    @isTest
    public static void testGetReceiptDetails() {
        PO_Receipt__c poRec = [SELECT Id FROM PO_Receipt__c LIMIT 1];
        List<Id> poRecList = new List<Id>();
        poRecList.add(poRec.Id);
        List<PO_Receipt__c> getPORecList = new List<PO_Receipt__c>();
        Test.startTest();
        getPORecList = SBR_3_0_PurchaseOrderReceiptCntrl.getReceiptDetails(poRecList);
        Test.stopTest();
        System.assertEquals(poRecList.size(), getPORecList.size(), 'Count match');
    }
    @isTest
    public static void testCreatePOReceiptsPos() {
        Purchase_Order__c testPO = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        string output = '';
        Decimal corrQty = 10;
        Decimal corrCost = 15;
        string poRecps = '';
        PO_Receipt__c poRecp = [SELECT Id, Purchase_Order__c, Quantity_Received__c, Unit_Cost__c, PO_Line_Item__c FROM PO_Receipt__c LIMIT 1];
        poRecps =  '[{"Quantity_Received__c":"'+ corrQty + '","Unit_Cost__c":"' + corrCost + '","PO_Line_Item__c":"' + poRecp.PO_Line_Item__c + '","Id":"' + poRecp.Id + '"}]';
        Test.startTest();
        output = SBR_3_0_PurchaseOrderReceiptCntrl.createPOReceipts(poRecps, 'OV Overage', testPO.Id);
        Test.stopTest();
        System.assertEquals('Success', output, 'Success scenario passed');
    }
    @isTest
    public static void testCreatePOReceiptsNeg() {
        Purchase_Order__c testPO = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        PO_Line_Item__c poLineItem = [SELECT Id FROM PO_Line_Item__c LIMIT 1];
        delete poLineItem;
        string output = '';
        Decimal corrQty = 10;
        Decimal corrCost = 15;
        string poRecps = '';
        PO_Receipt__c poRecp = [SELECT Id, Purchase_Order__c, Quantity_Received__c, Unit_Cost__c, PO_Line_Item__c FROM PO_Receipt__c LIMIT 1];
        poRecps =  '[{"Quantity_Received__c":"'+ corrQty + '","Unit_Cost__c":"' + corrCost + '","PO_Line_Item__c":"' + poRecp.PO_Line_Item__c + '","Id":"' + poRecp.Id + '"}]';
        Test.startTest();
        output = SBR_3_0_PurchaseOrderReceiptCntrl.createPOReceipts(poRecps, 'OV Overage', testPO.Id);
        Test.stopTest();
        System.assertEquals('Failure', output, 'Failure scenario passed');
    }
}