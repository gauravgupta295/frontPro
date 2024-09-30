global class Batch_Delete_SObject implements Database.Batchable<sObject>{

    String query='';
 
    global Batch_Delete_SObject(String q){
        query = q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        delete scope;
    }
 
    global void finish(Database.BatchableContext BC){
    }
 }