@istest
public class SBR_3_0_Api_Web_ProductItem_Test  {
  
    @istest
    private static void testMethod1()
    {//create api Data
        SBR_3_0_Api_Web_ProductItem.ProductItemEvents events= new SBR_3_0_Api_Web_ProductItem.ProductItemEvents();
        events.eventOrigin='test';
        events.eventTimestamp='testTimeStamp';
        events.eventType='TestClassEvent';
        events.uid= 123;
        events.user='Test User';
        events.systemName='test';
        SBR_3_0_Api_Web_ProductItem.PdtItemData pdtData=new SBR_3_0_Api_Web_ProductItem.PdtItemData();
        pdtData.allowToGoNegative='true';
        pdtData.amtDepreciationLifeInMonths='2';
         pdtData.branchLocNumber='Test'; 
		pdtData.category='Test'; 
		pdtData.class_Z='Test'; // in json: class
		pdtData.region='Test'; 
		pdtData.numberOfRentalUnits='Test'; 
		pdtData.qtyOnRent='Test'; 
		pdtData.qtyInTransit='Test'; 
		pdtData.qtyInOutsideShop='Test'; 
		pdtData.qtyMissing='Test'; 
		pdtData.qtyAvailable='Test'; 
		pdtData.qtyReserved='Test'; 
		pdtData.qtyWaitListd='Test'; 
		pdtData.qtyDueBack='Test'; 
		pdtData.qtyOnSchdldPickUp='Test'; 
		pdtData.qtyOnRentalPurchase='Test'; 
		pdtData.numberOfNewUnits='Test'; 
		pdtData.numberOfConsignedUnits='Test'; 
		pdtData.qtyInInsideShop='Test'; 
		pdtData.qtyTransferedOut='Test'; 
		pdtData.qtyReturned='Test'; 
		pdtData.qtyMinimum='Test'; 
		pdtData.cycleCode='Test'; 
		pdtData.lastDateCycleCounted='Test'; 
		pdtData.allowToGoNegative='Test'; 
		pdtData.qtyOnTruck='Test'; 
		pdtData.bulkRepairExpenseMtd=2; 
		pdtData.bulkRepairExpenseYtd=2; 
		pdtData.bulkRepairExpenseLtd=2; 
		pdtData.depreciationRatePercentTypeP=2; 
		pdtData.userDefnGLType='Test '; 
		pdtData.depreciationMethod='Test'; 
		pdtData.depreciationLifeInMonths='Test'; 
		pdtData.salvageValuePercent=2; 
		pdtData.taxDepreciationMethod='Test'; 
		pdtData.taxDepreciationLifeInMonths='Test'; 
		pdtData.taxSalvageValuePercent=1; 
		pdtData.amtDepreciationMethod='Test'; 
		pdtData.amtDepreciationLifeInMonths='Test'; 
		pdtData.amtSalvageValuePercent=1; 
		pdtData.taxDepreciationMethod4='Test'; 
		pdtData.taxDepreciationLifeInMonths4='Test'; 
		pdtData.taxSalvageValuePercent4=1; 
		pdtData.taxDepreciationMethod5='Test'; 
		pdtData.taxDepreciationLifeInMonths5='Test'; 
		pdtData.taxSalvageValuePercent5=1; 
          SBR_3_0_Api_Web_ProductItem.RelationalFields rel=new SBR_3_0_Api_Web_ProductItem.RelationalFields();
        rel.unitOfMeasure='test unit';
        pdtData.relationalFields=rel;
        
     events.ProductItemData= new List< SBR_3_0_Api_Web_ProductItem.PdtItemData>{pdtData};
     
              RestRequest request = new RestRequest();
        request.requestURI='/services/apexrest/ProductItem/ApiCreate/v1/';
        request.httpMethod = 'POST';
    RestContext.request = request;
        request.requestBody = Blob.valueOf(JSON.serialize(events));
         Test.startTest();
       String response=SBR_3_0_Api_Web_ProductItem.createProductItem();
       
       
        Test.stopTest();
        system.assertEquals(response,'');
    }

}