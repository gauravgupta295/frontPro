@IsTest
public class SBR_3_0_WrapAlternateItems_Test {
    @IsTest
    public static void testATIRequest() {
        // Create test data
        SBR_3_0_WrapAlternateItems.ATIRequest request = new SBR_3_0_WrapAlternateItems.ATIRequest();
        request.cartId = '123';
        request.sellingChannel = 'Online';
        request.timezoneId = 'GMT';
        request.requestedDeliveryDate = '2023-06-19';
        request.transactionType = 'Sales';
        request.fulfillmentType = 'Pickup';
        request.includeZeroATP = true;
        request.locationType = 'Warehouse';
        request.latitude = 37.7749;
        request.longitude = -122.4194;
        request.products = new List<SBR_3_0_WrapAlternateItems.Products>();
        
        SBR_3_0_WrapAlternateItems.Products product1 = new SBR_3_0_WrapAlternateItems.Products();
        product1.productId = 'P1';
        product1.uom = 'Each';
        request.products.add(product1);
        
        SBR_3_0_WrapAlternateItems.Products product2 = new SBR_3_0_WrapAlternateItems.Products();
        product2.productId = 'P2';
        product2.uom = 'Pack';
        request.products.add(product2);
        
        // Test the request object
        System.assertEquals('123', request.cartId);
        System.assertEquals('Online', request.sellingChannel);
        System.assertEquals('GMT', request.timezoneId);
        System.assertEquals('2023-06-19', request.requestedDeliveryDate);
        System.assertEquals('Sales', request.transactionType);
        System.assertEquals('Pickup', request.fulfillmentType);
        System.assertEquals(true, request.includeZeroATP);
        System.assertEquals('Warehouse', request.locationType);
        System.assertEquals(2, request.products.size());
        System.assertEquals(37.7749, request.latitude);
        System.assertEquals(-122.4194, request.longitude);
        
        // Test the products in the request
        System.assertEquals('P1', request.products[0].productId);
        System.assertEquals('Each', request.products[0].uom);
        System.assertEquals('P2', request.products[1].productId);
        System.assertEquals('Pack', request.products[1].uom);
    }
    
}