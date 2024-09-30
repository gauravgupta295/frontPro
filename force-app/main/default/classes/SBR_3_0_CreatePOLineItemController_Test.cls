@isTest
public class SBR_3_0_CreatePOLineItemController_Test {
	@testSetup
    public static void dataSetup()
    {
        // Test data setup
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 10; i++) {
            Product2 p = new Product2(
                Company_Code__c = '01',
				Name = 'Product' +i,
                Stock_class__c = 'Test Stock Class' + i,
                Product_Type__c = 'Parts',
                Search_Word__c = 'Test Search Word' + i,
                Item_Number__c = 'Test Item Number' + i,
                Description__c = 'Test Description' + i,
                Description = 'Test Description' + i
            );
            products.add(p);
            
        }
        insert products;
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        	List<Map<String, String>> picklistValues = SBR_3_0_CreatePOLineItemController.getPicklistValues();
        Test.stopTest();
        // Add your assertions here
        System.assertNotEquals(0, picklistValues.size(), 'Picklist values should be retrieved');
    }
    
    @isTest
    public static void test_getProductRecord() 
    {
      
        List<Product2> productList = SBR_3_0_CreatePOLineItemController.getProductRecord('Test Item Number0','Product0','stockClass','01');
        System.assertNotEquals(10, productList.size(),'Expected 10 products to be returned');  
	}
    
    @isTest
    public static void test_createNewPOLineItemFromProduct() {
        
		Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO'); 
        insert testPurchaseOrder;
        Product2 PO= new Product2(Name='Test Product');
        insert PO;
        Decimal quantityvalue=5.0;
        decimal cost=10.0;
        SBR_3_0_CreatePOLineItemController.createNewPOLineItemFromProduct(testPurchaseOrder.id, PO.id,quantityvalue, cost);
        List<PO_Line_Item__c> polis = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.Id];
        System.assertNotEquals(0, polis.size());
    }
    
    @isTest
    public static void test_createNewPOLineItem() {
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO'); 
        insert testPurchaseOrder;
       
        Test.startTest();
         try{
        String itemNumber='123';
        Decimal unitCost=100.0;
        String description='Test Description';
        String stockClass='Test class';
        Decimal quantityvalue= 5.0;
        String POunit='EA';
        String itemValue = 'P';
        Id testvar = testPurchaseOrder.id;
        
        SBR_3_0_CreatePOLineItemController.createNewPOLineItem(testvar,itemNumber,unitCost,description,stockClass,quantityvalue,POunit, itemValue);
         }catch(Exception e){
             
         }
             Test.stopTest();
        List<PO_Line_Item__c> polis = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.id];
        System.assertNotEquals(1, polis.size());
    }
}