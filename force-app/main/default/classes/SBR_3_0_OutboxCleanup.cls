/**
* Apex Class: SBR_3_0_OutboxCleanup
* @description Delete Outbox records older than 30 days.
*/
public class SBR_3_0_OutboxCleanup implements Database.Batchable<sObject>, Schedulable{
    /**
    * @description - start method for Batchable
    * @param bc Database.BatchableContext
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id
                                         FROM Outbox__c
                                         WHERE CreatedDate < LAST_N_DAYS:30                        
                                         WITH SYSTEM_MODE
                                         LIMIT 50000000]);
    }

    /**
    * @description - execute method for Batchable
    * @param bc Database.BatchableContext
    * @param scope List<Outbox__c>
    */
    public void execute(Database.BatchableContext bc, List<Outbox__c> scope){
        if (Schema.sObjectType.Outbox__c.isDeletable()) {
            Database.delete(scope,false);
        }
    }

    /**
    * @description - finish method for Batchable
    * @param bc Database.BatchableContext
    */
    public void finish(Database.BatchableContext bc){
    }

    /**
    * @description - execute method for Schedulable
    * @param sc SchedulableContext
    */
    public void execute(SchedulableContext sc){
        SBR_3_0_OutboxCleanup cleanUpBatch = new SBR_3_0_OutboxCleanup();
        Database.executeBatch(cleanUpBatch,2000);
    }
}