//LWC Controller Class to fetch Shipping Details for Sbr_3_0_POShippingDetailsEdit component
public with sharing class SBR_3_0_FetchShippingDetails {
    @AuraEnabled(cacheable=true)
    //Method to fetch shipping Details 
    public static Map<String, Object> getAcctShippingDetails(String accountId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            Account acc = [SELECT Id, ShippingAddress, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, RM_Account_Number_Display__c, Phone FROM Account WHERE Id = :accountId LIMIT 1];
            
            result.put('addressLine1', acc.ShippingStreet);
            result.put('shipToCity', acc.ShippingCity);
            result.put('shipToState', acc.ShippingState);
            result.put('shipToZip', acc.ShippingPostalCode);
            result.put('customerNo',acc.RM_Account_Number_Display__c);
            result.put('phoneNumber',acc.Phone);
        } catch (Exception e) {
            result.put('error', e.getMessage());
        }

        return result;
    }
    @AuraEnabled(cacheable=true)
    //Method to fetch branch shipping Details 
    public static Map<String, Object> getBranchShippingDetails(String branchId) {
        Map<String, Object> result1 = new Map<String, Object>();

        try {
            Schema.Location loc = [SELECT Id, City__c, State__c, Phone__c, Street_Address__c, Zip_Code__c, Branch_Location_Number__c FROM Location WHERE Id = :branchId LIMIT 1];
            
            result1.put('addressLine1', loc.Street_Address__c);
            result1.put('shipToCity', loc.City__c);
            result1.put('shipToState', loc.State__c);
            result1.put('shipToZip', loc.Zip_Code__c);
            result1.put('phoneNumber', loc.Phone__c);
            result1.put('branchNumber', loc.Branch_Location_Number__c);
        } catch (Exception e) {
            result1.put('error', e.getMessage());
        }

        return result1;
    }


    @AuraEnabled(cacheable=true)
    //To fetch list of Contact from Selected Vendor
    public static List<Contact> getVendorContacts(String accountId) {
       return
            [
                SELECT Id, 
                        AccountId, 
                        Name
                FROM Contact 
                WHERE AccountId = :accountId 
                LIMIT 49999
            ];
    }

}