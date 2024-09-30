public with sharing class SBR_3_0_EquipmentOnHoldDA {        

    public static List<Equipment_on_Hold__c> fetchEquipmentOnHold(String catClass, String branch ){

        List<Equipment_on_hold__c> equipment = [SELECT Id,SM_PS_Asset_Id__c,SM_PS_Line_Number__c,SM_PS_Line_Number__r.OrderId,SM_PS_Line_Number__r.Order.OrderNumber, SM_PS_Line_Number__r.Order.Contract_Order_Number__c,
      SM_PS_Line_Number__r.Order.Account.Name, SM_PS_Line_Number__r.Order.Start_Date__c,SM_PS_Line_Number__r.Order.Estimated_Return_Date__c, SM_PS_Line_Number__r.quantity__c,
       SM_PS_Hold_for_Customer_Name__c, SM_PS_Hold_for_Customer_Number__c, SM_PS_Hold_Request_To_Date__c,SM_PS_Hold_Request_From_Date__c,SM_PS_Equipment_Number__c,SM_PS_Location__c,SM_PS_Status__c	
        from Equipment_on_hold__c where SM_PS_Equipment_Number__r.SM_PS_Cat_Class__c = :catClass and SM_PS_Hold_Request_Location__r.Branch_Location_Number__c = :branch and SM_PS_Status__c = 'Active'];
                      
        return equipment;
    }

    public static List<Equipment_on_Hold__c> fetchEquipmentFromAssets(Set<Id> setAssetIds){
        return [SELECT ID, SM_PS_Equipment_Number__c, SM_PS_Hold_Request_From_Date__c, SM_PS_Hold_Request_To_Date__c, SM_PS_Status__c, 
                    SM_PS_Last_Maintenance_Date__c, SM_PS_Equipment_Number__r.SM_PS_Cat_Class__c, SM_PS_Equipment_Number__r.Id
                    FROM Equipment_on_Hold__c
                    WHERE SM_PS_Equipment_Number__c =: setAssetIds
                    ORDER BY SM_PS_Last_Maintenance_Date__c ASC];
    }
}