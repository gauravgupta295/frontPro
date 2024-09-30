public with sharing class SBR_3_0_UserOperations {
    public static void updateBranchLocation(List<User> usersnewList) {
        Set<String> DepNums = new Set<String>();
        Map<String,SObject> locNumberMap = new Map<String,SObject>();
        for(User u: usersnewList) {
            if(u.Department != null) {
                DepNums.add(u.Department);
            }
        }

        for(Schema.Location loc:[Select id,Name, Branch_Location_Number__c,Analysis_Region_Key__c, Company_Code__c from Location where RecordType.Name = 'Branch' AND Branch_Location_Number__c != null]) {
            locNumberMap.put(loc.Branch_Location_Number__c,loc);
            for(User u: usersnewList) {
                if(u.Department != null && u.CompanyName != null) {
                    If(u.CompanyName == loc.Company_Code__c && u.Department.replaceFirst( '^0+', '')  == loc.Branch_Location_Number__c.replaceFirst( '^0+', '')) {
                        u.Branch__c = loc.Name;
                        if(loc.Analysis_Region_Key__c != null) {
                            u.Analysis_Region_Key__c = loc.Analysis_Region_Key__c;
                        }
                        if(u.ProfileBranchNumber__c == null)//added by MOhsin for FRONT-23787
                            u.ProfileBranchNumber__c = loc.Branch_Location_Number__c;
                    }
                }
            }
        }
    }
    @future
    public static void upsertUserLocationObject(List<Id> usersNewIds) {
        Set<String> DepNums = new Set<String>();
        Map<String,SObject> locNumberMap = new Map<String,SObject>();
        Map<Id,User_Location__c> userLocationMap = new Map<Id,User_Location__c>();
        List<User_Location__c> userLocList = new List<User_Location__c>();
        List<User> usersList = new List<User>();

        for(User u: [Select id, Department, Branch__c, CompanyName, (Select Id, User__c, Branch__c, ProfileBranche__c, Analysis_Region2__c from User_Location__r) from User Where id IN: usersNewIds]) {
            if(u.Department != null) {
                DepNums.add(u.Department);
                usersList.add(u);
                If(u.User_Location__r.size() > 0) {
                    userLocationMap.put(u.Id, u.User_Location__r[0]);
                }
            }
        }

        for(Schema.Location loc:[Select id,Name, Branch_Location_Number__c,Analysis_Region2__c, Company_Code__c from Location where RecordType.Name = 'Branch' AND Branch_Location_Number__c != null]) {
            locNumberMap.put(loc.Branch_Location_Number__c,loc);
            for(User u: usersList) {
                if(u.Department != null && u.Department.replaceFirst( '^0+', '')  == loc.Branch_Location_Number__c.replaceFirst( '^0+', '')
                && u.CompanyName != null && u.CompanyName == loc.Company_Code__c) {
                    User_Location__c uLoc = new User_Location__c();
                    if(userLocationMap.containsKey(u.Id)){
                        uLoc = userLocationMap.get(u.Id);
                        uLoc.Branch__c = loc.Id;
                        uLoc.ProfileBranche__c = uLoc.ProfileBranche__c == null ? loc.Id : uLoc.ProfileBranche__c;
                        uLoc.Analysis_Region2__c = loc.Analysis_Region2__c;
                    }
                    else {
                        uLoc.User__c = u.Id;
                        uLoc.Branch__c = loc.Id;
                        uLoc.ProfileBranche__c = uLoc.ProfileBranche__c == null ? loc.Id : uLoc.ProfileBranche__c;
                        uLoc.Analysis_Region2__c = loc.Analysis_Region2__c;
                    }
                    userLocList.add(uLoc);
                }
            }
        }

        if(!userLocList.isEmpty()) {
            upsert userLocList;
        }

    }
    
    @future
    public static void populateEmptyProfileBranch(List<Id> userIds) {
        List<User_Location__c> userlocations = [select Id, Branch__c, ProfileBranche__c from User_Location__c where User__c IN : userIds];
        for(User_Location__c uLoc: userlocations) {
            if(uLoc.ProfileBranche__c == null) {
                uLoc.ProfileBranche__c = uLoc.Branch__c;
            }
        }
        update userlocations;
    }

    public static void deactivateOrRevertAccountRelationships(List<Id> userIds) 
    {
        SBR_3_0_UserDeactivationBatchable batchJob = new SBR_3_0_UserDeactivationBatchable(userIds);
        Id batchId = Database.executeBatch(batchJob);
    }
    @InvocableMethod(
        label='Get Users By Id'
        description=''
      )
      public static List<UserResponse> fetchUsersById(List<UserRequest> uRequests) {
          
          List<String> userIds = uRequests[0].userIds;
          List<User> uList = SBR_3_0_UserDA.getUsersByIds(userIds);
          
          List<UserResponse> uResponseList = new List<UserResponse>();
          UserResponse uResponse = new UserResponse();
          uResponse.users = uList;
          uResponseList.add(uResponse);
          
          return uResponseList;
      }
      
      public class UserRequest {
          @InvocableVariable(label='User Id List' required=true)
          public List<String> userIds;
      }
  
      public class UserResponse {
          @InvocableVariable(label='User List' required=false)
          public List<User> users;
      }
}