@isTest
public with sharing class SBR_3_0_TaskDA_Test {
    @TestSetup
    static void makeData(){
        List<Task> testTasks = new List<Task>();
        Task testTask1 = new Task();
        testTasks.add(testTask1);
        Task testTask2 = new Task();
        testTasks.add(testTask2);

        SBR_3_0_TestDataFactory.createUsers(1, true);

        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Prospect');

    }

    @isTest
    static void getAllTasks(){
        List<Task> validTasks = [SELECT Id FROM Task];

        Test.StartTest();
            List<Task> returnedTasks = SBR_3_0_TaskDA.getTasks();
            System.assertEquals(validTasks, returnedTasks);
        Test.stopTest();
    }

    @isTest
    static void getValidTaskById(){
        Task testTask = new Task();
        insert testTask;

        Test.StartTest();
            Task returnedTask = SBR_3_0_TaskDA.getTask(testTask.Id);
            System.assertEquals(testTask.Id, returnedTask.Id);
        Test.stopTest();
    }

    @isTest
    static void getValidTaskByOwnerId(){
        User testUser = [SELECT Id FROM User LIMIT 1];
        Task testTask = new Task(ownerId = testUser.Id);
        insert testTask;

        Test.StartTest();
            List<Task> returnedTasks = SBR_3_0_TaskDA.getTasksByOwner(testUser.Id);
            System.assertEquals(testTask.Id, returnedTasks[0].Id);
        Test.stopTest();
    }

    @isTest
    static void getFilteredTasks(){

        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Task> insertTasks = new List<Task>();
        
        Task testTask = new Task(Subject = 'TaskSub', 
                                ActivityDate = Date.today().toStartOfWeek().addDays(10),
                                ownerId = testUser.Id);
        insert testTask;

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();

        wrapper.userTerritories = testUser.Id;
        wrapper.taskSearch = 'TaskSub';
        wrapper.todaysTasks = false;
        wrapper.nextWeekTasks = true;
        wrapper.nextXDaysTasks = true;
        wrapper.nextXDaysTasksValue = '20';
        wrapper.dateRangeTasks = true;
        wrapper.dateRangeTasksStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeTasksEnd = String.valueOf(Date.today().addDays(25));

        Test.StartTest();
            List<Task> returnedTasks = SBR_3_0_TaskDA.getTasksFiltered(wrapper);
            System.assertEquals(testTask.Id, returnedTasks[0].Id);
        Test.stopTest();
    }

    @isTest
    static void testAllFilters(){

        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Task> insertTasks = new List<Task>();
        Account acc = [SELECT ID FROM Account LIMIT 1];
        
        Task testTask = new Task(Subject = 'TaskSub', 
                                ActivityDate = Date.today().toStartOfWeek().addDays(1),
                                ownerId = testUser.Id,
                                WhatId = acc.Id);
        insert testTask;

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();

        wrapper.userTerritories = testUser.Id;
        wrapper.todaysTasks = true;
        wrapper.openTasks = true;
        wrapper.thisWeekTasks = true;
        wrapper.taskParentType = 'Account';

        Test.StartTest();
            List<Task> returnedTasks = SBR_3_0_TaskDA.getTasksFiltered(wrapper);
            System.assertEquals(1, returnedTasks.size());
        Test.stopTest();
    }
}