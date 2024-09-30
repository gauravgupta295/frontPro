public with sharing class SBR_3_0_POSearchController {

    @AuraEnabled(cacheable=true)
    public static List<SObject> getObjectRecords(String objectName,List<String> fieldName,String filterBy, integer recLimit, string orderByField){
        string filterByString =  string.isBlank(filterBy) ? 'Id != null' : filterBy;
        integer recordLimit = recLimit > 0 ? recLimit : 49999;
        System.debug('recordLimit >> '+ recordLimit);
        string orderByFieldName = string.isBlank(orderByField) ? 'Name' : orderByField;
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where ' + filterByString + ' Order By ' + orderByFieldName + ' Limit '+ recordLimit + ''; 
        system.debug('query=='+query);
        return DataBase.query(query);   
    }  
    

    @AuraEnabled(cacheable=true)
    public static List<Purchase_Order__c> getPOSearchResults(String searchString){
        searchString = '*' + searchString.replace('-', '\\-') + '*';
        system.debug('searchString ,'+searchString);
        list<Purchase_Order__c> poList;
        List<List<sObject>> searchList = [FIND : searchString
                                                RETURNING Purchase_Order__c(Id, Name, Vendor__c, Vendor_Number__c, 
                                                Vendor_Name_Text__c, Status__c, 
                                                Type__c, Issue_Date__c, OrderedBy_Name__c, 
                                                Location__c, ShipTo__c Order By Name)];
       poList = (Purchase_Order__c[])searchList[0];
       system.debug('searchquery ,'+poList);
        system.debug('searchquery ,'+poList.size());
       return (poList);   
   }

 @AuraEnabled(cacheable=true)
    public static List<SObject> getObjectRecordsWithLineItems(String objectName,List<String> fieldName,String filterBy, integer recLimit, string orderByField){      
        string filterByString =  string.isBlank(filterBy) ? ' Id != null '  : filterBy;
        
        integer recordLimit = recLimit > 0 ? recLimit : 49999;
        string orderByFieldName = string.isBlank(orderByField) ? 'Name' : orderByField;
    String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where ' + filterByString +' Order By ' + orderByFieldName + ' Limit '+ recordLimit + ''; 


        system.debug('query=='+query);
        return DataBase.query(query);   
    }  

 @AuraEnabled(cacheable=true)
   public static List<PO_Line_Item__c> getPOLineItemsSearchResults(String searchString){
        searchString = '*' + searchString.replace('-', '\\-') + '*';
        system.debug('searchString ,'+searchString);
        list<PO_Line_Item__c> poLineItemList;
        List<List<sObject>> searchList = [FIND : searchString
                                                RETURNING PO_Line_Item__c(Id,Name,Purchase_Order__r.Id,Purchase_Order__r.Name,Purchase_Order__r.Vendor__c,Purchase_Order__r.Vendor_Number__c , Purchase_Order__r.Vendor_Name_Text__c, 
                                                                                             Purchase_Order__r.Status__c,Purchase_Order__r.Type__c, Purchase_Order__r.Issue_Date__c, Purchase_Order__r.OrderedBy_Name__c, Purchase_Order__r.Location__c, 
                                                                                             Purchase_Order__r.ShipTo__c 
                                                                                              Order By Name)];
       poLineItemList = (PO_Line_Item__c[])searchList[0];
       system.debug('searchquery ,'+poLineItemList);
        system.debug('searchquery ,'+poLineItemList.size());
       return (poLineItemList);   
   }

 @AuraEnabled(cacheable=true)
    public static List<Purchase_Order__c> getPOsFromVendor(String vendorId){
        List<Purchase_Order__c> purchaseOrderList = new List<Purchase_Order__c>();
        purchaseOrderList = [Select Id,Name,Vendor_Number__c,Status__c,Type__c,Issue_Date__c,Requested_Date__c,Ship_Date__c,OrderedBy__c,OrderedBy_Name__c,Location__c,ShipTo__c from Purchase_Order__c where Vendor__c =:vendorId];
        return purchaseOrderList;   
    }  



}