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

/**
 *
 *
 *  ******* MyException *******
 *
 *  A framework for handling errors. This will insert an Error__c record in the system upon errors,
 *  and if it is a DML error, will also insert DML_Error__c records as children.
 *
 *  This provides
  *  -- maximum information about the error
  *  -- reportable intelligence about errors
  *  -- process automation for notification purposes (i.e., email alerts)
  *  -- auto-create Cases from Errors
 *
 * Usage:
 * try(){
 *  ...
 * } catch (Exception e) {
 *    MyException.addError(Exception e, String className, String methodName);
 * }
 *
 * Optional parameters for a DeveloperMessage (anything you want the person receieving the error to know), the record
 * or list of records being operated on, or just the type of records.
 *
 * Type is useful on DML errors since it is necessary for identifying the field that caused the failure.
 *
 */

@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
public without sharing virtual class MyException extends Exception{
    private static Integer errorDepth = 0; // use to prevent runaway recursion
    private static final Integer MAX_DEPTH = 5;
    private static final String IGNORE = 'MyException-Ignore-RandomString-ZS-NMS';
    public static final String NULL_ID = '=0= Insert/Del Op?';

    public static void logError(Exception e, String code, String className, String methodName){
        logError(e,code,className,methodName,null);
    }

    public static void logError(Exception e, String code, String className, String methodName, String developerMessage){
        // send a blank Account
        logError(e,code,className,methodName,developerMessage,new Account(Name=IGNORE));
    }

    /*
        logError
        Overloaded method - provide an Exception, the class and the method name, and a message you want logged
        Also provide an sObject; the ID of the sObject will be logged.
        Logs an Error record

        NOTE: you can not send an object via the obj parameter that is deleted

        This version is tolerant of the sObject parameter coming in as null.
     */
    public static void logError(Exception e, String code, String className, String methodName, String developerMessage, sObject obj){
        if (depthCheck()){
            return;
        }
        Error__c err = baseError(e,code, className,methodName,developerMessage);
        try {
            err.Record_Ids__c = (obj == null || obj.Id == null ? NULL_ID : obj?.Id);
            Id errorId = insertError(e,err);
            if (isDML(e)){
                if (obj != null && obj?.getSObjectType() == Account.SObjectType && obj?.get('Name') == IGNORE){
                    // This came from one of the versions with fewer parameters and we can't know the type of the sObject
                    // It sent us a dummy Account ...
                    // Send null to the DML process
                    insertDMLErrorRecords(e,errorId, null);
                } else {
                    insertDMLErrorRecords(e,errorId, obj?.getSObjectType());
                }
            }
            errorDepth --;
        } catch (Exception exc){
            Util.debug('logError Failed. Message: ' + exc.getMessage());
            Util.debug('logError Failed. Stack Trace: ' + exc.getStackTraceString());
            err.Record_Ids__c = exc.getMessage().abbreviate(255);
        }


    }

    /*
        logError
        Overloaded method - provide an Exception, the class and the method name, and a message you want logged
        Also provide a list of sObjects; the ID of the sObjects will be logged as a comma delimited string
        Logs an Error record

        This version will not work correctly if the list of sObjects is zero-length or null
     */
    public static void logError(Exception e,  String code, String className, String methodName, String developerMessage, List<sObject> objects){
        if (depthCheck()){
            return;
        }
        Error__c err = baseError(e,code,className,methodName,developerMessage);
        if (objects != null && objects.size() > 0){
            try {
                // this will fail if the record(s) are deleted
                err.Record_Ids__c = Util.idsFromList(objects)?.abbreviate(255);
                Id errorId = insertError(e,err);
                if (isDML(e)){
                    insertDMLErrorRecords(e,errorId, objects[0].getSObjectType());
                }
                errorDepth --;
            } catch (MyException exc){
                Util.debug('logError (List<sObject>) Failed. Message: ' + exc.getMessage());
                Util.debug('logError (List<sObject>) Failed. Stack Trace: ' + exc.getStackTraceString());
                err.Record_Ids__c = exc.getMessage().abbreviate(255);
            }
        }

    }



    /*
        logError
        Overloaded method - provide an Exception, the class and the method name, and a message you want logged

        Use this version when you have an sObjectType only - primarily on delete operations
     */
    public static void logError(Exception e, String code, String className, String methodName, String developerMessage, sObjectType typ){
        if (depthCheck()){
            return;
        }
        Error__c err = baseError(e,code,className,methodName,developerMessage);
        err.Record_Ids__c = NULL_ID;
        try {
            Id errorId = insertError(e,err);
            if (isDML(e)){
                insertDMLErrorRecords(e,errorId, typ);
            }
            errorDepth --;
        } catch (Exception exc){
            Util.debug('logError Failed. (Type Only Version) Message: ' + exc.getMessage());
            Util.debug('logError Failed. (Type Only Version) Stack Trace: ' + exc.getStackTraceString());
            err.Record_Ids__c = exc.getMessage().abbreviate(255);
        }

    }

    // Generic/repeatable method for creating the Error__c
    private static Error__c baseError(Exception e, String code, String className, String methodName, String developerMessage){

        return new Error__c (
                Code__c = code,
                Class__c = className,
                Method__c = methodName,
                Type__c = 'Apex' + (isDML(e) ?' (DML)':''),
                Message__c = e?.getMessage(),
                Developer_Message__c = developerMessage?.abbreviate(255),
                Stack_Trace__c = e?.getStackTraceString()?.abbreviate(32768),
                Line_Number__c = e?.getLineNumber(),
                Severity__c = 'Error',
                Exception_Type__c = e?.getTypeName()?.abbreviate(80)
        );
    }

    private static void insertDMLErrorRecords(Exception exc, Id errorId, sObjectType typ){
        insert createDMLErrorRecords(exc, errorId, typ);
    }

    /**
     * createDMLErrorRecords
     *
     * DML_Error__c is a master-detail child record to Error__c. This will create DML_Error__c records
     * for each record that failed in the transaction, tied to the parent Error.
     *
     * @param exc The Exception that is really a DMLException
     * @param errorId The ID of the Error__c that was inserted, for the master-detail on the future DML_Error__c
     * @param typ The sObjectType we are working with. Necessary to try to get the fieldName from the DML error. If unknown, send null
     *
     * @return a list of DML_Error__c records that can be inserted and associated to the Error__c
     */
    private static List<DML_Error__c> createDMLErrorRecords(Exception exc, Id errorId, sObjectType typ){
        DMLException e = (DmlException) exc;
        List<DML_Error__c> toInsert = new List<DML_Error__c>();
        Integer numErrors = e.getNumDml();
        for(Integer i=0;i<numErrors;i++) {

            // Convoluted way of getting the field name because you need to know
            // the sObjectType of the record in order for the method to work.
            // The fields come in a List of sObjectFields so we need to parse them out and convert
            // them to Strings using getDescribe
            // h/t https://salesforce.stackexchange.com/questions/120932/dmlexception-getdmlfields-fails-when-inserting-list-of-sobjects

            List<String> fieldNames = e.getDmlFieldNames(i);
            Schema.SObjectType failedType =  typ;
            List<String> fieldNameList = new List<String>();
            for (String fieldName : fieldNames) {
                // Use the field name to get the SObjectField
                Schema.SObjectField fieldFromName = failedType.getDescribe().fields.getMap().get(fieldName);
                if (fieldFromName != null){
                    fieldNameList.add(String.valueOf(fieldFromName));
                    System.debug('SOBJECT FIELD FROM NAME');
                    System.debug(fieldFromName);
                }
            }
            String fieldNamesFinal = String.join(fieldNameList,', ');

            toInsert.add(new DML_Error__c(
                    Error__c = errorId,
                    Message__c = e.getDmlMessage(i)?.abbreviate(255),
                    Field_Names__c = fieldNamesFinal?.abbreviate(255),
                    DML_Error_Number__c = (i + 1) + ' of ' + numErrors,
                    Record_Id__c = (e.getDMLId(i) == null ? NULL_ID : e.getDMLId(i)?.abbreviate(18))
            ));

        }

        return toInsert;
    }

    private static Id insertError(Exception e, Error__c err){
        try{
            Util.debug('Attempting to Insert Error__c:' + Util.printSObject(err));
            if (!Schema.sObjectType.Error__c.isCreateable()){
                insert err;
                return err.Id;
            }
            
        } catch (Exception secondException) {
            // If this trips it's probably because there is something wrong like a new picklist value on the Error__c object
            Util.debug('\nError inserting Error__c Record While Attempting to Log: ' + e.getStackTraceString() + '\n Error Thrown while Inserting the Error: ' + secondException.getStackTraceString());

        }
        return err.id;
    }

    private static Boolean isDML(Exception e){
        return e?.getTypeName() == 'System.DmlException';
    }

    public static Boolean depthCheck(){
        errorDepth ++;
        if (errorDepth >= MAX_DEPTH){
            Util.debug('*** Max Debug Depth ('+MAX_DEPTH+') Reached in MyException ***');
            return true;
        } else { return false; }
    }
}