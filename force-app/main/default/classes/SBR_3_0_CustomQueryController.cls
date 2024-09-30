/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomQueryController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to execute Custom Query from LWC or AURA comps
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        26-Feb-2024         Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_CustomQueryController {
    @AuraEnabled(cacheable=true)
    public static list<sObject> executeQuery(String fieldsCSV, String objAPIName, String whereClause)
    {
        String query = 'SELECT Id, ' + fieldsCSV + ' FROM ' + objAPIName + ' ' + (String.isNotBlank(whereClause) ? whereClause : '');
        List<sObject> lstData = Database.query(query);
        return lstData;
    }
}