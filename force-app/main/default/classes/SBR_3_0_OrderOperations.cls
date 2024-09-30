/*********************************************************************************************************************
* Apex Class: SBR_3_0_OrderOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage any insert/updates that needs to be done on Order as part of trigger
--------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Joelle Ramiandrisoa    2022-11-16          Initial version
    2.0         Kaylee Gabus           2022-12-05          Added UpdateEndDate
    3.0         Shreenivas Adapur      2022-02-20          Updated to get Strandard PriceBook Id

*********************************************************************************************************************/
public with sharing class SBR_3_0_OrderOperations {

    /**
     * @description - Constructor class
     */
    public SBR_3_0_OrderOperations() {

    }

    /**
     * @description  - Method to update Pricebook2Id on Order creation
     * @param orders - List of orders that are updated
     *
     */
    //Moved to SBR 3 0 Update Order Default Values and SBR 3 0 Update Order Default Values Update Flow.
    /*public static void populatePricebook(List<Order> orders) {
        Pricebook2 stdPriceBookRec = SBR_3_0_UtilityDA.getStandardPriceBookRec();

        for (Order o : (List<Order>) Trigger.new) {
            if(o.Pricebook2Id == null){
                o.Pricebook2Id = stdPriceBookRec?.Id;
            }
        }
    }*/

    /**
     * @description - Method to update end date on Order creation
     * @param orders - List of orders that are updated
     */
    /* Replaced via default flow
    public static void updateEndDate(List<Order> orders) {
        for (Order o : orders) {            
            // new logic - SAL25334
            if(o.Start_Date__c != null) {
                switch on o.Duration__c {
                    when 'Day' {
                        o.Return_Date__c = o.Start_Date__c.addDays(1);
                    }
                    when 'Week' {
                        o.Return_Date__c = o.Start_Date__c.addDays(7);
                    }
                    when '4 Week' {
                        o.Return_Date__c = o.Start_Date__c.addDays(28);
                    }
                }

                if(o.Total_Est_Duration_weeks__c != null) {
                    Integer totalEstDurationWeeks = Integer.valueOf(o.Total_Est_Duration_weeks__c);
                    o.Estimated_Return_Date__c = o.Start_Date__c.addDays( totalEstDurationWeeks * 7);
                }else{
                    o.Estimated_Return_Date__c =   o.Return_Date__c;
                }
            }
        }
    }*/
    
    //SAL-19717
    /**
     * @description  - Method to update Pickup Override on Order creation
     * @param orders - List of orders that are updated
     */
    public static void updatePickUpOverride(List<Order> orders) {
        List<String> anaylisRegions = new List<String>{'921','922','933','934','945'};
        List<String> orderInitiatingChannel = new List<String>{'SF','Salesforce'};

        for (Order orderRec : orders) {
            if(anaylisRegions.contains(orderRec?.Analysis_Region_Key__c) && orderRec?.Deliverymethod__c == 'Delivery' 
                && !orderRec?.Using_3rd_Party__c && orderInitiatingChannel.contains(orderRec?.Order_Initiating_Channel__c) && orderRec?.Delivery_Charges_Override__c != orderRec?.Pickup_Charges_Override__c){
                    orderRec.Pickup_Charges_Override__c = orderRec.Delivery_Charges_Override__c;
            }
        }
    }

    //Added code for SF_6005 for Delivery Override Changes too
    /**
     * @description - Method to handle delivery Option change
     * @param oldMap - Map of old values for Order
     * @param newMap - Map of new values for Order
     */
    public static void handleDeliveryOptionChange(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        for(Order ord: newMap.values()){
            Order oldOrder = oldMap.get(ord.Id);
            
            if(oldOrder.Deliverymethod__c <> ord.Deliverymethod__c ||
                (oldOrder.Pickup_Charges__c <> null && oldOrder.Pickup_Charges__c <> ord.Pickup_Charges__c) ||          // SF-5925
                (oldOrder.Delivery_Charges__c <> null && oldOrder.Delivery_Charges__c <> ord.Delivery_Charges__c) ||    // SF-5925
                oldOrder.Delivery_Charges_Override__c <> ord.Delivery_Charges_Override__c ||
                oldOrder.Using_3rd_Party__c <> ord.Using_3rd_Party__c
            ){
                ord.IsDeliveryOptionsChanged__c = true;
            }

            // SF_6005   When Delivery override = true, Updating Suggested delivery Charges per truck same as delivery charge 
            // SF_6005   When Delivery override = true, Updating Suggested pickup Charges per truck same as pickup charge 
            if( ord.Deliverymethod__c  == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY &&  ord.Delivery_Charges_Override__c == true){
                if(ord.Delivery_Charges__c <> null && ord.Delivery_Charges__c <> oldOrder.Delivery_Charges__c){
                    ord.Delivery_Charge__c = ord.Delivery_Charges__c;
                }
                if(ord.Pickup_Charges__c <> null && ord.Pickup_Charges__c <> oldOrder.Pickup_Charges__c){
                    ord.Pickup_Charge__c = ord.Pickup_Charges__c;
                }
            }
        }
    }

    /**
     * @description       - Validate Order for 'Contract' RecordType
     * @param newOrders   - List of new orders
     * @param oldOrderMap - Map of old orders
     */
    public static void validateRepFieldsContractOrder(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        //SAL - 26936 - Project and Opportunity should be editable on Orders for sales reps assigned
        List<String> fields = new List<String>{'Contract_Order_Number__c','Original_Lead_Created_By__c','Secondary_Rep__c','Status','Total_Est_Duration_weeks__c','EffectiveDate','AccountId'};
        
        boolean hasBusinessAdminPermission = FeatureManagement.checkPermission('Business_Admin');

        //List<PermissionSetAssignment> businessAdmins = [SELECT Id, AssigneeId 
        //                                                FROM PermissionSetAssignment 
        //                                                WHERE PermissionSet.Name = 'Business_Admin1'
        //                                                AND AssigneeId = :UserInfo.getUserId() WITH SECURITY_ENFORCED ];
        //Id sysProfileId = [SELECT Id FROM Profile WHERE Name ='System Administrator'][0].Id;

        for(Order ord : newOrders){
            if((ord.Record_Type_Name__c == oldOrderMap.get(ord.Id).Record_Type_Name__c) && (ord.Record_Type_Name__c == 'Contract Order' || ord.Record_Type_Name__c == 'Locked Reservation Order' || ord.Record_Type_Name__c == 'Locked Contract Order') && !hasBusinessAdminPermission){
                for(String fieldname : fields ){
                    if(ord.get(fieldname) != oldOrderMap.get(ord.Id).get(fieldname)){
                        ord.addError('Only Project and Opportunity can be edited');
                    }
                }
            }
        }
    }

    //SF-5397: Updating Order.Account_Record_Type_Txt__c field which is used in sharing rules
    /**
     * @description     - Method to update Order.Account_Record_Type_Txt__c field
     * @param newOrders - List of new orders
     * @param accIds    - Set of Account Ids
     */
    /* - James: This was moved to the SBR 3.0 Update Order Default Values and SBR 3.0 Update Order Default Values (Update) Flows
    public static void populateAccountRecordType(List<Order> newOrders, Set<Id> accIds) {
        if(!accIds.isEmpty()) {
            Map<Id,Account> mapAccount = new Map<Id,Account>([Select RecordType.Name from Account Where Id in: accIds]);
            for(Order order : newOrders) {
                if(String.isBlank(order.Account_Record_Type_Txt__c)){
                    order.Account_Record_Type_Txt__c = mapAccount.get(order.AccountId).RecordType.Name;
                }
            }
        }
    }*/
    
    //SF-6267
    /**
     * @description         - Update Order Start Date with Order Activation Date
     * @param updatedOrders - Orders to be updated
     * @param newOrderMap   - Map of new orders
     * @param oldOrderMap   - Map of old orders 
     */
    //Moved to SBR 3 0 Update Order Default Values (Update) Flow
    /*public static void updateOrderStartDate(List<Order> updatedOrders, Map<Id, Order> newOrderMap, Map<Id, Order> oldOrderMap) {
        for (Order order : updatedOrders) {
            if ( order.Start_Date__c !=null && 
                (newOrderMap.get(order.Id).Start_Date__c != oldOrderMap.get(order.Id).Start_Date__c)) {
                order.EffectiveDate = order.Start_Date__c.date();
            }
        }
    }*/
    
    /**
     * @description  - Method to update CreatedBy User by Branch on Order
     * @param orders - List of new orders
     */
    /*
    public static void updateCreatedByUserBranch(List<Order> orders)
    {
        List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        if(userLocation !=null && userLocation.size() > 0)
        {
            for(Order currentOrder : orders)
            {
                if(currentOrder.Created_By_Users_Branch__c == null){

                    currentOrder.Created_By_Users_Branch__c = userLocation[0].Id;

                }
                
            }
        }
        
    }*/
}