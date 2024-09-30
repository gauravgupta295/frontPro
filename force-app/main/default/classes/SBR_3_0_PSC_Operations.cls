/**************************************************************************************************************************************
* Apex Class: SBR_3_0_PSC_Operations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Methods used by SBR_3_0_PSCTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
*   1.0         Chhavi Singhal           2023-11-10           Initial version
*   2.0         Chhavi Singhal           2023-11-24           Added publishUpdatedPSCItemRecords() method to trigger for PSCItem
*   3.0         Chhavi Singhal           2024-06-10           Added publishDeletedSendToRMRecords() method to handle beforeDelete 
***************************************************************************************************************************************/
@SuppressWarnings(
  'PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.NcssMethodCount'
)
public with sharing class SBR_3_0_PSC_Operations {
    /**
     * @description Publish Active & SendToRM = true PSC Records
     * @param newPSCs Stores the new PSC record values
     * @param oldPSCById Stores the old PSC record as a Map
    */
    public static void publishActiveSendToRMRecords(List<ProductServiceCampaign> newPSCs, Map<Id, ProductServiceCampaign> oldPSCById) {
        List<ProductServiceCampaign> pscToPublishAsNew = new List<ProductServiceCampaign>();
        List<ProductServiceCampaign> pscToPublishAsUpdated = new List<ProductServiceCampaign>();
        List<ProductServiceCampaign> pscToPublishAsDeleted = new List<ProductServiceCampaign>();
     
        Set<SObjectField> fieldsToCheckForUpdates = new Set<SObjectField>{ ProductServiceCampaign.ProductServiceCampaignName, ProductServiceCampaign.SM_PS_Company_Code__c, 
            															   ProductServiceCampaign.SM_PS_Send_to_RM__c, ProductServiceCampaign.Status,
            															   ProductServiceCampaign.SM_PS_Step_Number__c, ProductServiceCampaign.SM_PS_Est_Hrs_to_Complete__c,
            															   ProductServiceCampaign.SM_PS_Maintenance_Step_Y_N__c, ProductServiceCampaign.SM_PS_Labor_Code__c,
        																   ProductServiceCampaign.SM_PS_Search_Word__c
            															 };
                
        for (ProductServiceCampaign newPSC : newPSCs) {
            if(newPSC.SM_PS_Send_to_RM__c && newPSC.Is_Active__c) {
                Boolean hasRelevantChange = false;
                for (SObjectField field : fieldsToCheckForUpdates) {
                    if(newPSC.get(field) != oldPSCById.get(newPSC.Id).get(field)) {
                        hasRelevantChange = true;
                        break;
                    }
                }
                if(hasRelevantChange && newPSC.Is_Active__c) {
                    ProductServiceCampaign oldPSC = oldPSCById.get(newPSC.Id);
                    Boolean isSendToRmChangedToTrue = newPSC.SM_PS_Send_to_RM__c == true && oldPSC.SM_PS_Send_to_RM__c == false;
                    Set<String> oldSplitCompanyCode = SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(oldPSC.SM_PS_Company_Code__c);
                    Set<String> newSplitCompanyCode = SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(newPSC.SM_PS_Company_Code__c);
                    
                    pscToPublishAsNew.addAll(
                            (List<ProductServiceCampaign>)SBR_3_0_CopySObjectsByCompanyCode.createNewSObjectCopiesByCompanyCode(
                                    newPSC, ProductServiceCampaign.SM_PS_Company_Code__c, oldSplitCompanyCode,
                                    newSplitCompanyCode, isSendToRmChangedToTrue
                            )
                    );
                    pscToPublishAsUpdated.addAll(
                            (List<ProductServiceCampaign>)SBR_3_0_CopySObjectsByCompanyCode.createUpdatedSObjectCopiesByCompanyCode(
                                    newPSC, ProductServiceCampaign.SM_PS_Company_Code__c, oldSplitCompanyCode,
                                    newSplitCompanyCode, isSendToRmChangedToTrue
                            )
                    );

                    if(newPSC.SM_PS_Company_Code__c != oldPSCById.get(newPSC.Id).SM_PS_Company_Code__c) {
                        pscToPublishAsDeleted.addAll(
                                (List<ProductServiceCampaign>)SBR_3_0_CopySObjectsByCompanyCode.createDeletedSObjectCopiesByCompanyCode(
                                        newPSC, ProductServiceCampaign.SM_PS_Company_Code__c, oldSplitCompanyCode,
                                        newSplitCompanyCode, newPSC.Is_Active__c 
                                )
                        );
                    }
                }
            }
        }
        stageWithRecordSourceOfUpdate(pscToPublishAsNew, SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE);
        stageWithRecordSourceOfUpdate(pscToPublishAsUpdated, SBR_3_0_PublishToOutboxWithoutQuery.UPDATE_RECORD_SOURCE_OF_UPDATE);
        stageWithRecordSourceOfUpdate(pscToPublishAsDeleted, SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE);
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }
    
    /**
     * @description Publish Updated PSC Item Records
     * @param newPSCs Stores the new PSC record values
     * @param oldPSCById Stores the old PSC record as a Map
    */
    public static void publishUpdatedPSCItemRecords(List<ProductServiceCampaign> newPSCs, Map<Id, ProductServiceCampaign> oldPSCById) {
        List<ProductServiceCampaign> updatedPSCList = new List<ProductServiceCampaign>();
        List<ProductServiceCampaignItem> pscItemToPublishAsUpdated = new List<ProductServiceCampaignItem>();
        Map<Id,List<ProductServiceCampaignItem>> pscToPSCItemsMap = new Map<Id,List<ProductServiceCampaignItem>>();
        Set<SObjectField> formulaFieldsToCheckForUpdates = new Set<SObjectField>{ ProductServiceCampaign.ProductServiceCampaignName,
            															   		  ProductServiceCampaign.SM_PS_Step_Number__c, 
            																	  ProductServiceCampaign.SM_PS_Est_Hrs_to_Complete__c
            															 };
        Set<SObjectField> additionalFieldsPSCItem = new Set<SObjectField>{};                                                                 
        Set<Id> pscIds = new Set<Id>();
        
        //Check if there is update in cross-reference formula fields
        for (ProductServiceCampaign newPSC : newPSCs) {
            if(newPSC.SM_PS_Send_to_RM__c && newPSC.Is_Active__c) {
                Boolean hasRelevantChange = false;
                for (SObjectField field : formulaFieldsToCheckForUpdates) {
                    if(newPSC.get(field) != oldPSCById.get(newPSC.Id).get(field)) {
                        hasRelevantChange = true;
                        break;
                    }
                }
                if(hasRelevantChange && newPSC.Is_Active__c) {
                    updatedPSCList.add(newPSC);
                }
            }
        }
        for (ProductServiceCampaign pscId : updatedPSCList) {
            pscIds.add(pscId.Id);
        }       
        List<ProductServiceCampaign> pscToPSCItemsList = [SELECT Id, (SELECT FIELDS(STANDARD),SM_PS_Account__c,SM_PS_AssetNumber__c,SM_PS_AssetCategory__c,
                                                                      SM_PS_AssetClass__c,SM_PS_Company_Code__c,SM_PS_Current_Location__c,SVMXA360__DeliveryMethod__c,
                                                                      SM_PS_Equipment_Number__c,SM_PS_EstHrstoComplete__c,SM_PS_External_ID__c,SM_PS_HowtoMaintain__c,
                                                                      SVMXA360__Location__c,SM_PS_MaintenanceSubClass__c,SVMXA360__PSCEngineLogId__c,
                                                                      SVMXA360__SerialNumber__c,SM_PS_Step_Description__c,SM_PS_Step_Number__c 
                                                                      FROM ProductServiceCampaignItems)
                                                          FROM ProductServiceCampaign
                                                          WHERE Id =:pscIds
                                                          WITH SECURITY_ENFORCED]; 

        //Create Map to store PSC  and their PSC Items
        if(!pscToPSCItemsList.isEmpty()) {
           for(ProductServiceCampaign pscRec : pscToPSCItemsList) {
               pscToPSCItemsMap.put(pscRec.Id, pscRec.ProductServiceCampaignItems);
           }
        }

        if(!pscToPSCItemsMap.keyset().isEmpty()) {
            for(Id pscId : pscToPSCItemsMap.keyset()){
                for(ProductServiceCampaignItem pscItem : pscToPSCItemsMap.get(pscId)) {
                    if(pscItem.Status == 'OutputGenerated'){
                    	pscItemToPublishAsUpdated.add(pscItem);
                    }
                }
            }
        }
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                pscItemToPublishAsUpdated, ProductServiceCampaignItem.getSObjectType(),
                additionalFieldsPSCItem, SBR_3_0_PublishToOutboxWithoutQuery.UPDATE_RECORD_SOURCE_OF_UPDATE
        );
        publishToOutboxWithoutQuery.setObjectAPINameOverride('SM_PS_Eqp_Maintenance_Step__c');
        publishToOutboxWithoutQuery.setRecordTypeOverride('Eqp Maintenance Step');
        publishToOutboxWithoutQuery.stageOutboxChanges();
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }
    
    /**
     * @description Publish Deactivated & SendToRM = true PSC Records
     * @param newPSCs Stores the new PSC record values
     * @param oldPSCById Stores the old PSC record as a Map
    */
    public static void publishDeactivatedSendToRMRecords(List<ProductServiceCampaign> newPSCs, Map<Id, ProductServiceCampaign> oldPSCById) {
        List<ProductServiceCampaign> deactivatedPSCs = new List<ProductServiceCampaign>();
        for (ProductServiceCampaign newPSC : newPSCs) {
            ProductServiceCampaign oldPSC = oldPSCById.get(newPSC.Id);
            if(newPSC.SM_PS_Send_to_RM__c && !newPSC.Is_Active__c && oldPSC.Is_Active__c) {
                deactivatedPSCs.addAll(
                        (List<ProductServiceCampaign>)SBR_3_0_CopySObjectsByCompanyCode.createDeletedSObjectCopiesByCompanyCode(
                                newPSC, ProductServiceCampaign.SM_PS_Company_Code__c,
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(newPSC.SM_PS_Company_Code__c),
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(oldPSC.SM_PS_Company_Code__c),
                                false
                        )
                );
            }
        }
        stageWithRecordSourceOfUpdate(deactivatedPSCs, SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE);
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }

    /**
     * @description Publish Deleted & SendToRM = true PSC Records
     * @param oldPSCs Stores the old PSC record values
    */
    public static void publishDeletedSendToRMRecords(List<ProductServiceCampaign> oldPSCs) {
        List<ProductServiceCampaign> deletedPSCs = new List<ProductServiceCampaign>();
        for (ProductServiceCampaign oldPSC : oldPSCs) {
            if(oldPSC.SM_PS_Send_to_RM__c) {
                deletedPSCs.addAll(
                        (List<ProductServiceCampaign>)SBR_3_0_CopySObjectsByCompanyCode.createDeletedSObjectCopiesByCompanyCode(
                                oldPSC, ProductServiceCampaign.SM_PS_Company_Code__c,
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(oldPSC.SM_PS_Company_Code__c),
                                new Set<String>(),
                                oldPSC.Is_Active__c 
                        )
                );
            }
        }
        stageWithRecordSourceOfUpdate(deletedPSCs, SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE);
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }
    
    /**
     * @description Stage with Record Source of Update
     * @param productServiceCampaigns Stores the list of PSCs
     * @param recordSourceOfUpdate Stores Record Source of Update value
    */
    private static void stageWithRecordSourceOfUpdate(List<ProductServiceCampaign> productServiceCampaigns, String recordSourceOfUpdate) {
        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                productServiceCampaigns, ProductServiceCampaign.getSObjectType(),
                new Set<SObjectField>{ ProductServiceCampaign.SM_PS_Company_Code__c }, recordSourceOfUpdate
        );
        publishToOutboxWithoutQuery.setObjectAPINameOverride('WorkStepTemplate');
        publishToOutboxWithoutQuery.setRecordTypeOverride('WorkStepTemplate');
        publishToOutboxWithoutQuery.stageOutboxChanges();
    }
}