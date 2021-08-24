/** 
 * TestUtil 
 * Bob Hatcher - @BobHatcher
 * www.stupidcrmtricks.com
 * More Info: https://github.com/BobHatcher/TestUtil/wiki
 * 
    MIT License

    Copyright (c) 2021 Robert E Hatcher

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE. 
 */

@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount')
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

    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts')
    public static sObject newObject(String sObjectType, Boolean doInsert){
        if (gTestCodeDefault == null || gTestCodeDefault?.size() == 0){
            loadDefaults();
        }

        sObject newRecord = Schema.getGlobalDescribe().get(sObjectType).newSObject() ;
        Map<sObjectField,Object> values = gDefaults.get(sObjectType);
        //System.debug('Defaults for ' + sObjectType + ' -> ' + values);
        if (values != null && gDefaults.size() > 0){
            for (sObjectField field : values.keySet()){
                if (!gSuppressedDefaults?.contains(field)){
                    Object val = values.get(field);
                    if (String.valueOf(field) == 'Name' || String.valueOf(field) == 'LastName' || String.valueOf(field) == 'Title' || String.valueOf(Field) == 'Subject'){
                        // Adds an identifier to the Name/LastName/Title - i.e., Test Account 1
                        if (gRecordCounts.get(sObjectType) == null){
                            gRecordCounts.put(sObjectType, 1);
                        }
                        gRecordCounts.put(sObjectType,gRecordCounts.get(sObjectType)+1);
                    }
                    newRecord.put(field,val);
                }
            }
        }

        if (doInsert){
            newRecord = insertRecord(newRecord);
        }

        return newRecord;

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
            dmlOptions.OptAllOrNone = false;
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
                    value = tcd.Text_Area_Value__c;
                }
                when 'URL'{
                    value = tcd.URL_Value__c;
                }
                when 'Blob'{
                    value = Blob.valueOf(tcd.Blob_Value__c);
                }
                when 'Text'{
                    value = tcd.Text_Value__c;
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
                List<sObject> lookupValues = Database.query(String.escapeSingleQuotes(query)); // SOQL injection not a huge risk here but escapeSingleQuotes() is best practice

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
            if (!theField.getDescribe().isCreateable()){
                System.debug(LoggingLevel.WARN,'Tried to create default value for ' + String.valueOf(theField) + ' but it is not createable for this user.');
            }
            gDefaults.put(tcd.sObject__c,thisMap);
        }
    }

    public static void suppressDefault(sObjectField f){

        if (gSuppressedDefaults == null){
            gSuppressedDefaults = new Set<sObjectField>();
        }
        gSuppressedDefaults.add(f);
    }

    /************************
     * DML OPERATIONS
     * 
     * Overloaded methods. 
     * 
     * Simple operations (example for insert):
     * insertRecord(sObject rec); // simple insert
     * insertRecord(list<sObject> rec); // insert a list
     * 
     * Best practice is to run a permission check.
     * If you run a permission check:
     * - It will run an object-level permission check and if the uer does not have permission it will throw an error
     * - if it is a create/update operation, it will check field by field and remove fields the user does not have permission 
     *   to do the operation on (upsert checks both update and create)
     * 
     * 
     * insertRecord(sObject rec, Boolean permissionCheck); 
     * insertRecord(list<sObject> rec, Boolean permissionCheck); // insert a list
     * 
     * 
     */


    /**
     * Insert
     */
    
     public static sObject insertRecord(sObject rec){
        return insertRecord(rec,false);
    }

    public static void insertRecord(List<sObject> rec){
        insertRecord(rec,false);
    }

    public static sObject insertRecord(sObject rec, Boolean permissionCheck){
        insertRecord(new List<sObject>{rec}, permissionCheck);
        return rec;
    }

    public static void insertRecord(List<sObject> rec, Boolean permissionCheck){
        if (permissionCheck){
            validateCreatePermission(rec[0]);
        }
        try {
            Database.insert(rec,dmlOptions);
        } catch (Exception e){
            System.debug(LoggingLevel.ERROR,'Insert Errored! ' + e.getMessage() );
            throw new MyException('Insert Errored! ' + e.getMessage());
        }
    }

    public static void validateCreatePermission(List<sObject> recs){
        // Assumes all records have the same fields populated.
        validateCreatePermission(recs[0]);
    }

    public static void validateCreatePermission(sObject rec){
        // Can't remove a field from an sObject easily, so build a new one and leave out fields we don't have permission to
        Schema.DescribeSOBjectResult res = rec.getSObjectType().getDescribe();
        if (!res.isCreateable()){
            throw new MyException('User '+UserInfo.getUserId()+' does not have permission to create Object ' + res.getName());
        }
        String sObjectType = res.getName();
        Map<String,sObjectField> fieldMap = rec.getSObjectType().getDescribe().fields.getMap();
        List<sObjectField> fields = rec.getSObjectType().getDescribe().fields.getMap().values();
        sObject obj = res.getSObjectType().newSObject();
        for (sObjectField f : fields){
            if (rec.isSet(f) && f.getDescribe().isCreateable() ){
                throw new MyException('User '+UserInfo.getUserId()+' does not have permission to create field ' + f + ' on Object ' + res.getName());
            } 
        }
    }

    /**
     * Update
     */

    public static void updateRecord(sObject rec){
        updateRecord(rec,false);
    }

    public static void updateRecord(List<sObject> rec){
        updateRecord(rec,false);
    }

    public static void updateRecord(sObject rec, Boolean permissionCheck){
        updateRecord(new List<sObject>{rec},permissionCheck);
    }

    public static void updateRecord(List<sObject> rec, Boolean permissionCheck){
        if (permissionCheck){
            validateUpdatePermission(rec);
        }
        try {
            Database.update(rec,dmlOptions);
        } catch (Exception e){
            System.debug(LoggingLevel.ERROR,'Update Errored! ' + e.getMessage() );
            throw new MyException('Update Errored! ' + e.getMessage());
        }
    }

    public static void validateUpdatePermission(List<sObject> rec){
        // Assumes all records have the same fields populated
         validateUpdatePermission(rec[0]);
    }

    public static void validateUpdatePermission(sObject rec){
        // Can't remove a field from an sObject easily, so build a new one and leave out fields we don't have permission to
        Schema.DescribeSObjectResult res = rec.getSObjectType().getDescribe();
        if (!res.isUpdateable()){
            throw new MyException('User '+UserInfo.getUserId()+' does not have permission to update Object ' + res.getName());
        }
        String sObjectType = res.getName();
        Map<String,sObjectField> fieldMap = rec.getSObjectType().getDescribe().fields.getMap();
        List<sObjectField> fields = rec.getSObjectType().getDescribe().fields.getMap().values();
        sObject obj = res.getSObjectType().newSObject();
        for (sObjectField f : fields){
            if (rec.isSet(f) && !f.getDescribe().isUpdateable()){
                throw new MyException('User '+UserInfo.getUserId()+' does not have permission to update field ' + f + ' on Object ' + res.getName());
            } 
        }
    }

    /**
     * Upsert
     */

    public static void upsertRecord(List<sObject> rec){
        Database.upsert(rec, false);
    }

    public static void upsertRecord(sObject rec){
        Database.upsert(rec, false);
    }

    // Upsert, check both create and update permission
    public static void upsertRecord(List<sObject> rec, Boolean permissionCheck){
        if (permissionCheck){
            validateUpdatePermission(rec[0]);
            validateCreatePermission(rec[0]);
        }
        try {
            Database.upsert(rec);
        } catch (Exception e){
            System.debug(LoggingLevel.ERROR,'Upsert Errored! ' + e.getMessage() );
            throw new MyException('Upsert Errored! ' + e.getMessage());
        }
    }

    public static void upsertRecord(sObject rec, Boolean permissionCheck){
        upsertRecord(new List<sObject>{rec}, permissionCheck);
    }

     /**
      * Delete
      */
    public static void deleteRecord(sObject rec){
        Database.delete(rec);
    }

    public static void deleteRecord(List<sObject> rec){
        Database.delete(rec);
    }

    public static void deleteRecord(List<sObject> rec, Boolean permissionCheck){
        if (permissionCheck){
            validateDeletePermission(rec);
        }
        try {
            Database.delete(rec);
        } catch (Exception e){
            throw new MyException('Delete Errored! ' + e.getMessage());
        }
        
    }

    public static void deleteRecord(sObject rec, Boolean permissionCheck){
        deleteRecord(new List<sObject>{rec},permissionCheck);
    }

    public static void validateDeletePermission(List<sObject> recs){
        validateDeletePermission(recs[0]); // Permission for one is permission for any of the type
    }

    public static void validateDeletePermission(sObject rec){
        Schema.DescribeSObjectResult res = rec.getSObjectType().getDescribe();
        if (!res.isDeletable()){
            throw new MyException('User '+UserInfo.getUserId()+' does not have permission to delete Object ' + res.getName());
        }
    }

    /**
     * Undelete
     */
    public static void undeleteRecord(sObject rec){
        Database.undelete(rec);
    }

    public static void undeleteRecord(List<sObject> rec){
        Database.undelete(rec);
    }

    public static void undeleteRecord(List<sObject> rec, Boolean permissionCheck){
        if (permissionCheck){
            validateUndeletePermission(rec);
        }
        Database.undelete(rec[0]);
    }

    public static void undeleteRecord(sObject rec, Boolean permissionCheck){
        undeleteRecord(new List<sObject>{rec}, permissionCheck);
    }

    public static void validateUndeletePermission(List<sObject> recs){
        validateUndeletePermission(recs[0]); // Permission for one is permission for any of the type
    }

    public static void validateUndeletePermission(sObject rec){
        Schema.DescribeSObjectResult res = rec.getSObjectType().getDescribe();
        if (!res.isUndeletable()){
            throw new MyException('User '+UserInfo.getUserId()+' does not have permission to undelete Object ' + res.getName());
        }
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
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :profile WITH SECURITY_ENFORCED];
            if (profiles.size() != 1){
                throw new MyException ('generateUsers: ' + profile + ' either does not exist or has multiple matches on its name.');
            }
            profileId = profiles[0].Id;
        }

        List<User> toReturn = new List<User>();
        for (Integer x = 0; x < quantity; x++) {
            User u = (User) TestUtil.newObject('User');
            u.put(User.ProfileId,profileId);
            u.put(User.UserRoleId,roleId);
            u.put(User.CommunityNickname, 'testusernickname' + userCount);
            u.put(User.email, 'Test' + userCount + '@' + Util.MASTER_DOMAIN + (usernameSuffix ? '.invalid' : ''));
            u.put(User.Username, 'Test' + userCount + '@' + Util.MASTER_DOMAIN + (usernameSuffix ? '.test' : ''));
            u.put(User.LastName, 'Test' + userCount);
            u.put(User.Alias,('Test' + userCount).abbreviate(8));
            system.debug('Constructed User ' + Util.printSObject(u));
            toReturn.add(u);
            userCount++;
        }

        

        if (doInsert){
            insertRecord(toReturn);
        }
        return toReturn;
    }
}