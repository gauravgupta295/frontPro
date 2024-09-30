/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountRelationshipTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Account Relationships
* - SF-165
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                   2023-04-17               Initial version 
    1.1         Mohnish Garg                      2023-04-18               Added updateStrategicType method
    1.2         Mohnish Garg                      2023-04-19               Added populateStrategicRepField method
*********************************************************************************************************************/
public class SBR_3_0_AccountRelationshipOperations {
    public static void updateSyncSortingOrder(List<Account_Relationship__c> lARNew,Map<Id,Account_Relationship__c> mAROld){
        Map<String,Schema.SObjectField> mFieldsFromObject = Schema.getGlobalDescribe().get('Account_Relationship__c').getDescribe().fields.getMap();
        System.debug('mFieldsFromObject'+mFieldsFromObject);
        list<String> lAccount_Record_Types_to_Update_Sorting = Label.SBR_3_0_Account_Record_Types_to_Update_Sorting.split(',');
        System.debug('lAccount_Record_Types_to_Update_Sorting'+lAccount_Record_Types_to_Update_Sorting);
        set<Id> sAccountIds = new set<Id>();
        for(Account_Relationship__c oARNew : lARNew){
            Account_Relationship__c oAROld = new Account_Relationship__c();
            if(mAROld != NULL){
                oAROld = mAROld.get(oARNew.id);
            }    
            if(	            
                oARNew.Territory__c  != oAROld.Territory__c ||
                oARNew.User_Account__c  != oAROld.User_Account__c ||
                oARNew.Type__c  != oAROld.Type__c ||
                oARNew.Customer_Spend__c != oAROld.Customer_Spend__c
               )
            {
           		oARNew.SBR_3_0_Sync_Sorting_Order__c = false;
                //sAccountIds.add(oARNew.Account_ID__c);
            }
        }
    }

    public static void updateStrategicType(List<Account_Relationship__c> lARNew,Map<Id,Account_Relationship__c> mAROld){
        Map<String,SBR_3_0_Rep_Type_Classification__mdt> mRepTypeMtd =  new Map<String,SBR_3_0_Rep_Type_Classification__mdt>();
        Map<Id,string> accrelationIdVsSalesRepMap = new Map<Id,String>();
        List<Account> accountList =  new List<Account>();
        Map<string,integer> precedenceMap = new Map<String, integer>{ 'National'=>3,'Regional'=> 2, 'None'=>1};
        for(SBR_3_0_Rep_Type_Classification__mdt each: SBR_3_0_Rep_Type_Classification__mdt.getAll().values()){
            mRepTypeMtd.put(each.Rep_Type__c,each);
        }
        for(Account_Relationship__c each: lARNew){
            //SF-6494 changes
            if (each.Type__c != 'Tracking'){
               accrelationIdVsSalesRepMap.put(each.Account_ID__c, each.Rep_Type__c); 
            }
            
        }
        if(!accrelationIdVsSalesRepMap.keyset().isEmpty()){
            for(Account each:[Select id,Strategic_Type__c from Account where id in: accrelationIdVsSalesRepMap.keySet()]){
                if(accrelationIdVsSalesRepMap.get(each.id) ==null || mRepTypeMtd.get(accrelationIdVsSalesRepMap.get(each.id)) == null){
                    account obj = new account();
                    obj.id = each.id;
                    obj.Managed__c = false;
                    obj.Strategic_Type__c = 'None';
                    /*if(each.Strategic_Type__c != obj.Strategic_Type__c){
                    	accountList.add(obj);
                    }*/
                }
                else if(precedenceMap.get(each.Strategic_Type__c) <=  precedenceMap.get(mRepTypeMtd.get(accrelationIdVsSalesRepMap.get(each.id)).Strategic_Type__c)){
                    account obj = new account();
                    obj.id = each.id;
                    obj.Strategic_Type__c = mRepTypeMtd.get(accrelationIdVsSalesRepMap.get(each.id)).Strategic_Type__c;
                    if(each.Strategic_Type__c != obj.Strategic_Type__c && each.Strategic_Type__c == 'None'){
                    	accountList.add(obj);
                    }
                }
            }
        }
        map<id,account> accUpdateMap = new map<id,account> ();
        accUpdateMap.putall(accountList);
        if(accUpdateMap.size()>0){
        	update accUpdateMap.values();
        }
        //UPDATE accountList;
    }


