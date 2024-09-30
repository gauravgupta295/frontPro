/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_BranchATP
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invoke Branch ATP API to identify the order item ATP.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Pratiksha Kadam         2023-11-23          Initial version   
*********************************************************************************************************************/
public class SBR_3_0_API_BranchATP {  
    private static final String APINAME_BRANCH_ATP = 'Branch_ATP_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Decimal> CheckOrderItemATP(String orderId) {
        Set<Id> orderIds = new Set<Id>();
        orderIds.add(orderId);
        Map<Id, Order> ordMap = SBR_3_0_OrderDA.getOrdersWithItems(orderIds);
        Order ord = ordMap.get(orderId);
        String payload = '';
        Set<String> productIdSet = new Set<String>();
        
        if(ord != null){
            for(OrderItem ordItm : ord.OrderItems){
                productIdSet.add(ordItm.Product2.Product_SKU__c);
            }
            payload = generateWrapper(ord);
        }      
        system.debug('payload+ '+ payload);
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME_BRANCH_ATP);
        HttpRequest req = httpCallout.getRequest();
        req.setMethod('POST');
        req.setEndpoint(req.getEndpoint());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        req.setHeader('companyId', ord.Company_Code__c);
        
        req.setTimeout(20000);
        req.setBody(payload);
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        
        String returnPayload = res.getBody();
        system.debug('response+ '+ returnPayload);
        system.debug('response2+ '+ res.getStatusCode()+' '+res.getStatus());
        if (res.getStatusCode() == 201 || res.getStatus()== 'OK' || res.getStatusCode() == 200){
            Map<String, Decimal> resultMap = new Map<String, Decimal>();
            
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(returnPayload);
            Map<String, Object> data = (Map<String, Object>) jsonData.get('data');
            if(returnPayload.contains('productId')){
                List<Object> availabilityByProducts = (List<Object>) data.get('availabilityByProducts');
                
                // Iterate through the availabilityByProducts
                for (Object product : availabilityByProducts) {
                    Map<String, Object> productMap = (Map<String, Object>) product;
                    String prodId = (String)productMap.get('productId');
                    List<Object> availabilityByFulfillmentTypes = (List<Object>) productMap.get('availabilityByFulfillmentTypes');
                    
                    
                    // Iterate through the availabilityByFulfillmentTypes
                    for (Object fulfillmentType : availabilityByFulfillmentTypes) {
                        Map<String, Object> fulfillmentTypeMap = (Map<String, Object>) fulfillmentType;
                        List<Object> availabilityDetails = (List<Object>) fulfillmentTypeMap.get('availabilityDetails');
                        
                        // Iterate through the availabilityDetails
                        for (Object availabilityDetail : availabilityDetails) {
                            Map<String, Object> availabilityDetailMap = (Map<String, Object>) availabilityDetail;
                            List<Object> availabilityByLocations = (List<Object>) availabilityDetailMap.get('availabilityByLocations');
                            
                            // Iterate through the availabilityByLocations
                            for (Object location : availabilityByLocations) {
                                Map<String, Object> locationMap = (Map<String, Object>) location;
                                Decimal atp = (Decimal) locationMap.get('atp');
                                String pcId = (String) locationMap.get('pcId');
                                system.debug('resultMap3=='+resultMap+'-'+pcId);
                                // Populate the resultMap
                                if ((!resultMap.containsKey(prodId)) && pcId == ord.Branch__r.Branch_Location_Number__c) {
                                    resultMap.put(prodId, atp);
                                    system.debug('resultMap2=='+resultMap+'-'+pcId);
                                }
                            }
                        }
                    }
                }
            }
            if(!productIdSet.isEmpty()){
                for(String productId : productIdSet){
                    if(!resultMap.containsKey(productId)){
                        resultMap.put(productId,0.0);
                    }
                }
            }
           system.debug('resultMap=='+resultMap);
            return resultMap;
        }
        else{
            system.debug('resultMap==');
            //error response 
            return null;
        }
    }
    
    public static string generateWrapper(Order ord){
        List<productWrapper> prodWrapperObjList = new List<productWrapper>();
        List<orderItemWrapper> ordItmWrapperList = new List<orderItemWrapper>();
        orderItemWrapper oiWrapperObj = new orderItemWrapper();
        
        ordDetailsWrapper ordWrapperObj = new ordDetailsWrapper();
        ordWrapperObj.segment = 'DEFAULT';
        ordWrapperObj.sellingChannel = 'SBRB2B';
        if(ord.Earliest_Delivery_Date__c != null){
            ordWrapperObj.requestedDeliveryDate = ord.Earliest_Delivery_Date__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }
        ordWrapperObj.pcId = ord.Branch__r.Branch_Location_Number__c;
        //ordWrapperObj.pcId='0001';
        ordWrapperObj.fulfillmentType = (ord.Deliverymethod__c == 'Delivery') ? 'DEL' : 'CPU';
        if(ord.orderItems.size() > 0){
            for(OrderItem ordItm : ord.orderItems){
                productWrapper prodWrapperObj = new productWrapper();
                prodWrapperObj.orderId = ord.Id;
                prodWrapperObj.productId = ordItm.Product2.Product_SKU__c;
                //prodWrapperObj.uom = ordItm.Order_Item_Unit_of_Measure__c; 
                prodWrapperObj.uom = 'EA'; 

            }            
        }
        oiWrapperObj.products = prodWrapperObjList;
        ordItmWrapperList.add(oiWrapperObj);
        ordWrapperObj.orderLines = ordItmWrapperList;
        String req = JSON.Serialize(ordWrapperObj);
        return req;
    }
    
    public class ordDetailsWrapper{
        public string segment;
        public string sellingChannel;
        public string requestedDeliveryDate ;
        public string pcId;
        public string fulfillmentType ;
        public List<orderItemWrapper> orderLines;
    }
    
    public class orderItemWrapper{
        public List<productWrapper> products;       
    }
    
    public class productWrapper{
        public string productId;
        public string uom;
        public string orderId;
    }    
}