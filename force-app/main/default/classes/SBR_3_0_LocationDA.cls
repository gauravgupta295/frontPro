/*********************************************************************************************************************
* Apex Class: SBR_3_0_LocationDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Location Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul             2022-10-25          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_LocationDA implements SBR_3_0_LocationDAI {
    public static Schema.Location getBranchByBranchNumber(String branchNumber, String cc){
        Schema.Location branch; 
        List<Schema.Location> branches = [
            SELECT ID, Branch_Location_Number__c 
            FROM Location 
            WHERE Recordtype.Name =: SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH AND 
            Branch_Location_Number__c = :branchNumber 
            AND Company_Code__c = :cc
            LIMIT 1];
        if(branches.size() > 0){
            branch = branches[0];
        }
        return branch;
    }
    
    public static Map<Id, Schema.Location> getLocations(Set<Id> locationIds){
        return new Map<Id, Schema.Location>([SELECT Id FROM Location WHERE Id In :locationIds]);
    }
    
    public static List<Schema.Location> getLocation(String branch){
        //23506
    	return [SELECT Id, Branch_Location_Number__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s,Time_Zone_Id__c
                FROM Location 
                WHERE Branch_Location_Number__c = :branch 
                AND Recordtype.Name =: SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH 
                LIMIT 1];
    }    
}