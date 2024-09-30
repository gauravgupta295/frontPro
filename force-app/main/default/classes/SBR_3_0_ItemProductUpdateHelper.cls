/*********************************************************************************************************************
* Apex Class: SBR_3_0_ItemProductUpdateHelper
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is to be used update old products on Order Item, Quote Line Item, Asset, and Cart Item with new products
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Hashem Abdul                        2023-04-10           Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_ItemProductUpdateHelper {
    private String newProductId;
    private String oldProductId;
    private String oldCatClass;
    private String newCatClass;
    private List<PricebookEntry> newPBEList = new List<PricebookEntry>();
    private Conversion_Log__c cLog;
    public SBR_3_0_ItemProductUpdateHelper(String oldProductId, String newProductId, Conversion_Log__c cLog) {
        this.newProductId = newProductId;
        this.oldProductId = oldProductId;
        Set<String> pIdSet = new Set<String>();
        pIdSet.add(newProductId);
        pIdSet.add(oldProductId);
        this.cLog = cLog;
        for(Product2 p:[Select id, Product_SKU__c,(Select Id,unitPrice,CurrencyIsoCode from PricebookEntries) from Product2 Where Id IN:pIdSet ]) {
            if(p.id == newProductId) {
                this.newCatClass = p.Product_SKU__c;
                if(!p.PricebookEntries.isEmpty()){
                    newPBEList.addAll(p.PricebookEntries);
                }
                
            }
            else if(p.id == oldProductId) {
                this.oldCatClass = p.Product_SKU__c;
            }
        } 
    }

    public void run(){
        updateAssetItem();
        updateAssetCatClass();
        updateQuoteLineItems();
        updateCartItems();
        updateEquipmentType();
        updateWorkOrderLineItem();
        updateOrderLineItems();
    }

    public void updateQuoteLineItems(){

        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('SBQQ__Product__c', newProductId);
        Id batchJobId = Database.executeBatch(
            new SBR_3_0_BatchSObjectUpdate('SBQQ__QuoteLine__c', newFieldValue, 
            'SBQQ__Product__c = \'' + oldProductId + '\'', cLog, newPBEList, new List<String>{'SBR_3_0_QuoteLineTriggerHandler'}), 20
        );
    }

    public void updateAssetItem(){
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('Product2Id', newProductId);
        Id batchJobId = Database.executeBatch(
            new SBR_3_0_BatchSObjectUpdate('Asset', newFieldValue, 
            'Product2Id = \'' + oldProductId + '\'', cLog, newPBEList, new List<String>{'SBR_3_0_AssetTriggerHandler'}), 20
        );
    }
    
    public void updateAssetCatClass(){
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('SM_PS_Cat_Class__c', newCatClass);
        newFieldValue.put('SM_PS_Category__c', newCatClass.substring(0, 3));
        newFieldValue.put('SM_PS_Class__c', newCatClass.substring(3));
        Id batchJobId = Database.executeBatch(
            new SBR_3_0_BatchSObjectUpdate('Asset', newFieldValue, 
            'SM_PS_Cat_Class__c = \'' + oldCatClass + '\'', cLog, newPBEList, new List<String>{'SBR_3_0_AssetTriggerHandler'}), 20
        );
    }

    public void updateCartItems(){
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('Product__c', newProductId);
        Id batchJobId = Database.executeBatch(
            new SBR_3_0_BatchSObjectUpdate('Cart_Items__c', newFieldValue, 'Product__c = \'' + oldProductId + '\'', cLog,newPBEList,
            new List<String>()), 20
        );
    }

    public void updateEquipmentType(){
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('SM_PS_Product__c', newProductId);
        Id batchJobId = Database.executeBatch(
            new SBR_3_0_BatchSObjectUpdate('Equipment_Type__c', newFieldValue, 'SM_PS_Product__c = \'' + oldProductId + '\'',
            cLog,newPBEList, new List<String>{'SBR_3_0_EquipmentTypeTriggerHandler'}), 20
        );
    }

    public void updateWorkOrderLineItem(){
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('Product2Id', newProductId);
        Id batchJobId = Database.executeBatch(
            new SBR_3_0_BatchSObjectUpdate('WorkOrderLineItem', newFieldValue, 'Product2Id = \'' + oldProductId + '\'',
            cLog, newPBEList, new List<String>()), 20
        );
    }

    public void updateOrderLineItems(){
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('Product2Id', newProductId);

        // Closed Order
        String whereClause = 'Product2Id = \'' + oldProductId + '\'';
        // whereClause += '((Order.Status in (\'Filled\', \'Cancelled\') AND Order.RecordType.DeveloperName = \'' + SBR_3_0_Constants.ORDER_REC_TYPE_RESERVATION_ORDER + '\') OR ';
        // whereClause += '(Order.Status in (\'Cancelled\', \'Closed\') AND Order.RecordType.DeveloperName = \'' + SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER + '\') OR ';
        // whereClause += '(Order.Status in (\'Cancelled\', \'Invoiced\') AND Order.RecordType.DeveloperName = \'' + SBR_3_0_Constants.ORDER_REC_TYPE_SALES_ORDER + '\'))';

        Id batchJobId = Database.executeBatch(new SBR_3_0_BatchSObjectCloneAndDelete('OrderItem', newFieldValue, 
        whereClause, 'OrderItemNumber DESC', cLog,newPBEList, new List<String>{'SBR_3_0_OrderItemTriggerHandler'}), 20);

    }
}