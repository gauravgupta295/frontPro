/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConsumablesItemSearchCtrl
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for sbr_3_0_salesItemSearchContainerCmp
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Nilesh Jaiswal		    2023-12-28			Initial version
**********************************************************************************************************************************************/
public without sharing class SBR_3_0_ConsumablesItemSearchCtrl {
    /*
     * get productitem aggreegate to get the Availability and return productItemWrapper
     */
    @AuraEnabled
    public static List<ProductionItemWrapper> getAllProductItemsForSales(
        Integer offset,
        Integer batchSize,
        String whereClause,
        String productType
    ){
        String sQuery;
        String limitClause = ' LIMIT ' + batchSize;
        String offsetClause = ' OFFSET ' + offset;
        String selectClause = '';
        String groupByClause = ' GROUP BY Product2Id, Product2.Stock_class__c ';
        
        System.debug('==whereClause=='+whereClause);
        String partsAndMerchRecTypeDevName = SBR_3_0_Constants.PRODUCTITEM_PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME;
        List<ProductionItemWrapper> productItemWrapperList = new List<ProductionItemWrapper>();
        
         //FRONT-14358,14357,14356 starts
         try {     
            if(productType=='SALES'){
                selectClause = 
                'SELECT SUM(SM_PS_PartsMerch_Available_Quantity__c) quantity, Product2Id, Product2.Stock_class__c ' +
                'FROM ProductItem WHERE RecordType.DeveloperName =: partsAndMerchRecTypeDevName AND ' +
                '(Product2.Product_Type__c = \'Parts\' OR Product2.Product_Type__c = \'Merchandise\') ';

            }     
            
            if(productType=='MISC'){
                selectClause = 
                'SELECT SUM(SM_PS_PartsMerch_Available_Quantity__c) quantity, Product2Id, Product2.Stock_class__c ' +
                'FROM ProductItem WHERE ' +
                ' (Product2.Product_Type__c = \'Misc-Charge\' OR Product2.Product_Type__c = \'MISC Charge Items\') ';


            }
            //FRONT-14358,14357,14356 End
            sQuery =
                selectClause +
                (String.isNotBlank(whereClause) ? ' AND ' + whereClause : whereClause) +
                groupByClause +
                limitClause + 
                offsetClause;
            
            system.debug('==sQuery=='+sQuery);
            Map<Id, Decimal> productIdToItemQuanityMap = new Map<Id, Decimal>();
            for(AggregateResult agrObj: Database.query(sQuery)) {
                productIdToItemQuanityMap.put((Id)agrObj.get('Product2Id'), (Decimal)agrObj.get('quantity'));
            }
            
            for(Product2 prodObj: [SELECT Item_Number__c, Inventoried_Item__c, Miscellaneous_Charge_Item__c,
                                    Type_of_Misc_Charge_Item__c,User_Selectable_for_Quote__c,
                                    Stock_class__c, Name, Sell_Price__c, Product_Description__c ,Product_Type__c 
                			  		FROM Product2 WHERE Id IN: productIdToItemQuanityMap.keySet()])
            {
                ProductionItemWrapper wrapper = new ProductionItemWrapper();
                wrapper.availableQty = Integer.valueOf(productIdToItemQuanityMap.get(prodObj.Id));
                wrapper.product = prodObj;
                productItemWrapperList.add(wrapper);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return productItemWrapperList;
    }
    
    public class ProductionItemWrapper {
        @AuraEnabled public Integer availableQty { get;set; }
        @AuraEnabled public Product2 product { get;set; }
    }
}