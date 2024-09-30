public with sharing class SBR_3_0_Create_Inventory_Transfer_Cntr {
    @AuraEnabled
    public static map<string,string> getLoggedInUserLocation(string userId){
        User_Location__c  userLocation = new User_Location__c();
        map<string,string> retunMap = new map<string,string>();
        retunMap.put('locationID','');
        retunMap.put('locationNumber','');
        try {
            if(!string.isBlank(userId)){
                userLocation = [SELECT id,Name,User__c,Branch__r.Branch_Location_Number__c,Branch__c,ProfileBranche__c FROM User_Location__c WHERE User__c =:userId limit 1]; 
                if(userLocation != null){
                    retunMap.put('Id',userLocation.id);
                    if(userLocation.Branch__c != null){
                        retunMap.put('locationID',userLocation.Branch__c);
                        if(userLocation.Branch__r.Branch_Location_Number__c != null){
                            retunMap.put('locationNumber',userLocation.Branch__r.Branch_Location_Number__c);
                        }
                    }
                     //Added by pankaj for FRONT-17954,FRONT-19128
                    if(userLocation.ProfileBranche__c != null){
                        retunMap.put('ProfileBranch',userLocation.ProfileBranche__c);
                    }//end by pankaj

                }
            }
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
        return retunMap;
    }   
}