/*********************************************************************************************************************
* Apex Class: SBR_3_0_Clean_Json_Payload
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_Clean_Json_Payload which clean/remove JSON Payload of any empty/null values
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Harry Rokad          2024-07-01             Initial version
*********************************************************************************************************************/
@isTest
public class SBR_3_0_Clean_Json_Payload_Test {

    @isTest
    static void testCleanJsonObject() {
        // Create a JSON object with various null and empty values
        Map<String, Object> jsonObject = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => null,
            'key3' => '',
            'key4' => new Map<String, Object>{
                'subKey1' => 'subValue1',
                'subKey2' => null,
                'subKey3' => ''
            },
            'key5' => new List<Object>{'listValue1', null, '', new Map<String, Object>{'subKey1' => null}}
        };

        // Clean the JSON object
        Map<String, Object> cleanedJsonObject = SBR_3_0_Clean_Json_Payload.cleanJsonObject(jsonObject);

        // Verify that null and empty values are removed
        System.assertEquals(3, cleanedJsonObject.size());
        System.assert(cleanedJsonObject.containsKey('key1'));
        System.assert(cleanedJsonObject.containsKey('key4'));

        // Verify nested map cleaning
        Map<String, Object> nestedMap = (Map<String, Object>) cleanedJsonObject.get('key4');
        System.assertEquals(1, nestedMap.size());
        System.assert(nestedMap.containsKey('subKey1'));
        System.assertEquals('subValue1', nestedMap.get('subKey1'));

        // Verify nested list cleaning
        List<Object> nestedList = (List<Object>) cleanedJsonObject.get('key5');
        System.assertEquals(1, nestedList.size());
    }

    @isTest
    static void testCleanJsonList() {
        // Create a JSON list with various null and empty values
        List<Object> jsonList = new List<Object>{
            'value1', 
            null, 
            '', 
            new Map<String, Object>{
                'key1' => 'subValue1', 
                'key2' => null, 
                'key3' => ''
            },
            new List<Object>{'listValue1', null, '', new Map<String, Object>{'subKey1' => null}}
        };

        // Clean the JSON list
        List<Object> cleanedJsonList = SBR_3_0_Clean_Json_Payload.cleanJsonList(jsonList);

        // Verify that null and empty values are removed
        System.assertEquals(3, cleanedJsonList.size());
        System.assertEquals('value1', cleanedJsonList.get(0));

        // Verify nested map cleaning
        Map<String, Object> nestedMap = (Map<String, Object>) cleanedJsonList.get(1);
        System.assertEquals(1, nestedMap.size());
        System.assert(nestedMap.containsKey('key1'));
        System.assertEquals('subValue1', nestedMap.get('key1'));

    }

    @isTest
    static void testEmptyJsonObject() {
        // Test with an empty JSON object
        Map<String, Object> jsonObject = new Map<String, Object>();

        // Clean the JSON object
        Map<String, Object> cleanedJsonObject = SBR_3_0_Clean_Json_Payload.cleanJsonObject(jsonObject);

        // Verify the object is still empty
        System.assertEquals(0, cleanedJsonObject.size());
    }

    @isTest
    static void testEmptyJsonList() {
        // Test with an empty JSON list
        List<Object> jsonList = new List<Object>();

        // Clean the JSON list
        List<Object> cleanedJsonList = SBR_3_0_Clean_Json_Payload.cleanJsonList(jsonList);

        // Verify the list is still empty
        System.assertEquals(0, cleanedJsonList.size());
    }
}