/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomerSpendOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage any updates that needs to be done on Leads as part of trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mohnish Garg            24 Aug,2023          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_CustomerSpendOperations {
    public static void updateSyncSortingOrder(List<Customer_Spend__c> lCSNew,Map<Id,Customer_Spend__c> mCSOld){
        list<String> lAccount_Record_Types_to_Update_Sorting = Label.SBR_3_0_Account_Record_Types_to_Update_Sorting.split(',');
        System.debug('lAccount_Record_Types_to_Update_Sorting'+lAccount_Record_Types_to_Update_Sorting);
        set<Id> sAccountIds = new set<Id>();
        set<Id> sCSIds = new set<Id>();
        for(Customer_Spend__c oCSNew : lCSNew){
            Customer_Spend__c oCSOld = new Customer_Spend__c();
            if(mCSOld != NULL){
                oCSOld = mCSOld.get(oCSNew.id);
            }    
           if(
               oCSNew.Account__c != null &&
               Trigger.isUpdate && 
               oCSNew.Current_TTM_Spend__c != oCSOld.Current_TTM_Spend__c
           ){
           		sAccountIds.add(oCSNew.Account__c);
                sCSIds.add(oCSNew.id);
			}
        }
        System.debug('sAccountIds'+sAccountIds);
        list<Account_relationship__c> lAccountRelToUpdate = 	[
            									SELECT 
            									Id,
            									SBR_3_0_Sync_Sorting_Order__c 
            									FROM 
            									Account_relationship__c 
            									WHERE 
            									Account_ID__c  IN: sAccountIds
            									AND
            									SBR_3_0_Sync_Sorting_Order__c = TRUE
            									AND
            									Customer_Spend__c IN: sCSIds
        									];
        System.debug('lAccountRelToUpdate'+lAccountRelToUpdate);
        for(Account_relationship__c oAccountRel : lAccountRelToUpdate){
        	oAccountRel.SBR_3_0_Sync_Sorting_Order__c = FALSE;    
        }
        if(!lAccountRelToUpdate.isEmpty()){
        	UPDATE lAccountRelToUpdate;    
        }
    }
    public static void updateLOBOnAccount(List<Customer_Spend__c> newList, Map<Id,Customer_Spend__c> oldMap){
        Set<id> accIdSet = new Set<id>();
    //    Set<Id> creditId = new Set<Id>();
        Map<id,Map<string,string>> accVsLobMap = new Map<id,Map<string,string>>();
        List<Account> updateAccList = new List<Account>();
        for(Customer_Spend__c each: newList){
            if(oldmap==null || each.Analysis_Region__c != oldmap.get(each.id).Analysis_Region__c){
                if(each.Account__c !=null ){
                    accIdSet.add(each.Account__c);
                }
            }
        }
        if(!accIdSet.isempty()){
        for(Customer_Spend__c each: [Select id, Account__c, Analysis_Region__r.name, Account__r.recordtype.name,
                                            Analysis_Region__r.Analysis_Region_Key__c from Customer_Spend__c
                                            where Account__c in : accIdSet order by Account__c]){
                if(accVsLobMap.containskey(each.Account__c)){
                    accVsLobMap.get(each.Account__c).put(each.Analysis_Region__r.Analysis_Region_Key__c,each.Analysis_Region__r.name);
                }else{
                    Map<string,string> tempMap = new Map<string,string>();
                    tempMap.put(each.Analysis_Region__r.Analysis_Region_Key__c,each.Analysis_Region__r.name);
                    accVsLobMap.put(each.Account__c, tempMap);
                }
               /* if(each.Account__r.recordtype.name =='Credit'){
                    creditId.add(each.account__c);
                } */
            }
      /*  for(Customer_Spend__c each:[Select id, Account__c, Analysis_Region__r.name, Account__r.recordtype.name,
                            Analysis_Region__r.Analysis_Region_Key__c from Customer_Spend__c
                            where Account__r.parentid in : creditId AND Account__r.recordtype.name ='Office' order by Account__c ]){
            if(accVsLobMap.containskey(each.Account__c)){
                accVsLobMap.get(each.Account__c).put(each.Analysis_Region__r.Analysis_Region_Key__c,each.Analysis_Region__r.name);
            }else{
                Map<string,string> tempMap = new Map<string,string>();
                tempMap.put(each.Analysis_Region__r.Analysis_Region_Key__c,each.Analysis_Region__r.name);
                accVsLobMap.put(each.Account__c, tempMap);
            }

        } */

        for(id eachMap: accVsLobMap.keyset()){ // Select id from Account WHere ParentId IN:accVsLobMap.keyset()
            Account obj = new Account();
            obj.No_of_Lines_of_Business__c = accVsLobMap.get(eachMap).values().size();
            obj.Lines_of_Business__c = STRING.join( accVsLobMap.get(eachMap).values(),';');
            obj.id = eachMap;
            updateAccList.add(obj);
           /* for(Account acc:[Select id from Account WHere ParentId IN:updateAccList ]) {
            acc.No_of_Lines_of_Business__c = accVsLobMap.get(eachMap).values().size() ;
            acc.Lines_of_Business__c = STRING.join( accVsLobMap.get(eachMap).values(),';');
            updateAccList.add(acc);
            } */
        }
           
        Update updateAccList;
    }
}
}