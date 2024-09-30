@istest
public class Sbr_3_0_FetchLookupDataControllerTest {
    @testsetup
    public static void createAccount()
    {
           Account a = new Account();
            A.Name = 'TestName'+ DateTime.now().getTime();
            a.Phone = '9999999999'; 
            a.BillingStreet = 'Test Street';
            a.BillingCity = 'Manassas';
            a.BillingState = 'IN';
            a.BillingPostalCode = '20111';
            a.BillingCountry = 'US';
            a.ShippingStreet = 'Test Street';
            a.ShippingCity = 'Manassas';
            a.ShippingState = 'IN';
            a.ShippingPostalCode = '20111';
            a.ShippingCountry = 'US';
            insert a;
    }
    @istest
    private static void testmethod1()
    {
        string query='Select id from Account';
     	Sbr_3_0_FetchLookupDataController.QueryResult data=   Sbr_3_0_FetchLookupDataController.getSObjects(query);
        Assert.isNotNull(data.firstResult);
        
    }

}