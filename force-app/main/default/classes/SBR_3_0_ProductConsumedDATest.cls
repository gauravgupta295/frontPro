/**********************************************************************************************************************
* Apex Class: SBR_3_0_ProductConsumedDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Product consumed DAO Test class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Vikas Kumar-Initial version
    2.0          2023-10-18          Vikas Kumar - Added Fields 
**********************************************************************************************************************************************/
@istest
public class SBR_3_0_ProductConsumedDATest {
    @istest
    Public static void getPcTableRecsTest(){ 
        List<ProductConsumed> prodc=SBR_3_0_ProductConsumedDA.getPcTableRecs(userinfo.getUserId());
        Assert.areEqual(prodc.size(),0);
    }
}