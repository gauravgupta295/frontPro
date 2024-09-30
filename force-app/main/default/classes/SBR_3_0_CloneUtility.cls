/*********************************************************************************************************************
* Apex Class: SBR_3_0_CloneUtility
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Clone a list of objects to a particular object type
--------------------------------------------------------------------------------------------------------------------------------------
* @param         sObjects - the list of objects to be cloned
*                objectType - the type of object to be cloned.
*                whereClause - Field on which where clause is applied
*                excludedFields - Fields which we are not cloning leaving the non creatable field
--------------------------------------------------------------------------------------------------------------------------------------
* @return        List<sObject>: Returns list of cloned sObject
* --------------------------------------------------------------------------------------------------------------------------------------
* @pre-requisite The sObjects you pass in must include the ID field,
* --------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala        2022-11-18          Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_CloneUtility {
    public static List<sObject> cloneObjects(List<sObject> sObjects, Schema.SObjectType objectType,
                                             String whereClause, List<String> excludedFields,Boolean isPreserveId){
        // A list of IDs representing the objects to clone
        List<Id> sObjectIds = new List<Id>{};
        Map<String, Schema.SObjectField> fMap =  objectType.getDescribe().fields.getMap();
        list<string> selectFields = new list<string>();
        Schema.SObjectType objType = sObjects.get(0).getsObjectType();
        // A list of fields for the sObject being cloned
        List<String> sObjectFields = new List<String>{};
        // A list of new cloned sObjects
        List<sObject> clonedSObjects = new List<sObject>{};
        String allSObjectFieldsQuery = '';
        Id recordypeId;
        // Get all the fields from the selected object type using
        // the get describe method on the object type.
        if(objectType != null){
            sObjectFields.addAll(
                objectType.getDescribe().fields.getMap().keySet());
            }
        // If there are no objects sent into the method,
        // then return an empty list
        if (sObjects != null && !sObjects.isEmpty() && !sObjectFields.isEmpty()) {
            // Get Ids from List of sObjects
            for (sObject objectInstance: sObjects){
                sObjectIds.add(objectInstance.Id);
            }
            System.debug('@sObjectIds'+sObjectIds);
            /* Get the name of all the fields*/

            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable() /*|| fd.isCalculated()*/){ // field is creatable and for formula fields
                    selectFields.add(fd.getName());
                }
            }

            for (string fieldName:selectFields){
                if(excludedFields != null && excludedFields.contains(fieldName)) {
                       // allSObjectFieldsQuery += fieldName + ',';
                }
                else {
                    allSObjectFieldsQuery += fieldName + ',';
                }
            }
            if (allSObjectFieldsQuery.endsWith(',')){
                allSObjectFieldsQuery = allSObjectFieldsQuery.substring(0,allSObjectFieldsQuery.lastIndexOf(','));
            }

            allSObjectFieldsQuery = 'SELECT ' + allSObjectFieldsQuery ;
            allSObjectFieldsQuery += ' FROM ' +
                                    objectType.getDescribe().getName() +
                                    ' WHERE '+ whereClause+' IN (\'' + sObjectIds.get(0) +
                                    '\'';

            for (Integer i=1 ; i < sObjectIds.size() ; i++){
                allSObjectFieldsQuery += ', \'' + sObjectIds.get(i) + '\'';
            }

            allSObjectFieldsQuery += ')';
            System.debug('allSObjectFieldsQuery'+JSON.serializePretty(allSObjectFieldsQuery));
            try{

                // Execute the query. For every result returned,
                // use the clone method on the generic sObject
                // and add to the collection of cloned objects
                for (SObject sObjectFromDatabase:Database.query(allSObjectFieldsQuery)){
                    clonedSObjects.add(sObjectFromDatabase.clone(isPreserveId,true,false,false));
                }
                System.debug('clonedSObjects'+clonedSObjects);
            } catch (exception errorMessage){
                System.debug('errorMessage' + errorMessage);
            }
        }

        // return the cloned sObject collection.
        return clonedSObjects;
    }
}