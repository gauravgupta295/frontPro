/*********************************************************************************************************************
* Apex Class: SBR_3_0_Queuable_ProjectTerritory
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Queueable class to insert Project Relationships when an internal user created a Project record.
*********************************************************************************************************************/

public with sharing class SBR_3_0_Queuable_ProjectTerritory implements Queueable, Database.AllowsCallouts {
    public List<Project__c> projectList; 
    
    public SBR_3_0_Queuable_ProjectTerritory(List<Project__c> projectList) {
        this.projectList=projectList;
    }
    public void execute(QueueableContext context) {
        // SF-8059: Bulkified the code and moved to the below method 
        List<Project_Relationship__c> proRlnList = SBR_3_0_ProjectOperations.getProjectRelationships(projectList);

        if(!proRlnList.isEmpty()) {
            Project_Relationship__c[] deleteProjRelList = [Select Id,Name from Project_Relationship__c where Project__c IN: projectList];
            Database.DeleteResult[] projRel_Dels = Database.delete(deleteProjRelList,false);
            Database.SaveResult[] projRel_INS = Database.insert(proRlnList, false);
        }
    }
}