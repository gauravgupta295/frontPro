/**********************************************************************************************************************
* Apex Class: SBR_3_0_ProductConsumedDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - DAO for ProductConsumed
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Vikas Kumar-Initial version
    2.0          2023-10-18          Vikas Kumar - Added Fields 
**********************************************************************************************************************************************/
public with sharing class SBR_3_0_ProductConsumedDA implements SBR_3_0_ProductConsumedDAInterface {

    // Get all pc records by workOrder Id
    @AuraEnabled//(cacheable=true)
    public static List<ProductConsumed> getPcTableRecs(ID recId){
        List<ProductConsumed> pcRecs = new List<ProductConsumed>();

        pcRecs =[select Id,toLabel(SF_PS_ItemType__c),ProductItemId,SF_PS_Product_Item__c,SF_PS_Shipped_Qty__c,SF_PS_Backordered_Qty__c,SF_PS_Original_Backordered_Quantity__c,
                    SF_PS_Product_Item__r.SM_PS_Stock_Class__c,SF_PS_Product_Item__r.SM_PS_Item_Number__c,SF_PS_Product_Item__r.SM_PS_Average_Cost__c,
                    ProductItem.SM_PS_Description__c,WorkOrderId,
                    SF_PS_Product_Item__r.QuantityOnHand, Product2.Sell_Price__c,SF_PS_Product_Item__r.SM_PS_PartsMerch_Available_Quantity__c, 
                    Product2.Average_Cost__c,Product2.Stock_class__c,Product2.Description__c,Product2.SM_PS_Item_number__c,Product2.Item_Number__c,SF_PS_Quantity__c,product2.StockKeepingUnit, product2.List_Price__c, 
                    product2.QuantityUnitOfMeasure,product2.Name,SF_PS_Product_Item__r.SM_PS_Bin_Location_1__c,QuantityConsumed,toLabel(SF_PS_Labor_Code__c),
                    SF_PS_Cost_Price__c,SF_PS_List_Price__c,SF_PS_Selling_Price__c,SF_PS_Description__c,QuantityUnitOfMeasure,SF_PS_Stock_Class__c,SF_PS_Unit_Of_Measure__c
                    from ProductConsumed
                    where  WorkOrderId= :recId];

        return  pcRecs;
    }
}