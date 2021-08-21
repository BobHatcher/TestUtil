@IsTest
public with sharing class DemoTestUtilUsage {

    @IsTest
    public static void demoTest(){
        // Constructs an Account with defaults
        Account a = (Account) TestUtil.newObject('Account');

        // Constructs an Account with defaults and inserts it
        Account b = (Account) TestUtil.newObject('Account',true);

        // Constructs an Account with defaults then add an attribute
        Account c = (Account) TestUtil.newObject('Account');
        c.BillingCity = 'Dunedin';
        TestUtil.insertRecord(c);

        c.BillingCity = 'Invercargill';
        TestUtil.upsertRecord(c);

        c = [SELECT BillingCity FROM Account WHERE Id =: c.Id];
        System.assertEquals(c.BillingCity,'Invercargill','Billing City Was ' + c.BillingCity + ', Expected \'Invercargill\'');
    }

    @IsTest
    public static void demoTestUsers(){
        // This method is very handy for avoiding MIXED_DML_OPERATION errors.
        // Generates two System Administrator users.
        List<User> users = TestUtil.generateUsers(2,'System Administrator', true);
        System.runAs(users[0]){
            System.assertNotEquals(users[0].Id,null,'User[0] ID Is Null');
            System.assertNotEquals(users[1].Id,null,'User[1] ID Is Null');
            System.assertNotEquals(users[0].Id, users[1].Id,'User[0] ID ('+users[0].Id+') Should Not Equal User[1] ID ('+users[1].Id+')');

        }
    }
}