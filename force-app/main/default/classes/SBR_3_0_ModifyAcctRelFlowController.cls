public with sharing class SBR_3_0_ModifyAcctRelFlowController {
	ApexPages.StandardSetController setCon;
    public List<Id> arIds {get;set;}
    public SBR_3_0_ModifyAcctRelFlowController(ApexPages.StandardSetController controller)
    {
        setCon = controller;
        arIds = new List<Id>();
        for (Account_Relationship__c acc : (List<Account_Relationship__c>)setCon.getSelected() )
        {
        	arIds.add(acc.Id);
        }
        System.debug('arIds: ' + arIds);
    }
}