/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomNotificationClass_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To test class SBR_3_0_CustomNotificationClass
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Shubham Tunkikar               2023-07-04               Initial version
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_CustomNotificationClass_Test {

    @isTest
    public static void sendCustomNotificationTest(){
        Test.startTest();
        try
        {
            CustomNotificationType cn = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'PDF_Downloaded'];
            SBR_3_0_CustomNotificationClass.NotificationWrapper nw = new SBR_3_0_CustomNotificationClass.NotificationWrapper();
        	nw.body = 'PDF file for the WO has been downloaded.';
            nw.customNotificationType = cn.Id;
            nw.targetId = '';
            nw.title = 'PDF Downloaded successfully.';

			SBR_3_0_CustomNotificationClass.sendCustomNotification(JSON.serialize(nw));
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void sendCustomNotificationErrorTest()
    {
        Test.startTest();
        try
        {
            SBR_3_0_CustomNotificationClass.NotificationWrapper nw = new SBR_3_0_CustomNotificationClass.NotificationWrapper();
        	nw.body = 'PDF file for the WO has been downloaded.';
            nw.targetId = '';
            nw.title = 'PDF Downloaded successfully.';
			SBR_3_0_CustomNotificationClass.sendCustomNotification(JSON.serialize(nw));
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
        Test.stopTest();
    }
}