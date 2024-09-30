public with sharing class SBR_3_0_AccChangeMngmtReqOperations {
    @testVisible static List<Wynne_Sales_Rep_Mapping__mdt> wyneeSalesMappings{ 
        get{ 
            if(wyneeSalesMappings == NULL){ 
                wyneeSalesMappings = [Select id, CRMRepType__c, Managed__c,SalesRepType__c,WynneSalesRepType__c from Wynne_Sales_Rep_Mapping__mdt];
            } 
            return wyneeSalesMappings; 
        } 
        set;} 
    
    public static void updateWyneeRepDetails(List<Account_Management_Change_Request__c> acmrnewList) {
        //Wynne_Sales_Rep_Mapping__mdt[] wyneeSalesList = [Select id, CRMRepType__c, Managed__c,SalesRepType__c,WynneSalesRepType__c from Wynne_Sales_Rep_Mapping__mdt];
       List<Account_Management_Change_Request__c> acmrListUpdate = new List<Account_Management_Change_Request__c>();
        
        for(Account_Management_Change_Request__c acmr:[Select id, Sales_Rep__c, Sales_Rep__r.Rep_Type__c from Account_Management_Change_Request__c Where id IN:acmrnewList ]) {
            for(Wynne_Sales_Rep_Mapping__mdt wsr:wyneeSalesMappings) {
                if(acmr.Sales_Rep__r.Rep_Type__c == wsr.CRMRepType__c) {
                    acmr.WynRepType__c = wsr.WynneSalesRepType__c;
                    acmr.Managed__c = wsr.Managed__c;
                    acmrListUpdate.add(acmr);
                }
            }
            
        }
        if(!acmrListUpdate.isEmpty()) {
            update acmrListUpdate;
        }
        

    }
}