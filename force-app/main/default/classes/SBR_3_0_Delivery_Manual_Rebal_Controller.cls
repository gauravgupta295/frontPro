/*********************************************************************************************************************
* Apex Class: SBR_3_0_Delivery_Manual_Rebal_Controller
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for any operations for sbr_3_0_delivery_Manual_Rebalance LWC
* - FRONT-8094,FRONT-8747
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Gopal Raj            2024-02-21          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_Delivery_Manual_Rebal_Controller {
      
    /**
    * @description validate if am order line item has the 'notbulk state custom field' value. 
    * @param orderId (used to query the orderlineitem)
    * @return True, If it has not bulk record.
    **/
    @AuraEnabled
    public static boolean isOrderItemNotBulk(string orderId){
        boolean result = false;
        list<OrderItem> orderItemList = new list<OrderItem>();
        if(orderId != null && orderId != ''){
            orderItemList = [SELECT id FROM orderitem where SBQQ__Asset__c != null and orderId =: orderId and 
            Product2.Product_Type__c = 'Cat-Class' and product2.Bulk_Item__c = false];
            result = orderItemList.size() > 0 ? true : false;
        }
    return result;
    }

    /**
    * @description This method will set the asset value to null under the order line object and updating source branch value to order object
    * @param orderId (used to query the orderlineitem) , sourceBranchId (Used to update the source branch value)
    * @return Success, If it set asset value to null. Error - Any issue happened while making asset value null
    **/ 
    @AuraEnabled
    public static string nullifyAssetRecord(string orderId,string sourceBranchId){
        system.debug('orderId>>'+orderId);
        string resultString = 'error';
        list<OrderItem> orderItemList = new list<OrderItem>();
        list<OrderItem> updatedOLIList = new list<OrderItem>();
        Savepoint sp = Database.setSavepoint(); 
        try {
            if(orderId != null && orderId != ''){
                system.debug('entered if block>>'+orderId);
                orderItemList = [SELECT id,SBQQ__Asset__c,product2.Bulk_Item__c FROM orderitem where  orderId =: orderId and SBQQ__Asset__c != null and 
                product2.Bulk_Item__c = false ];
                if(orderItemList.size()>0){
                    system.debug('entered 2nd if block>>'+orderItemList);
                    for(OrderItem oli:orderItemList){
                        system.debug('entered for block start>>'+oli);
                        oli.SBQQ__Asset__c = null;
                        updatedOLIList.add(oli);
                        system.debug('entered for block end>>'+oli);
                    }
                    system.debug('updatedOLIList>>'+updatedOLIList);
                    if(updatedOLIList.size()>0){
                        update updatedOLIList;
                    }
                    if(sourceBranchId != null && sourceBranchId != ''){
                        order ordObj = new order();
                        ordObj.id = orderId;
                        ordObj.Sourcing_Branch__c  = sourceBranchId;
                        update ordObj;
                        system.debug('updatedOLIList>>'+ordObj);
                        resultString = 'success';
                    }else{
                        Database.rollback(sp);
                        resultString = 'error';
                    }
                    system.debug('resultString 108>> '+resultString);
                }
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
        system.debug('orderItemList>>'+updatedOLIList);
        return resultString;
    }
}