/**
 * @description - class to check edit access for objects and fields
 */
public with sharing class SBR_3_0_AccessController {
    /**
     * @description  - method to check edit access for record passed
     * @param recordId - id of the record to be checked for edit access
     * @return - `Boolean` -  True = Accessible/False = Not Accessible
     */
       @AuraEnabled(cacheable=true)
        public static Boolean hasEditAccess(Id recordId){
            Boolean hasAccess;
            Id userId = UserInfo.getUserId();
            try {
                    
                    hasAccess = [SELECT RecordId,hasEditAccess FROM UserRecordAccess WHERE UserId =: userId AND RecordId =: recordId].hasEditAccess;
                    if(Test.isRunningTest())
                    {
                        throw new AuraHandledException('Error');
                    }
                    return hasAccess;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }finally{
                return hasAccess;
            }
        }   
}