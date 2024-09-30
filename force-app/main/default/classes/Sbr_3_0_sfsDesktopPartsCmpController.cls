/*****************************************************************************************************************
* Apex Class: SBR_3_0_DesktopPartsController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller for  Parts component mobile and desktop
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-09-08          Vikas Kumar-Initial version  
    2.0        2023-10-16            Vikas Kumar- Added pricebook entries emthod
    3.0        2024-03-22            Diksha Tiwari- Added wo to be deleted method
*********************************************************************************************************************/

public class Sbr_3_0_sfsDesktopPartsCmpController {
    
   
    @AuraEnabled
    public static Map<String,Object> getProductItemDetails(string productItemId)
    {
        Map<String,Object> productDetails= new Map<String,Object>();
        list<ProductItem> prod=[SELECT SM_PS_Average_Cost__c,SM_PS_Item_Number__c,SM_PS_Quantity_Available__c,Product2.Expected_Profit_Percent__c,Product2.Last_Cost__c,Product2.Freight_Percentage__c,Product2.List_Price__c,
                                        Product2.Sell_Price__c,SM_PS_Stock_Class__c,Product2.Average_Cost__c,SM_PS_Description__c,SM_PS_Bin_Location_1__c,SM_PS_PartsMerch_Available_Quantity__c,Product2.QuantityUnitOfMeasure,SM_PS_Product_Type__c,
                                        QuantityOnHand,Product2.Name,Product2.Product_SKU__c,Product2Id,Product2.Item_Number__c,Product2.Stock_class__c,Product2.Description__c,Product2.SM_PS_Item_number__c,Product2.Item_Type__c,Product2.Product_Type__c,
                                        SM_PS_Last_Cost__c 
                                FROM productItem 
                                WHERE id=:productItemId];
        

        if(prod.size()>0)
        {
            
            productDetails.put('Item',prod[0]);
            productDetails.put('PricebookEntry',getPricebookEntriesForProd(prod[0].Product2Id));
            return productDetails;

        }
        else {
            return null;
        }
    }

    @AuraEnabled
    public static   Map<String,Object>  getProductDetails(string prodId)
    {
        Map<String,Object> productDetails= new Map<String,Object>();
        list<Product2> prodDetails=[SELECT Id,Description,Description__c,QuantityUnitOfMeasure,SM_PS_Item_number__c,
                                        Sell_Price__c,List_Price__c,Average_Cost__c,Last_Cost__c,Item_Number__c,Stock_class__c,
                                        Freight_Percentage__c,Expected_Profit_Percent__c,Product_Type__c,Product_SKU__c,
                                    (SELECT Id,SM_PS_Average_Cost__c,SM_PS_Last_Cost__c,Location.Branch_Location_Number__c,Location.Company_Code__c from ProductItems)
                                    FROM Product2
                                    where id=:prodId];
        if(prodDetails.size()>0)
        {
            productDetails.put('Item',prodDetails[0]);
            productDetails.put('PricebookEntry',getPricebookEntriesForProd(prodDetails[0].Id));
            return productDetails;
        }
        else {
            return null;
        }
    }
    
    @AuraEnabled
    public static list<PricebookEntry> getPricebookEntriesForProd(string prodId){
        list<PricebookEntry> PricEnt = [SELECT id,Name,Pricebook2.Name,CurrencyIsoCode,Pricebook2.Id 
                                        from  PricebookEntry  
                                        where Product2.id=: prodId];
        
        if(PricEnt.size()>0)
        {
            return PricEnt;
        }
        else {
            return null;
        }

 
    }

    @AuraEnabled
    public static void getWoToBeDeleted(string recordId)
    {
        List<WorkOrder> woRecord=[Select Id from WorkOrder where Id=:recordId];
        if(woRecord.size()>0)
        {
           delete woRecord;
        }

    }

}