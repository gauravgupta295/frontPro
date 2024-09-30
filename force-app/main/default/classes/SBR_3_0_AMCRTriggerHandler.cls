public  with sharing  class SBR_3_0_AMCRTriggerHandler extends SBR_3_0_TriggerHandler{
private list<Account_Management_Change_Request__c> listAMCRNew;
    
    public SBR_3_0_AMCRTriggerHandler(){
        this.listAMCRNew = (list<Account_Management_Change_Request__c>) Trigger.new;
    }
    
    //public override void afterInsert(){
        //not needed anymore since handled by flow
        //SBR_3_0_AMCROperations.CheckAMCRUser(listAMCRNew);
       
    //}
}