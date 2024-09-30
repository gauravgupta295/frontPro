/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SBR_3_0_CartOperations {
    
	//SF-5347
    public static void setCartStatusToNull(List<Cart__c> newCartRecords){
        if(newCartRecords!=null){
            Id cartOGRecordTypeId = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Oil & Gas').getRecordTypeId();
            for (Cart__c cartRec : newCartRecords){
                if(cartRec.isClone() && cartRec.RecordtypeId == cartOGRecordTypeId){
                    cartRec.Status__c = '';   
                }
            }
        }
    }

    public static void setDateInUserTimeZone(List<Cart__c> newCartRecords){
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        Organization companyInfo = [SELECT Id, TimeZoneSidKey FROM Organization];

        String dateFormat = 'MM/dd/yyyy hh:mm:ss a';
        String timeZone = companyInfo.TimeZoneSidKey;
        
        if (newCartRecords!=null){
            for (Cart__c cartRec : newCartRecords){
                
                if(timeZone != userTimeZone){
                    cartRec.Rental_Start_Date__c.format(dateFormat,userTimeZone);
                    cartRec.Rental_End_Date__c.format(dateFormat,userTimeZone);  
                }
                if(cartRec.Rental_Start_Date__c != null){
                    cartRec.Start_Date__c= getDateOfDatetime(cartRec.Rental_Start_Date__c);
                }

                if(cartRec.Rental_End_Date__c != null){
                    cartRec.Return_Date__c = getDateOfDatetime(cartRec.Rental_End_Date__c);
                }
                
                if(cartRec.Rental_Start_Time__c != null){// SAL-23497 Fix
                    cartRec.Rental_Start_Date_Time_UTC__c= DateTime.newInstance(cartRec.Start_Date__c,cartRec.Rental_Start_Date__c.time());
                } else{
                    Time myTime = Time.newInstance(0, 0, 0, 0);
                    cartRec.Rental_Start_Date_Time_UTC__c= DateTime.newInstance(cartRec.Start_Date__c, myTime );
                } 
            }
        }
    }

    public static void populateUTCstartTime(List<Cart__c> newCartRecords, Map<Id,Cart__c> oldMap){ //SF-6143
        for(Cart__c cartRec : newCartRecords){
            if((oldMap == null || cartRec.Rental_Start_Date__c != oldMap.get(cartRec.Id).Rental_Start_Date__c || 
                cartRec.Rental_Start_Time__c != oldMap.get(cartRec.Id).Rental_Start_Time__c ) &&
                (cartRec.Rental_Start_Date__c != null && cartRec.Rental_Start_Time__c != null)){
                cartRec.Rental_Start_Date_Time_UTC__c = DateTime.newInstance(Date.valueOf(cartRec.Rental_Start_Date__c),cartRec.Rental_Start_Time__c);
            }
        }
    }

    public static void populateStartTime(List<Cart__c> newCartRecords){ //SF-6260
        for(Cart__c cartRec : newCartRecords){
            if(cartRec.Rental_Period__c != 'Custom' && cartRec.Rental_Start_Time__c == null && cartRec.Rental_End_Time__c == null){
                cartRec.Rental_Start_Time__c = cartRec.Rental_Start_Date__c.time();
                cartRec.Rental_End_Time__c = cartRec.Rental_Start_Date__c.time();
            }
            else if(cartRec.Rental_Period__c == 'Custom' && cartRec.Rental_Start_Time__c == null && cartRec.Rental_End_Time__c == null ){
                cartRec.Rental_Start_Time__c = cartRec.Rental_Start_Date__c.time();
                cartRec.Rental_End_Time__c = cartRec.Rental_End_Date__c.time();
            }
        }
    }

    private static Date getDateOfDatetime(Datetime dateTimeInput) {
        if(dateTimeInput != null) {
            String isoStr = dateTimeInput.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            String dateStr = isoStr.substringBefore('T');
            return Date.valueOf(dateStr);
        }
        return null;
    }

    /*
    public static void setStartAndReturnTime(List<Cart__c> newCartRecords){

        List<Cart__c> cartsToUpdate = new List<Cart__c>(); 
        for(Cart__c cart : newCartRecords){
            //if(cart.SBR_Is_Created_by_Flow__c == true){
                Cart__c tempCart  = new Cart__c (Id = cart.Id, 
                Rental_Start_Time__c =  cart.Start_Time__c,
                Rental_End_Time__c = cart.Return_Time__c);
                cartsToUpdate.add(tempCart);
            //}
        }
        if(!cartsToUpdate.isEmpty()){
            update cartsToUpdate;
        }
    }
    */
    
    //SAL-26857
    public static void SetRentalEndDateForOG(List<Cart__c> newCartRecords){
        Id cartOGRecordTypeId = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Oil & Gas').getRecordTypeId();
        for (Cart__c cartRec : newCartRecords){
            if (cartRec.RecordTypeId == cartOGRecordTypeId){
                switch on cartRec.Rental_Period__c {
                    when '1 Day'{
                        cartrec.Rental_End_Date__c = cartrec.Rental_Start_Date__c.adddays(1);
                    }
                    when '7 Days'{
                        cartrec.Rental_End_Date__c = cartrec.Rental_Start_Date__c.adddays(7);
                    }
                    when '28 Days'{
                        cartrec.Rental_End_Date__c = cartrec.Rental_Start_Date__c.adddays(28);
                    }
                    
                } 
            }
        }
    }
}