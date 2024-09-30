/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchSObjectUpdate
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch update objects with new values
* - SAL-19738
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul         2023-04-14             Initial version    
*********************************************************************************************************************/

global class SBR_3_0_BatchSObjectUpdate implements Database.Batchable<sObject>, Database.Stateful{
   
    String sObjectName = '';
    Map<String,Object> nameValues = new Map<String,Object>();
    String whereClause ='';
    List<String> triggersToByPass = new List<String>();
    Conversion_Log__c cLog = new Conversion_Log__c();
    List<PricebookEntry> newPBEList = new List<PricebookEntry>();

    global SBR_3_0_BatchSObjectUpdate(String sObjectName, Map<String,Object> nameValues, String whereClause, Conversion_Log__c cLog, List<PricebookEntry> newPBEList, List<String> triggersToByPass){
        this.sObjectName = sObjectName;
        this.nameValues.putAll(nameValues);
        this.whereClause = whereClause;
        this.cLog = cLog;
        this.triggersToByPass = triggersToByPass;
        this.newPBEList = newPBEList;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> fields = new List<String>(nameValues.keySet());
        if(this.sObjectName == 'WorkOrderLineItem'){
            fields.add('WorkOrder.CurrencyIsoCode');
            fields.add('WorkOrderId');
        }
        String query = 'Select Id, ' + String.join(fields, ',') 
            + ' FROM ' + sObjectName 
            + ' WHERE ' + whereClause;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope){
        try {
             // By Pass Triggers
            if(!triggersToByPass.isEmpty()){
                for(String trg: triggersToByPass){
                    SBR_3_0_TriggerHandler.bypass(trg);
                }
            }

            for(SObject c : scope) {
                if(this.sObjectName == 'WorkOrderLineItem'){
                    WorkOrderLineItem currObj = (WorkOrderLineItem)c;
                    Id prodId = (String)nameValues.get('Product2Id');
                    /*PricebookEntry PbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prodId AND CurrencyIsoCode =: currObj.WorkOrder.CurrencyIsoCode];
                    c.put('PricebookEntryId', PbEntry.Id);*/
                    for(PricebookEntry pbe:newPBEList){
                        if(currObj.WorkOrder.CurrencyIsoCode == pbe.CurrencyIsoCode) {
                            c.put('PricebookEntryId', pbe.Id);
                        }
                    }
                }
                
                for(String fld : nameValues.keySet()) {
                    if(this.sObjectName == 'WorkOrderLineItem' && fld.equalsIgnoreCase('Product2Id')){
                        continue;
                    } 
                    c.put(fld, nameValues.get(fld));
                }
            }
            update scope;
        } catch (Exception e) {
            SBR_3_0_LogException.LogIt(e, cLog.Id);
            //SAL-25595
            String errorMsg = e.getMessage() + ' | ' + e.getStackTraceString();
            SBR_3_0_API_Create_ConversionLog.logError(cLog.Id, errorMsg);
        }
        
       
    }

    global void finish(Database.BatchableContext BC){
        
    }
}