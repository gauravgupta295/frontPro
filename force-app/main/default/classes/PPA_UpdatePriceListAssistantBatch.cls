/*
    This global class PPA_UpdatePriceList Assistant Batch is responsible for updating the price list associated with a manager.
    It does so by using the Apex Batchable interface.
*/
global with sharing class PPA_UpdatePriceListAssistantBatch implements Database.Batchable<sObject>{
    private String query;
    private Map<Id, Id> mgrAsstMap;
    Set<Id> mgrKeys;
    /*
        The FlowInputs inner class is used to define the inputs for the Flow that uses this batch class.
    */
    public class FlowInputs {
        @InvocableVariable
        public string mgrIdFromFlow;
        @InvocableVariable
        public string asstIdFromFlow;
    }
    @InvocableMethod(label='updatePriceListAssistantBatch' description='This method will update the assistant id in the price lists.')
    public static void updatePriceListAssistantBatch(List<FlowInputs> requests) {
        Map<Id, Id> mgrAsstFlowMap = new Map<Id, Id>();
        for(FlowInputs req : requests) {
            mgrAsstFlowMap.put(req.mgrIdFromFlow, (String.isBlank(req.asstIdFromFlow) ? null : req.asstIdFromFlow));
        }
        Database.executeBatch(new PPA_UpdatePriceListAssistantBatch(mgrAsstFlowMap));
    }
    public static void updateFromSeedClassBatch(Map<Id, Id> getMgrAsstMap) {
        Database.executeBatch(new PPA_UpdatePriceListAssistantBatch(getMgrAsstMap));
    }
    global PPA_UpdatePriceListAssistantBatch(Map<Id, Id> getMgrAsstMap){
        mgrKeys = new Set<Id>();
        for(Id mgr : getMgrAsstMap.keySet()) {
            mgrKeys.add(mgr);
        }
        this.query = 'SELECT Id, PPA_ManagerId__c, PPA_AssistantId__c FROM PPA_Price_List__c WHERE PPA_ManagerId__c IN: mgrKeys AND PPA_Visible__c=true';
        this.mgrAsstMap = getMgrAsstMap;
	}
	global Database.QueryLocator start(Database.BatchableContext BC){
		// collect the batches of records or objects to be passed to execute
		return Database.getQueryLocator(this.query);
	}
	global void execute(Database.BatchableContext BC, List<PPA_Price_List__c> scope){
        List<PPA_Price_List__c> updPriceLists = new List<PPA_Price_List__c>();
        // process each batch of records
        for(PPA_Price_List__c pl : scope) {
            pl.PPA_AssistantId__c = mgrAsstMap.containsKey(pl.PPA_ManagerId__c) ? mgrAsstMap.get(pl.PPA_ManagerId__c) : null;            
            updPriceLists.add(pl);
        }
        if(!updPriceLists.isEmpty()) {
            Database.update(updPriceLists);
        }
	}
	global void finish(Database.BatchableContext BC){
		// execute any post-processing operations
        // Get email ids from custom setting
        PPA_Admin_Config__c admConfig = PPA_Admin_Config__c.getOrgDefaults();
        String[] toAddresses = admConfig.PPA_Admin_Group_Email__c.split(';');
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.    
        // Query the AsyncApexJob object to retrieve the current job's information.  
        AsyncApexJob a = [SELECT Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        // Send an email to the Apex job's submitter notifying of job completion.  
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('PPA_UpdatePriceListAssistantBatch ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}