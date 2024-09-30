//------------------------------------------------------------------------------------------------------------------------//
// Class: TestAPI_ContractFromReservation
// Purpose: Provides an API for quickly creating test data for Tosca regression testing.
// Author: Publicis Sapient
// Related: TestAPI_ContractFromReservation_Test.cls	
// To Use: 
//		curl -X POST -H "Authorization: Bearer sessionId" -H "Content-Type: application/json" -d '{"reservationId":"8018L000000KriSQAS","numberOfClones":10}' 
//		"https://sunbeltrentals--fs4.sandbox.my.salesforce.com/services/apexrest/TestContractFromReservation/"
//------------------------------------------------------------------------------------------------------------------------//
@RestResource(urlMapping='/TestContractFromReservation/*')
global with sharing class TestAPI_ContractFromReservation 
{
    private static final String NEW_RECORD_TYPE_LABEL = 'Reservation Order';
    private static final Map<String,Schema.RecordTypeInfo> recordTypeInfosById = Schema.SObjectType.Order.getRecordTypeInfosByName();
    private static final Id CONTRACT_RECORDTYPE_ID = recordTypeInfosById.get(NEW_RECORD_TYPE_LABEL).getRecordTypeId();
    private static Set<String> orderFields = new Set<String>{'Id'};
	private static Set<String> orderItemFields = new Set<String>{'Id','PricebookEntryId'};
    private static Schema.SObjectType sObjType = ((SObject)(Type.forName('Schema.Order')?.newInstance()))?.getSObjectType();
	private static Schema.DescribeSObjectResult objDescribe = sObjType?.getDescribe();
	private static Map<String,Schema.SObjectField> orderFieldMap = objDescribe?.fields.getMap();

    @HttpPost global static List<Id> doPostCall(String reservationId, Integer numberOfClones) 
    {
        List<Id> newContractIds = new List<Id>();
        List<Order> clonedOrders = new List<Order>();
        Map<Integer,List<OrderItem>> clonedOrderItemMap = new Map<Integer,List<OrderItem>>();
        List<OrderItem> clonedOrderItems = new List<OrderItem>();
        System.debug(LoggingLevel.INFO,'Attempting to clone Order: ' + reservationId);

        // Collect the editable fields on Order for the query - we'll clone these.
		if (orderFieldMap != null)
    	{  
      		for (String fieldName : orderFieldMap.keySet())
      		{
       			Schema.DescribeFieldResult fieldDetails = orderFieldMap.get(fieldName).getDescribe();
        		if (fieldDetails.isUpdateable())
          			{orderFields.add(fieldName);}
      		}
    	} 
        System.debug(LoggingLevel.INFO,'Updateable Order fields (to be cloned): ' + String.valueOf(orderFields));
        
        // Collect the editable fields on OrderItem for the query - we'll clone these.
        Schema.SObjectType orderItemObjType = ((SObject)(Type.forName('Schema.OrderItem')?.newInstance()))?.getSObjectType();
        Schema.DescribeSObjectResult orderItemObjDescribe =  orderItemObjType?.getDescribe();
        Map<String,Schema.SObjectField> orderItemFieldMap = orderItemObjDescribe?.fields.getMap();
        if (orderItemFieldMap != null)
        {
          for (String fieldName : orderItemFieldMap.keySet())
          {
            Schema.DescribeFieldResult fieldDetails = orderItemFieldMap.get(fieldName).getDescribe();
            if (fieldDetails.isUpdateable())
              {orderItemFields.add(fieldName);}
          }
        }
        System.debug(LoggingLevel.INFO,'Updateable OrderItem fields (to be cloned): ' + String.valueOf(orderItemFields));
        
        // Build the query strings
        String orderQueryString = 'SELECT ' + String.join(orderFields,',') + ' FROM Order WHERE Id = :reservationId LIMIT 1 ';
        System.debug(LoggingLevel.INFO,'Order Query String: ' + orderQueryString);
        String orderItemQueryString = 'SELECT ' + String.join(orderItemFields,',') + ' FROM OrderItem WHERE OrderId = :reservationId ';
        System.debug(LoggingLevel.INFO,'Order Item Query String: ' + orderItemQueryString);
        
        // Query and clone the records
        Savepoint sp = Database.setSavepoint();
        try
        {
          Order reservationRecord = Database.query(orderQueryString);
          List<OrderItem> reservationLineItems = Database.query(orderItemQueryString);
          System.debug(LoggingLevel.INFO,'# Reservation Line Items Found: ' + reservationLineItems.size());
          
          Integer cloneNum = 1;
          while (cloneNum <= numberOfClones)
          {
              // Clone the Order
              System.debug('Cloning the Order... ');
              Order clonedOrder = reservationRecord.clone();
              clonedOrder.RecordTypeId = CONTRACT_RECORDTYPE_ID;
              clonedOrder.Account_Record_Type_Txt__c = NEW_RECORD_TYPE_LABEL;
              //clonedOrder.AccountId = reservationRecord.AccountId;
              clonedOrder.Name = (reservationRecord.Name + ' CONTRACT ' + String.valueOf(Math.random())).left(80);
              clonedOrder.Status = 'Draft';
              clonedOrder.Duration__c = 'Custom';
              clonedOrder.External_Order_ID__c = reservationRecord.External_Order_ID__c + '.' + cloneNum;
              clonedOrders.add(clonedOrder); // Put in a list for insert
              
              // Clone the Line Items
              System.debug(LoggingLevel.INFO,'Cloning the OrderItems... ');  
              clonedOrderItemMap.put(cloneNum-1,new List<OrderItem>());// Make the map key match the list index
              for (OrderItem oi : reservationLineItems)
              {
                OrderItem clonedItem = oi.clone();
                Integer globalLineNum = oi.Global_Line_Number__c == null ? Math.round((Math.random() * (900000) + 100000)) : Integer.valueOf(oi.Global_Line_Number__c);
                clonedItem.Line_Composite_Key__c = clonedOrder.External_Order_ID__c + '-' + globalLineNum;  
                clonedOrderItemMap.get(cloneNum-1).add(clonedItem);// Make the map key match the list index
              }
              cloneNum++;
          }
          // Insert the Orders 
          insert clonedOrders;
          System.debug(LoggingLevel.INFO,'Orders Cloned: ' + clonedOrders.size());
          
          // Associate the cloned OrderItems with their parent Orders
          for (Integer i=0; i<clonedOrders.size(); i++)
          {
          	newContractIds.add(clonedOrders[i].Id); // Add the Order Ids to the return list
            for (OrderItem clonedItem :clonedOrderItemMap.get(i))
            {
            	clonedItem.OrderId = clonedOrders[i].Id;
              	clonedOrderItems.add(clonedItem);
            }     
          }
          insert clonedOrderItems;
          System.debug(LoggingLevel.INFO,'Cloned Order Items inserted: ' + clonedOrderItems.size());
        }
        catch(Exception e)
        {
          System.debug(LoggingLevel.ERROR,e);
          Database.rollback(sp);
        }
        //RestContext.response.responseBody = Blob.valueOf(JSON.serialize(newContractIds));
        return newContractIds;
    }

}