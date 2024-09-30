public with sharing class SBR_3_0_ChangeVendorController {
	//method to return list of records for an object with parameterised field and filter
    @AuraEnabled(cacheable=true)
    public static List<Account> getVendorName(String recordId, String objectName,List<String> fieldName,String filterBy){
        List<SObject> returnedObjects = new List<SObject>();
        if(string.isNotBlank(filterBy)) {
            filterBy = 'AND ' + filterBy;
        }
        String query = 'Select ' + String.join(fieldName,',') + ' From ' + objectName + ' where Vendor_Status__c !=\'D\'' + filterBy + ' Order By Name Limit 50'; 
        //system.debug('query=='+query);
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

    @AuraEnabled(cacheable=true)
    public static List<Account> getSearchResults(String recordId, String searchString){
        searchString = '*' + searchString.replace('-', '\\-') + '*';
        system.debug('searchString ,'+searchString);
        list<Account> accList;
        List<List<sObject>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Account(Id,Vendor_Account_Number__c,Name,Tolabel(Vendor_Status__c),BillingStreet,BillingState,BillingPostalCode WHERE RecordType.DeveloperName = 'Vendor' AND Vendor_Status__c !='D' Order By Name)];
        accList = (Account[])searchList[0];
        system.debug('searchquery ,'+accList);
        return (accList);   
    }

    @AuraEnabled
    public static string updateVendor(Id recordId, String vendorRecordId ) {
        //System.debug('recordid,'+recordId);
        //System.debug('vendorrecordid,'+vendorRecordId);
        String returnVal = '';
        try { 
            Purchase_Order__c poRec = new Purchase_Order__c();
            poRec.Id = recordId;
            poRec.Vendor__c = vendorRecordId;
            System.debug(poRec);
            update poRec;
            returnVal = 'Success';
        } catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
            returnVal = 'Error';
        }
        return returnVal;
    }
}