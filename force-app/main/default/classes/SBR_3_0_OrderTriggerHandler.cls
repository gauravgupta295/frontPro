/*********************************************************************************************************************
* Apex Class:   
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Class to intercept Order Creation 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Joelle Ramiandrisoa               2022-11-17            Initial version - Populate Pricebook2Id on Order creation
    2.0         Kaylee Gabus                      2022-12-05             Added UpdateEndDate on Insert and Update
*********************************************************************************************************************/
public with sharing class SBR_3_0_OrderTriggerHandler extends SBR_3_0_TriggerHandler {

    /*public override void afterInsert() {
        SBR_3_0_OrderOperations.populatePricebook(Trigger.New);
    }*/
    public static Boolean beforeUpdateRecursiveCheck = false;

    public override void beforeInsert() {
        List<Order> newOrders = (List<Order>) Trigger.new;
        
        //This has to stick in a before insert trigger, because the Name field is required,
        //and the validation happens prior to any flows running.
        for(Order o : newOrders){
            if(String.isBlank(o.Name)){
                o.Name = o.Job_Name__c;
            }
        }
        
        /*Id reservationTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        List<Order> updateEndDateList = new List<Order>();
        Set<Id> accIds = new Set<Id>(); // SF-5397

          for (Order o : newOrders) {
           
             //11173, SADAPUR
            //Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
            //if (o.RecordTypeId == reservationTypeId && !o.Submitted_to_Wynne__c && o.Duration__c != null && o.Start_Date__c != null) {
            //    updateEndDateList.add(o);
            //}
            // SF-5397
            accIds.add(o.AccountId); 
        }*/
        

        //Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
        //SBR_3_0_OrderOperations.updateEndDate(updateEndDateList);
        //SBR_3_0_OrderOperations.populatePricebook(Trigger.New); 
         //SBR_3_0_OrderOperations.updateCreatedByUserBranch(Trigger.New); 
        
        //Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
        //SBR_3_0_OrderOperations.populateAccountRecordType(Trigger.New, accIds); // SF-5397
        
        //Moved to three flows...1) SBR_3_0_Update Order Default values, 2) SBR 3 0 Order default values after insert,
        //and 3) SBR 3.0 - Sum Total Invoiced Amount on Order
        //if(!Test.isRunningTest()){
        //    System.enqueueJob(new SBR_3_0_Queueable_OrderInvoiceSync(newOrders));
        //}

    }

    public override void beforeUpdate() {
        if (!SBR_3_0_OrderTriggerHandler.beforeUpdateRecursiveCheck) {
            
        
        Map<Id, Order> newMap = (Map<Id, Order>) Trigger.newMap;
        Map<Id, Order> oldMap = (Map<Id, Order>) Trigger.oldMap;
        List<Order> orders = (List<Order>)Trigger.new;
        Id reservationTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        List<Order> updateEndDateList = new List<Order>();
        List<Order> updatePickUpOverrideList = new List<Order>();
        
        //Set<Id> accIds = new Set<Id>(); // SF-5397  
        for (Order o : newMap.values()) {
            if (o.RecordTypeId == reservationTypeId){
                updatePickUpOverrideList.add(o);
            }
            //Order oOldOrder = oldMap.get(o.id);
            // if(oProfile.id != userinfo.getProfileId() && o.RecordTypeId != oOldOrder.RecordTypeId){
            // 	o.addError('Record type cannot be changed. Contact your System Admin');     
            //     break;
            // }
             
            
            //Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
            if (o.RecordTypeId == reservationTypeId && !o.Submitted_to_Wynne__c) {
                updateEndDateList.add(o);
            }
            // SF-5397
            //if(String.isBlank(o.Account_Record_Type_Txt__c)) {
            //    accIds.add(o.AccountId); 
            //}
        }

        //Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
        //SBR_3_0_OrderOperations.updateEndDate(updateEndDateList);
        
        if (!updatePickUpOverrideList.isEmpty()){
            SBR_3_0_OrderOperations.updatePickUpOverride(updateEndDateList); //SAL-19717
        }
        
        SBR_3_0_OrderOperations.handleDeliveryOptionChange(oldMap, newMap);
        SBR_3_0_OrderOperations.validateRepFieldsContractOrder(orders, oldMap); // SAL-26936
            
        /*Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
        SBR_3_0_OrderOperations.populateAccountRecordType(Trigger.New, accIds); // SF-5397
            try {
               SBR_3_0_OrderOperations.updateOrderStartDate(orders, newMap, oldMap);//SF-6267
            } catch (Exception e) {
                SBR_3_0_Log.logException(e);
                throw new SBR_3_0_OrderTriggerHandlerException(e.getMessage());
            } finally {
                SBR_3_0_Log.saveLog();
            }
        */    
            
        SBR_3_0_OrderTriggerHandler.beforeUpdateRecursiveCheck = true;
		}
    }
    
    /**
     * @description - Exception class to handle custom trigger errors
     */
    /*public class SBR_3_0_OrderTriggerHandlerException extends Exception {
        
    }*/
}