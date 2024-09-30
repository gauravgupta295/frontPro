/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_FetchOptimalSourcingBranch
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Fetch the optimal branch which can fulfill all the product in the inquiry table
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Viren Patel          2022-09-06             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_FetchOptimalSourcingBranch {
    private static final String APINAME = 'OptimalSourcingBranch_API';

    @AuraEnabled
    public static SBR_3_0_WrapInventorySources.ATSResponse getOptimalSourcingBranch(SBR_3_0_WrapInventorySources.ATSRequest request, String companyId){
        String resp = '';

        resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(request), APINAME, companyId);
        System.debug('response '+resp);
        if (String.IsNotBlank(resp)){
            return (SBR_3_0_WrapInventorySources.ATSResponse) JSON.deserialize(resp,SBR_3_0_WrapInventorySources.ATSResponse.class);
        }
        return null;
    }



//   SBR_3_0_WrapInventorySources.ATSRequest obj = new SBR_3_0_WrapInventorySources.ATSRequest();
//         obj.companyId='01';
//         obj.cartId ='5242f682-13de-4b77-a654-612a62ab782e';
//        obj.cartTotal =70.0;
//        obj.cartType='SBRB2B';
//        obj.customerType='DEFAULT';
//         obj.sellingChannel = 'SBRB2B';
//         obj.fulfillmentType ='DEL';
//         obj.fulfillmentService = 'STANDARD';
//         obj.overrideDistance= true;
//         obj.sourceSystem = 'salesForce';
//         SBR_3_0_WrapInventorySources.Address addr = new SBR_3_0_WrapInventorySources.Address();
//           addr.line1='';
//           addr.line2='';
//           addr.state='TX';
//           addr.city='Plano';
//         addr.country='US';
//         addr.zip = '75024';

//         SBR_3_0_WrapInventorySources.Jobsite j = new SBR_3_0_WrapInventorySources.Jobsite();
//         j.latitude = 48.51;
//         j.longitude = -117.62;
//         j.address = addr;

//         obj.jobsite = j;

//         SBR_3_0_WrapInventorySources.Products p = new SBR_3_0_WrapInventorySources.Products();
//         p.requestedDeliveryDate = '2022-10-09T23:00:00+00:00';
//         p.lineId = '1';
//         p.uom='EACH';
//         p.quantity = 1;
//         p.productId = '0032958';
//         p.productType='E';
//         p.catId = '003';
//         p.classId= '2958';
//         obj.products = new List<SBR_3_0_WrapInventorySources.Products>();
//         obj.products.add(p);
//         SBR_3_0_WrapInventorySources.salesItems s= new SBR_3_0_WrapInventorySources.salesItems();
//           s.itemNumber='123458';
//           s.stockClass='9';
//           s.quantity=1;
//           s.unitPrice=190;
//           obj.salesItems = new List<SBR_3_0_WrapInventorySources.salesItems>();
//           obj.salesItems.add(s);
//         String res = JSON.serializePretty(obj);
//         System.debug('\n obj = ' + res);
//         SBR_3_0_WrapInventorySources.ATSResponse resp = SBR_3_0_API_FetchOptimalSourcingBranch.getOptimalSourcingBranch(obj,'01');
//         System.debug(resp);


//         obj.products = new List<SBR_3_0_WrapAlternateItems.Products>();
//         obj.products.add(p);
//         String s = JSON.serializePretty(obj);
//         System.debug('\n obj = ' + s);
//         SBR_3_0_WrapAlternateItems.ATIResponse resp = SBR_3_0_API_FetchAlternateItems.getAlternateItems(obj,'01');
//         System.debug(resp);
    // @AuraEnabled
    // public static SBR_3_0_WrapInventoryAtBranch.ATPResponse getInventoryAtBranch(SBR_3_0_WrapInventoryAtBranch.ATPRequest req, String companyId){

    //     String resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(req), APINAME, companyId);
    //     if(String.IsNotBlank(resp)){
    //         return (SBR_3_0_WrapInventoryAtBranch.ATPResponse) JSON.deserialize(resp,SBR_3_0_WrapInventoryAtBranch.ATPResponse.class);
    //     }
    //     return null;
    // }
}