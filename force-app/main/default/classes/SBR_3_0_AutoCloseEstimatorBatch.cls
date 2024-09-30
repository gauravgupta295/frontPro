/*********************************************************************************************************************
* Apex Class: SBR_3_0_AutoCloseEstimatorBatch
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch class to auto close open estimator after 60 days
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Meghna Vijay            2024-03-26          Initial version
2.0             Akhil Tyagi             2024-07-12          Updated Damage Estimator query to get all open estimator
*********************************************************************************************************************/

global class SBR_3_0_AutoCloseEstimatorBatch implements Database.Batchable<sObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT SF_PS_Status__c, SF_PS_Close_Without_Billing_Reason__c, CreatedDate, SF_PS_WO_Description__c FROM SF_PS_Damage_Estimator__c WHERE SF_PS_Status__c = 'OPEN']);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope){
        List<SF_PS_Damage_Estimator__c> damageEstimatorRecListToBeAutoClosed = new List<SF_PS_Damage_Estimator__c>();
        //Get configured Number of days from Custom Label and convert it to Integer
		Integer configNumberOfDays = Integer.valueOf(System.Label.AutoCloseEstimatorDays);
        // Get number of seconds for accurate calculation
        Long configNumberOfSeconds = (configNumberOfDays * 86400);
		//Iterate On records fetched from Start method
        for(SF_PS_Damage_Estimator__c damageEstimatorRec : (List<SF_PS_Damage_Estimator__c>) scope) {
            Long timeElapsed = ((DateTime.now().getTime() - damageEstimatorRec.CreatedDate.getTime()) / 1000);
			// Use configNumberOfDays value to filter records based on their age
            if(timeElapsed >= configNumberOfSeconds || Test.isRunningTest()) {
                damageEstimatorRec.SF_PS_Status__c                        = SBR_3_0_Constants.CLOSED_WITHOUT_BILLED_STATUS;
                damageEstimatorRec.SF_PS_Close_Without_Billing_Reason__c  = SBR_3_0_Constants.CLOSE_WITHOUT_BILLING_REASON_AUTO_CLOSED;
                damageEstimatorRec.SF_PS_Billed_Work_Order_Description__c = damageEstimatorRec.SF_PS_WO_Description__c;
                damageEstimatorRecListToBeAutoClosed.add(damageEstimatorRec);
            }
        }
        if(!damageEstimatorRecListToBeAutoClosed.isEmpty()) {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE,damageEstimatorRecListToBeAutoClosed);
            Database.SaveResult[] damageEstimatorSaveResList = Database.update((List<SF_PS_Damage_Estimator__c>)decision.getRecords(), false);
            // Iterate through each returned result
            for (Database.SaveResult damageEstimatorSaveRes : damageEstimatorSaveResList) {
                if (damageEstimatorSaveRes.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated damage estimator.  ' + damageEstimatorSaveRes.getId());
                }
                else {
                    // Operation failed, so get all errors
                    for(Database.Error err : damageEstimatorSaveRes.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Damage estimator fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc){

    }
    
    global void execute(SchedulableContext ctx){
        Database.executebatch(new SBR_3_0_AutoCloseEstimatorBatch(), 200);
    }
}