/**
 * @description       :
 * @author            : Salesforce
 * @group             :
 * @last modified on  : 05-26-2024
 * @last modified by  : Salesforce
**/
public with sharing class SBR_3_0_SalesHelper {

    /**
     * @description Create schema location from Account's shipping address
     * @param  a The account / shipping address to use when creating the job site.
     * @return The resulting Schema.Location record (before DML is performed)
     */
    public static Schema.Location createJobLocFromShippingAddr(Account acct) {
        if(acct != null) {
            Schema.Location l = new Schema.Location();
            l.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
            l.Name = !String.isBlank(acct.ShippingStreet) ? acct.ShippingStreet : '';
            
            //Max street address length for schema.location is 80 characters.
            //Trucate street address 1 to a length of 80, and then overflow into street address 2, and truncate that to 30 as well, if necessary.
            l.Street_Address__c = acct.ShippingStreet?.left(80) ?? '';
            l.Street_Address_2__c = acct.ShippingStreet?.length() > 80 ? (acct.ShippingStreet?.substring(80))?.left(30) : '';
            
            l.City__c = !String.isBlank(acct.ShippingCity) ? acct.ShippingCity : '';
            l.Zip_Code__c = !String.isBlank(acct.ShippingPostalCode) ? acct.ShippingPostalCode : '';
            l.State__c = !String.isBlank(acct.ShippingState) ? acct.ShippingState : '';
            l.Country__c = !String.isBlank(acct.ShippingCountry) ? acct.ShippingCountry : '';
            l.Latitude_Longitude__Latitude__s = acct.ShippingLatitude;
            l.Latitude_Longitude__Longitude__s = acct.ShippingLongitude;
            return l;
        }
        return new Schema.Location();
    }

    /**
     * @description Create schema location from Account's billing address
     * @param  a The account / billing address to use when creating the job site.
     * @return The resulting Schema.Location record (before DML is performed)
     */
    public static Schema.Location createJobLocFromBillingAddr(Account acct) {
        if(acct != null) {
            Schema.Location l = new Schema.Location();
            l.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
            l.Name = !String.isBlank(acct.BillingStreet) ? acct.BillingStreet : '';
            
            //Max street address length for schema.location is 80 characters.
            //Trucate street address 1 to a length of 80, and then overflow into street address 2, and truncate that to 30 as well, if necessary.
            l.Street_Address__c = acct.BillingStreet?.left(80) ?? '';
            l.Street_Address_2__c = acct.BillingStreet?.length() > 80 ? (acct.BillingStreet?.substring(80))?.left(30) : '';
            
            l.City__c = !String.isBlank(acct.BillingCity) ? acct.BillingCity : '';
            l.Zip_Code__c = !String.isBlank(acct.BillingPostalCode) ? acct.BillingPostalCode : '';
            l.State__c = !String.isBlank(acct.BillingState) ? acct.BillingState : '';
            l.Country__c = !String.isBlank(acct.BillingCountry) ? acct.BillingCountry : '';
            l.Latitude_Longitude__Latitude__s = acct.BillingLatitude;
            l.Latitude_Longitude__Longitude__s = acct.BillingLongitude;
            return l;
        }
        return new Schema.Location();
    }

    /**
     * @description Create job site / AssociatedLocation from Account's shipping address
     * @param  a The account / shipping address to use when creating the job site.
     * @param  locId Id of the parent location when creating the new AssociatedLocation / JobSite.
     * @param  branchId Id of the aprent branch when creating the new AssociatedLocation / JobSite.
     * @return The resulting AssociatedLocation / Jobsite (before DML is performed)
     */
    public static AssociatedLocation createJoSiteFromShippingAddr(Account acct, String locId, String branchId) {
        if(acct != null) {
            AssociatedLocation js = new AssociatedLocation();
            js.ParentRecordId = acct.Id;
            js.LocationId = locId;
            js.Branch__c = branchId;
            js.Job_Number__c = acct.ShippingStreet;
            
            //Max street address length for job site / associated location is 30 characters.
            //Trucate street address 1 to a length of 30, and then overflow into street address 2, and truncate that to 30 as well, if necessary.
            js.Street_Address__c = acct.ShippingStreet?.left(30) ?? '';
            js.Street_Address_2__c = acct.ShippingStreet?.length() > 30 ? (acct.ShippingStreet?.substring(30))?.left(30) : '';
            
            js.City__c = acct.ShippingCity;
            js.State__c = acct.ShippingState;
            js.Zip_Code__c = acct.ShippingPostalCode;
            js.Country__c = acct.ShippingCountry;
            js.Latitude_Longitude__Latitude__s = acct.ShippingLatitude;
            js.Latitude_Longitude__Longitude__s = acct.ShippingLongitude;
            SBR_3_0_AssociatedLocationOperations.truncateJobNumber(js);
            System.debug('\n create js from shipping:' + js);
            return js;
        }
        return new AssociatedLocation();
    }

    /**
     * @description Create job site / AssociatedLocation from Account's billing address
     * @param  a The account / billing address to use when creating the job site.
     * @param  locId Id of the parent location when creating the new AssociatedLocation / JobSite.
     * @param  branchId Id of the aprent branch when creating the new AssociatedLocation / JobSite.
     * @return The resulting AssociatedLocation / Jobsite (before DML is performed)
     */
    public static AssociatedLocation createJoSiteFromBillingAddr(Account acct, String locId, String branchId) {
        if(acct != null) {
            AssociatedLocation js = new AssociatedLocation();
            js.ParentRecordId = acct.Id;
            js.LocationId = locId;
            js.Branch__c = branchId;
            js.Job_Number__c = acct.BillingStreet;
            
            //Max street address length for job site / associated location is 30 characters.
            //Trucate street address 1 to a length of 30, and then overflow into street address 2, and truncate that to 30 as well, if necessary.
            js.Street_Address__c = acct.BillingStreet?.left(30) ?? '';
            js.Street_Address_2__c = acct.BillingStreet?.length() > 30 ? (acct.BillingStreet?.substring(30))?.left(30) : '';
            
            js.City__c = acct.BillingCity;
            js.State__c = acct.BillingState;
            js.Zip_Code__c = acct.BillingPostalCode;
            js.Country__c = acct.BillingCountry;
            js.Latitude_Longitude__Latitude__s = acct.BillingLatitude;
            js.Latitude_Longitude__Longitude__s = acct.BillingLongitude;
            SBR_3_0_AssociatedLocationOperations.truncateJobNumber(js);
            return js;
        }
        return new AssociatedLocation();
    }

    /**
     * @description Creates a Location from SBR_3_0_WrapAddress instance.
     * @param  a The address wrapper to use when creating the job site.
     * @return The resulting Schema.Location (before DML is performed)
     */
    public static Schema.Location createJobLocFromAddress(SBR_3_0_WrapAddress a) {
        if(a != null) {
            Schema.Location l = new Schema.Location();
            l.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
            l.Name = !String.isBlank(a.street1) ? a.street1 : '';
            
            //Max street address length for schema.location is 80 characters.
            //Trucate street address 1 to a length of 80, and then overflow into street address 2, and truncate that to 30 as well, if necessary.
            l.Street_Address__c = a.street1?.left(80) ?? '';
            l.Street_Address_2__c = a.street2?.left(30) ?? '';
            
            l.City__c = !String.isBlank(a.city) ? a.city : '';
            l.Zip_Code__c = !String.isBlank(a.zip) ? a.zip : '';
            l.State__c = !String.isBlank(a.state) ? a.state : '';
            l.Country__c = !String.isBlank(a.country) ? a.country : '';
            l.Latitude_Longitude__Latitude__s = a.latitude;
            l.Latitude_Longitude__Longitude__s = a.longitude;
            return l;
        }
        return new Schema.Location();
    }

    /**
     * @description Create job site / AssociatedLocation from SBR_3_0_WrapAddress instance.
     * @param  a The address wrapper to use when creating the job site.
     * @param  acctId Id of the parent account of the new AssociatedLocation / JobSite.
     * @param  locId Id of the parent location when creating the new AssociatedLocation / JobSite.
     * @param  branchId Id of the aprent branch when creating the new AssociatedLocation / JobSite.
     * @return The resulting AssociatedLocation / Jobsite (before DML is performed)
     */
    public static AssociatedLocation createJoSiteFromAddress(SBR_3_0_WrapAddress a, String acctId, String locId, String branchId) {
        if(a != null) {
            AssociatedLocation js = new AssociatedLocation();
            js.ParentRecordId = acctId;
            js.LocationId = locId;
            js.Branch__c = branchId;
            js.Job_Number__c = a.street1;
            
            //Max street address length for job site / associated location is 30 characters.
            //Trucate street address 1 to a length of 30, and then overflow into street address 2, and truncate that to 30 as well, if necessary.
            js.Street_Address__c = a.street1?.left(30) ?? '';
            js.Street_Address_2__c = a.street2?.left(30) ?? '';
            
            js.City__c = a.city;
            js.State__c = a.state;
            js.Zip_Code__c = a.zip;
            js.Country__c = a.country;
            js.Latitude_Longitude__Latitude__s = a.latitude;
            js.Latitude_Longitude__Longitude__s = a.longitude;
            SBR_3_0_AssociatedLocationOperations.truncateJobNumber(js);
            return js;
        }
        return new AssociatedLocation();
    }

    /**
     * @description findOrCreateContact description
     * @param  c An instance of SBR_3_0_ContactWrap, to determine the contact to look for.
     * @param  a SBR_3_0_WrapAddress instance to use when determining whether the contact is found or to be created.
     * @param  acct The account record to look for or link the new contact to.
     * @return  returns existing contact if found, or a new contact record (before insert) if no existing contact is found.
     */
    public static Contact findOrCreateContact(SBR_3_0_ContactWrap c, SBR_3_0_WrapAddress a, Account acct ) {

        if(String.isNotBlank(c.firstName)){ c.firstName =c.firstName.trim(); }
        if(String.isNotBlank(c.lastName)){ c.lastName =c.lastName.trim(); }
        //ps-6215 update to us p2p getcontact method delvin riley
        List<Contact> con = SBR_3_0_ContactDA.p2pgetContact(c, acct);
        SBR_3_0_Log.setRelatedRecordId(acct.id);
        SBR_3_0_Log.logAPIDetails(JSON.serialize(c),'','Contact Wrapper');
        if(con.size() == 1) {
            Contact contactRecord = con[0];
            Boolean updateFlag = false;
            // update email and phone details if it does not match as per RM payload
            if(String.isNotBlank(c.email) && c.email != contactRecord.email){                 
                contactRecord.email = c.email.trim();
                updateFlag=true;
            }
            if(String.isNotBlank(c.phone) && c.phone != contactRecord.phone){                 
                contactRecord.phone = c.phone.trim();
                updateFlag=true;
            }
            if(updateFlag){
                update contactRecord;
            }
            SBR_3_0_Log.saveLog(); 
            return contactRecord; //return if contact found
        }

        
        //Create new contact
        Contact newContact = new Contact();
        newContact.FirstName = c.firstName;
        newContact.LastName = c.lastName;

        return newContact;
    }

    // SAL-26426 _ SAL-26424 start
    /**
     * @description wrapAccountOverrideAddress
     * @param  a The account to ..?
     * @return an instance of SBR_3_0_WrapAddress
     */
    public static SBR_3_0_WrapAddress WrapAccountOverrideAddress(Account a) {
        SBR_3_0_WrapAddress acctAddr = new SBR_3_0_WrapAddress();
        acctAddr.street1 = a.Override_Address__Street__s;
        acctAddr.street2 = '';
        acctAddr.city = a.Override_Address__City__s;
        acctAddr.state = a.Override_Address__Statecode__s;
        acctAddr.zip = a.Override_Address__PostalCode__s;
        acctAddr.country = a.Override_Address__Countrycode__s;
        acctAddr.latitude = a.Override_Address__Latitude__s;
        acctAddr.longitude = a.Override_Address__Longitude__s;
        return acctAddr;
    }
    // SAL-26426 _ SAL-26424 end

    /**
     * @description Determines if the instance account shipping address has all the necessary
     * fields "completed" or populated.
     * @param  a The account and shipping address to validate for completeness
     * @return true if the address fields are populated or completed / false otherwise.
     */
    public static Boolean isAddressComplete(Account a) {
        if(
            !String.isBlank(a.ShippingStreet) 
            && !String.isBlank(a.ShippingCity) 
            && !String.isBlank(a.ShippingState) 
            && !String.isBlank(a.ShippingPostalCode) 
            && !String.isBlank(a.ShippingCountry)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @description Determines if the instance account billing address has all the necessary
     * fields "completed" or populated.
     * @param  a The account and billing address to validate for completeness
     * @return true if the address fields are populated or completed / false otherwise.
     */
    public static Boolean isBillingAddressComplete(Account a) {
        if(
            !String.isBlank(a.BillingStreet) 
            && !String.isBlank(a.BillingCity) 
            && !String.isBlank(a.BillingState) 
            && !String.isBlank(a.BillingPostalCode) 
            && !String.isBlank(a.BillingCountry)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @description Determines if the instance of SBR_3_0_WrapAddress has all the necessary
     * fields "completed" or populated.
     * @param  a The instance of SBR_3_0_WrapAddress to validate for completeness
     * @return true if the address fields are populated or completed / false otherwise.
     */
    public static Boolean isAddressComplete(SBR_3_0_WrapAddress a) {
        if(
            !String.isBlank(a.street1) 
            && !String.isBlank(a.city) 
            && !String.isBlank(a.state) 
            && !String.isBlank(a.zip) 
            && !String.isBlank(a.country)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @description converts the account shippingaddress into an instance of SBR_3_0_WrapAddress.
     * @param  a The account, whose shipping address to convert.
     * @return an instance of SBR_3_0_WrapAddress popualted with the account's shipping address information.
     */
    public static SBR_3_0_WrapAddress WrapAccountShippingAddress(Account a) {
        SBR_3_0_WrapAddress acctAddr = new SBR_3_0_WrapAddress();
        acctAddr.street1 = a.ShippingStreet;
        acctAddr.street2 = '';
        acctAddr.city = a.ShippingCity;
        acctAddr.state = a.ShippingState;
        acctAddr.zip = a.ShippingPostalCode;
        acctAddr.country = a.ShippingCountry;
        acctAddr.latitude = a.ShippingLatitude;
        acctAddr.longitude = a.ShippingLongitude;
        return acctAddr;
    }

    /**
     * @description converts the account billingaddress into an instance of SBR_3_0_WrapAddress.
     * @param  a The account, whose billing address to convert.
     * @return an instance of SBR_3_0_WrapAddress popualted with the account's billing address information.
     */
    public static SBR_3_0_WrapAddress WrapAccountBillingAddress(Account a) {
        SBR_3_0_WrapAddress acctAddr = new SBR_3_0_WrapAddress();
        acctAddr.street1 = a.BillingStreet;
        acctAddr.street2 = '';
        acctAddr.city = a.BillingCity;
        acctAddr.state = a.BillingState;
        acctAddr.zip = a.BillingPostalCode;
        acctAddr.country = a.BillingCountry;
        acctAddr.latitude = a.BillingLatitude;
        acctAddr.longitude = a.BillingLongitude;
        return acctAddr;
    }

    /**
     * @description getSerializedProducts
     * @param  orderItems used to determine the set of serialized products.
     * @return The resulting set of serialized products.
     */
    public static Set<String> getSerializedProducts(List<OrderItem> orderItems) {
        //returns Set of ids which has isSerialized=true from Product2
        Set<String> serializedProducts = new Set<String> ();

        //get Ids
        Set<String> productIds = new Set<String>();
        for(OrderItem oi: orderItems) {
            productIds.add(oi.Product2Id);
        }

        //get Serialized info for Product Ids
        Map<String, Product2> productsMap = SBR_3_0_ProductDA.getProductsById(productIds);
        if(productsMap != null) {
            for(Product2 p : productsMap.values()) {
                if(String.IsBlank(p.Stock_class__c) && !p.Bulk_Item__c && p.Status__c == 'A') {
                    serializedProducts.add(p.Id);
                }
            }
        }
        return serializedProducts;
    }

    /**
     * @description Validates email addreses.  If valid, the email address is returend.
     * If invalid, an empty string is returned.
     * @param  email email address to validate.
     * @return  If valid, the email string is returned, if invalid, an empty string is returned.
     */
    public static String validateEmail(String email) {
        if(String.isNotBlank(email)) {            
            //Source: http://www.regular-expressions.info/email.html
            String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
            Pattern MyPattern = Pattern.compile(emailRegex);
            Matcher MyMatcher = MyPattern.matcher(email);        
            if (MyMatcher.matches()) {
                return email;
            }
        }
        return '';
    }

    /*public static Boolean isDateValueValid(Date d) {
        // The earliest valid date is 1700-01-01T00:00:00Z GMT, or just after midnight on January 1, 1700. 
        // The latest valid date is 4000-12-31T00:00:00Z GMT, or just after midnight on December 31, 4000. 
        if(d != null) {
            Date minDate = Date.valueOf('1700-01-01');
            Date maxDate = Date.valueOf('4000-12-31');
            if(d > minDate && d < maxDate) {
                return true;
            }
        }
        return false;
    }*/
    
    //P2P-5261 START
    public static Contact p2pFindOrCreateContact(SBR_3_0_ContactWrap c, SBR_3_0_WrapAddress a, Account acct ) {

        if(String.isNotBlank(c.firstName)){ c.firstName =c.firstName.trim(); }
        if(String.isNotBlank(c.lastName)){ c.lastName =c.lastName.trim(); }
        List<Contact> con = SBR_3_0_ContactDA.p2pGetContact(c, acct);
        if(con.size() > 0) {
            Contact contactRecord = con[0];
            Boolean updateFlag = false;
            // update email and phone details if it does not match as per RM payload
            if(String.isNotBlank(c.email) && c.email != contactRecord.email){                 
                contactRecord.email = c.email.trim();
                updateFlag=true;
            }
            if(String.isNotBlank(c.phone) && c.phone != contactRecord.phone){                 
                contactRecord.phone = c.phone.trim();
                updateFlag=true;
            }
            if(updateFlag){
                update contactRecord;
            }
            return contactRecord; //return if contact found
        }
        
        //Create new contact
        Contact newContact = new Contact();
        newContact.FirstName = c.firstName;
        newContact.LastName = c.lastName;
        newContact.Email = c.email;
        newContact.Phone = c.phone;
        newContact.AccountId = acct.Id;
        SBR_3_0_WrapAddress useThisAddr = new SBR_3_0_WrapAddress();
        // SAL-26426 _ SAL-26424 start
        if (isAddressComplete(WrapAccountOverrideAddress(acct))) {
            useThisAddr = WrapAccountOverrideAddress(acct);
        } else if (isAddressComplete(WrapAccountShippingAddress(acct)))
        {
            useThisAddr = WrapAccountShippingAddress(acct);
        } else {
            useThisAddr = WrapAccountBillingAddress(acct);
        }
        // SAL-26426 _ SAL-26424 end

        newContact.MailingStreet = useThisAddr.street1;
        newContact.MailingCity = useThisAddr.city;
        newContact.MailingState = useThisAddr.state;
        newContact.MailingPostalCode = useThisAddr.zip;
        newContact.MailingCountry = useThisAddr.country;
        try {
            insert newContact;
        }catch(Exception ex){
           	system.debug('Contact to return without insert : '+ newContact);
        }
        return newContact;
    }
    //P2P-5261 END
    
    public class SalesException extends Exception {}
}