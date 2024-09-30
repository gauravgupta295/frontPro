/********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateProjectRelationshipBatch
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Get all Projects that need a refresh of Project Relationship data
* - For Each Project make a callout to get Territory Reps for project Latitude/Longitude
* - Create new Project relationship records using returned Territory Reps
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Salesforce                            05-15-2024          Initial version 
*********************************************************************************************************************/

global class SBR_3_0_UpdateProjectRelationshipBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String projectQuery = 'Select Id, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, '+
            + 'Project_Relationship_Update_Flag__c from Project__c where Project_Relationship_Update_Flag__c = true';
        return Database.getQueryLocator(projectQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Project__c> projectList){
        List<Project_Relationship__c> insProjRelList = SBR_3_0_ProjectOperations.getProjectRelationships(projectList);
        
        if(!insProjRelList.isEmpty()) {
            Project_Relationship__c[] deleteProjRelList = [Select Id,Name from Project_Relationship__c where Project__c IN: projectList];
            Database.DeleteResult[] PR_Dels = Database.delete(deleteProjRelList,false);
            Database.SaveResult[] PR_Ins = Database.insert(insProjRelList,false);
        }
        
        for(Project__c proj : projectList) {
             proj.Project_Relationship_Update_Flag__c = false;
        }
        Database.SaveResult[] PROJ_update = Database.update(projectList,false);
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}