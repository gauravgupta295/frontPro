/*********************************************************************************************************************
* Apex Class: SBR_3_0_EquipOnHoldTriggerOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage handler logic for Equipment On Hold 
* - SAL-9546
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Ritesh Mohapatra                  2022-11-17               Initial version
*********************************************************************************************************************/

public class SBR_3_0_EquipOnHoldTriggerOperations 
{
    public static void updateContractOrderApplied(Map<Id, Equipment_on_Hold__c> oldEquipOnHoldMap, Map<Id, Equipment_on_Hold__c> newEquipOnHoldMap, List<Equipment_on_Hold__c> newEquipOnHoldList, Boolean isUpdateValue)
    {
        List<Equipment_on_Hold__c> equipOnHoldFinalList = new List<Equipment_on_Hold__c>();
        Map<Id,String> CompanyCodeMap = new Map<Id,String>();
        Map<Id,String> ContractAppliedMap = new Map<Id,String>();
        
        for(Equipment_on_Hold__c oEquipOnHold : newEquipOnHoldList)
        {
            if(oldEquipOnHoldMap.get(oEquipOnHold.Id).SM_PS_Status__c != newEquipOnHoldMap.get(oEquipOnHold.Id).SM_PS_Status__c && newEquipOnHoldMap.get(oEquipOnHold.Id).SM_PS_Status__c == 'Filled' && isUpdateValue)
            {
                equipOnHoldFinalList.add(oEquipOnHold);
                CompanyCodeMap.put(oEquipOnHold.id,oEquipOnHold.SM_PS_Company_Code__c);
                ContractAppliedMap.put(oEquipOnHold.id,String.ValueOf(oEquipOnHold.SM_PS_Contract_Applied__c));
            }
        }
       	
        if(CompanyCodeMap.keyset().size()>0 && ContractAppliedMap.keyset().size()>0)
        {
            Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id, Company_Code__c , Contract_Order_Number__c, RecordType.Name 
                                                      FROM Order 
                                                      WHERE RecordType.Name = 'Contract Order' 
                                                      AND Company_Code__c IN : CompanyCodeMap.values() 
                                                      AND Contract_Order_Number__c IN : ContractAppliedMap.values()]);
            for(Equipment_on_Hold__c oEquipOnHoldRecord : equipOnHoldFinalList)
            {
                for(Order odRecord : orderMap.values())
                {
                    if(odRecord.Company_Code__c == oEquipOnHoldRecord.SM_PS_Company_Code__c && odRecord.Contract_Order_Number__c == String.valueOf(oEquipOnHoldRecord.SM_PS_Contract_Applied__c))
                    {
                        oEquipOnHoldRecord.SM_PS_Contract_Order_Applied__c =  odRecord.Id;
                    }
                }
            } 
        } 
    }
}