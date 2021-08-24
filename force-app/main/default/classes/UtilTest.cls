/** 
 * UtilTest 
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

@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
@IsTest
public with sharing class UtilTest {

    public static testmethod void config(){
        System.assertEquals(true,Util.getBoolConfig('test_boolean'),'Config \'test_string\' =/= true, got false');
        System.assertEquals('true',Util.getConfig('test_string'), 'Config \'test_string\' =/= \'true\', got ' + Util.getConfig('test_string'));
        Boolean gotError =false;
        try {
            String discard = Util.getConfig('this_string_does_not_exist');
        } catch (Exception e){
            gotError=true;
        }
        System.assertEquals(true,gotError, 'Boolean Config not properly throwing error when config value does not exist');
        gotError =false;
        try {
            Boolean discard = Util.getBoolConfig('this_string_does_not_exist');
        } catch (Exception e){
            gotError=true;
        }
        System.assertEquals(true,gotError,'Boolean Config not properly throwing error when config value does not exist');
        Util.setConfigForTest('test_string','false');
        System.assertEquals('false',Util.getConfig('test_string'),'Tried to set a config override for test. Config \'test_string\' =/= \'false\', got ' + Util.getConfig('test_string'));
    }

    public static testmethod void idList(){
        System.assert((true || false), Util.rand5050());
        List<Account> accounts = new List<Account>{(Account)TestUtil.newObject('Account'),(Account)TestUtil.newObject('Account')};
        insert accounts;
        System.assertEquals(accounts[0].Id + ',' + accounts[1].Id, Util.idsFromList(accounts),'Expected ID List to match idsFromList()');

        List<String> invocableRequest = new List<String>();
        invocableRequest.add('test_string');
        List<String> invocableResponse = Util.invocableGetConfig(invocableRequest);
        System.assertEquals(invocableResponse.size(),1,'Expected Invocable Response Size 1, Got ' + invocableResponse.size());
        System.assertEquals(invocableResponse[0],'true', 'Expected Invocable to return TRUE, got FALSE');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts') // these are prints to debug log
    public static testmethod void printSObject(){
        // printSObject is a debug utility that prints stuff to debug log
        // this is mostly for coverage
        String discard = '';
        List<Account> accounts = new List<Account>{(Account)TestUtil.newObject('Account'),(Account)TestUtil.newObject('Account')};
        discard = Util.printSObject(accounts);
        discard = Util.printSObject(accounts[0]);
        discard = Util.printSObject(accounts[0],true); // as a table
        List<Double> a = new List<Double>{1,2,3,4};
        discard = Util.getType(a);
        discard = Util.getBaseType(a);
        Util.TEST_SCENARIO=true; // triggers errors for test in some methods
        discard = Util.getBaseType(a);
        discard = Util.getType(a);
        
    }

}