/*********************************************************************************************************************
* Apex Class: SBR_3_0_AppointmentDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_AppointmentDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-15            Initial version 
    2.0         Konrad Haight         2022-08-17            Added all tests   
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_AppointmentDA_Test {
    @TestSetup
    static void makeData() {
        Event e = SBR_3_0_TestDataFactory.createAppointments(2, null, null, true)[0];
        System.debug('Event ' + e);
    }

    @IsTest
    static void testGetAppointment() {

        List<Event> setupEvents = [SELECT Id FROM Event ORDER BY StartDateTime ASC];

        Test.startTest();
        Event testEvent = SBR_3_0_AppointmentDA.getAppointment(setupEvents[0].Id);
        Test.stopTest();

        System.assertEquals(setupEvents[0].Id, testEvent.Id, 'Test Event returned Id does not match Setup Event id');
    }

    @IsTest
    static void testGetAppointments() {
        
        List<Event> setupEvents = [SELECT Id FROM Event ORDER BY StartDateTime ASC];
        Set<Id> eventIds = new Set<Id>();

        for (Event e : setupEvents) {
            eventIds.add(e.Id);
        }

        Test.startTest();
        Map<Id, Event> testEventsMap = SBR_3_0_AppointmentDA.getAppointments(eventIds);
        Test.stopTest();

        System.assertEquals(setupEvents.size(), testEventsMap.size(), 'Test events not retrieved');
    }

    @IsTest
    static void testGetAppointmentsByOwner() {
        
        List<Event> setupEvents = [SELECT Id, OwnerId FROM Event ORDER BY StartDateTime ASC];

        Test.startTest();
        List<Event> testEvents = SBR_3_0_AppointmentDA.getAppointmentsByOwner(setupEvents[0].OwnerId);
        Test.stopTest();

        System.assertEquals(setupEvents.size(), testEvents.size(), 'Test events not retrieved');
    }

    @IsTest
    static void testGetAppointmentsByOwners() {
        
        List<Event> setupEvents = [SELECT Id, OwnerId FROM Event ORDER BY StartDateTime ASC];
        Set<Id> userIds = new Set<Id>();

        for (Event e : setupEvents) {
            userIds.add(e.OwnerId);
        }

        Test.startTest();
        Map<Id, List<Event>> testEventsMap = SBR_3_0_AppointmentDA.getAppointmentsByOwners(userIds);
        Test.stopTest();

        System.assertEquals(setupEvents.size(), testEventsMap.get(setupEvents[0].OwnerId).size(), 'Test events not retrieved');   
    }

    @IsTest
    static void testGetFilteredAppointments() {
        
        List<Event> setupEvents = [SELECT Id, OwnerId FROM Event ORDER BY StartDateTime ASC];

        for(Event e : setupEvents) {
            e.Subject = 'eventTest';
            e.ActivityDate = Date.today().toStartOfWeek().addDays(10);
            e.StartDateTime = Date.today().toStartOfWeek().addDays(10);
            e.Status__c = 'Open';
        }
        update setupEvents;

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.appointmentSearch = 'eventTest';
        wrapper.openAppointments = true;
        wrapper.todaysAppointments = false;
        wrapper.nextWeekAppointments = true;
        wrapper.nextXDaysAppointments = true;
        wrapper.nextXDaysAppointmentsValue = '20';
        wrapper.dateRangeAppointments = true;
        wrapper.dateRangeAppointmentsStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeAppointmentsEnd = String.valueOf(Date.today().addDays(25));
        
        Test.startTest();
            List<Event> testEvents = SBR_3_0_AppointmentDA.getAppointmentsFiltered(wrapper);
        Test.stopTest();

        System.assertEquals(setupEvents.size(), testEvents.size(), 'Test events not retrieved');   
    }
}