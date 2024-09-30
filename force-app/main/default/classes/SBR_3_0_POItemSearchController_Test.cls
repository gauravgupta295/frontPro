@isTest
public class SBR_3_0_POItemSearchController_Test {
    @testSetup
    public static void dataSetup(){
        Purchase_Order__c po= new Purchase_Order__c(Company_Code__c='01');
        insert po;
        Product2 item = new Product2(name='testItem',Company_Code__c=po.Company_Code__c,Product_Type__c='MISC Charge Items');
        insert item;
        
    }
    
    @isTest
    public static void test_getProduct(){
        id recId = [select id from Purchase_Order__c].id;
        List<Product2> prodList = SBR_3_0_POItemSearchController.getProduct(recId,'Product2',new List<String>{'Name'},'Product_Type__c=\'MISC Charge Items\'');
        System.assert(true, prodList.size() > 0 );
    }
    
    @isTest
    public static void test_createPOLineItem(){
        id recId = [select id from Purchase_Order__c].id;
        SBR_3_0_POItemSearchController.createPOLineItem(recId,null,10,'Test Item Number',5,'MISC');
        List<PO_Line_Item__c> poLineItems=[select Id from PO_Line_Item__c where Purchase_Order__c=:recId];
        System.assertEquals(1,poLineItems.size(),'PO Line Item should be created');
    }
	
    @isTest
    public static void test_createBulkPOLineItem(){
        id recId = [select id from Purchase_Order__c].id;
        List<String> RowsIds=new List<String>{null};
        List<Integer> RowsCostValues=new List<Integer>{10};
        List<String> RowsItemNumbers=new List<String>{'Test Item Number'};
        List<Decimal> values=new List<Decimal>{10};
        List<String> selectedRowsStockValues=new List<String>{'MISC'};
        SBR_3_0_POItemSearchController.createBulkPOLineItem(recId,RowsIds,RowsCostValues,RowsItemNumbers,values,selectedRowsStockValues);
        List<PO_Line_Item__c> poLineItems=[select Id from PO_Line_Item__c where Purchase_Order__c=:recId];
        System.assertEquals(1,poLineItems.size(),'PO Line Items should be created');
    }
}