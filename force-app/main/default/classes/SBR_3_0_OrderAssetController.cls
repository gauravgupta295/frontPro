public without sharing class SBR_3_0_OrderAssetController {

    @AuraEnabled(cacheable=false)
    public static String SetAssetstatus(String orderItemRecords, String pickupComment, Datetime pickupDate, Id loggedInUser ){
        System.debug('MapData Apex');
        System.debug(orderItemRecords);
        List<orderItemRecord> o = (List<orderItemRecord>) JSON.deserialize(orderItemRecords, List<orderItemRecord>.class);
        for (orderItemRecord one : o){
            OrderItem a =[Select SBQQ__Asset__r.Id, Global_Line_Number__c, Order_Item_Detail__c from OrderItem where Id=: one.Id limit 1];
            //Asset asset = [Select Id, Status, Name,SBQQ__OrderProduct__c from Asset where Id=: a.SBQQ__Asset__r.Id limit 1];
            // asset.status = 'SCHEDULED FOR PICKUP';
            // update asset;

            //OrderItem OI = [Select Id, Order_Item_Detail__c from OrderItem where Id=:one.Id];
            User loggedInUserDtls = SBR_3_0_UserDA.getUserById(loggedInUser); //13808

            if(a.Order_Item_Detail__c != null){                   
                Order_Item_Detail__c OID = [Select Id, Pickup_Ticket__c from Order_Item_Detail__c where Id=:a.Order_Item_Detail__c limit 1];
                OID.Pickup_Ticket__c = one.ticketNumber;
                OID.Order_Item_Comments__c = pickupComment;
                OID.Pickup_Requested_Date__c = (Datetime) pickupDate;
                //OID.Pickup_Ticket_Requested_By__c = loggedInUser;

                OID.Pickup_Ticket_Request_By__c = loggedInUserDtls?.Name; //13808

                if(a.Global_Line_Number__c != null){
                    OID.OMS_Order_ID__c = OID.Pickup_Ticket__c+'-'+a.Global_Line_Number__c;
                }

                update OID;
            }

            System.debug('ID '+one.Id);
            System.debug('ticketNumber '+one.ticketNumber);
        }

        return 'ABC';

        //Customer c = (Customer) JSON.deserialize(customer, Customer.class);
        //System.debug(List<orderItemRecord>);
        // for (String rec :o){ Select Id, Pickup_Ticket__c from Order_Item_Detail__c where Line_Item__r.Id=
        //     System.debug('rec'+rec);
        // } Select Id, Status from Asset where SBQQ__OrderProduct__c='8023C0000024uVmQAI'  Select Id, Pickup_Ticket__c,line_item__c from Order_Item_Detail__c where Id='a693C000000YMRjQAO'
    }

    @AuraEnabled(cacheable=false)
    public static String CreateOrderItemDetail(String orderProductId, String pickupComment, Date pickupDate, Id loggedInUser, String assetNumber, Boolean isBulkItem){

        User loggedInUserDtls = SBR_3_0_UserDA.getUserById(loggedInUser); //13808

        Order_Item_Detail__c OID = new Order_Item_Detail__c();
        OID.Name = orderProductId+'_OID';
        OID.Order_Item_Comments__c = pickupComment;
        OID.Pickup_Requested_Date__c = (Datetime) pickupDate;
        //OID.Pickup_Ticket_Requested_By__c = loggedInUser;
        OID.Pickup_Ticket_Request_By__c = loggedInUserDtls?.Name; //13808
        OID.Line_Item__c=orderProductId;
        if (isBulkItem == false){
            OID.Asset_Number__c=assetNumber;
        }
        
        insert OID;

        OrderItem OI =[Select Id, Order_Item_Detail__c from OrderItem where Id=:orderProductId limit 1];
        OI.Order_Item_Detail__c = OID.Id;
        update OI;


        return OID.Id;
    }

    @AuraEnabled(Cacheable = false)
    public static List<Order_Item_Detail__c> getOrderDetailItems(String orderLineItemId) {
        List<Order_Item_Detail__c> orderDetailItems = new List<Order_Item_Detail__c>();
        try {
            orderDetailItems = SBR_3_0_OrderDA.getScheduledPickUpTktDtlsByOrderLineItemId(orderLineItemId);
            String dateFormat = 'MM/dd/yyyy hh:mm:ss a';
            User loggedInUserDtls = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
            String timeZone = loggedInUserDtls.TimeZoneSidKey;
            if(String.isBlank(timeZone)){
                timeZone = 'America/Los_Angeles'; // US Pacific time zone, use New_York for Eastern time zone
            }
            
            if(orderDetailItems != null && !orderDetailItems.isEmpty()){
                for( Order_Item_Detail__c orderDetailItem : orderDetailItems){
                    if(orderDetailItem.Pickup_Requested_Date__c != null ){
                        orderDetailItem.Pickup_Requested_Date__c.format(dateFormat,timeZone);
                    }
                }
            }
            return orderDetailItems;
        } catch (Exception e) {
            System.debug('CustomDataTableCmpController.getOrderDetailItems error: ' + e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class orderItemRecord {
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public String ticketNumber {get; set;}
    }

}

// Select SBQQ__Asset__r.Status, SBQQ__Asset__r.Name, SBQQ__Asset__r.Id, Order_Item_Detail__c from OrderItem where Id='8023C0000024uVmQAI'

// Select Id, Name,Line_Item__r.Id from Order_Item_Detail__c where Name='Harry OID'



// Select Id, Name,Line_Item__r.OrderId from Order_Item_Detail__c where Pickup_Ticket__c='pickup-ticket-0'


// Select Id, Name from Order_Item_Detail__c where Name='Test OID Harry'

// [Select Id, Order_Item_Detail__c from OrderItem where Id='8023C0000024xpRQAQ']
// Select Id, SBQQ__OrderProduct__c, Status from Asset where SBQQ__OrderProducts__r.Id='02i3C000001k7Y5QAI'