    public static void populateStrategicRepField(List<Account_Relationship__c> lARNew){
        Map<String,SBR_3_0_Rep_Type_Classification__mdt> mRepTypeMtd =  new Map<String,SBR_3_0_Rep_Type_Classification__mdt>();
        List<Account> updateAccountList = new List<Account>();
        //SF-5883 changes to update Account only if needed
        map<id,account> accUpdateMap = new map<id,account> ();
        for(SBR_3_0_Rep_Type_Classification__mdt each: SBR_3_0_Rep_Type_Classification__mdt.getAll().values()){
            mRepTypeMtd.put(each.Rep_Type__c,each);
        }
        for(Account_Relationship__c each:lARNew){
            Boolean accUpd = false;
            //SF-6494 changes
            if(each.Rep_Type__c !=null && each.Type__c != 'Tracking'){
                Account obj = new Account();
                SBR_3_0_Rep_Type_Classification__mdt mtd =  mRepTypeMtd.get(each.Rep_Type__c);
                if (mtd != null)
                {
                    if (accUpdateMap.containsKey(each.Account_ID__c)){
                        obj = accUpdateMap.get(each.Account_ID__c);
                    }else{
                     	obj.id = each.Account_ID__c;   
                    }
                    
                    if(mtd.Wynne_Sales_Rep_Type__c == 'TERREP' && each.account_id__r.GT_Territory_Rep__c != each.User_Account__c)
                    { obj.GT_Territory_Rep__c = each.User_Account__c; accUpd = true;}   
                    else if (mtd.Wynne_Sales_Rep_Type__c == 'NSAM' && each.account_id__r.National_Strategic_Customer_Manager__c != each.User_Account__c)
                        {  obj.National_Strategic_Customer_Manager__c = each.User_Account__c; accUpd = true;}
                    else if (mtd.Wynne_Sales_Rep_Type__c == 'RSAM' && each.account_id__r.Regional_Strategic_Customer_Rep__c != each.User_Account__c)
                        { obj.Regional_Strategic_Customer_Rep__c = each.User_Account__c; accUpd = true;}
                    else if (mtd.Wynne_Sales_Rep_Type__c == 'NSSAM' && each.account_id__r.Specialty_Strategic_Customer_Mgr__c != each.User_Account__c)
                        { obj.Specialty_Strategic_Customer_Mgr__c = each.User_Account__c; accUpd = true;}
                    else if (mtd.Wynne_Sales_Rep_Type__c == 'RSSAM' && each.account_id__r.Specialty_Strategic_Customer_Rep__c != each.User_Account__c)
                        { obj.Specialty_Strategic_Customer_Rep__c = each.User_Account__c; accUpd = true;}
                    if (mtd.Managed__c && !each.Account_ID__r.Managed__c){
                        obj.Managed__c = True;
                        accUpd = true;
                    }
                    if (accUpd){
                        accUpdateMap.put(obj.id,obj);
                    }
                      
                }
            }
        }
        
        if(accUpdateMap.size()>0){
        	update accUpdateMap.values();
        }
        //update updateAccountList;
    }
    public static void updateNewAssignment(List<Account_Relationship__c> lARNew,Map<Id,Account_Relationship__c> mAROld){
        for(Account_Relationship__c oARNew : lARNew){
            Account_Relationship__c oAROld = new Account_Relationship__c();
            if(mAROld != NULL){
                oAROld = mAROld.get(oARNew.id);
            }    
            if(!System.isBatch() && (Trigger.isInsert  || oAROld.User_Account__c != oARNew.User_Account__c)){
                  oARNew.SBR_3_0_New_Assignment__c = TRUE;
            }
        }
    }
}