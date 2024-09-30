/*********************************************************************************************************************
* Apex Class: SBR_3_0_TaskDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Tasks Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-07-20          Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_TaskDA implements SBR_3_0_TaskDAInterface{
    public static List<Task> getTasks(){
        return [SELECT ID, Subject, Priority, ActivityDate, WhoId, WhatId, Who.Name, What.Name, OwnerId, Status, Description, IsReminderSet, ReminderDateTime 
                    FROM Task ORDER BY ActivityDate ASC];
    }

    public static List<Task> getTasksByOwner(Id ownerId){
        return [SELECT ID, Subject, Priority, ActivityDate, WhoId, WhatId, Who.Name, What.Name, OwnerId, Status, Description, IsReminderSet, ReminderDateTime 
                    FROM Task WHERE OwnerId =: ownerId ORDER BY ActivityDate ASC];
    }

    public static Task getTask(Id id){
        return [SELECT ID, Subject, Priority, ActivityDate, WhoId, WhatId, Who.Name, What.Name, OwnerId, Status, Description, IsReminderSet, ReminderDateTime
                    FROM Task WHERE ID =: id ORDER BY ActivityDate ASC];
    }

    public static List<Task> getTasksFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) {
        
        Set<Id> ownerIds = new Set<Id>();

        String users = wrapper.userTerritories;
        if(String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for(String s : users.split(',')) {
                ownerIds.add(s);
            }
        }

        String sQuery = 'SELECT ID, Subject, Priority, ActivityDate, WhoId, WhatId, Who.Name, What.Name, OwnerId, Status, Description, IsReminderSet, ReminderDateTime' 
                        + ' FROM Task WHERE ';
        


        sQuery += '(';

        if(String.isNotBlank(wrapper.taskSearch)) {
            sQuery += 'Subject LIKE \'%' + String.escapeSingleQuotes(wrapper.taskSearch) + '%\' AND ';
        }

        if(String.isNotBlank(wrapper.taskParentType) && wrapper.taskParentType == 'Other') {
            sQuery += 'What.Type != \'Account\' AND What.Type != \'Project__c\' AND What.Type != \'Opportunity\' AND ';
        }
        else if(String.isNotBlank(wrapper.taskParentType)) {
            sQuery += 'What.Type = \'' + wrapper.taskParentType + '\' AND ';
        }

        if(wrapper.openTasks == true) {
            sQuery += 'Status__c = \'Open\'';
        }

        sQuery += ') AND ';
        sQuery = sQuery.replaceAll('\\(\\) AND', '');
        sQuery = sQuery.replaceAll('AND \\)', ')');
        sQuery += '(';

        if(wrapper.todaysTasks == true) {
            sQuery += 'ActivityDate = TODAY OR ';
        }

        if(wrapper.next7DaysTasks == true) {
            sQuery += '(ActivityDate = NEXT_N_DAYS:7 OR ActivityDate = TODAY) OR ';
        }

        if(wrapper.thisWeekTasks == true) {
            sQuery += 'ActivityDate = THIS_WEEK OR ';
        }

        if(wrapper.nextWeekTasks == true) {
            sQuery += 'ActivityDate = NEXT_WEEK OR ';
        }

        if(wrapper.nextXDaysTasks == true && String.isNotBlank(wrapper.nextXDaysTasksValue)) {
            sQuery += '(ActivityDate = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysTasksValue) + ' OR ActivityDate = TODAY) OR ';
        }

        if(wrapper.dateRangeTasks == true && String.isNotBlank(wrapper.dateRangeTasksStart) &&
            String.isNotBlank(wrapper.dateRangeTasksEnd)) {
            sQuery += '(ActivityDate >= ' + String.escapeSingleQuotes(wrapper.dateRangeTasksStart) + ' AND ActivityDate <= ' + String.escapeSingleQuotes(wrapper.dateRangeTasksEnd)
                    + ')';
        }

        sQuery += ') AND ';

        System.debug('pre sQuery -> ' + sQuery);

        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('OR \\)', ')');

        sQuery += 'OwnerId IN ' + inClausify(ownerIds);

        sQuery += ' ORDER BY ActivityDate ASC';
        System.debug('sQuery -> ' + sQuery);

        List<Task> result = Database.query(sQuery);

        return result;
    }

    public static String inClausify(Set<Id> ids) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<Id>(ids) , '\',\'') });
        return inClause;
    }

}