/**
 * @description       : CustomLookupCmpController
 * @author            : Hamza Benlafkih
 * @group             : 
 * @last modified on  : 06-12-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CustomLookupCmpController {
    /**
    * @author : Hamza Benlafkih
    * @date   : 06-12-2023
    * @param searchKeyWord  : search keyword
    * @param objectAPIName  : API Name of Object
    * @param whereCondition : filters to add
    * @param fieldNames     : fields to query
    * @param displayFields  : fields to query
    * @param customLimit    : no of records
    * @return List<sObject> : list of records
    * @description : getRecords based on search Text
    */
    @AuraEnabled(cacheable=true)
    public static List<sObject> getLookupValues( String searchKeyWord,String objectAPIName,String whereCondition, String fieldNames, String displayFields, Integer customLimit ) {
        String searchKey = '%'+ searchKeyWord + '%'; 
        String filterCritiria = '';       
        List<sObject> returnList = new List<sObject>();
        String sQuery = 'SELECT Id, Name';

        if(String.isNotBlank(displayFields) && !displayFields.equalsIgnoreCase('Name')) {
            sQuery += ', '+displayFields;
        }

        List<String> splitFieldNames = fieldNames.split(',');
        for(String field: splitFieldNames) {
            if(String.isNotBlank(filterCritiria)) {
                filterCritiria += ' OR ';
            }
            filterCritiria += field + ' LIKE \'' + searchKey + '\'';
        }
        
        if(String.isNotBlank(whereCondition) && whereCondition != null){
            sQuery +=  ' FROM ' +objectAPIName + ' WHERE ' + whereCondition + ' AND (' + filterCritiria + ') ORDER BY CreatedDate DESC limit ' + String.valueOf(customLimit);
        } else {
            sQuery +=  ' FROM ' +objectAPIName + ' WHERE ' + filterCritiria + ' ORDER BY CreatedDate DESC limit ' + String.valueOf(customLimit);
        }

        List<sObject> lstOfRecords = Database.query(sQuery); // NOPMD
        for (sObject obj: lstOfRecords) { returnList.add(obj); }
        return returnList;

    }

    @AuraEnabled(cacheable=true)
    public static sObject getinitRecord(String recordId, String objectAPIName, String fieldNames) {

        String sRecId = recordId;    
        String sQuery = 'SELECT id, Name';
        if(String.isNotBlank(fieldNames)) {
            sQuery += ', '+fieldNames;
        }

        sQuery +=  ' FROM ' + objectAPIName + ' WHERE Id = : sRecId LIMIT 1 ';
        for (sObject obj: Database.query(sQuery)) {
            return obj;
        }

        return null;
    }

    /**
    * @author : Hamza Benlafkih
    * @date   : 06-12-2023
    * @param  objectAPIName  : API Name of Object
    * @param  fieldNames     : fields to query
    * @param  whereCondition : filters to add
    * @param  customLimit    : no of records
    * @return List<sObject>  : records
    * @description : get recently created records
    */
    @AuraEnabled(cacheable=true)
    public static List<sObject> gerRecentlyCreatedRecords( String objectAPIName,String fieldNames, String whereCondition, Integer customLimit){

        List<sObject> returnList = new List<sObject>();
        String sQuery = 'SELECT Id, Name';

        if(String.isNotBlank(fieldNames) && !fieldNames.equalsIgnoreCase('Name')) {

            sQuery += ', '+fieldNames;

        }

        if(String.isNotBlank(whereCondition) && whereCondition != null){

            sQuery +=  ' FROM ' +objectAPIName + ' WHERE ' + whereCondition + ' ORDER BY CreatedDate DESC limit ' + String.valueOf(customLimit);

        } else {

            sQuery +=  ' FROM ' +objectAPIName + ' ORDER BY CreatedDate DESC limit ' + String.valueOf(customLimit);

        }
        List<sObject> lstOfRecords = Database.query(sQuery);// NOPMD
        for (sObject obj: lstOfRecords) { returnList.add(obj); }

        return returnList;
    }
}