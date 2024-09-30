/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetUpdateOnMPTActivationBatch
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invocable class update assets on activation of Maintenance Plan Templates
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Dec-13      Initial version
**********************************************************************************************************************/

global class SBR_3_0_AssetUpdateOnMPTActivationBatch implements Database.Batchable<sObject>, Database.Stateful 
{
    global List<Id> finalAssetListUpdate;

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {  
        String query = 'SELECT Id, SM_PS_Create_MP__c FROM Asset WHERE Id IN (\''+String.join(finalAssetListUpdate,'\',\'')+'\')';

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Asset> assetList) 
    {
        for(Asset oAssetRecord : assetList)
        {    
            oAssetRecord.SM_PS_Create_MP__c = TRUE;
        }
        
        try 
        { 
           update assetList;
        } 
        
        catch(Exception ex) 
        {
            System.debug(ex.getMessage());
        }  
    }   
    
    global void finish(Database.BatchableContext BC) 
    {
        // execute any post-processing operations
    }
}