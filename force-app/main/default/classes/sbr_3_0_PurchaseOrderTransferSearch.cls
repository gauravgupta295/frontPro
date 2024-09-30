public class sbr_3_0_PurchaseOrderTransferSearch {
         @AuraEnabled(cacheable=true)
        public static List<Internal_Order__c> getTransfer(Id recordId, String objectName,List<String> fieldName){

        System.debug('recordId   '+ recordId);
        System.debug('objectName   '+ objectName);

        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + '' + ' Order By Name Limit 50';
        return DataBase.query(query); 

        }

  @AuraEnabled(cacheable=true)
    public static List<Internal_Order__c> getSearchResults(String recordId, String searchString){
        searchString = '*' + searchString.replace('-', '\\-') + '*';
        system.debug('searchString ,'+searchString);
        list<Internal_Order__c> accList;
        List<List<Internal_Order__c>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Internal_Order__c(Id,RM_Transfer_Number__c, Receiving_Branch_Name__c, Sending_Branch_Name__c, Status__c, Transfer_Date__c, Ordered_By_Name__c)];
       	system.debug('searchList ,'+searchList);
        accList = (Internal_Order__c[])searchList[0];
        system.debug('searchquery ,'+accList);
        return (accList);   
    }
 @AuraEnabled(cacheable=true)
    public static List<Internal_Order__c> getTransferForFilter(String recordId, String objectName,List<String> fieldName,String filterBy){
        List<SObject> returnedObjects = new List<SObject>();
        if(string.isNotBlank(filterBy)) {
            filterBy = ' ' + filterBy;
        }
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where RM_Transfer_Number__c !=\'null\'' + filterBy + ' Order By Name Limit 50';       
        system.debug('query=='+query);
        returnedObjects = DataBase.query(query);
        //Create a set of result Ids
        Set<Id> resultIds = (new Map<Id,SObject>(returnedObjects)).keySet();
        //Get exact record only if record Id does not exist in the list of records since we are pulling only first 50 records in the above query
        system.debug('recordId >>>'+recordId);
        system.debug('resultIds >>>'+ resultIds);
        system.debug('resultIds >>>'+ JSON.serialize(resultIds));
        if(string.isNotBlank(recordId) && !resultIds.contains(recordId)){
            query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' Where Id =\'' + recordId + '\'LIMIT 1';
            List<SObject> exactRecord = DataBase.query(query);
            if(exactRecord.size() > 0) {
                returnedObjects.addAll(exactRecord);
            }
        }
        return returnedObjects;
    }

     @AuraEnabled(cacheable=true)
    public static List<Internal_Order_Line_Item__c> getTransfersForFilter(String recordId, String objectName,List<String> fieldName,String filterBy){
        List<SObject> returnedObjects = new List<SObject>();
        if(string.isNotBlank(filterBy)) {
            filterBy = ' ' + filterBy;
        }
        string filterByString =  string.isBlank(filterBy) ? 'Id != null' : filterBy;
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where ' + filterByString + ' Order By Name Limit 50';       
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