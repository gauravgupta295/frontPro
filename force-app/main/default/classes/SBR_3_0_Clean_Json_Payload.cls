/*********************************************************************************************************************
* Apex Class: SBR_3_0_Clean_Json_Payload
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To clean/remove JSON Payload of any empty/null values
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Harry Rokad          2024-07-01             Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_Clean_Json_Payload {

    public static Map<String, Object> cleanJsonObject(Map<String, Object> jsonObject) {
        List<String> keysToRemove = new List<String>();
    
        for (String key : jsonObject.keySet()) {
            Object value = jsonObject.get(key);
    
            // Check for null values or empty strings
            if (value == null || (value instanceof String && String.isBlank((String)value))) {
                keysToRemove.add(key);
            } else if (value instanceof Map<String, Object>) {
                value = cleanJsonObject((Map<String, Object>) value);
                if (((Map<String, Object>) value).isEmpty()) {
                    keysToRemove.add(key);
                }
            } else if (value instanceof List<Object>) {
                value = cleanJsonList((List<Object>) value);
                if (((List<Object>) value).isEmpty()) {
                    keysToRemove.add(key);
                }
            }
        }
    
        for (String key : keysToRemove) {
            jsonObject.remove(key);
        }
        return jsonObject;
    }

    public static List<Object> cleanJsonList(List<Object> jsonList) {
        for (Integer i = jsonList.size() - 1; i >= 0; i--) {
            Object value = jsonList.get(i);
    
            // Check for null values or empty strings
            if (value == null || (value instanceof String && String.isBlank((String)value))) {
                jsonList.remove(i);
            } else if (value instanceof Map<String, Object>) {
                value = cleanJsonObject((Map<String, Object>) value);
                if (((Map<String, Object>) value).isEmpty()) {
                    jsonList.remove(i);
                }
            } else if (value instanceof List<Object>) {
                value = cleanJsonList((List<Object>) value);
                if (((List<Object>) value).isEmpty()) {
                    jsonList.remove(i);
                }
            }
        }
        return jsonList;
    }
}