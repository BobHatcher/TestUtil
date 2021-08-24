/** 
 * MyException 
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