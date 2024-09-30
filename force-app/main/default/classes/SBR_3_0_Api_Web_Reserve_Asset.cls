/**
 * @description       : Blue Yonder inbound Interface to Reserve an Asset
 * @author            : Bill Convis - ServiceMax
 * @group             : 
 * @last modified on  : 08-31-2022
 * @last modified by  : Tom Canter - ServiceMax
**/
@RestResource(urlMapping='/ASSET/ReserveAsset/v1/*')
global  class SBR_3_0_Api_Web_Reserve_Asset {

    @HttpPost
    global static void reserveAsset(){
        String strReturn = '';  
        String strServiceError = '';
        String strOrderLineId = '';
        Boolean assetIsAvailable = true;
        Asset selectedAsset = new Asset();
        Set<Id> setAssetIds = new Set<Id>();
        Set<String> setCatClass = new Set<String>();
        Set<String> setLocations = new Set<String>();
        Map<Id, Asset> mapAssetIdAsset = new Map<Id, Asset>();
        Map<String, orderLines> mapAssetClassOrderLine = new Map<String, OrderLines>();
        Map<String, Asset> mapAssetIsAvailable = new Map<String, Asset>();
        Map<String, Asset> mapAssetIsNotAvailable = new Map<String, Asset>();
        Map<String, orderLines> mapOrderLineIdOrderLine = new Map<String, orderLines>();
        Equipment_on_Hold__c newEquipRecord = new Equipment_on_Hold__c();
        ReserveAssetWrapper raWrapper = (ReserveAssetWrapper)JSON.deserialize(RestContext.request.requestBody.toString(), ReserveAssetWrapper.class);
        JSONGenerator gen = JSON.createGenerator(false); 

        //GENERAL TESING CODE

        //Get all the Cat Classs from the OrderLines
        for (OrderLines ol : raWrapper.orderLines) {
            setCatClass.add(ol.productId);
            setLocations.add(ol.locations[0].locationId);  
            //strOrderLineId = ol.orderLineId + ol.productId + ol.locations.locationId;
            mapOrderLineIdOrderLine.put(ol.orderLineId,ol);
            mapAssetClassOrderLine.put(ol.productId, ol);
        }
        try{
            //Get all the Assets based on what Blue Yonder is asking for  
            for (Asset availableAssets : [SELECT ID, SM_PS_Company_Code__c, SM_PS_Category__c, SM_PS_Class__c, SM_PS_Cat_Class__c, SM_PS_Machine_Weight__c, SM_PS_Current_Location__c, SM_PS_Equipment_Number__c,
                                          SM_PS_Assigned_Location__c, Name, Description, SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c, SM_PS_Current_Location__r.Branch_Location_Number__c 
                                          FROM ASSET                              
                                          WHERE SM_PS_Company_Code__c =: raWrapper.orgId
                                          AND SM_PS_Cat_Class__c IN: setCatClass
                                          AND SM_PS_Current_Location__r.Branch_Location_Number__c IN:   setLocations
                                          ORDER BY SM_PS_Last_Transaction_Date__c ASC
                                          ]){   
                                            setAssetIds.add(availableAssets.Id);
                                            //strOrderLineId = availableAssets.SM_PS_Cat_Class__c + availableAssets.SM_PS_Current_Location__r.A360SPARK_ExternalId__c;
                                            mapAssetIdAsset.put(availableAssets.Id, availableAssets);                      
            }
    
            //Now go and see if there are any records in the Equipment on Hold Table for these Assets
            for (Equipment_on_Hold__c eqhold : [SELECT ID, SM_PS_Equipment_Number__c, SM_PS_Hold_Request_From_Date__c, 
                                                SM_PS_Hold_Request_To_Date__c, SM_PS_Status__c, SM_PS_Last_Maintenance_Date__c,
                                                SM_PS_Equipment_Number__r.SM_PS_Cat_Class__c,
                                                SM_PS_Equipment_Number__r.Id
                                                FROM Equipment_on_Hold__c
                                                WHERE SM_PS_Equipment_Number__c =: setAssetIds
                                                ORDER BY SM_PS_Last_Maintenance_Date__c ASC]) {
                    //Go and find the OrderLine in the inbound payload for this class
                    for (OrderLines oll : raWrapper.orderLines) {
                        if (oll.productId == eqhold.SM_PS_Equipment_Number__r.SM_PS_Cat_Class__c) {
                            if (oll.dates.requestedDeliveryDate.min >= eqhold.SM_PS_Hold_Request_From_Date__c &&  oll.dates.requestedDeliveryDate.max <= eqhold.SM_PS_Hold_Request_To_Date__c
                                || oll.dates.requestedDeliveryDate.max >= eqhold.SM_PS_Hold_Request_From_Date__c && oll.dates.requestedDeliveryDate.max <= eqhold.SM_PS_Hold_Request_To_Date__c) {
                                mapAssetIsNotAvailable.put(oll.orderLineId,mapAssetIdAsset.get(eqhold.SM_PS_Equipment_Number__r.Id));
                                break;
                            }else{
                                mapAssetIsAvailable.put(oll.orderLineId,mapAssetIdAsset.get(eqhold.SM_PS_Equipment_Number__r.Id));
                                break;
                            } 
                        }
                    }                            
            }
            //Now check to see if there are any Assets not available - if not then all the assets sent in the payload are valid
            if(mapAssetIsNotAvailable.isEmpty()){
                for (String  assetID : mapAssetIdAsset.keySet()) {
                    Asset thisAsset = mapAssetIdAsset.get(assetID);
                    //Now go back over all the Order Lines and match an order with an Asset that is available
                    for (String olid : mapOrderLineIdOrderLine.keySet()) {
                        orderLines ol_lines = mapOrderLineIdOrderLine.get(olid);

                        if (ol_lines.productId == thisAsset.SM_PS_Cat_Class__c && ol_lines.locations[0].locationId == thisAsset.SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c) {
                            newEquipRecord = reserveTheAsset(thisAsset, ol_lines, raWrapper.orgId, raWrapper.orderId, raWrapper.customerId);
                            mapAssetIsAvailable.put(ol_lines.orderLineId, thisAsset);
                        }
                    }
                }
            }else{
                //Loop through all the assets sent in and see which ones are not available
                for (String  assetID : mapAssetIdAsset.keySet()) {
                    Asset thisAsset = mapAssetIdAsset.get(assetID);
                    for (String olid : mapOrderLineIdOrderLine.keySet()) {
                        if (!mapAssetIsNotAvailable.containsKey(olid)) {
                            orderLines ol_lines = mapOrderLineIdOrderLine.get(olid);
                            if (ol_lines.productId == thisAsset.SM_PS_Cat_Class__c && ol_lines.locations[0].locationId == thisAsset.SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c) {
                                newEquipRecord = reserveTheAsset(thisAsset, ol_lines, raWrapper.orgId, raWrapper.orderId, raWrapper.customerId);
                                mapAssetIsAvailable.put(ol_lines.orderLineId, thisAsset);
                            }
                        }
                    }
                }
            }

        }catch(Exception e){  
            strServiceError = strServiceError + e.getMessage();
        }
        //Now build the response
        if (!mapAssetIsAvailable.isEmpty() || !mapAssetIsNotAvailable.isEmpty() ) {
            gen.writeStartObject();
            gen.writeStringField('orgId', raWrapper.orgId);
            gen.writeStringField('orderId', raWrapper.orderId);
            gen.writeStringField('updateUser', 'SF');
            if (!mapAssetIsNotAvailable.isEmpty()) {
                gen.writeStringField('ResponseCode', '300');  
                gen.writeStringField('ResponseMessage', strServiceError);  
            }else{
                gen.writeStringField('ResponseCode', '200');    
            }
            gen.writeFieldName('orderLines');
            gen.writeStartArray();
                for (String oLineID : mapAssetIsAvailable.keySet()) {
                    Asset thisAsset = mapAssetIsAvailable.get(oLineID);
                    OrderLines oll = mapOrderLineIdOrderLine.get(oLineID);
                    gen.writeStartObject();
                        gen.writeStringField('orderLineId', oll.orderLineId);
                        gen.writeStringField('ResponseCode', '200'); 
                        gen.writeStringField('ResponseMesssage', 'SUCCESS'); 
                        gen.writeStringField('productId', thisAsset.SM_PS_Cat_Class__c);
                        gen.writeFieldName('customFields');
                        gen.writeStartObject();
                            gen.writeStringField('extnAssetNo', thisAsset.Name);
                            gen.writeStringField('extnAssetLocation', thisAsset.SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c);
                        gen.writeEndObject();
                        gen.writeStringField('updateUser', 'SF');
                    gen.writeEndObject();
                }
                if (!mapAssetIsNotAvailable.isEmpty()) {
                    for (String oLineID : mapAssetIsNotAvailable.keySet()) {
                        Asset thisAsset = mapAssetIsNotAvailable.get(oLineID);
                        orderLines oll = mapOrderLineIdOrderLine.get(oLineID);
                        gen.writeStartObject();
                            gen.writeStringField('orderLineId', oll.orderLineId);
                            gen.writeStringField('ResponseCode', '300'); 
                            gen.writeStringField('ResponseMesssage', 'ASSET NOT AVAILABLE'); 
                            gen.writeStringField('productId', thisAsset.SM_PS_Cat_Class__c);
                            gen.writeFieldName('customFields');
                            gen.writeStartObject();
                                gen.writeStringField('extnAssetNo', thisAsset.Name);
                                gen.writeStringField('extnAssetLocation', thisAsset.SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c);
                            gen.writeEndObject();
                            gen.writeStringField('updateUser', 'SF');
                        gen.writeEndObject();
                    }
                }
            gen.writeEndArray();
            gen.writeEndObject();
        }else{
            gen.writeStartObject();
            gen.writeStringField('orgId', raWrapper.orgId);
            gen.writeStringField('orderId', raWrapper.orderId);
            gen.writeStringField('updateUser', 'SF');
            gen.writeStringField('ResponseCode', '300'); 
            gen.writeStringField('ResponseMesssage', strServiceError); 
            gen.writeEndObject();
        }
        
        RestResponse restRes = RestContext.response;
        if(restRes == null){
            restRes = new RestResponse();
            RestContext.response = restRes;
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        restRes.statusCode = 200;
        restRes.responseBody = Blob.valueOf(gen.getAsString());
    }

    public static Equipment_on_Hold__c reserveTheAsset(Asset assetToReserve, orderLines oll, String strOrgID, String strOrderId, String strCustomerID){
        Equipment_on_Hold__c newEquipmentHoldRec = new Equipment_on_Hold__c();
        Id acctId = null;
        String acctName = '';
        Integer intCustomerNumber;
        for (Account acct : [SELECT ID, Name FROM ACCOUNT WHERE RM_Account_Number__c =: strCustomerID]) {
            acctId = acct.Id;
            acctName = acct.Name;
        }
        newEquipmentHoldRec.Name = assetToReserve.Name;
        newEquipmentHoldRec.SM_PS_Asset_Id__c = assetToReserve.Name;
        newEquipmentHoldRec.SM_PS_Company_Code__c = assetToReserve.SM_PS_Company_Code__c;
        newEquipmentHoldRec.SM_PS_Equipment_Number__c = assetToReserve.Id;
        newEquipmentHoldRec.SM_PS_Account_Name__c = acctId;
        newEquipmentHoldRec.SM_PS_Hold_Request_Location__c = assetToReserve.SM_PS_Current_Location__c;
        newEquipmentHoldRec.SM_PS_Hold_Request_From_Date__c = Date.valueOf(oll.dates.requestedDeliveryDate.min);
        newEquipmentHoldRec.SM_PS_Hold_Request_To_Date__c = Date.valueOf(oll.dates.requestedDeliveryDate.max);
        newEquipmentHoldRec.SM_PS_Hold_Request_Reason__c = 'HOLD';
        newEquipmentHoldRec.SM_PS_Status__c = 'Active';
        insert newEquipmentHoldRec;

        return newEquipmentHoldRec;
    }

    public String orgId {get;set;} 
	public String orderId {get;set;} 
	public String customerId {get;set;} 
	public List<OrderLines> orderLines {get;set;} 

    public class OrderLines {
		public String orderLineId;
		public String productId;
		public Dates dates;
		public List<Locations> locations;
	}
    public class Locations {
		public String locationId;
		public String locationType;
	}

    public class RequestedDeliveryDate {
		public DateTime min;
		public DateTime max;
	}

    public class CustomFields {
		public String extnEstimatedReturnDate;
	}
    
    public class Dates {
		public RequestedDeliveryDate requestedDeliveryDate;
		public CustomFields customFields;
	}

    public class ReserveAssetWrapper{
        public String orgId {get;set;} 
        public String orderId {get;set;} 
        public String customerId {get;set;} 
        public List<OrderLines> orderLines {get;set;} 
    }


}