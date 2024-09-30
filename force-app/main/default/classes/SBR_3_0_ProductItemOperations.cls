/*****************************************************************************************
* Apex Class: SBR_3_0_ProductItemOperations
------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Class to manage handler logic for Product Items
------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE            DETAIL FEATURES
    1.0         Alex DeVries        2022-11-11      Initial version (SAL-5640)
    2.0         Shilpa Mitra        2024-02-27      Created populateDefaultValue()
******************************************************************************************/
public with sharing class SBR_3_0_ProductItemOperations
{   /**
    * @description used to publish outbox record
    * @param oldProdItemMap holds old value of ProductItem record in the form of Map
    * @param newProdItemMap holds new value of ProductItem record in the form of Map
    */
    public static void publishProductItem(Map<Id, ProductItem> oldProdItemMap, Map<Id, ProductItem> newProdItemMap)
    {
        if (!newProdItemMap.isEmpty())
        {
            SBR_3_0_PublishRecordsToOutbox publishProdItems = new SBR_3_0_PublishRecordsToOutbox(
                newProdItemMap, SBR_3_0_Constants.PRODUCT_ITEM_API_NAME);
                publishProdItems.publish();
        }
    }

    /**
    * @description used to populate the value of SM_PS_Last_Message_DateTime_Stamp__c as part of PS-4644
    * @param newProdItemList hold list of productItem that is inserted
    */
    public static void populateDefaultValue(List<ProductItem> newProdItemList){
   		for(ProductItem prodItem : newProdItemList){
            DateTime myDateTime = DateTime.now();
			String formatted = myDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
            if(prodItem.SM_PS_Last_Message_DateTime_Stamp__c == null){
            	prodItem.SM_PS_Last_Message_DateTime_Stamp__c =  formatted+'.000000Z';
            }
        }
    } 
}