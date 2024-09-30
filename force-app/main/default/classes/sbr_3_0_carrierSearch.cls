public class sbr_3_0_carrierSearch {
   
    @AuraEnabled(cacheable=true)
    public static List<Third_Party_Carrier__c> getcarrier(integer recLimit){
        integer recordLimit = recLimit > 0 ? recLimit : 4999;
        String query = 'Select Id, Name, Carrier_Num__c, Main_Phone__c, Liability_Insurance__c, Status__c from Third_Party_Carrier__c' + ' Limit ' + recordLimit + ''; 
        system.debug('query=='+query);
        return DataBase.query(query);   
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Third_Party_Carrier__c> getSearchResults(String searchString){
        searchString = '*' + searchString.replace('-', '\\-') + '*';
        // searchString = searchString.replace('-', '\\-');
        system.debug('searchString ,'+searchString);
        
        list<Third_Party_Carrier__c> carrierList;
        List<List<Third_Party_Carrier__c>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Third_Party_Carrier__c(Id,Name,Carrier_Num__c,Main_Phone__c,Liability_Insurance__c, Status__c Order By Name)];
        system.debug('searchList ,'+searchList);
        carrierList = (Third_Party_Carrier__c[])searchList[0];
        system.debug('searchquery ,'+carrierList);
        return (carrierList);   
    }    
}