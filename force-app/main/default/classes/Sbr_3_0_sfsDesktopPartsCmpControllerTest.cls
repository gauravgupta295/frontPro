/*****************************************************************************************************************
* Apex Class: SBR_3_0_DesktopPartsControllerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Controller for SBR_3_0_DesktopPartsController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0         2023-09-08          Vikas Kumar- Added Test method for Product and ProductItem
2.0        2023-10-16           Vikas Kumar- Added Test method for Pricebook Entry
3.0        2024-03-22            Diksha Tiwari- Added wo to be deleted test method
*********************************************************************************************************************/
@istest
public with sharing class Sbr_3_0_sfsDesktopPartsCmpControllerTest {
    @istest
    private static void testGetProductItemDetails(){
        Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
        insert loc;
        Product2 pd = new Product2(name='TestProduct', Product_SKU__c='10870996');
        insert pd;
        
        ProductItem pi = new ProductItem();
        pi.Product2Id = pd.Id;
        pi.QuantityOnHand = 1;
        pi.LocationId = loc.Id;
        insert pi;
        Test.startTest();
        Map<String,Object> prodID=Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails(pi.Id);
         Map<String,Object> product=  (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(prodID.get('Item')));
       
        Test.stopTest();
        Assert.areEqual(product.get('Id'),pi.Id);
        
    }
    @istest
    private static void testGetProductItemDetails2(){
        
        Product2 pd = new Product2(name='TestProduct', Product_SKU__c='10870996');
        insert pd;
        
        Test.startTest();
        Map<String,Object> prodID=Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails(pd.Id);
        //ID prodID=Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails(pd.Id)?.Id;
        Test.stopTest();
        Assert.isNull(prodID);
        
    }
    @istest
    private static void testGetProductDetails(){
        
        Product2 pd = new Product2(name='TestProduct01', Product_SKU__c='10870676');
        insert pd;
        
        
        Test.startTest();
        Map<String,Object>  prodID=Sbr_3_0_sfsDesktopPartsCmpController.getProductDetails(pd.Id);
      Map<String,Object> product=  (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(prodID.get('Item')));
        Test.stopTest();
        Assert.areEqual(product.get('Id'),pd.Id);
        
    }
    @istest
    private static void testGetProductDetails2(){
        
        
        
        Test.startTest();
        Map<String,Object>  prodID=Sbr_3_0_sfsDesktopPartsCmpController.getProductDetails('56743');
        Test.stopTest();
        Assert.isNull(prodID);
        
    }
    
    @istest
    private static void testgetPricebookEntriesForProd(){
        
        Test.startTest();
        list<PricebookEntry> PricEnt=Sbr_3_0_sfsDesktopPartsCmpController.getPricebookEntriesForProd('56743');
        Test.stopTest();
        Assert.isNull(PricEnt);
        
    }
    
    @istest
    private static void testgetPricebookEntriesForProd2(){
        // Product
        Product2 pd = new Product2(name='TestProduct01', Product_SKU__c='10870676');
        insert pd;
        
        // pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        
        // Pricebookentry
        PricebookEntry pe = new PricebookEntry(Pricebook2Id= pricebookId ,Product2Id=pd.Id ,UnitPrice=1);
        insert pe;
        
        Test.startTest();
        list<PricebookEntry> PricEnt=Sbr_3_0_sfsDesktopPartsCmpController.getPricebookEntriesForProd(pd.Id);
        Test.stopTest();
        Assert.areEqual(pe.Pricebook2Id,pricebookId);
        
    }
    
    @istest
    private static void testgetWoToBeDeleted(){
       WorkOrder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
         ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        wo.SF_PS_Expense_To_Location__c=testE2Loc.id;
        insert wo;
        Test.startTest();
        Sbr_3_0_sfsDesktopPartsCmpController.getWoToBeDeleted(wo.id);
        Test.stopTest();
        
    }
    
    
    
    
}