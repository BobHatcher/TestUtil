/**
 * Utility Class provided as an example.
 * 
 * This includes a handy printsObject() method as well as a way to use a Config table
 * to use custom metadata to turn features on/off, or swap strings into your code without 
 * having to redeploy.
 * 
 */

@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
public with sharing class Util {

    public static Boolean isTestScenario = false;
    public static Map<String,String> globalConfig = initConfig();
    public static final Boolean IS_TEST = Test.isRunningTest(); // Alias the heavy function
    public static final String MASTER_DOMAIN = 'stupidsalesforcetricks.com';
    public static final string PROFILE_ADMIN = 'System Administrator';

    public static Map<String,String> initConfig(){
        Map<String,String> config = new Map<String,String>();
        for (Global_Configuration__mdt c : [SELECT Name__c, Value__c FROM Global_Configuration__mdt]){
            config.put(c?.name__c.toLowerCase(),c.value__c);
        }
        System.debug(config);
        return config;
    }

    /**
     * getConfig
     * 
     * Usage: 
     * String x = Util.getConfig('my_flag');
     * 
     * Will return the value from Global_Configuration__mdt where name == 'my_flag'
     * 
     * Similarly,
     * Boolean x = Util.getBoolConfig('my_flag');
     * will return a Boolean. In this case enter 'true' or 'false' as a String in the config table.
     * 
     */

    public static String getConfig(String configName){
        if (globalConfig == null || globalConfig?.size() == 0 || !globalConfig.containsKey(configName.toLowerCase())){
            throw new MyException('Config table missing value: ' + configName);
        } else {
            return globalConfig.get(configName?.toLowerCase());
        }
    }

    public static Boolean getBoolConfig(String configName){
        if (globalConfig == null || globalConfig?.size() == 0 || !globalConfig.containsKey(configName.toLowerCase())){
            throw new MyException('Config table missing value: ' + configName);
        } else {
            return Boolean.valueOf(globalConfig.get(configName?.toLowerCase()));
        }
    }

    public static void setConfigForTest(String configName, String configValue){
        globalConfig.put(configName,configValue);
    }

    public static void setConfigForTest(String configName, Boolean configValue){
        globalConfig.put(configName,String.valueOf(configValue));
    }

    public static Boolean rand5050(){
        decimal x = Math.random();
        return x < .5;
    }

    public static String idsFromList(List<sObject> objects){
        List<String> ids = new List<String>();
        for (sObject obj : objects){
            if (obj.Id != null){
                ids.add(obj.id);
            }
        }
        return String.join(ids,',');
    }


    /** 
     * Invocable Version - makes these available in Flows.
     */
    @InvocableVariable
    global string configName;

    @InvocableMethod(label='Retrieve Global Configuration Value')
    global static List<String> invocableGetConfig(List<String> requests) {
        List<String> toReturn = new List<String>();
        toReturn.add(Util.getConfig(requests[0]));
        return toReturn;
    }


    /**
         *
         * ***** printsObject()
         *
         * These methods are super useful. You can basically send this any sObject and it will print it out nicely
         * in the log. It prints all available fields in the record including any parent or child values.
         *
         * Usage:
         * List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
         * System.debug(accounts);// Prints all 5 Accounts
         * System.debug(accounts[0]); // prints just the one Account
         * System.debug(accounts[0],true); // prints the values in a table format
         *
         * Actual example:
         * List<Account> accounts = [select id, parent.name, (select id, name from Contacts LIMIT 1) FROM Account where parentid != null limit 2];
         * system.debug(globalutilities.printsobject(accounts));
         *
         * Gives:
         * -- MULTIPLE Records ==> Type: ACCOUNT, Displaying all 2 records

             -- ACCOUNT  (1 of 2) ==> Id: 0012M00002FGRRxQAP
                  -- Id (Id) = 0012M00002FGRRxQAP
                  -- ParentId (Id) = 0012M000021rnk4QAA
                  -- Industry (String) = Healthcare

                       ↳- ACCOUNT (Lookup From Account.Parent)  ==> Id: 0012M000021rnk4QAA
                            -- Id (Id) = 0012M000021rnk4QAA
                            -- Name (String) = La Esperanza Clinic

             -- ACCOUNT  (2 of 2) ==> Id: 0014100001VPcCAAA1
                  -- Id (Id) = 0014100001VPcCAAA1
                  -- ParentId (Id) = 0012M000022jdpaQAA
                  -- Industry (String) = Government - Local

                       ↳- CONTACT (Lookup From Account.Contacts)  ==> Id: 0034100001st0hNAAQ
                            -- AccountId (Id) = 0014100001VPcCAAA1
                            -- Id (Id) = 0034100001st0hNAAQ
                            -- Name (String) = Stephen Booth

                       ↳- ACCOUNT (Lookup From Account.Parent)  ==> Id: 0012M000022jdpaQAA
                            -- Id (Id) = 0012M000022jdpaQAA
                            -- Name (String) = Capita Birmingham




         * @param records a List or a single sObject
         *
         * @return a String
         */

    public static String printSObject(List<sObject> records) {
        return printSObject(records,5);
    }

    public static String printSObject(List<sObject> records, Integer spacePad) {
        return printSObject(records,5, -1);
    }

    public static String printSObject(List<sObject> records, Integer spacePad, Integer recordLimit){
        try {
            if (spacePad == -1) {
                spacePad = 5;
            }
            if (records == null || records.size() == 0) {
                return '--no records to display--';
            }
            String pad = getPad(spacePad);
            Integer quantity = records.size();
            String recordLimitClause = '';
            if (recordLimit == -1) {
                recordLimitClause = 'Displaying all ' + quantity + ' records';
            } else {
                recordLimitClause = 'Displaying ' + recordLimit + ' of ' + quantity + ' records';
            }
            String out = '\n' + pad + '\n-- MULTIPLE Records ==> Type: ' + String.valueOf(records[0].getSObjectType()).toUpperCase() + ', ' + recordLimitClause + '\n';
            Integer x = 1;
            for (sObject myObject : records) {
                out += printSObject(myObject, spacePad + 4, x, quantity);
                if (x == recordLimit) {
                    break;
                }
                x++;
            }
            return out;
        } catch (Exception e){
            System.debug('** CANNOT PRINT sOBJECT LIST: ' + e.getMessage());
            return (e.getMessage());
        }
    }

    public static String printSObject(sObject record){
        return printSObject(record,5);
    }

    public static String printSObject(sObject record, Boolean asTable){
        return printSObject(record,0, 1, 1, asTable,null);
    }

    public static String printSObject(sObject record, Integer spacePad){
        return printSObject(record,spacePad, 1,1);
    }

    public static String printSObject(sObject record, Integer spacePad, Integer recordNumber, Integer totalQuantity){
        return printSObject(record,spacePad,recordNumber,totalQuantity, false,null);
    }
    public static String printSObject(sObject record, Integer spacePad, Integer recordNumber, Integer totalQuantity, Boolean asTable, String parentObjectType) {

        if (record == null){
            return '-- Record Is Null --';
        }
        try {
            String pad = getPad(spacePad);
            Boolean isSubObject = parentObjectType != null;
            String quantity = '';
            if (totalQuantity > 1) {
                quantity = '(' + recordNumber + ' of ' + totalQuantity + ')';
            }

            String thisObjectType = String.valueOf(record.getSObjectType());
            String parentClause = (parentObjectType != null ? '(Lookup From ' + parentObjectType + ')' : '');
            String out = '\n' + pad + (isSubObject ? '↳' : '-') + '- ' + thisObjectType.toUpperCase() + ' ' + parentClause + ' ' + quantity + ' ==> Id: ' + (record.Id == null ? '-- null --' : record.Id) + '\n' ;
            Map<String, Object> fieldsAndValues = record.getPopulatedFieldsAsMap();
            pad = pad + '  '; // indent fields

            if (asTable){
                out += '<TABLE style="border:1px solid black;"><TR><TH>Field</TH><TH>Type</th><th>Value</th></tr>';
            }
            for (String field : fieldsAndValues.keySet()) {
                if (field != null) {
                    out += printSingleObject(fieldsAndValues.get(field), spacePad + 5, asTable, thisObjectType, field);
                }
            }
            return (asTable ? out + '</table>' : out);
        } catch (Exception e) {
            System.debug('** CANNOT PRINT sOBJECT : ' + e.getMessage());
            return (e.getMessage());
        }
    }

    public static String printSingleObject(Object record, Integer spacePad, Boolean asTable, String parentObjectType, String fieldName){
        try {
            String out ='';

            // object returned is either an Object or a List<sObject>

            // Need to account for
            // sObject (Single)
            // sObject (List)
            // Object
            // for both table and non
            if (record == null) {
                return '';
            }
            //System.debug(record + ' 0> ' getBaseType(record) + ' ' + getType(record));
            String trLineStart = '';
            String trLineEnd = '';
            if (getBaseType(record) == 'sObject'){
                trLineStart = '<tr><td style="padding: 5px;"></td><td style="padding: 5px;"></td><td style="padding: 5px;">';
                trLineEnd = '</td></tr>';
                out += printsObject((sObject) record, spacePad + 5, 1, 1, asTable, parentObjectType + '.' + fieldName );
            } else if (getBaseType(record)== 'Object'){
                if (asTable){
                    trLineStart = '<tr><td style="padding: 5px;">' + fieldName + ' (BT)</td><td style="padding: 5px;" >' + getType(record) + '</td><td style="padding: 5px;">';
                    out += record;
                    trLineEnd = '</td></tr>';
                } else {
                    out += getPad(spacePad) + '-- ' + fieldName + ' (' + getType(record) + ') = ' + record + '\n';
                }
            } else if (getBaseType(record) == 'sObjectList') {
                Integer x = 1;
                Integer recordSize = ((List <Object>) record).size();
                trLineStart = '<tr><td style="padding: 5px;"></td><td style="padding: 5px;"></td><td style="padding: 5px;">';
                for (Object obj : (List <Object>) record){
                    out += printsObject((sObject) obj, spacePad + 5, x, recordSize, asTable, parentObjectType + '.' + fieldName);
                    x ++;
                }
                trLineEnd = '</td></tr>';
            }
            return (asTable ? trLineStart + out + trLineEnd : out);
        } catch (Exception e){
            System.debug('** CANNOT PRINT sOBJECT LINE: ' + e.getMessage());
            return (e.getMessage());
        }

    }

    public static String getPad(Integer spacePad){
        String pad = '';
        for (Integer x = 0; x < spacePad ; x++) {
            pad += ' ';
        }
        return pad;
    }
    
    @SuppressWarnings('PMD.NcssMethodCount')
    public static string getType(Object o) {
        try {
            if(o==null) {
                return '';              // we can't say much about null with our current techniques
            }
            if (getBaseType(o) == 'sObjectList'){
                if (((List<sObject>) o).size() > 0){
                    return getType(((List<sObject>)o)[0]);
                }
            }
            if (IS_TEST && isTestScenario){
                throw new MyException('Exception For Test');
            }
            if(o instanceof SObject){
                return ((SObject)o).getSObjectType().getDescribe().getName()+'';
            }
            if(o instanceof Boolean)            {return 'Boolean';}
            if(o instanceof Id)                 {return 'Id';}
            if(o instanceof String)             {return 'String';}
            if(o instanceof Blob)               {return 'Blob';}
            if(o instanceof Date)               {return 'Date';}
            if(o instanceof Datetime)           {return 'Datetime';}
            if(o instanceof Time)               {return 'Time';}
            if(o instanceof String)             {return 'String';}
            if(o instanceof Integer)            {return 'Integer';}
            if(o instanceof Long)               {return 'Long';}
            if(o instanceof Decimal)            {return 'Decimal';}  // we can't distinguish between decimal and double
            if(o instanceof Double)             {return 'Double';}   // we can't distinguish between decimal and double
            if(o instanceof List<object>)       {return 'List';}
            return 'Object';                    // actually we can't detect maps and sets and maps
        }
        catch (Exception e){
            MyException.logError(e,'Util_GET_TYPE_FAILURE','Util','getType');
            return '--getType Failed--';
        }

    }

    @SuppressWarnings('PMD.NcssMethodCount')
    public static String getBaseType (Object o){
        try {
            if (IS_TEST && isTestScenario){
                throw new MyException('Exception For Test');
            }
            if(o==null) {return '';    }          // we can't say much about null with our current techniques
            if(o instanceof List<sObject>)       {return 'sObjectList';}
            if(o instanceof SObject)            {return 'sObject';}
            if(o instanceof Boolean)            {return 'Object';}
            if(o instanceof Id)                 {return 'Object';}
            if(o instanceof String)             {return 'Object';}
            if(o instanceof Blob)               {return 'Object';}
            if(o instanceof Date)               {return 'Object';}
            if(o instanceof Datetime)           {return 'Object';}
            if(o instanceof Time)               {return 'Object';}
            if(o instanceof String)             {return 'Object';}
            if(o instanceof Integer)            {return 'Object';}
            if(o instanceof Long)               {return 'Object';}
            if(o instanceof Decimal)            {return 'Object';}  // we can't distinguish between decimal and double
            if(o instanceof Double)             {return 'Object';}   // we can't distinguish between decimal and double
            if(o instanceof List<object>)       {return 'ObjectList';}
            return 'Object';                    // actually we can't detect maps and sets and maps
        } catch (Exception e){
            MyException.logError(e,'Util_GET_BASE_TYPE_FAILURE','Util','getBaseType');
            return '--getBaseType Failed--';
        }
    }

    public static void debug(String msg){
        System.debug('-->' + msg);
    }
}