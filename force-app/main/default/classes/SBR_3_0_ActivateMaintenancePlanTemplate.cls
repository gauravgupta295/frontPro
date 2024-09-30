/*********************************************************************************************************************
* Apex Class: SBR_3_0_ActivateMaintenancePlanTemplate
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invocable class update assets on activation of Maintenance Plan Templates
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Dec-13      Initial version
   
**********************************************************************************************************************/
public class SBR_3_0_ActivateMaintenancePlanTemplate {
      @InvocableMethod(label='Update Asset on Maintenance Plan Template Activation' 
                     description='Update Asset on Maintenance Plan Template Activation'
                     category='Asset')
    public static void updateAsset(List<Requests> requestList) 
    {
        Id maintenancePlanTemplate = requestList.get(0).maintenancePlanTemplateId;
        
        List<Id> appProdIdList = new List<Id>();
        List<Id> assetsToUpdateIdList = new List<Id>();
        List<Asset> assetsToUpdateList = new List<Asset>();
        List<SVMXA360__ApplicableProduct__c> appProductsList = [SELECT Id, SVMXA360__ProductId__c 
                                                                FROM SVMXA360__ApplicableProduct__c 
                                                                WHERE SVMXA360__MaintenancePlanTemplateId__c = : maintenancePlanTemplate];
       
        
        if(!appProductsList.isEmpty())
        {
            for(SVMXA360__ApplicableProduct__c appProd : appProductsList)
            {
                if(appProd.SVMXA360__ProductId__c!=null)
                appProdIdList.add(appProd.SVMXA360__ProductId__c);
            }
            
            Id rentalAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Rental_Asset').getRecordTypeId();
            Id cmpOwnAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Company_Owned_Asset').getRecordTypeId();
            
            List<String> recordTypeList = new List<String>();
            recordTypeList.add(rentalAssetRTId);
            recordTypeList.add(cmpOwnAssetRTId);
            
            List<String> StatusList = new List<String>();
            StatusList.add('JUNKED');
            StatusList.add('MISSING LOST');
            StatusList.add('SOLD');
            StatusList.add('STOLEN');

            assetsToUpdateList = new List<Asset>([SELECT Id,Product2Id,SM_PS_Commissioning_Complete__c,RecordTypeId,Status 
                                                  FROM Asset
                                                  WHERE Product2Id IN : appProdIdList 
                                                  AND SM_PS_Commissioning_Complete__c = TRUE
                                                  AND Status NOT IN : StatusList
                                                  AND RecordTypeId IN : recordTypeList]);
            
        }
        
        if(!assetsToUpdateList.isEmpty())
        {
            for(Asset oAsset: assetsToUpdateList)
            {
                assetsToUpdateIdList.add(oAsset.Id);
            }
            
            SBR_3_0_AssetUpdateOnMPTActivationBatch be = new SBR_3_0_AssetUpdateOnMPTActivationBatch();
            be.finalAssetListUpdate = assetsToUpdateIdList;
            
            database.executeBatch(be);
        }
        
        
    }
    
    public class Requests 
    {

        @InvocableVariable(label = 'Maintenance Plan Template Id' 
                           description = 'Maintenance Plan Template Id'
                           required = true)
        public Id maintenancePlanTemplateId; 
    }

}