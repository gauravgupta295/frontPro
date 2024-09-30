global class Batch_SobjectQuery implements Database.Batchable<sObject>, Database.Stateful{

    String query = '';
    Integer count = 0;
 
    global Batch_SobjectQuery(String q){
        query = q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Account> accts = (List<Account>) scope;
        for(Account a : accts) {
            if(a.Recordtype.name =='Credit' || a.RecordType.name == 'Corp Link' || a.RecordType.name == 'Non-Credit'){
                //if(!a.RM_Account_Number__c.contains('-')) {
                    count++;
                //}
            }
        }
    }
 
    global void finish(Database.BatchableContext BC){
        String info = 'Total count : ' + count;
        TempObject__c to = new TempObject__c(data__c= info);
        insert to;
        System.debug('\n count = ' + count);
    }
 }