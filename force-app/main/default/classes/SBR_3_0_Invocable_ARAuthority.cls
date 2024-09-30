/*********************************************************************************************************************
* Apex Class: SBR_3_0_Invocable_ARAuthority
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invocable class to get Account Relationship and Determine Requester Authority from a flow
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Saathvik Tulasi      2023-03-21             Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_Invocable_ARAuthority {
    private static final String BUSINESS_ADMIN_CUSTOM_PERMISSION = 'Business_Admin';
    private static final String BRANCH_MANAGER_CUSTOM_PERMISSION = 'Branch_Manager';
    private static final String REGIONAL_SALES_DIRECTOR_CUSTOM_PERMISSION = 'Regional_Sales_Director';
    private static final String COMMISSIONS_TEAM_CUSTOM_PERMISSION = 'Commissions_Team';
    private static final String SALES_MANAGER_CUSTOM_PERMISSION = 'Sales_Management';

    @InvocableMethod(label='Determine Requester Authority' description='Get Account Relationship and Determine Requester Authority')
    public static List<ARResponse> authenticateUserHierarchy(List<ARRequest> Request) {
        
        Boolean hasBusinessAdminCustomPermission = FeatureManagement.checkPermission(BUSINESS_ADMIN_CUSTOM_PERMISSION);
        Boolean hasBranchManagerCustomPermission = FeatureManagement.checkPermission(BRANCH_MANAGER_CUSTOM_PERMISSION);
        Boolean hasRegionalSalesDirecotrCustomPermission = FeatureManagement.checkPermission(REGIONAL_SALES_DIRECTOR_CUSTOM_PERMISSION);
        Boolean hasCommissionTeamCustomPermission = FeatureManagement.checkPermission(COMMISSIONS_TEAM_CUSTOM_PERMISSION);
        Boolean hasSalesManagerCustomPermission = FeatureManagement.checkPermission(SALES_MANAGER_CUSTOM_PERMISSION);

        ARResponse oARResponse = new ARResponse();
        List<ARResponse> lResponses = new List<ARResponse>();
        list<Id> lUserIds = new List<Id>();
        List<Account_Relationship__c> lAR = new List<Account_Relationship__c>();
        Map<Id,list<Id>> mUsersWithManagers = new Map<Id,list<Id>>();
        List<Account_Relationship__c> lARFailures = new List<Account_Relationship__c>();
        Map<Id,User> mUserLevels = new Map<Id,User>();
        
        ARRequest Req = Request[0];
        list<String> ARIds = Req.ARIds;
        System.debug('ARIds'+ARIds);
        list<String> UserIds = Req.UserIds;
        System.debug('UserIds'+UserIds);
        list<String> ProfilesWithFullAccess = System.Label.SBR_3_0_Admin_For_AR_Authentication.split(',');
        Map<Id,Profile> mProfile = new Map<Id,Profile>();
        list<Profile> lProfile =    [
            SELECT Id
            FROM Profile
            WHERE Name IN :ProfilesWithFullAccess
        ];
        for(Profile oProfile : lProfile){
            mProfile.put(oProfile.id, oProfile);    
        }
        if(ARIds!=null && !ARIds.isEmpty()){
            UserIds = new List<String>();
            lAR = [
                SELECT Id, Name, Account_ID__c, Account_ID__r.Name, Type__c, Territory__c, Territory__r.Name, Territory__r.OwnerId, Territory__r.Owner.Name, User_Account__c, User_Account__r.Name, User_Account__r.Analysis_Region_Key__c
                FROM Account_Relationship__c
                WHERE Id IN :ARIds
            ];
            System.debug('lAR'+lAR);
            System.debug('lAR size'+lAR.size());
            for(Account_Relationship__c oAR : lAR){
                lUserIds.add(oAR.User_Account__c);    
            }
        } else if (!UserIds.isEmpty()) {
            lUserIds = UserIds;    
        }
        System.debug('lUserIds'+lUserIds);
        
        if(!lUserIds.isEmpty()){
            list<User> lUserLevels =    [
                SELECT Id, Analysis_Region_Key__c, Manager.Id, Manager.Manager.Id, Manager.Manager.Manager.Id, Manager.Manager.Manager.Manager.Id, Manager.Manager.Manager.Manager.Manager.Id, Manager.Manager.Manager.Manager.Manager.Manager.Id
                FROM User
                WHERE Id IN :lUserIds
            ];
            System.debug('lUserLevels'+lUserLevels);
            for(User oUser : lUserLevels){
                list<Id> lManagerIds = new List<Id>();
                mUserLevels.put(oUser.id,oUser);
            }
            mUsersWithManagers = prepareUserIdVsManager(lUserIds, mUserLevels);
            System.debug('mUsersWithManagers'+mUsersWithManagers);
            set<String> sLOB = new Set<String>();
            
             Map<String, Account_Management_GT_Rules__mdt> oAMCRGTRules = Account_Management_GT_Rules__mdt.getAll();
                    List<String> ListAnalysisRegions = new List<String>();
                    System.debug('oAMCRGTRules'+oAMCRGTRules);
                    for(string LabelString : oAMCRGTRules.keySet()){
                        Account_Management_GT_Rules__mdt oAMCRGTRule = oAMCRGTRules.get(LabelString);
                        ListAnalysisRegions.add(oAMCRGTRule.Analysis_Region__c);
                        System.debug('oAMCRGTRule.Analysis_Region__c'+ ListAnalysisRegions);
                    }
            
            for(Account_Relationship__c oAR : lAR){
                for (Id userId : mUserLevels.keySet()) {
                    System.debug('Current Map Key: ' + userId);
                }
                System.debug('oAR.User_Account__c: ' + oAR.User_Account__c);
                System.debug('mUserLevels.containsKey(oAR.User_Account__c): ' + mUserLevels.containsKey(oAR.User_Account__c));
                if(mUserLevels.containsKey(oAR.User_Account__c)){               
                    User oUser = mUserLevels.get(oAR.User_Account__c);
                    
                    for (String AnalysisRegionKey : ListAnalysisRegions){
                    if(oUser.Analysis_Region_Key__c == AnalysisRegionKey){
                        sLOB.add('GT');  
                        oARResponse.LOB = 'GT';
                    }
                    }           
                    if(sLOB.size() == 0)
                    {
                        sLOB.add('Non-GT');   
                        oARResponse.LOB = 'Non-GT';
                    }
                    System.debug('oARResponse.LOB'+oARResponse.LOB);
                } else {
                    sLOB.add('Non-GT');   
                    oARResponse.LOB = 'Non-GT';
                }
                System.debug('hasBusinessAdminCustomPermission: '+hasBusinessAdminCustomPermission);
                System.debug('hasBranchManagerCustomPermission: '+hasBranchManagerCustomPermission);
                System.debug('hasCommissionTeamCustomPermission: '+hasCommissionTeamCustomPermission);
                System.debug('hasRegionalSalesDirecotrCustomPermission: '+hasRegionalSalesDirecotrCustomPermission);
                System.debug('hasSalesManagerCustomPermission: '+hasSalesManagerCustomPermission);
                if (!mProfile.containsKey(userInfo.getProfileId()) && !hasBusinessAdminCustomPermission && !hasBranchManagerCustomPermission && !hasCommissionTeamCustomPermission && !hasRegionalSalesDirecotrCustomPermission && !hasSalesManagerCustomPermission) {
                    if(mUsersWithManagers.containsKey(oAR.User_Account__c)){
                        list<Id> lManagerIds = mUsersWithManagers.get(oAR.User_Account__c);  
                        if(!lManagerIds.contains(userInfo.getUserId())){
                            oARResponse.isSuccessful = false;
                            if(!UserIds.isEmpty()){
                                oARResponse.isSuccessfulUser = false;
                            }
                            lARFailures.add(oAR);
                        }
                    }
                }
            }
            System.debug('sLOB'+sLOB);
            System.debug('sLOB Size'+sLOB.size());
            if(sLOB.size() != 1){
                oARResponse.LOB = 'Failed';    
            }
        }
        if(oARResponse.isSuccessful){
            if(lAR.size() == 1){
                oARResponse.isSinglRecord = true;
                oARResponse.oARResponse = lAR[0];
                oARResponse.lARResponse = lAR;
                lResponses.add(oARResponse);
                System.debug('lResponses'+lResponses);
                return lResponses;    
            }
            else{
                oARResponse.lARResponse = lAR;
                lResponses.add(oARResponse);
                System.debug('lResponses'+lResponses);
                return lResponses; 
            }
        }
        else{
            System.debug('lARFailures'+lARFailures);
            System.debug('lARFailures size'+lARFailures.size());
            oARResponse.lARResponse = lARFailures;
            lResponses.add(oARResponse);
            System.debug('lResponses'+lResponses);
            return lResponses;    
        }
    }

    public static Map<Id,list<Id>> prepareUserIdVsManager(List<Id> lUserIds,Map<Id,User> mUserLevels){
        Map<Id,list<Id>> mUsersWithManagers = new Map<Id,list<Id>>();
        list<User> lUserLevels =    [
                SELECT
                Id,
                Analysis_Region_Key__c,
                Manager.Id,
                Manager.Manager.Id,
                Manager.Manager.Manager.Id,
                Manager.Manager.Manager.Manager.Id,
                Manager.Manager.Manager.Manager.Manager.Id,
                Manager.Manager.Manager.Manager.Manager.Manager.Id
                FROM
                User
                WHERE
                Id IN: lUserIds
            ];
            System.debug('lUserLevels'+lUserLevels);
            for(User oUser : lUserLevels){
                list<Id> lManagerIds = new list<Id>();
                mUserLevels = new Map<Id,User>();
                mUserLevels.put(oUser.id,oUser);
                if(oUser.Manager != NULL){
                    System.debug('Inside Manager 1 : '+oUser.Manager.Id);
                    lManagerIds.add(oUser.Manager.Id);
                    if(oUser.Manager.Manager != NULL){
                        System.debug('Inside Manager 2 : '+oUser.Manager.Manager.Id);
                        lManagerIds.add(oUser.Manager.Manager.Id);    
                        if(oUser.Manager.Manager.Manager != NULL){
                            System.debug('Inside Manager 3 : '+oUser.Manager.Manager.Manager.Id);
                            lManagerIds.add(oUser.Manager.Manager.Manager.Id);
                            if(oUser.Manager.Manager.Manager.Manager != NULL){
                                System.debug('Inside Manager 4 : '+oUser.Manager.Manager.Manager.Manager.Id);
                                lManagerIds.add(oUser.Manager.Manager.Manager.Manager.Id);   
                                if(oUser.Manager.Manager.Manager.Manager.Manager != NULL){
                                    System.debug('Inside Manager 5 : '+oUser.Manager.Manager.Manager.Manager.Manager.Id);
                                    lManagerIds.add(oUser.Manager.Manager.Manager.Manager.Manager.Id);    
                                    if(oUser.Manager.Manager.Manager.Manager.Manager.Manager != NULL){
                                        System.debug('Inside Manager 6 : '+oUser.Manager.Manager.Manager.Manager.Manager.Manager.Id);
                                        lManagerIds.add(oUser.Manager.Manager.Manager.Manager.Manager.Manager.Id);    
                                    }
                                }
                            }
                        }
                    }
                }
                mUsersWithManagers.put(oUser.id,lManagerIds);
            }
            return mUsersWithManagers;
    }

    public class ARRequest {
        @InvocableVariable(label='Account Relationship Ids' required=FALSE)
        public list<String> ARIds;
        @InvocableVariable(label='User Ids' required=FALSE)
        public list<String> UserIds;
    }
    public class ARResponse {
        @InvocableVariable(label='Single Record' required=FALSE)
        public Boolean isSinglRecord = FALSE;
        @InvocableVariable(label='Authentication Successful for 1 Record' required=FALSE)
        public Account_Relationship__c oARResponse = new Account_Relationship__c();
        @InvocableVariable(label='Account Relationship List' required=FALSE)
        public list<Account_Relationship__c> lARResponse = new list<Account_Relationship__c>();
        @InvocableVariable(label='Authentication Successful' required=FALSE)
        public Boolean isSuccessful = TRUE;
        @InvocableVariable(label='User Authentication Successful' required=FALSE)
        public Boolean isSuccessfulUser = TRUE;
        @InvocableVariable(label='LOB' required=FALSE)
        public String LOB = '';
    }
}