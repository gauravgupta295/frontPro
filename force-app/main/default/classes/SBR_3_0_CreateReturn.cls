public with sharing class SBR_3_0_CreateReturn {
    private static WrapReturn wr = new WrapReturn();
    private static final String RETURN_PICKUP ='ReturnOrder';
    private static final String EXCHANGE ='ExchangeOrder';
    private static Boolean isReturn = false; 
    private static String strReq;
    public static boolean throwUnableToLockError;

    public SBR_3_0_CreateReturn(String req) {
		strReq= req;
        wr = (WrapReturn) JSON.deserialize(req, WrapReturn.class);
        if(wr.type != null && String.isBlank(wr.type)) {
            throw new OrderException ('Type of Order (Return or Exchange) is required!');
        }
        if(wr.type != null && String.isBlank(wr.contractNumber)) {
            throw new OrderException ('Contract Number is required!');
        }
        if(wr.type == RETURN_PICKUP) {
            isReturn = true;
        }
    }

    public String syncReturnToSF() {
        if(lineCompositeKey != null && sfLines != null && sfLines.size() > 0 && sfLines.containsKey(lineCompositeKey)) {
            OrderItem line = new OrderItem();
            line = sfLines.get(lineCompositeKey);
            Asset assetObj;
            Boolean isBulk = line.Product2.Bulk_Item__c;
            
            Order_Item_Detail__c oid = new Order_Item_Detail__c();
            oid = (Order_Item_Detail__c)JSON.deserializeStrict(JSON.serialize(wr.data), Order_Item_Detail__c.class);
            oid.Contract_Number__c = line.OrderId;
            oid.Line_Item__c = line.Id;
			//Added Null check | PS-5734 | VS
            If(!isBulk && String.isNotBlank(wr.assetNumber) && !wr.assetNumber.startsWith('RR')){
	        	oid.Asset_Number__c = sfAssets.get(wr.assetNumber)?.Id;
            }

            upsert oid OMS_Order_ID__c;
            return oid.Id;
        }
        // PS-5648: SG: 05132024: Included the Contract # in the exception message
        throw new OrderException ('Unable to find related Line Item to Return or Exchange for this Contract # '+ wr.contractNumber);
    }

    private static String lineCompositeKey {
        get {
            if(lineCompositeKey == null && wr != null && wr.data != null) {
                if(wr.data.Global_Line_Number__c != null) {
                    System.debug('\n @@ sflines lineCompositeKey=' + wr.contractNumber + '-'+ Integer.valueOf(wr.data.Global_Line_Number__c));
                    return wr.contractNumber + '-'+ Integer.valueOf(wr.data.Global_Line_Number__c);
                }
                else {
                    throw new OrderException ('Global Line Number is required!');
                }
            }
            return lineCompositeKey;
        }
        set;       
    }

    private static Map<String, Asset> sfAssets {
        get {
            if(sfAssets == null && String.isNotBlank(wr.assetNumber)) {                
                sfAssets = SBR_3_0_AssetDA.getAssetsByNumbers(new Set<String>{wr.assetNumber});
                //Logged Exception | PS-5734 | VS
                try{
                    if(sfAssets.isEmpty()){
                        throw new OrderException('Unable to find Asset with Asset# - ' + wr.assetNumber);
                    }
                }catch(Exception e){
                    SBR_3_0_LogException.LogIt(e,'',strReq);
                }
            }
            return sfAssets;
        }
        set;
    }

    private static Map<String, OrderItem> sfLines {
        get {
            if(sfLines == null && String.isNotBlank(wr.contractNumber)) {                
                sfLines = SBR_3_0_OrderItemDA.getOrderItemByContractNumber(wr.contractNumber, wr.companyCode);
            }
            return sfLines;
        }
        set;
    }

    public class WrapReturn {
        public String companyCode ='';
        public String contractNumber = '';
        public String type = '';
        public String assetNumber = '';
        public Order_Item_Detail__c data = new Order_Item_Detail__c();
    }

    public class OrderException extends Exception {}
}