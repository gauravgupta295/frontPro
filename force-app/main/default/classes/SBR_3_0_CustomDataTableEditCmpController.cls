/**
* Apex Class: SBR_3_0_CustomDataTableEditCmpController
* ---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Controller class for any operations for SBR_3_0_CustomDataTableEditCmp LWC
*---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*    1.0         Kunal Patel             2023-07-03          Initial version
*/
public with sharing class SBR_3_0_CustomDataTableEditCmpController {
    public static final String QUOTE_LINE_TYPE = 'SBQQ__QuoteLine__c';
    public static final String ORDER_LINE_TYPE = 'OrderItem';

    /**
     * @description Method to save QuoteLines and Order Items
     * @param quoteLines 
     * @param orderLines 
     * @param objectType 
     * @return  `Boolean`
     * @exception Throws an `Aura Exception`
     * 
     */
    @AuraEnabled
    public static Boolean saveSObjects(List<SBQQ__QuoteLine__c> quoteLines, List<OrderItem> orderLines, String objectType) {

        Boolean updatesSuccessful = false;
        //Pass a JSON stringified value, based on objecttype create record type
        //avoid Uirecordapi if possible
        //create wrapper class to pass data as a json itself

        try {
            if (objectType != 'OrderItem') {
                saveQuoteLine(quoteLines);
            } else {
                saveOrderItems(orderLines);
            }
            updatesSuccessful = true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return updatesSuccessful;
    }

    /**
     * @description Method to save quotelines received from LWC
     * @param quoteLines 
     */
    public static void saveQuoteLine(List<SBQQ__QuoteLine__c> quoteLines){
        List<SBQQ__QuoteLine__c> delList = new List<SBQQ__QuoteLine__c>();
                List<SBQQ__QuoteLine__c> listToUpdate = new List<SBQQ__QuoteLine__c>();
                for(SBQQ__QuoteLine__c ql : quoteLines) {
                    if(ql.SBQQ__Quantity__c == 0) {
                        delList.add(ql);
                    } else {
                        listToUpdate.add(ql);
                    }
                }
                if(delList.size() > 0 && Schema.sObjectType.SBQQ__QuoteLine__c.isDeletable()) {
                    delete delList;
                }
                if(listToUpdate.size() > 0 && Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
                    update listToUpdate;
                }
    }

   /**
    * @description Method to save orderLines received from LWC
    * @param orderLines 
    */
    public static void saveOrderItems(List<OrderItem> orderLines){
        List<OrderItem> delList = new List<OrderItem>();
        List<OrderItem> listToUpdate = new List<OrderItem>();
        for(OrderItem oi : orderLines) {
            if(oi.Quantity == 0) {
                delList.add(oi);
            } else {
                listToUpdate.add(oi);
            }
        }
        if(delList.size() > 0 && Schema.sObjectType.OrderItem.isDeletable()) {
            delete delList;
        }
        if(listToUpdate.size() > 0 && Schema.sObjectType.OrderItem.isUpdateable()) {
            List<OrderItem> childLines = updateQuantityonChildLineToMatchParent(listToUpdate);
            if(!childLines.isEmpty()){
                listToUpdate.addAll(childLines);
            }
            update listToUpdate;
        }
    }

    /**
     * @description 
     * @param newLines 
     * @return  `List<OrderItem>`
     */
    private static List<OrderItem> updateQuantityonChildLineToMatchParent(List<OrderItem> newLines) {
        Map<String, Decimal> mapOfProductQuantities = new Map<String, Decimal>();
        Set<Id> orderIds = new Set<Id>();
        List<String> productSkus = new List<String>();
        Set<String> groupIds = new Set<String>();
    
        collectOrderData(newLines, mapOfProductQuantities, orderIds, productSkus);
        
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String loggedInUserCompanyCode = loggedInUser.CompanyName;
        List<SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptionsForProducts(productSkus, loggedInUserCompanyCode, 'Forced Item');
        productOptions.addAll(SBR_3_0_ProductDA.getProductKitComponents(productSkus));
        List<OrderItem> updatedChildlines=updateChildLines(newLines, mapOfProductQuantities, orderIds, productOptions, groupIds);
    
        return updatedChildlines;
    }

    /**
     * @description 
     * @param newLines 
     * @param mapOfProductQuantities 
     * @param orderIds 
     * @param productSkus 
     */
    private static void collectOrderData(List<OrderItem> newLines, Map<String, Decimal> mapOfProductQuantities, Set<Id> orderIds, List<String> productSkus) {
        Set<Id> orderLineIds = new Set<Id>();
    
        for (OrderItem orderLine : newLines) {
            orderLineIds.add(orderLine.Id);
        }
    
        Map<ID, OrderItem> mapOfOrderItems = new Map<ID, OrderItem>([SELECT Id, Product_SKU__c, Kit_Number_This_Item_Belongs_to__c, orderId, Quantity FROM OrderItem WHERE id IN :orderLineIds]);
    
        for (OrderItem orderLine : newLines) {
            OrderItem oldLineData = mapOfOrderItems.get(orderLine.Id);
    
            if (String.isBlank(oldLineData.Kit_Number_This_Item_Belongs_to__c) && String.isNotBlank(oldLineData.Product_SKU__c)) {
                orderIds.add(oldLineData.orderId);
                productSkus.add(oldLineData.Product_SKU__c);
    
                if (!mapOfProductQuantities.containsKey(oldLineData.Product_SKU__c)) {
                    mapOfProductQuantities.put(oldLineData.Product_SKU__c, orderLine.Quantity);
                }
            }
        }
    }

    /**
     * @description 
     * @param newLines 
     * @param mapOfProductQuantities 
     * @param orderIds 
     * @param productOptions 
     * @param groupIds 
     * @return  `List<OrderItem>`
     */
    private static List<OrderItem> updateChildLines(List<OrderItem> newLines, Map<String, Decimal> mapOfProductQuantities, Set<Id> orderIds, List<SBQQ__ProductOption__c> productOptions, Set<String> groupIds) {
        List<OrderItem> updatedChildlines = new List<OrderItem>();
    
        if (!productOptions.isEmpty()) {
            Map<Id,SBQQ__ProductOption__c> mapOfProductOptions = new Map<Id,SBQQ__ProductOption__c>();
    
            for (SBQQ__ProductOption__c option : productOptions) {
                if (!mapOfProductOptions.containsKey(option.SBQQ__OptionalSKU__c)) {
                    mapOfProductOptions.put(option.SBQQ__OptionalSKU__c,option);
                }
            }
    
            List<OrderItem> childlines = [SELECT id, Kit_Number_this_Item_Belongs_to__c, Product2.Name, Quantity, groupID__c, Product2Id FROM OrderItem WHERE Kit_Number_this_Item_Belongs_to__c IN :mapOfProductQuantities.keySet() AND OrderId IN :orderIds];
    
            for (OrderItem orderLine : childlines) {
                if ((String.isNotBlank(orderLine.groupID__c) && 
                    !groupIds.contains(orderLine.groupID__c) && 
                      String.isNotBlank(orderLine.Kit_Number_this_Item_Belongs_to__c) && 
                      mapOfProductQuantities.containsKey(orderLine.Kit_Number_this_Item_Belongs_to__c) &&
                      mapOfProductOptions.containsKey(orderLine.Product2Id) && 
                      ((mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Feature__r.Name == 'Sales Addons' && 
                      mapOfProductQuantities.get(orderLine.Kit_Number_this_Item_Belongs_to__c) > orderLine.Quantity)  || 
                      mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Feature__r.Name == 'Rental Addons' 
                      ) )
                     ) {
                        
                        orderLine.Quantity = mapOfProductQuantities.get(orderLine.Kit_Number_this_Item_Belongs_to__c) * mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Quantity__c;    
                        updatedChildlines.add(orderLine);
                        groupIds.add(orderLine.groupID__c);
                            
                }else if((String.isNotBlank(orderLine.Kit_Number_this_Item_Belongs_to__c) && 
                mapOfProductQuantities.containsKey(orderLine.Kit_Number_this_Item_Belongs_to__c) && 
                mapOfProductOptions.containsKey(orderLine.Product2Id)) &&
                mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Feature__r.Name == 'Kit Component'){
                    orderLine.Quantity = mapOfProductQuantities.get(orderLine.Kit_Number_this_Item_Belongs_to__c) * mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Quantity__c;
                    updatedChildlines.add(orderLine);
                }
            }
        }
        return updatedChildlines;
    }
}