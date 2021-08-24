/** 
 * TestUtilTest 
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

@IsTest
public with sharing class TestUtilTest {

    /**
     * Test class assumes there are Test_Code_Default__mdt records
     *  sObject__c  sObjectField__c Picklist_Value_ Text_Value__c       Type__c     Is_Test__c
        Account     AnnualRevenue                                       Number      TRUE
        Account     Name                            Test Account        Text        TRUE    
        Account     BillingStreet                   123 Cumberland St.  Text        TRUE
        Refund      Type            NonReferenced                       Picklist    TRUE
        Refund      ProcessingMode  External                            Picklist    TRUE
        Refund      Status          Draft                               Picklist    TRUE
        Refund      Amount                                              Number      TRUE
        User        TimeZoneSIDKey                  America/New York    Text        TRUE    
        User        LocaleSidKey                    en_US               Text        TRUE    
        User        EmailEncodingKey                ISO-8859-1          Text        TRUE
     */

    static{
        TestUtil.restrictDefaultsToIsTest = true;
    }
    @isTest
    public static void baseTest(){

        // Test Text fields
        Account a = (Account) TestUtil.newObject('Account',true);
        a = [SELECT Id, Name, AnnualRevenue,BillingStreet FROM Account WHERE Id =: a.Id];
        System.assertEquals(a.Name,'Test Account','Expected value \'Test Account\', Got ' + a.Name);
        System.assertEquals(Integer.valueOf(a.AnnualRevenue),1000, 'Expected 1000, Got ' + a.AnnualRevenue);
        System.assertEquals((a.BillingStreet),'123 Cumberland St', 'Expected \'123 Cumberland St\', got ' + a.BillingStreet);
        // Note: can not test the Lookup field since it implies a data dependency
    }

    @isTest
    public static void suppressDefault(){

        // Check that default suppression works
        TestUtil.suppressDefault(Account.AnnualRevenue);
        Account a = (Account) TestUtil.newObject('Account',true);
        a = [SELECT Id, Name, AnnualRevenue, BillingStreet FROM Account WHERE Id =: a.Id];

        System.assertEquals(a.Name,'Test Account','Expected value \'Test Account\', Got ' + a.Name);
        System.assertEquals(a.AnnualRevenue,null, 'Expected AnnualRevenue to be suppressed and should be null. Instead, got ' + a.AnnualRevenue); // This value was suppressed
        System.assertEquals((a.BillingStreet),'123 Cumberland St', 'Expected \'123 Cumberland St\', got ' + a.BillingStreet);
        // Note: can not test the Lookup field since it implies a data dependency
    }

    public static testmethod void dmlOperations(){
        Account a = (Account) TestUtil.newObject('Account');
        TestUtil.insertRecord(a);
        a = [SELECT Id, Name FROM Account WHERE Id =: a.Id];
        System.assertEquals(a.Name,'Test Account', 'Expected \'Test Account\', Got ' + a.Name);
        a.name = 'New Test Account';
        TestUtil.updateRecord(a);
        a = [SELECT Id, Name FROM Account WHERE Id =: a.Id];
        System.assertEquals(a.Name,'New Test Account', 'Expected \'New Test Account\', Got ' + a.Name);
        Account b = (Account) TestUtil.newObject('Account');
        TestUtil.upsertRecord(b);
        a = [SELECT Id, Name FROM Account WHERE Id =: b.Id];
        System.assertEquals(a.Name,'Test Account', 'Expected \'Test Account\', Got ' + a.Name);
        b.name = 'Different Name to Avoid Deduplication';
        TestUtil.upsertRecord(b);
        a = [SELECT Id, Name FROM Account WHERE Id =: b.Id];
        System.assertEquals(a.Name,'Different Name to Avoid Deduplication', 'dmlListOperations - upsertRecord 2 - Expected \'Different Name to Avoid Deduplication\', Got ' + a.Name);
        TestUtil.deleteRecord(a);
        List<Account> accounts =  [SELECT Id, Name FROM Account WHERE Id =: a.Id];
        System.assertEquals(accounts.size(),0, 'Expected 0 Accounts, got ' + accounts.size());
        TestUtil.undeleteRecord(a);
        accounts =  [SELECT Id, Name FROM Account WHERE Id =: a.Id];
        System.assertEquals(accounts.size(),1, 'Expected 1 Account, got ' + accounts.size());

    }

    public static testmethod void dmlListOperations(){
        Account a = (Account) TestUtil.newObject('Account');
        TestUtil.insertRecord(new List<Account>{a});
        a = [SELECT Id, Name FROM Account WHERE Id =: a.Id];
        System.assertEquals(a.Name,'Test Account', 'dmlListOperations - insertRecord - Expected \'Test Account\', Got ' + a.Name);
        a.name = 'New Test Account';
        TestUtil.updateRecord(new List<Account>{a});
        a = [SELECT Id, Name FROM Account WHERE Id =: a.Id];
        System.assertEquals(a.Name,'New Test Account', 'dmlListOperations - updateRecord - Expected \'New Test Account\', Got ' + a.Name);
        Account b = (Account) TestUtil.newObject('Account');
        TestUtil.upsertRecord(new List<Account>{b});
        a = [SELECT Id, Name FROM Account WHERE Id =: b.Id];
        System.assertEquals(a.Name,'Test Account', 'dmlListOperations - upsertRecord - Expected \'Test Account\', Got ' + a.Name);
        b.name = 'Different Name to Avoid Deduplication';
        TestUtil.upsertRecord(new List<Account>{b});
        a = [SELECT Id, Name FROM Account WHERE Id =: b.Id];
        System.assertEquals(a.Name,'Different Name to Avoid Deduplication', 'dmlListOperations - upsertRecord 2 - Expected \'Different Name to Avoid Deduplication\', Got ' + a.Name);
        Id aId = a.Id;
        TestUtil.deleteRecord(a);
        List<Account> accounts = [SELECT Id, Name, IsDeleted FROM Account WHERE Id =: aId ALL ROWS];
        System.assertEquals(accounts[0].IsDeleted,true, 'Expected isdeleted=true, got false');
        TestUtil.undeleteRecord(accounts);
        a = [SELECT Id, Name, IsDeleted FROM Account WHERE Id =: aId ALL ROWS];
        System.assertEquals(a.IsDeleted,false, 'Expected Account to be deleted, but it is not');

    }

    public static testmethod void noPermission(){
        List<User> users = TestUtil.generateUsers(3, 'System Administrator',false);
        users.addAll(TestUtil.generateUsers(3, 'Contract Manager',false));
        TestUtil.insertRecord(users);

        // List is ordered so 0,1,2 are admins, 3,4,5 are contract managers (standard profile)
        System.runAs(users[3]){
            Boolean gotError = false;

            // Using Refund here since it is a standard object where Contract Manager, a standard
            // Profile, does not have any permissions. There are Test Code Default records since
            // Refund has four required fields.
            Refund refundRecord = (Refund) TestUtil.newObject('Refund');
            try{
                TestUtil.insertRecord(refundRecord,true);
            } catch (Exception e){
                gotError = true;
                System.assertEquals(true,e.getMessage().contains('does not have permission to create Object Refund'),'Create - Error did not contain correct error message');
            }
            System.assertEquals(true,gotError,'Create: Error Was Not Thrown');

            // UPDATE a record
            System.runAs(users[0]){
                // Create the record as superuser
                TestUtil.insertRecord(refundRecord);
            }

            // Try to update the record as a user with no permission
            gotError = false;
            try{
                refundRecord.Amount = 200;
                TestUtil.updateRecord(refundRecord,true);
            } catch (Exception e){
                gotError = true;
                System.assertEquals(true,e.getMessage().contains('does not have permission to update Object Refund'),'Update - Error did not contain correct error message');
            }
            System.assertEquals(true,gotError,'Update: Error Was Not Thrown');

            // Try to upsert the record as a user with no permission
            gotError = false;
            try{
                refundRecord.Amount = 300;
                TestUtil.upsertRecord(refundRecord,true);
            } catch (Exception e){
                gotError = true;
                // No "upsertable" permission, so checks create and update independently and will throw one or the other
                System.assertEquals(true,e.getMessage().contains('does not have permission to'),'Update - Error did not contain correct error message');
            }
            System.assertEquals(true,gotError,'Upsert: Error Was Not Thrown');

            System.runAs(users[0]){
                List<Refund> refunds = [SELECT Id, Amount FROM Refund];
                System.assertEquals(1,refunds.size(), 'Upsert Created a new Refund record');
                refundRecord = refunds[0];
                System.assertNotEquals(null,refundRecord.Id, 'refundRecord does not have an Id');
            }
            

            // Try to delete the record as a user with no permission
            gotError = false;
            try{
                TestUtil.deleteRecord(refundRecord,true);
            } catch (Exception e){
                gotError = true;
                System.assertEquals(true,e.getMessage().contains('does not have permission to delete Object Refund'),'Update - Error did not contain correct error message');
            }
            System.assertEquals(true,gotError,'Upsert: Error Was Not Thrown');

            // Actually delete it
            System.runAs(users[0]){
                // Delete the record as superuser
                TestUtil.deleteRecord(refundRecord,true);
            }

            // Try to undelete the record as a user with no permission
            gotError = false;
            try{
                TestUtil.undeleteRecord(refundRecord,true);
            } catch (Exception e){
                gotError = true;
                System.assertEquals(true,e.getMessage().contains('does not have permission to undelete Object Refund'),'Update - Error did not contain correct error message');
            }
            System.assertEquals(true,gotError,'Upsert: Error Was Not Thrown');
        }
        

    }

    public static testmethod void noDefaults(){
        // construct an object that has no defaults, make sure there are no nulls
        Lead l = (Lead) TestUtil.newObject('Lead');
        System.assertEquals(l == null, false, 'Expected a test lead that is not null, got null.');
    }

    public static testmethod void generateUsers(){
        List<User> users = TestUtil.generateUsers(2,'System Administrator');
        insert users;

        System.runAs(users[0]){
            // Insert an Account to make sure we do not get MIXED_DML errors
            Account a = (Account) TestUtil.newObject('Account',true);
            System.assertEquals(a.Name,'Test Account', 'Expected \'Test Account\', Got ' + a.Name);
        }
    }
}