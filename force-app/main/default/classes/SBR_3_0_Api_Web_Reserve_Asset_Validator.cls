/************************************************
Class Name : SBR_3_0_Api_Web_Reserve_Asset_Validator
Developer Name : Ritesh Mohapatra (ServiceMax)
Created Date : 2022/09/22
*************************************************
Modification History :
2022/09/22 - Ritesh Mohapatra - Initial Version (SAL-7102)
/************************************************/

public with sharing class SBR_3_0_Api_Web_Reserve_Asset_Validator 
{
    public static Order getOrder(String OrderId)
    {
        List<Order> orderRecList = [SELECT Id, Reservation_Order_Number__c FROM Order WHERE Reservation_Order_Number__c = : OrderId LIMIT 1];
        
        if(orderRecList.size()>0)
        {  
            return orderRecList[0];
        }
        
        else 
        {
            return null;
    	}
    }
    public static Boolean assetFieldValidation() 
    {
         //Asset Fields Access Check
         List<String> validateAssetFieldsList = new List<String>();
         Asset oAssetRecord = new Asset();
         validateAssetFieldsList.add('ID');
         validateAssetFieldsList.add('Name');
         validateAssetFieldsList.add('SM_PS_Company_Code__c');
         validateAssetFieldsList.add('SM_PS_Cat_Class__c');
         validateAssetFieldsList.add('SM_PS_Current_Location__c');
         validateAssetFieldsList.add('SM_PS_Equipment_Number__c');
         validateAssetFieldsList.add('SM_PS_Assigned_Location__c'); 
         validateAssetFieldsList.add('SM_PS_Current_Location__c');

         return SBR_3_0_AccessUtilities.isAccesible(oAssetRecord,validateAssetFieldsList);
    }

    public static Boolean eqHoldFieldValidation() 
    {
        ///Equipment on Hold Fields Access Check
        List<String> validateEquipOnHoldFieldsList = new List<String>();
        Equipment_on_Hold__c eqHoldRecord = new Equipment_on_Hold__c();
        validateEquipOnHoldFieldsList.add('ID');
        validateEquipOnHoldFieldsList.add('SM_PS_Equipment_Number__c');
        validateEquipOnHoldFieldsList.add('SM_PS_Hold_Request_From_Date__c');
        validateEquipOnHoldFieldsList.add('SM_PS_Hold_Request_To_Date__c');
        validateEquipOnHoldFieldsList.add('SM_PS_Status__c');
        validateEquipOnHoldFieldsList.add('SM_PS_Equipment_Number__c');

         return SBR_3_0_AccessUtilities.isAccesible(eqHoldRecord,validateEquipOnHoldFieldsList);
    }

    public static Boolean eqHoldCreateValidation() 
    {
        
        //Equipment on Hold Fields Create Access Check
        List<String> createAccessChecksList = new List<String>();
        Equipment_on_Hold__c eqHoldRec = new Equipment_on_Hold__c();
        createAccessChecksList.add('Name');
        createAccessChecksList.add('SM_PS_Equipment_Number__c');
        createAccessChecksList.add('SM_PS_Hold_Request_From_Date__c');
        createAccessChecksList.add('SM_PS_Hold_Request_To_Date__c');
        createAccessChecksList.add('SM_PS_Status__c');
        createAccessChecksList.add('SM_PS_Equipment_Number__c');

         return SBR_3_0_AccessUtilities.isCreateable(eqHoldRec,createAccessChecksList);
    }

    public static Boolean dateFieldValidator(String datevalue, DateTime dateTimeVal)
    {
        Boolean validDate = true;

        try 
        {
            if(datevalue!=null)
            DateTime datet = DateTime.valueOf(JSON.deserialize('"'+datevalue+'"', DateTime.class));
            if(dateTimeVal!=null)
            DateTime dt = dateTimeVal;
            return validDate;
        } 
        catch (Exception ex) 
        {
            validDate = false;
            return validDate;
        }
    }
}