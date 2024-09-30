public with sharing class PPA_TableForAnalyticsController {
    @AuraEnabled(cacheable=true)
    public static List<PPA_Price_List__c> fetchPriceList(String Status, String Health, String RepName, String Enddate, String IsStarted) {

        String statusVal = Status.replace('[', '').replace(']', '').replace('"', '');
        String healthVal = Health.replace('[', '').replace(']', '').replace('"', '');
        String repNameVal = RepName.replace('[', '').replace(']', '').replace('"', '');
        String endDateVal = Enddate.replace('[', '').replace(']', '').replace('"', '');
        List<String> listStatus = statusVal.split(',');
        List<String> listHealth = healthVal.split(',');
        List<String> listRepName = repNameVal.split(',');
        List<String> listEndDate = endDateVal.split(',');

        String query = 'SELECT Id, Name, PPA_Customer_Name__c, PPA_Customer_No__c, PPA_Customer_TTM__c, ' +
                        'PPA_Current_TTM_RA__c, PPA_Current__c, PPA_Next_Approver_Name__c, PPA_Start_Date__c, ' +
                        'PPA_Dashboard_End_Date__c, PPA_Active_Days__c,PPA_Next_30_Days__c, PPA_Next_90_Days__c, PPA_Rep_Name__c, ' +
                        'PPA_Health__c, PPA_Status__c, PPA_RowColorClass__c, PPA_Started__c FROM PPA_Price_List__c WHERE PPA_Current__c = true';
        /*PPA Phase 2: DP-1025
        Added PPA_Started__c */
        if(!string.isBlank(IsStarted)) {
            if(IsStarted == 'Yes') {
                query += ' AND PPA_Started__c =:IsStarted';
            }
        }

        if (!String.isBlank(Status)) {
            query += ' AND PPA_Status__c IN :listStatus';
        }

        if (!String.isBlank(Health)) {
            query += ' AND PPA_Health__c IN :listHealth';
        }

        if (!String.isBlank(RepName)) {
            query += ' AND PPA_Rep_Name__c IN :listRepName';
        }
        
        if (!String.isBlank(Enddate)) {
            List<Date> endDates = new List<Date>();
            for (String endD: listEndDate) {
                Date dt = Date.valueOf(endD);
                endDates.add(dt);
            }
            query += ' AND PPA_Dashboard_End_Date__c IN :endDates';
        }
        query += ' ORDER BY PPA_Dashboard_End_Date__c , PPA_Rep_Name__c, PPA_Customer_Name__c';
        query += ' LIMIT 500';
        return Database.query(query);
    }
}