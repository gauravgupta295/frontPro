/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to implement trigger logic SBR_3_0_ProjectOperations
* - SAL-2911
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad           2022-05-17            Initial version    
    2.0         Shruti Gujarathi      2024-05-17            Project Rel creation logic seperated for bulk load vs single creation
*********************************************************************************************************************/
public with sharing class SBR_3_0_ProjectOperations  implements Database.AllowsCallouts{

    private static final String projectID = 'a4N3C000000EZ8AUAW';
    public static Set<String> validRecTypes;
    private static final Boolean isIntegrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
    private static final Boolean isDataMigrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.DATA_MIGRATION_USER);

    public static void publishProjectsToOutbox(Map<Id, Project__c> newProjectMap) {
        SBR_3_0_PublishRecordsToOutbox publishProjects= new SBR_3_0_PublishRecordsToOutbox(newProjectMap, SBR_3_0_Constants.PROJECT_API_NAME);
        publishProjects.publish();
    }

    public static void publishSfUserUpdates(Map<Id, Project__c> newProjectMap){
        Boolean hasPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
            if (hasPermission==False){
                SBR_3_0_PublishRecordsToOutbox publishProjects= new SBR_3_0_PublishRecordsToOutbox(newProjectMap, SBR_3_0_Constants.PROJECT_API_NAME);
                publishProjects.publish();
            }
    }

    public static void fetchAddressLatLong(Map<Id, Project__c> oldProjectMap, Map<Id, Project__c> newProjectMap){
        Set<Id> changedStreetAddress = new Set<Id>();

        for(Project__c pct: newProjectMap.values()){
            if(oldProjectMap == NULL || oldProjectMap.isEmpty()){
                // Insert Operation
                // Street Address Populated
                if(pct.Project_Origin__c <> 'Dodge' && pct.Project_Origin__c <> 'PEC'){
                if(pct.Street__c <> NULL || 
                pct.City__c <> NULL ||
                pct.State__c <> NULL ||
                pct.ZIP_Code__c <> NULL ||
                pct.Country__c <> NULL && (pct.Latitude_Longitude__Latitude__s == NULL ||
                pct.Latitude_Longitude__Latitude__s == 0 ||
                pct.Latitude_Longitude__Longitude__s == NULL ||
                pct.Latitude_Longitude__Longitude__s == 0)
                ){
                    if(!changedStreetAddress.contains(pct.Id)){
                        changedStreetAddress.add(pct.Id);
                    }
                }

            }
            } else {
                // Update Operation
                Project__c oldPct = oldProjectMap.get(pct.Id);
                // Changed Street Address
                if(pct.Project_Origin__c <> 'Dodge' && pct.Project_Origin__c <> 'PEC'){
                if(pct.Street__c <> oldPct.Street__c || 
                pct.City__c <> oldPct.City__c ||
                pct.State__c <> oldPct.State__c ||
                pct.ZIP_Code__c <> oldPct.ZIP_Code__c){
                    if(!changedStreetAddress.contains(pct.Id)){
                        changedStreetAddress.add(pct.Id);
                    }
                }
            }
            }
        }

        if(!changedStreetAddress.isEmpty()){
            // Call SBR_3_0_BatchProjectLatLongProcessor Batch Class
            SBR_3_0_BatchProjectLatLongProcessor latLongBtch = new SBR_3_0_BatchProjectLatLongProcessor(changedStreetAddress);
            if(isIntegrationUser == false && isDataMigrationUser == false && Test.isRunningTest() == false) {
                Database.executeBatch(latLongBtch, 1);
            }
            List<Project__c> changedAddrPcts = [SELECT ID, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, Latitude_Longitude_Status__c, Latitude_Longitude_error__c FROM Project__c WHERE ID in: changedStreetAddress];
            for(Project__c pct: changedAddrPcts){
                if(changedStreetAddress.contains(pct.Id)){
                    pct.Latitude_Longitude_Status__c = 'Fetching';
                    pct.Latitude_Longitude_error__c = '';
                    // pct.Street_Address_LatLong__Latitude__s = null;
                    // pct.Street_Address_LatLong__Longitude__s = null;
                }
            }

            update changedAddrPcts;
        }
    }

    public String getProjectInfo(String projectID) {
        List<Project__c> projectData = [
            SELECT
                Id,
                Project_Number__C,
                Kickoff_Date__c
            FROM
                Project__c
            WHERE
                Id = :projectID
        ];

        String projectNumber = projectData[0].Project_Number__c;
        Integer projectDate = projectData[0].Kickoff_Date__c.year();
        String projectInfo = projectDate + projectNumber;
        return projectInfo;
    }

    //SF-8129 & SF-8059: updates Project.Project_Relationship_Update_Flag__c when new Project is created OR when Lat/Lon is modified.
    public static void updateProjRelField(Map<Id,Project__c> oldMap, List<Project__c> newList) {
        for(Project__c newProj : newList) {
            if (newProj.Latitude_Longitude__Latitude__s != null && newProj.Latitude_Longitude__Longitude__s != null
                && (oldMap == null || (oldMap != null 
                && (oldMap.get(newProj.Id).Latitude_Longitude__Latitude__s != newProj.Latitude_Longitude__Latitude__s
                || oldMap.get(newProj.Id).Latitude_Longitude__Longitude__s != newProj.Latitude_Longitude__Longitude__s)))
            ){
                newProj.Project_Relationship_Update_Flag__c = true;
            }
        }
    }

    //SF-8129 & SF-8059: Used by SBR_3_0_Queuable_ProjectTerritory and SBR_3_0_UpdateProjectRelationshipBatch to create Proj Relationships
    public static List<Project_Relationship__c> getProjectRelationships(List<Project__c> projectList) {
        List<Project_Relationship__c> proRlnList = new List<Project_Relationship__c>();
        Map<Id,List<Object>> mapPrjAndTerrResponse = new Map<Id,List<Object>>();
        Set<String> setTerrExtIds = new Set<String>();
        
        for(Project__c pro :projectList){ 
            SBR_3_0_API_FetchTerritory sh = new SBR_3_0_API_FetchTerritory();
            List<Object> returnval = sh.getTerritoryDetails(String.valueOf(pro.Latitude_Longitude__Latitude__s),String.valueOf(pro.Latitude_Longitude__Longitude__s),'Project');
            if(returnval != null){
                mapPrjAndTerrResponse.put(pro.Id, returnval);
                for (Object objc: returnval){
                    Map<String , Object> TerryMap = (Map<String, Object>) objc;
                    setTerrExtIds.add(String.valueOf(TerryMap.get('territoryId')));
                }
            }
        }
        Map<String,Id> mapTerrIds = new Map<String,Id>();   // Map of Territory Ext ID and related SFDC ID
        List<Territory__c> territories = [SELECT Id, OwnerId, Territory_Id__c FROM Territory__c WHERE Territory_Id__c in: setTerrExtIds];
        for(Territory__c terr : territories) {
            mapTerrIds.put(terr.Territory_Id__c,terr.Id);
        }

        String terrExtID, terrSFID, mapSource;
        for(Project__c pro :projectList){
            if(mapPrjAndTerrResponse.containsKey(pro.Id)) {
                List<Object> returnval = mapPrjAndTerrResponse.get(pro.Id);
                for (Object objc: returnval){
                    Map<String , Object> TerryMap = (Map<String, Object>) objc;
                    terrExtID = String.valueOf(TerryMap.get('territoryId'));
                    mapSource = String.valueOf(TerryMap.get('mapSource'));
                    if(mapTerrIds.containsKey(terrExtID)) {
                        terrSFID = mapTerrIds.get(terrExtID);
                        Project_Relationship__c projRln = new Project_Relationship__c(
                            Name = mapSource + ' - ' + terrExtID + ' - ' + pro.Id,
                            Territory__c = terrSFID,
                            Project__c = pro.Id,
                            Territory_ID__c = terrExtID,
                            External_ID__c = pro.Id+terrExtID);
                        proRlnList.add(projRln);
                    }
                }
            }
        }
        return proRlnList;
    }
}