public with sharing class sbr_3_0_PurchaseOrderContractSearch {
    
    //method to return list Contract numbers
    @AuraEnabled(cacheable=true)
    // public static List<Order> getContract(String objectName,List<String> fieldName,String filterBy){
    public static List<Order> getContract(Id recordId, String objectName,List<String> fieldName){

        System.debug('recordId   '+ recordId);
        System.debug('objectName   '+ objectName);

        // String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where Vendor_Status__c !=\'D\'' + filterBy + ' Order By Name Limit 50'; 
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + '' + ' Order By Name Limit 50';
        return DataBase.query(query);   
    }
    
    // Method to search contracts
    @AuraEnabled(cacheable=true)
    public static List<Order> getSearchResults(String recordId, String searchString){
        searchString = '*' + searchString.replace('-', '\\-') + '*';
        system.debug('searchString ,'+searchString);
        list<Order> contractList;
        List<List<sObject>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Order(Id, Name, Account.Name,OrderNumber, Contract_Order_Number__c, Contract_Number__c, ContractId, Account.RM_Account_Number_Display__c, AccountId, Status, EffectiveDate, EndDate )];
        
        contractList = (Order[])searchList[0];
        system.debug('searchquery ,'+contractList);
        return (contractList);   
    }
    

    // Method to search contracts for filter
  @AuraEnabled(cacheable=true)
    public static List<Order> getContractForFilter(String recordId, String objectName,List<String> fieldName,String filterBy){
        List<SObject> returnedObjects = new List<SObject>();
        if(string.isNotBlank(filterBy)) {
            filterBy = ' ' + filterBy;
        }
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where Status !=\'Activated\'' + filterBy + ' Order By Name Limit 50'; 
        // String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' Where ' + filterBy + ' Order By Name Limit 50'; 
        system.debug('query=='+query);
        returnedObjects = DataBase.query(query);
        //Create a set of result Ids
        Set<Id> resultIds = (new Map<Id,SObject>(returnedObjects)).keySet();
        //Get exact record only if record Id does not exist in the list of records since we are pulling only first 50 records in the above query
        if(string.isNotBlank(recordId) && !resultIds.contains(recordId)){
            query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' Where Id =\'' + recordId + '\'LIMIT 1';
            List<SObject> exactRecord = DataBase.query(query);
            if(exactRecord.size() > 0) {
                returnedObjects.addAll(exactRecord);
            }
        }
        return returnedObjects;
    }



}