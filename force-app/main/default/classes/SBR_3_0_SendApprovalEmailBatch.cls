global  class SBR_3_0_SendApprovalEmailBatch implements Database.Batchable<SObject>,Database.Stateful{
    global List<Account_Management_Change_Request__c> StrategicTypeList = new List<Account_Management_Change_Request__c>();
    global List<Account_Management_Change_Request__c> OSRFingerprintList = new List<Account_Management_Change_Request__c>();
    global List<Account_Management_Change_Request__c> AccountRelationshipList = new List<Account_Management_Change_Request__c>();

    global Database.QueryLocator start(Database.BatchableContext BC)
    {   string APPROVED = 'Submitted';
  
        system.debug('today@ '+ date.today());
        String query = 'select id, recordtype.DeveloperName,Strategic_Type__c,Name,Account__r.name,account__r.RepID__c,Sales_Rep_Name__c,account__c,Sales_Rep__c,Sales_Rep__r.RepID__c '
                        +', Account__r.Strategic_Type__c, Account_Relationship__c,Account__r.RM_Account_Number__c,Account__r.RM_Account_Number_Display__c '
                        + ', Managed_w_OSR_Fingerprint_text__c ' 
                        +' from Account_Management_Change_Request__c where Approval_Status__c=:APPROVED AND createdDate = YESTERDAY Order by recordtype.DeveloperName';
       
        system.debug('@@ Query: ' + query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account_Management_Change_Request__c> scope)
    {   
        for(Account_Management_Change_Request__c each:scope){
            if (each.recordtype.DeveloperName == 'Account_Relationship_Change' )
            {
               this.AccountRelationshipList.add(each);
            }else if(each.recordtype.DeveloperName =='Strategic_Type_Change'){
                this.StrategicTypeList.add(each);
            }
            else if (each.recordtype.DeveloperName == 'OSR_Fingerprinting_Change')
            {
                this.OSRFingerprintList.add(each);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        system.debug('this.AccountRelationshipList'+this.AccountRelationshipList);
        // We need to do this as the test class requires SeeAllData set to true as we are quering Reports object in the Queuable class
        if(!Test.isRunningTest()){
            ID jobID = System.enqueueJob(new SBR_3_0_SendApprovalEmailQueueable(this.AccountRelationshipList, this.StrategicTypeList, this.OSRFingerprintList));
            system.debug('@@ Send email Queueable Id: ' + jobID);
        }
    }
}