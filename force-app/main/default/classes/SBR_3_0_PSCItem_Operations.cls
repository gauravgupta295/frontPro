/*********************************************************************************************************************
* Apex Class: SBR_3_0_PSCItem_Operations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods used by SBR_3_0_PSCItemTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
1.0             Chhavi Singhal           2023-11-22           Initial version
2.0             Evan Kuminski            2023-12-19           Added validateStatusBeforeDelete()
*********************************************************************************************************************/

public with sharing class SBR_3_0_PSCItem_Operations {
    public static Set<SObjectField> fieldsToCheckForUpdates = new Set<SObjectField>{ProductServiceCampaignItem.SM_PS_Step_Number__c, 
            															   			ProductServiceCampaignItem.SM_PS_EstHrstoComplete__c,
            															   			ProductServiceCampaignItem.SM_PS_Step_Description__c
            															 		   };
    public static void publishActiveRecords(List<ProductServiceCampaignItem> newPSCItems, Map<Id, ProductServiceCampaignItem> oldPSCItemsById) {
        List<ProductServiceCampaignItem> pscItemToPublishAsNew = new List<ProductServiceCampaignItem>();
        
        for (ProductServiceCampaignItem newPSCItem : newPSCItems) {
            ProductServiceCampaignItem oldPSCItem = oldPSCItemsById.get(newPSCItem.Id);
            Boolean isStatusChangedToCompleted = newPSCItem.Status == 'OutputGenerated' && oldPSCItem.Status != 'OutputGenerated';
            if(newPSCItem.Status == 'OutputGenerated'){
            	if(isStatusChangedToCompleted)    
                	pscItemToPublishAsNew.add(newPSCItem);
            }
        }
        stageWithRecordSourceOfUpdate(pscItemToPublishAsNew, SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE);
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }

    public static void validateStatusBeforeDelete(List<ProductServiceCampaignItem> oldPSCItems) {
        for (ProductServiceCampaignItem oldPSCItem : oldPSCItems) {
            if (oldPSCItem.Status == 'OutputGenerated') {
                oldPSCItem.addError('Product Service Campaign Items cannot be deleted when status is Output Generated');
            }
        }
    }
    
    public static void publishDeactivatedRecords(List<ProductServiceCampaignItem> oldPSCItems) {
        List<ProductServiceCampaignItem> pscItemToPublishAsDeleted = new List<ProductServiceCampaignItem>();
        Set<SObjectField> additionalFieldsPSCItem = new Set<SObjectField>{};
        for (ProductServiceCampaignItem oldPSCItem : oldPSCItems) {
            if(oldPSCItem.Status == 'OutputGenerated') {
                pscItemToPublishAsDeleted.add(oldPSCItem);
            }
        }
        
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                pscItemToPublishAsDeleted, ProductServiceCampaignItem.getSObjectType(),
                additionalFieldsPSCItem, SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        publishToOutboxWithoutQuery.setObjectAPINameOverride('SM_PS_Eqp_Maintenance_Step__c');
        publishToOutboxWithoutQuery.setRecordTypeOverride('Eqp Maintenance Step');
        publishToOutboxWithoutQuery.stageOutboxChanges();
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }
    
    private static void stageWithRecordSourceOfUpdate(List<ProductServiceCampaignItem> productServiceCampaignItems, String recordSourceOfUpdate) {
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                productServiceCampaignItems, ProductServiceCampaignItem.getSObjectType(),
                fieldsToCheckForUpdates, recordSourceOfUpdate
        );
        publishToOutboxWithoutQuery.setObjectAPINameOverride('SM_PS_Eqp_Maintenance_Step__c');
        publishToOutboxWithoutQuery.setRecordTypeOverride('Eqp Maintenance Step');
        publishToOutboxWithoutQuery.stageOutboxChanges();
    }
}