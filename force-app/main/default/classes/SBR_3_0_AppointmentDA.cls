/*********************************************************************************************************************
* Apex Class: SBR_3_0_AppointmentDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Appointment Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-15            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_AppointmentDA implements SBR_3_0_AppointmentDAInterface {

    public static Event getAppointment(Id id) {
        return [SELECT Id, Subject, IsAllDayEvent, WhatId, WhoId, Who.Name, What.Name, OwnerId, StartDateTime, EndDateTime, Type, Description, Street__c, City__c,
                        State__c, Zip_Code__c, Country__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, IsReminderSet, ReminderDateTime, Outcome__c FROM Event WHERE ID =: id 
                        ORDER BY StartDateTime ASC];
    }

    public static Map<Id, Event> getAppointments(Set<Id> ids) {
        return new Map<Id, Event>([SELECT Id, Subject, IsAllDayEvent, WhatId, WhoId, Who.Name, What.Name, OwnerId, StartDateTime, EndDateTime, Type, Description, Street__c, City__c,
                                        State__c, Zip_Code__c, Country__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, IsReminderSet, ReminderDateTime, Outcome__c FROM Event WHERE ID IN: ids 
                                        ORDER BY StartDateTime ASC]);
    }

    public static List<Event> getAppointmentsByOwner(Id id) {
        return [SELECT Id, Subject, IsAllDayEvent, WhatId, WhoId, Who.Name, What.Name, OwnerId, StartDateTime, EndDateTime, Type, Description, Street__c, City__c,
                    State__c, Zip_Code__c, Country__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, IsReminderSet, ReminderDateTime, Outcome__c FROM Event WHERE OwnerId =: id
                    ORDER BY StartDateTime ASC];
    }

    public static Map<Id, List<Event>> getAppointmentsByOwners(Set<Id> ids) {
        
        Map<Id, List<Event>> result = new Map<Id, List<Event>>();

        List<Event> events = [SELECT Id, Subject, IsAllDayEvent, WhatId, WhoId, Who.Name, What.Name, OwnerId, StartDateTime, EndDateTime, Type, Description, Street__c, City__c,
                                State__c, Zip_Code__c, Country__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, IsReminderSet, ReminderDateTime, Outcome__c FROM Event
                                WHERE OwnerId IN: ids ORDER BY OwnerId ASC, StartDateTime ASC];

        for(Event e : events) {
            if(result.get(e.OwnerId) == null) {
                result.put(e.OwnerId, new List<Event>());
            }
            List<Event> eventsByOwner = result.get(e.OwnerId);
            eventsByOwner.add(e);
            result.put(e.OwnerId, eventsByOwner);
        }

        return result;
    }

    public static List<Event> getAppointmentsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) {
        
        Set<Id> ownerIds = new Set<Id>();

        String users = wrapper.userTerritories;
        if(String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for(String s : users.split(',')) {
                ownerIds.add(s);
            }
        }

        String sQuery = 'SELECT Id, Subject, IsAllDayEvent, WhatId, WhoId, Who.Name, What.Name, OwnerId, StartDateTime, EndDateTime, Type, Description, Street__c, City__c,'
                                + ' State__c, Zip_Code__c, Country__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, IsReminderSet, ReminderDateTime, Outcome__c' 
                                + ' FROM Event WHERE ';

        sQuery += '(';

        if(String.isNotBlank(wrapper.appointmentSearch)) {
            sQuery += 'Subject LIKE \'%' + String.escapeSingleQuotes(wrapper.appointmentSearch) + '%\' AND ';
        }

        if(String.isNotBlank(wrapper.apptParentType) && wrapper.apptParentType == 'Other') {
            sQuery += 'What.Type != \'Account\' AND What.Type != \'Project__c\' AND What.Type != \'Opportunity\' AND ';
        }
        else if(String.isNotBlank(wrapper.apptParentType)) {
            sQuery += 'What.Type = \'' + wrapper.apptParentType + '\' AND ';
        }

        if(wrapper.openAppointments == true) {
            sQuery += '(Status__c = \'Open\' OR Status__c = \'Scheduled\')';
        }
        
        sQuery += ') AND ';
        sQuery = sQuery.replaceAll('\\(\\) AND', '');
        sQuery = sQuery.replaceAll('AND \\)', ')');
        sQuery += '(';

        if(wrapper.todaysAppointments == true) {
            sQuery += 'ActivityDate = TODAY OR ';
        }

        if(wrapper.next7DaysAppointments == true) {
            sQuery += '(ActivityDate = NEXT_N_DAYS:7 OR ActivityDate = TODAY) OR ';
        }

        if(wrapper.thisWeekAppointments == true) {
            sQuery += 'ActivityDate = THIS_WEEK OR ';
        }

        if(wrapper.nextWeekAppointments == true) {
            sQuery += 'ActivityDate = NEXT_WEEK OR ';
        }

        if(wrapper.nextXDaysAppointments == true && String.isNotBlank(wrapper.nextXDaysAppointmentsValue)) {
            sQuery += '(ActivityDate = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysAppointmentsValue) + ' OR ActivityDate = TODAY) OR ';
        }

        if(wrapper.dateRangeAppointments == true && String.isNotBlank(wrapper.dateRangeAppointmentsStart) &&
            String.isNotBlank(wrapper.dateRangeAppointmentsEnd)) {
            sQuery += '(ActivityDate >= ' + String.escapeSingleQuotes(wrapper.dateRangeAppointmentsStart) + ' AND ActivityDate <= ' + String.escapeSingleQuotes(wrapper.dateRangeAppointmentsEnd)
                    + ')';
        }
        sQuery += ') AND ';

        System.debug('pre sQuery -> ' + sQuery);

        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('OR \\)', ')');
        sQuery = sQuery.replaceAll('AND \\)', ')');

        sQuery += 'OwnerId IN ' + inClausify(ownerIds);

        sQuery += ' ORDER BY OwnerId ASC, StartDateTime ASC';
        System.debug('sQuery -> ' + sQuery);

        List<Event> result = Database.query(sQuery);

        return result;
    }

    public static String inClausify(Set<Id> ids) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<Id>(ids) , '\',\'') });
        return inClause;
    }

}