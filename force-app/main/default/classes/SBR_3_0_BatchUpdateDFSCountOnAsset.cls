/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchUpdateDFSCountOnAsset
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Update DFS count on ALL assets KM2023
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kedar Mudhalwadkar      2023-05-24           Initial version    
*********************************************************************************************************************/

// Apex Batch Job
public class SBR_3_0_BatchUpdateDFSCountOnAsset implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('In start|X999|');
        String query = 'SELECT Id, SM_PS_Steps_Due_for_Service__c FROM Asset';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<Asset> scope) {
        System.debug('In execute|X999|');
        try {
            List<Asset> updateListAsset = new List<Asset>();
            
            // Get all DueForService__c records
            List<DueForService__c> allListDFS = [SELECT Id, SM_PS_Equipment_Number__c FROM DueForService__c];
            
            for (Asset assetRec : scope) {
                Integer ctrDFS = 0;
				System.debug(assetRec.SM_PS_Steps_Due_for_Service__c + 
                             '|X001|' + ctrDFS);                
                for (DueForService__c dfsRec : allListDFS) {
                    System.debug(assetRec.SM_PS_Steps_Due_for_Service__c + 
                                 '|X002|' + ctrDFS);                
                    if (dfsRec.SM_PS_Equipment_Number__c != null && dfsRec.SM_PS_Equipment_Number__c == assetRec.Id) {
                        ctrDFS++;
                        System.debug(assetRec.SM_PS_Steps_Due_for_Service__c +  + 
                                     '|X003|' + ctrDFS);                
                    }
                        System.debug(assetRec.SM_PS_Steps_Due_for_Service__c + '|X004|' + ctrDFS);                
                }
                
                // Update asset with the counter value
                //if(assetRec.SM_PS_Steps_Due_for_Service__c == null || assetRec.SM_PS_Steps_Due_for_Service__c <> ctrDFS){
                	assetRec.SM_PS_Steps_Due_for_Service__c = ctrDFS;
	            //}
                System.debug(assetRec.SM_PS_Steps_Due_for_Service__c + '|X005|' + ctrDFS);                
                updateListAsset.add(assetRec);
            }
            
            // Update the asset records
            if (!updateListAsset.isEmpty()) {
                update updateListAsset;
				System.debug(updateListAsset.size() + '|X006|');                
            }
         } catch (Exception e) {
            String subject = 'Error in SBR_3_0_BatchUpdateDFSCountOnAsset';
            String body = 'An error occurred in the batch job SBR_3_0_BatchUpdateDFSCountOnAsset:\n\n' + e.getMessage();
            sendErrorEmail(subject,body);
        }
    }
    
    public void finish(Database.BatchableContext context) {
        System.debug('In final|X999|');
        // Optional: Perform any post-processing logic here
        String subject = 'Completed execution SBR_3_0_BatchUpdateDFSCountOnAsset';
        String body = 'SBR_3_0_BatchUpdateDFSCountOnAsset batch job completed successfully';
        sendErrorEmail(subject,body);
        System.debug('Email sent|X008|');
    }
    
    // Method to send error email
    private void sendErrorEmail(String subject, String body) {
        System.debug('Sending email|X007|' + subject + ' ' + body);
        String[] toAddresses = new String[] { 'kedar.mudhalwadkar@sunbeltrentals.com' };
        toAddresses.add(UserInfo.getUserEmail());    
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}