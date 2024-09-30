public with sharing class SBR_3_0_Queuable_AccountTerritory implements Queueable, Database.AllowsCallouts{
    public List<Account> accList; 
    public List<Account_Relationship__c> accRlnListFinal = new List<Account_Relationship__c>();
    public SBR_3_0_Queuable_AccountTerritory(List<Account> accList) {
        this.accList=accList;
    }
    public void execute(QueueableContext context) {
        for(Account acc :accList){
            // Update the Account Name 
            SBR_3_0_API_FetchTerritory sh = new SBR_3_0_API_FetchTerritory();
            List<Object> returnval = sh.getTerritoryDetails(String.valueOf(acc.Street_Address_LatLong__Latitude__s),String.valueOf(acc.Street_Address_LatLong__Longitude__s),'Account');
            if (acc.RecordTypeId==SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID){
                for (Object objc: returnval){
                    Map<String , Object> TerryMap = (Map<String, Object>) objc;
                    String terriId=String.valueOf(TerryMap.get('territoryId'));
                    String pcNumber=String.valueOf(TerryMap.get('pcId'));
                    String salesRepIdString=String.valueOf(TerryMap.get('salesRepId'));
                    Decimal salesRepId = decimal.valueOf(salesRepIdString);
                    String externalId=acc.Id+''+terriId;
                    List<Territory__c> retTerri = [Select Id from Territory__c where Territory_Id__c=: terriId];
                    Account_Relationship__c accRln = new Account_Relationship__c(Name='Accrln'+acc.Id, Account_ID__c=acc.Id, Rank__c=99999, External_ID__c=externalId, Type__c='Territory', PC_Number__c=pcNumber, Sales_Rep_ID__c=salesRepId);
                    if(!retTerri.isEmpty()){
                        accRln.Territory__c = retTerri[0].Id;
                    }
                    accRlnListFinal.add(accRln);
                }
            }
            if (acc.RecordTypeId==SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID){
                for (Object objc: returnval){
                    Map<String , Object> TerryMap = (Map<String, Object>) objc;
                    String terriId=String.valueOf(TerryMap.get('territoryId'));
                    String pcNumber=String.valueOf(TerryMap.get('pcId'));
                    String salesRepIdString=String.valueOf(TerryMap.get('salesRepId'));
                    Decimal salesRepId = decimal.valueOf(salesRepIdString);
                    String externalId=acc.Id+''+terriId;
                    Decimal resultRank;
                    String resultType;
                    List<Account_Relationship__c> accRlnList = [Select Id,Rank__c,Type__c from Account_Relationship__c where Account_ID__c=: acc.ParentId and Territory_ID_hr__c=: terriId and Rank__c!=null and Rank__c!=99999 limit 1];
                    if (accRlnList!=null && !accRlnList.isEmpty()){
                        resultRank=accRlnList[0].Rank__c;
                        if (accRlnList[0].Type__c !=null && !String.isBlank(accRlnList[0].Type__c)){
                            resultType=accRlnList[0].Type__c;
                        }
                        //Type from accRlnList[0].Type__c;
                    }
                    else{
                        resultRank=99999;
                        resultType='Territory';
                    }
                    List<Territory__c> retTerri = [Select Id from Territory__c where Territory_Id__c=: terriId];
                    Account_Relationship__c accRln = new Account_Relationship__c(Name='Accrln'+acc.Id, Account_ID__c=acc.Id, Rank__c=resultRank, Type__c=resultType, External_ID__c=externalId, PC_Number__c=pcNumber, Sales_Rep_ID__c=salesRepId );
                    if(!retTerri.isEmpty()){
                        accRln.Territory__c = retTerri[0].Id;
                    }
                    accRlnListFinal.add(accRln);
                }
            }
        }
        insert accRlnListFinal;
    }
}


// Decimal resultRank;
// Territory__c retTerri = [Select Id from Territory__c where Territory_Id__c='1-1577-13-1'];
// List<Account_Relationship__c> accRlnList = [Select Id,Rank__c from Account_Relationship__c where Account_ID__c='0013C00000k8IHMQA2' and Territory_ID_hr__c='1-1577-13-1' and Rank__c!=null and Rank__c!=999 limit 1]; 
// if (accRlnList!=null && !accRlnList.isEmpty()){
//     resultRank=accRlnList[0].Rank__c;
// }
// else{
//     resultRank=999;
// }
// System.debug(retTerri.Id);
// System.debug(resultRank);