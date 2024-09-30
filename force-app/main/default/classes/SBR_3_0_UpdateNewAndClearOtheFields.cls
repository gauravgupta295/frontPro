public without sharing class SBR_3_0_UpdateNewAndClearOtheFields {
    private String sObjType;
    private List<SObject> incoming;
    private String externalIdField;
    private Schema.SObjectField sObjFldExternalId;

    private Set<String> isUpdateable;
    private Set<String> isNillable;
    private Map<String,Schema.DisplayType> fieldTypes;

    private static final String RECORD_TYPE_ID = 'RecordTypeId';
    
    public SBR_3_0_UpdateNewAndClearOtheFields(String sObjType, List<SObject> incoming, String externalIdField) {
        if(incoming == null || incoming.size() == 0) {
            return;
        }
        this.sObjType = sObjType;
        this.incoming = new List<SObject>();
        this.incoming.addAll(incoming);
        this.externalIdField = externalIdField;
        setFieldInfoForSObject();
    }

    public void updateNewAndNillOtherFields() {
        Map<String,SObject> incomingMap = getIncomingMap();
                
        for (SObject rec : incomingMap.values()) {
            Map<String, Object> newNonNullValues = rec.getPopulatedFieldsAsMap();
            //loop through all fields for the record
            for(String fld: isUpdateable) {
                //if field has a new non-null value, update the field
                if(newNonNullValues.containsKey(fld)) {
                    Object val = newNonNullValues.get(fld); 
                    puStronglyTypedValue(rec, fld, val);
                } 
                // update to null
                else {
                    putNullValue(rec, fld);
                }
            }
        }

        upsertRecords();
    }

    //get map of id to records based on id fields
    private Map<String,SObject> getIncomingMap() {
        Map<String,SObject> incomingMap = new Map<String,SObject>();
        for(SObject o : incoming) {
                incomingMap.put(String.valueOf(o.get(externalIdField)), o);
        }
        System.debug('\n vp incomingmap =' + incomingmap);
        return incomingMap;
    }
    
    private void puStronglyTypedValue(SObject rec, String fld, Object val) {
        //System.debug('\nvp null update fld = ' + fld + ' val =' + val);
        /*
        if(fieldTypes.get(fld) == Schema.DisplayType.Boolean) {
            rec.put(fld, Boolean.valueOf(val));
        }
        
        if(fieldTypes.get(fld) == Schema.DisplayType.Date) {
            rec.put(fld, Date.valueOf(val));
        }
        if(fieldTypes.get(fld) == Schema.DisplayType.DateTime) {
            rec.put(fld, DateTime.valueOf(val));
        }
        */
        rec.put(fld, val);
    }

    private void putNullValue(SObject rec, String fld) {
        if(isExcluded(fld)) {
            return;
        }
        //System.debug('\nvp null update fld = ' + fld );
        if(fieldTypes.get(fld) != Schema.DisplayType.Boolean && isNillable.contains(fld) ) {
            //System.debug('setting non-boolean null');            
            rec.put(fld, null);
        }
        else if(isNillable.contains(fld)) {
            //System.debug('nillable');
            rec.put(fld, null);
        }
    }

    private Boolean isExcluded(String fld) {
        if(fld.containsIgnoreCase(RECORD_TYPE_ID)) {
            return true;
        }
        return false;
    }

    private void upsertRecords() {
        String listType = 'List<' + this.sObjType + '>';
        List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        castRecords.addAll(this.incoming);
        Database.upsert (castRecords, this.sObjFldExternalId, true);
    }

    private void setFieldInfoForSObject() {
        
        //get Schema Mapreturn
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjSchema = schemaMap.get(this.sObjType);

        //get Field Map
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField> ();
        fieldMap = sObjSchema.getDescribe().fields.getMap();

        fieldTypes = new Map<String,Schema.DisplayType>();
        isUpdateable = new Set<String>();
        isNillable = new Set<String>();

        //get all the fields Names for SObject
        for (Schema.SObjectField fname: fieldMap.values()){
            String fieldName =  String.valueOf(fname);
            if(fieldname == this.externalIdField) {
                sObjFldExternalId = fname;
            }

            Schema.DisplayType fielddataType = fieldMap.get(fieldName).getDescribe().getType();
            fieldTypes.put(fieldName, fielddataType);

            //build updateable map
            if (fieldMap.get(fieldName).getDescribe().isUpdateable() ) {
                isUpdateable.add(fieldName);
            } 
            //build nillable map
            if (fieldMap.get(fieldName).getDescribe().isNillable() ) {
                isNillable.add(fieldName);
            } 

        }
        System.debug('\n Total fields' + fieldTypes.size());
    }

}