/**
 * Created by Bob.Hatcher on 8/18/21.
 */

public with sharing class TestUtil {

    private static List<Test_Code_Default__mdt> gTestCodeDefault ;
    private static Map<String,Map<sObjectField, Object>> gDefaults = new Map<String,Map<sObjectField, Object>>();
    private static Set<sObjectField> gSuppressedDefaults ;
    private static Integer userCount;
    private static Map<String,Integer> gRecordCounts;
    public static Boolean restrictDefaultsToIsTest = false;
    private static Database.DMLOptions dmlOptions ;

    public static sObject newObject(String sObjectType) {
        return newObject(sObjectType,false);
    }

    public static sObject newObject(String sObjectType, Boolean doInsert){
        if (gTestCodeDefault == null || gTestCodeDefault?.size() == 0){
            loadDefaults();
        }

        sObject toReturn = Schema.getGlobalDescribe().get(sObjectType).newSObject() ;
        Map<sObjectField,Object> values = gDefaults.get(sObjectType);
        //System.debug('Defaults for ' + sObjectType + ' -> ' + values);
        if (values != null && gDefaults.size() > 0){
            for (sObjectField field : values.keySet()){
                if (!gSuppressedDefaults?.contains(field)){
                    Object val = values.get(field);
                    if (String.valueOf(field) == 'Name' || String.valueOf(field) == 'LastName' || String.valueOf(field) == 'Title'){
                        // Adds an identifier to the Name/LastName/Title - i.e., Test Account 1
                        if (gRecordCounts.get(sObjectType) == null){
                            gRecordCounts.put(sObjectType, 1);
                        }
                        gRecordCounts.put(sObjectType,gRecordCounts.get(sObjectType)+1);
                    }
                    toReturn.put(field,val);
                }
            }
        }

        if (doInsert){
            toReturn = insertRecord(toReturn);
        }
        return toReturn;
    }

    private static void loadDefaults(){
        if (gSuppressedDefaults == null){
            gSuppressedDefaults = new Set<sObjectField>();
        }
        if (gRecordCounts == null){
            gRecordCounts = new Map<String,Integer>();
        }
        if (dmlOptions == null){
            dmlOptions = new Database.DMLOptions();
            dmlOptions.DuplicateRuleHeader.AllowSave = true;
        }
        gTestCodeDefault = [SELECT
                Checkbox_Value__c
                ,DateTime_Value__c
                ,Date_Value__c
                ,Email_Value__c
                ,Number_Value__c
                ,Percent_Value__c
                ,Phone_Value__c
                ,Picklist_Value__c
                ,Text_Area_Value__c
                ,Text_Value__c
                ,Type__c
                ,URL_Value__c
                ,Lookup_Value__c
                ,Lookup_Object__c
                ,Lookup_Field__c
                ,Blob_Value__c
                ,Is_Test__c
                ,sObject__c
                ,sObjectField__c
                FROM Test_Code_Default__mdt
                WHERE Is_Test__c = :restrictDefaultsToIsTest];
        //System.debug(Util.printSObject(gTestCodeDefault));
        for (Test_Code_Default__mdt tcd : gTestCodeDefault){
            if (gDefaults.get(tcd.sObject__c) == null){
                gDefaults.put(tcd.sObject__c,new Map<sObjectField,Object>());
            }
            Object value = null;
            switch on tcd.Type__c{
                when 'Checkbox'{
                    value = tcd.Checkbox_Value__c;
                }
                when 'Date'{
                    value = tcd.Date_Value__c;
                }
                when 'DateTime'{
                    value = tcd.DateTime_Value__c;
                }
                when 'Email'{
                    value = tcd.Email_Value__c;
                }
                when 'Number'{
                    value = tcd.Number_Value__c;
                }
                when 'Percent'{
                    value = tcd.Percent_Value__c;
                }
                when 'Phone'{
                    value = tcd.Phone_Value__c;
                }
                when 'Picklist'{
                    value = tcd.Picklist_Value__c;
                }
                when 'Text Area'{
                    value = tcd.Text_Value__c;
                }
                when 'URL'{
                    value = tcd.URL_Value__c;
                }
                when 'Blob'{
                    value = Blob.valueOf(tcd.Blob_Value__c);
                }
            }
                
            // RecordType needs to be unique because of the sObjectType filter. can't assume name won't be reused across objects.
            if (tcd.sObjectField__c == 'RecordTypeId') {
                value = Schema.getGlobalDescribe().get(tcd.sObject__c).getDescribe().getRecordTypeInfosByName().get(tcd.Text_Value__c).getRecordTypeId();
                if (value == null){
                    throw new MyException('Error setting default record type for ' + tcd.sObject__c + ' - Value ' + tcd.Text_Value__c + ' not found');
                }
            }



            if (tcd.Type__c == 'Lookup') {

                if (tcd.Lookup_Value__c == null || tcd.Lookup_Object__c == null || tcd.Lookup_Field__c == null){
                    throw new MyException('Error setting default record type for Lookup field ' + tcd.Lookup_Object__c + ' - Value ' + tcd.Lookup_Field__c + ' - can not set Lookup if one or more of the 3 Lookup fields is null.');
                }
                String query = 'SELECT Id from ' + tcd.Lookup_Object__c + ' Where ' + tcd.Lookup_Field__c + ' =  \'' + tcd.Lookup_Value__c + '\'';
                System.debug('** REH Setting default Lookup; assembled query: ' + query);
                List<sObject> lookupValues = Database.query(query);

                if (lookupValues.size() <> 1 && !Util.IS_TEST) {
                    System.debug(LoggingLevel.WARN,'** WARNING : UNABLE TO SET LOOKUP - NO VALUES OR TOO MANY VALUES FOR ' + query);
                    MyException.logError(new MyException(), 'UNABLE_TO_SET_LOOKUP_IN_TEST_CODE_DEFAULT', 'TMTest', 'loadDefaults()', 'loadDefaults');
                } else {
                    value = (id) lookupValues[0].Id;
                }

            }
            if (gDefaults.get(tcd.sObject__c) == null){
                gDefaults.put(tcd.sObject__c, new Map<sObjectField, Object>());
            }
            Map<sObjectField,Object> thisMap = gDefaults.get(tcd.sObject__c);
            Schema.SobjectField theField = Schema.getGlobalDescribe().get(tcd.sObject__c).getDescribe().fields.getMap().get(tcd.sObjectField__c);
            thisMap.put(theField,value);
            gDefaults.put(tcd.sObject__c,thisMap);
        }
    }

    public static void suppressDefault(sObjectField f){

        if (gSuppressedDefaults == null){
            gSuppressedDefaults = new Set<sObjectField>();
        }
        gSuppressedDefaults.add(f);
    }

    public static sObject insertRecord(sObject rec){
        Database.insert(rec,dmlOptions);
        return rec;
    }

    public static void updateRecord(sObject rec){
        Database.update(rec,dmlOptions);
    }

    public static void deleteRecord(sObject rec){
        Database.delete(rec);
    }

    public static void undeleteRecord(sObject rec){
        Database.undelete(rec);
    }

    public static void upsertRecord(sObject rec){
        Database.upsert(rec);
    }

    public static void insertRecord(List<sObject> rec){
        Database.insert(rec,dmlOptions);
    }

    public static void updateRecord(List<sObject> rec){
        Database.update(rec,dmlOptions);
    }

    public static void deleteRecord(List<sObject> rec){
        Database.delete(rec);
    }

    public static void upsertRecord(List<sObject> rec){
        Database.upsert(rec);
    }

    public static void undeleteRecord(List<sObject> rec){
        Database.undelete(rec);
    }

    public static list<User> generateUsers(Integer quantity, String profile){
        return generateUsers(quantity,profile, false,false);
    }

    public static list<User> generateUsers(Integer quantity, String profile, Boolean doInsert){
        return generateUsers(quantity,profile,doInsert, false);
    }

    public static List<User> generateUsers(Integer quantity, String profile, Boolean doInsert, Boolean usernameSuffix) {
        if (userCount == null){
            userCount = 1000;
        }

        Id profileId;
        Id roleId;

        // when creating Community users under runAs() it's important that the running user have a Role.
        if (profile != '') {
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :profile];
            if (profiles.size() != 1){
                throw new MyException ('generateUsers: ' + profile + ' either does not exist or has multiple matches on its name.');
            }
            profileId = profiles[0].Id;
        }

        List<User> toReturn = new List<User>();
        for (Integer x = 0; x < quantity; x++) {
            User u = (User) newObject('User');
            u.put(User.ProfileId,profileId);
            u.put(User.UserRoleId,roleId);
            u.put(User.CommunityNickname, 'testusernickname' + userCount);
            u.put(User.email, 'Test' + userCount + '@' + Util.MASTER_DOMAIN + (usernameSuffix ? '.invalid' : ''));
            u.put(User.Username, 'Test' + userCount + '@' + Util.MASTER_DOMAIN + '-lne1' + (usernameSuffix ? '.test' : ''));
            u.put(User.LastName, 'Test' + userCount);
            u.put(User.Alias,('Test' + userCount).abbreviate(8));
            system.debug('Constructed User ' + Util.printSObject(u));
            toReturn.add(u);
            userCount++;
        }

        if (doInsert)
            insert toReturn;
        return toReturn;
    }
}