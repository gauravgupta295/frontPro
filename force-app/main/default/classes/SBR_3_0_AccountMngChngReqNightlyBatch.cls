global  class SBR_3_0_AccountMngChngReqNightlyBatch implements Database.Batchable<SObject>,schedulable{
    global Map<id,Sobject> sbObjMap = new Map<Id,Sobject>();

    global void execute(SchedulableContext sc)
    {
        SBR_3_0_AccountMngChngReqNightlyBatch b = new SBR_3_0_AccountMngChngReqNightlyBatch(); //ur batch class
        database.executebatch(b);
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {   string APPROVED = 'Approved';
        Date TODAY = Date.today();
        system.debug('today@ '+ TODAY);
        String query = 'select id, recordtype.DeveloperName,Effective_Date__c,Managed_w_OSR_Fingerprint__c,Strategic_Type__c '
                        +', Account__r.Strategic_Type__c, Account__r.Managed_w_OSR_Fingerprint__c,Current_Sales_Rep__c,Sales_Rep__c,Account_Relationship__c ' 
                        +' from Account_Management_Change_Request__c where Approval_Status__c=:APPROVED AND Effective_Date__c=:TODAY';
       
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account_Management_Change_Request__c> scope)
    {   set<string> uniqueSalesAcSet = new Set<String>();
        set<id> salesRepSet = new Set<Id>();
        set<Id> accIdSet = new Set<ID>();
       for(Account_Management_Change_Request__c each: scope){
            if(each.recordtype.DeveloperName == 'OSR_Fingerprinting_Change' && each.Managed_w_OSR_Fingerprint__c != each.account__r.Managed_w_OSR_Fingerprint__c){
                if(this.sbObjMap.containsKey(each.account__c)){
                    ((Account)this.sbObjMap.get(each.account__c)).Managed_w_OSR_Fingerprint__c = each.Managed_w_OSR_Fingerprint__c;
                }else{
                    account temp = new account();
                    temp.id = each.account__c;
                    temp.Managed_w_OSR_Fingerprint__c = each.Managed_w_OSR_Fingerprint__c;
                    this.sbObjMap.put(each.account__c, temp);
                }
            }
            else if(each.recordtype.DeveloperName == 'Strategic_Type_Change' && each.Strategic_Type__c != each.account__r.Strategic_Type__c){
                if(this.sbObjMap.containsKey(each.account__c)){
                    ((Account)this.sbObjMap.get(each.account__c)).Strategic_Type__c = each.Strategic_Type__c;
                }else{
                    account temp = new account();
                    temp.id = each.account__c;
                    temp.Strategic_Type__c = each.Strategic_Type__c;
                    this.sbObjMap.put(each.account__c, temp);
                }
            }else if( each.recordtype.DeveloperName == 'Account_Relationship_Change' && 
                        each.Current_Sales_Rep__c!=null && 
                        each.Sales_Rep__c ==null ){
                        if(each.Account_Relationship__c !=null){
                            if(this.sbObjMap.containsKey(each.Account_Relationship__c)){
                                ((Account_Relationship__c)this.sbObjMap.get(each.Account_Relationship__c)).Inactive__c = true;
                            }else{
                                Account_Relationship__c temp = new Account_Relationship__c();
                                temp.id = each.Account_Relationship__c;
                                temp.Inactive__c = true;
                                this.sbObjMap.put(each.Account_Relationship__c, temp);
                            }
                        }else{
                            uniqueSalesAcSet.add(each.account__c+'-'+each.Current_Sales_Rep__c);
                            accIdSet.add(each.account__c);
                            salesRepSet.add(each.Current_Sales_Rep__c);
                        }
            }
       }
       if(salesRepSet !=null && accIdSet !=null){
        for(Account_Relationship__c each: [Select id,Account_ID__c,User_Account__c from Account_Relationship__c where Account_ID__c in:accIdSet AND User_Account__c in:salesRepSet ]){
            string key = each.Account_ID__c+'-'+ each.User_Account__c;    
            if(uniqueSalesAcSet.contains(key)){
                Account_Relationship__c temp = new Account_Relationship__c();
                temp.id = each.id;
                temp.Inactive__c = true;
                this.sbObjMap.put(each.id,temp);
            }
       }
       }
       system.debug('this.sbObjMap.values()@'+ this.sbObjMap.values());
       update this.sbObjMap.values();
    }
    global void finish(Database.BatchableContext BC) {
    }
}