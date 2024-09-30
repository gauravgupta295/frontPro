public with sharing class SBR_3_0_BatchAccountLatLongProcessor implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful{
    Set<Id> streetAddresses = new Set<Id>();
    Set<Id> overrideAddresses = new Set<Id>();
    Set<Id> billingAddresses = new Set<Id>();
    list<Account> lAccounts = new list<Account>();
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';

    public SBR_3_0_BatchAccountLatLongProcessor(Set<Id> streetAddresses, Set<Id> overrideAddresses, Set<Id> billingAddresses, list<Account> lAccounts){
        this.streetAddresses = streetAddresses;
        this.overrideAddresses = overrideAddresses;
        this.billingAddresses = billingAddresses;
        this.lAccounts = lAccounts;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        Set<Id> allAddresses = new Set<Id>(new List<Id>(streetAddresses));
        allAddresses.addAll(new List<Id>(overrideAddresses));
        String query = 'SELECT ID, BillingStreet, Billing_Street2__c, BillingCity, BillingState, BillingPostalCode, BillingCountryCode, BillingLatitude, BillingLongitude, ShippingStreet, Shipping_Street2__c, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode, Street_Address_LatLong_Status__c, Street_Address_LatLong__c, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s, Override_Address_LatLong_Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s FROM Account Where Id IN: allAddresses';
        return Database.getQueryLocator(query);
     }

     public void execute(Database.BatchableContext bc, List<sObject> scope) {
        system.debug('Processing Address Execute Method');
        system.debug(streetAddresses);
        system.debug(overrideAddresses);
        List<Account> accountsToUpdate = new List<Account>();
        for(Account act : (List<Account>)scope) {
            // Get Street Address Lat Long
            if(streetAddresses.contains(act.Id)){
                system.debug('Calling Street Address API');
                SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
                Map<String, String> result = strLatLongApi.getAddressLatLong(act.ShippingStreet == null ? '' : act.ShippingStreet, 
                                                act.Shipping_Street2__c == null ? '' : act.Shipping_Street2__c,
                                                act.ShippingCity == null ? '' : act.ShippingCity,
                                                act.ShippingState == null ? '' : act.ShippingState,
                                                act.ShippingPostalCode == null ? '' : act.ShippingPostalCode,
                                                act.ShippingCountryCode == null ? '' : act.ShippingCountryCode);
                System.debug('Street Address Result: ');
                system.debug(JSON.serialize(result));
                if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        act.Street_Address_LatLong__Latitude__s = Decimal.valueOf(result.get(LATITUDE));                       
                        act.Street_Address_LatLong__Longitude__s = Decimal.valueOf(result.get(LONGITUDE));
                        // SAL-26502
                        act.ShippingLatitude = Decimal.valueOf(result.get(LATITUDE));
                        act.ShippingLongitude = Decimal.valueOf(result.get(LONGITUDE));
                        act.Street_Address_LatLong_Status__c = 'Success';
                } else {
                    act.Street_Address_LatLong_Status__c = 'Error';
                }
            }

            // Get Override Address Lat Long
            if(overrideAddresses.contains(act.Id)){
                if (!(String.isBlank(act.Override_Address__Street__s) && String.isBlank(act.Override_Address__City__s) && String.isBlank(act.Override_Address__StateCode__s) && String.isBlank(act.Override_Address__PostalCode__s) && String.isBlank(act.Override_Address__CountryCode__s))) {

                    SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
                    Map<String, String> result = strLatLongApi.getAddressLatLong(act.Override_Address__Street__s == null ? '' : act.Override_Address__Street__s,
                    '',
                    act.Override_Address__City__s == null ? '' : act.Override_Address__City__s,
                    act.Override_Address__StateCode__s == null ? '' : act.Override_Address__StateCode__s,
                    act.Override_Address__PostalCode__s == null ? '' : act.Override_Address__PostalCode__s,
                    act.Override_Address__CountryCode__s == null ? '' : act.Override_Address__CountryCode__s);
                    if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') &&
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        act.Override_Address__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                        act.Override_Address__Longitude__s= Decimal.valueOf(result.get(LONGITUDE));
                        act.Override_Address_LatLong_Status__c = 'Success';
                    } else {
                        act.Override_Address_LatLong_Status__c = 'Error';
                    }
                } else {
                    system.debug('inside blank override address condition');
                    act.Override_Address__Latitude__s = null;
                    act.Override_Address__Longitude__s = null;
                    act.Override_Address_LatLong_Status__c = '';
                }
            }

             // Get Street Address Lat Long
             if(billingAddresses.contains(act.Id)){
                system.debug('Calling Billing Address API');
                SBR_3_0_API_FetchLatLong billingLatLongApi = new SBR_3_0_API_FetchLatLong();
                Map<String, String> result = billingLatLongApi.getAddressLatLong(act.BillingStreet == null ? '' : act.BillingStreet, 
                                                act.Billing_Street2__c == null ? '' : act.Billing_Street2__c,
                                                act.BillingCity == null ? '' : act.BillingCity,
                                                act.BillingState == null ? '' : act.BillingState,
                                                act.BillingPostalCode == null ? '' : act.BillingPostalCode,
                                                act.BillingCountryCode == null ? '' : act.BillingCountryCode);
                System.debug('Billing Address Result: ');
                system.debug(JSON.serialize(result));
                if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        act.BillingLatitude = Decimal.valueOf(result.get(LATITUDE));
                        act.BillingLongitude = Decimal.valueOf(result.get(LONGITUDE));
                }
            }
        }

        update((List<Account>)scope);
    }
    
    public void finish(Database.BatchableContext bc) {
        list<Account> lAccountsAfterUpdate = SBR_3_0_AccountDA.getAccountsFromLatLong(lAccounts);
        if(!lAccountsAfterUpdate.isEmpty()){
           if(!Test.isRunningTest()){
        	Database.executeBatch(new SBR_3_0_BatchAcctTerritoryProcessor(lAccountsAfterUpdate), 1);
            }
        }
    }
}