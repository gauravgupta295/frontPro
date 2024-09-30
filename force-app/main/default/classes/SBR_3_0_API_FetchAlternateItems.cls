/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_FetchAlternateItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Fetch Alternate Items
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad          2022-10-02             Initial version    
*********************************************************************************************************************/



public with sharing class SBR_3_0_API_FetchAlternateItems {

    private static final String APINAME = 'Alternate_Item';

    @AuraEnabled
    public static SBR_3_0_WrapAlternateItems.ATIResponse getAlternateItems(SBR_3_0_WrapAlternateItems.ATIRequest req, String companyId){

        String resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(req), APINAME, companyId);
        if(String.IsNotBlank(resp)){
            return (SBR_3_0_WrapAlternateItems.ATIResponse) JSON.deserialize(resp,SBR_3_0_WrapAlternateItems.ATIResponse.class);
        }
        return null;
    }
    @AuraEnabled
    public static string getAlternateItemsTest(SBR_3_0_WrapAlternateItems.ATIRequest req, String companyId){

        String resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(req), APINAME, companyId);
        System.debug(resp);
        return resp;
        // if(String.IsNotBlank(resp)){
        //     return (SBR_3_0_WrapAlternateItems.ATIResponse) JSON.deserialize(resp,SBR_3_0_WrapAlternateItems.ATIResponse.class);
        // }
        // return null;
    }
}

/*
SBR_3_0_WrapAlternateItems.ATIRequest obj = new SBR_3_0_WrapAlternateItems.ATIRequest();
obj.companyId='01';
obj.cartId ='5242f682-13de-4b77-a654-612a62ab782e';
obj.sellingChannel = 'SBRB2B';
obj.fulfillmentType ='DEL';
obj.fulfillmentService = 'STANDARD';
obj.sourceSystem = 'salesForce';
SBR_3_0_WrapAlternateItems.Address addr = new SBR_3_0_WrapAlternateItems.Address();
addr.country='US';
addr.zip = '75020';

SBR_3_0_WrapAlternateItems.Jobsite j = new SBR_3_0_WrapAlternateItems.Jobsite();
j.latitude = 48.51;
j.longitude = 48.51;
j.address = addr;

obj.jobsite = j;

SBR_3_0_WrapAlternateItems.Products p = new SBR_3_0_WrapAlternateItems.Products();
p.requestedDeliveryDate = '2022-05-10T23:00:00+00:00';
p.lineId = '1';
p.quantity = 10;
p.productId = '0012394';
p.productType='E';
p.catId = '020';
obj.products = new List<SBR_3_0_WrapAlternateItems.Products>();
obj.products.add(p);
String s = JSON.serializePretty(obj);
System.debug('\n obj = ' + s);
String resp = SBR_3_0_API_FetchAlternateItems.getAlternateItemsTest(obj,'01');
System.debug(resp);
*/