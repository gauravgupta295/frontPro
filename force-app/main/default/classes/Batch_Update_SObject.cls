global class Batch_Update_SObject implements Database.Batchable<sObject>{

    String query='';
 
    global Batch_Update_SObject(String q){
        query = q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Outbox__c> ob = (List<Outbox__c>) scope;
        // for(Outbox__c o : ob) {
        //     o.Publish_Status__c = 'X';
        // }
        delete scope;
    }
 
    global void finish(Database.BatchableContext BC){
    }
 }