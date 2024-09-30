public with sharing class SBR_3_0_AccountConversionMergeHelper {
    public static void mergeAccounts(String oldAccountNumber, String newAccountNumber, Conversion_Log__c cLog){
        Account masterAccount = [SELECT ID, E_mail_Address__c FROM Account WHERE Id =: newAccountNumber];
        Account mergeAccount = [SELECT ID, E_mail_Address__c FROM Account WHERE Id =: oldAccountNumber];
        Map<Id, Schema.Asset> mergeAcctAssets = new Map<Id, Schema.Asset>([SELECT ID FROM Asset WHERE AccountId =: mergeAccount.Id]);
        Map<Id, AssociatedLocation> mergeAcctJobSites = new Map<Id, AssociatedLocation>([SELECT ID FROM AssociatedLocation WHERE ParentRecordId =: mergeAccount.Id]);
        try {
            SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');
            List<Account_Relationship__c> account_relationships_del = SBR_3_0_AccountRelationshipDA.getAccountRelsByAccountId(mergeAccount.Id);
            merge masterAccount mergeAccount;
            // Create Outbox record for merge account asset
            if(!mergeAcctAssets.isEmpty()){
                SBR_3_0_PublishRecordsToOutbox publishAsset = new SBR_3_0_PublishRecordsToOutbox(mergeAcctAssets, SBR_3_0_Constants.ASSET_API_NAME);
                publishAsset.setRecordSourceOfUpdate('Conversion');
                publishAsset.publish();
            }
            if(!mergeAcctJobSites.isEmpty()){
                Set<String> validRecTypes = new Set<String>();
                SBR_3_0_PublishRecordsToOutbox publishLocations = new SBR_3_0_PublishRecordsToOutbox(mergeAcctJobSites, SBR_3_0_Constants.ASSOCIATED_LOCATION_API_NAME , validRecTypes);
                publishLocations.setRecordSourceOfUpdate('Conversion');
                publishLocations.publish();
            }
			
            // The below change is part of FS1, will be deployed when its ready
            List<Account_Management_Change_Request__c> amcrInsert = new List<Account_Management_Change_Request__c>();

            for(Account_Relationship__c ar : account_relationships_del) {
                Account_Management_Change_Request__c amcr = new Account_Management_Change_Request__c();
                amcr.Account__c = ar.Account_ID__c;
                if(ar.Account_ID__c != null) {
                    amcr.Account_Name__c = ar.Account_ID__r.Name;
                }
                amcr.Account_Relationship__c = ar.Id;
                amcr.Current_Sales_Rep__c = ar.User_Account__c;
                if(ar.User_Account__c != null) {
                    amcr.Current_Sales_Rep_Name__c = ar.User_Account__r.Name;
                }
                amcr.Current_Territory__c = ar.Territory__c;
                if(ar.Territory__c != null) {
                    amcr.Current_Territory_Name__c = ar.Territory__r.Name;
                }
                amcr.Current_Type__c = ar.Type__c;
                amcr.Effective_Date__c = System.now().date();
                amcr.RecordTypeId = SBR_3_0_Constants.Account_Relationship_Change_RecordTypeId;
                amcrInsert.add(amcr);
            }

            if(!amcrInsert.isEmpty()) {
                insert amcrInsert;
            }
            if(!account_relationships_del.isEmpty()) {
                delete account_relationships_del;
            }


        } catch (Exception e) {
            // Process exception
            System.debug('An unexpected error has occurred: ' + e.getMessage()); 
            SBR_3_0_LogException.LogIt(e, cLog.Id);
            //SAL-25595
            String errorMsg = e.getMessage() + ' | ' + e.getStackTraceString();
            SBR_3_0_API_Create_ConversionLog.logError(cLog.Id, errorMsg);
        }
    }
}