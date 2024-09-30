/**************************************************************************
* Apex Class: SBR_3_0_ProductItemTriggerHandler
---------------------------------------------------------------------------
* Purpose/Methods:
* @description Class to manage trigger logic for Product Items
---------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE        DETAIL FEATURES
    1.0         Alex DeVries        2022-11-10  Initial version (SAL-5640)
    2.0         Shilpa Mitra        2024-02-27  Modified as part of PS-4644
***************************************************************************/
public with sharing class SBR_3_0_ProductItemTriggerHandler extends SBR_3_0_TriggerHandler
{
    @TestVisible
    private Map<Id, ProductItem> oldProductItemMap;
    @TestVisible
    private Map<Id, ProductItem> newProductItemMap;
    @TestVisible
    private List<ProductItem> newProductitemList;
    
    /**
     * @description constructor used to initialize the context variable
     */
    public SBR_3_0_ProductItemTriggerHandler() {
        this.oldProductItemMap = (Map<Id, ProductItem>) Trigger.oldMap;
        this.newProductItemMap = (Map<Id, ProductItem>) Trigger.newMap;
        this.newProductitemList = (List<ProductItem>) Trigger.new;
    }

    public override void afterInsert() {
        SBR_3_0_ProductItemOperations.publishProductItem(this.oldProductItemMap, this.newProductItemMap);
    }
    
    public override void beforeInsert() {
        //Added part of PS-4644 to populate value for SM_PS_Last_Message_DateTime_Stamp__c
        SBR_3_0_ProductItemOperations.populateDefaultValue(this.newProductitemList);
    }

    /*public override void beforeUpdate() {
        for (ProductItem productItem : this.newProductItemMap.values()) {
            ProductItem oldProductItem = this.oldProductItemMap.get(productItem.Id);
            if(oldProductItem.SM_PS_Last_Message_DateTime_Stamp__c.length() != 0 && compareTimestamps(productItem.SM_PS_Last_Message_DateTime_Stamp__c, oldProductItem.SM_PS_Last_Message_DateTime_Stamp__c) < 0) {
                for (SObjectField field : ProductItem.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().values()) {
                    if (field.getDescribe().updateable && productItem.get(field) != oldProductItem.get(field)) {
                        productItem.put(field, oldProductItem.get(field));
                    }
                }
            }
        }
    }

    private static Integer compareTimestamps(String timestamp1, String timestamp2) {
        List<String> splitTimestamp1 = timestamp1.split('[-:TZ]');
        List<String> splitTimestamp2 = timestamp2.split('[-:TZ]');
        if(splitTimestamp1.size() != splitTimestamp2.size()) {
            throw new IllegalArgumentException('');
        }
        for(Integer i = splitTimestamp1.size() - 1; i >= 0; i--) {
            if(Decimal.valueOf(splitTimestamp1[i]) > Decimal.valueOf(splitTimestamp2[i])) {
                return 1;
            } else if(Decimal.valueOf(splitTimestamp1[i]) < Decimal.valueOf(splitTimestamp2[i])) {
                return -1;
            }
        }
        return 0;
    }*/

    public override void afterUpdate() {
        SBR_3_0_ProductItemOperations.publishProductItem(this.oldProductItemMap, this.newProductItemMap);
    }
}