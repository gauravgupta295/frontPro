/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomNotificationClass
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Sending Custom Notifications to loggedin user
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Shubham Tunkikar               2023-07-04               Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_CustomNotificationClass {
    @AuraEnabled
    public static Boolean sendCustomNotification(String strWrapp)
    {
        try
        {
            System.debug('sendCustomNotification:start::'+strWrapp);
            NotificationWrapper wrapp = (NotificationWrapper)JSON.deserialize(strWrapp,NotificationWrapper.class);
            // Initialize a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            // Set the contents for the notification
            notification.setTitle(wrapp.title);
            notification.setBody(wrapp.body);
            // Set the notification type and target
            notification.setNotificationTypeId(wrapp.customNotificationType);
            notification.setTargetId(wrapp.targetId);
            Set<String> lstUserId = new Set<String>{Userinfo.getUserId()};
			notification.send(lstUserId);
            System.debug('sendCustomNotification:end::');
            return true;
        }
        catch (Exception e)
        {
            System.debug('Exception:end::'+e);
            return false;
        }
    }

    public class NotificationWrapper {
        public string title;
        public string body;
        public string customNotificationType;
        public string targetId;
    }
}