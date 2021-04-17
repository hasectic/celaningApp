/**
* @File Name          : BookingCreateController.cls
* @Description        : it is utilized in Booking Creation LWC
* @Author             : Saifullah Saifi
* @Group              : 
* Test Class		   : BookingCreateControllerTest
* @Last Modified By   : 
* @Last Modified On   : 11/04/2021
* @Modification Log   : 
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    03/04/2021, 11s:00:01 AM         Saifullah Saifi    			  Initial Version
**/
public with sharing class BookingCreateController {
    
    /**
Author: Saifullah Saifi    
Company: 
Description: This method returns the Client detail  with Booking instance
Inputs: recordId of Client
Returns: bookingInfo a wrapper
History:
================
1.0     11 Apr 2021     Saif     Initial Version
*/
    @AuraEnabled
    public static BookingInfo retriveBookingInfo(String recordId){
        BookingInfo ci = new BookingInfo();
        system.debug('>>'+recordId);
        if(String.isNotBlank(recordId)){ 
            List<Account> accList = new List<Account>([Select id,ShippingStreet,ShippingCity,ShippingState,
                                                       ShippingCountry,ShippingPostalCode,Type, Name from Account Where Id =: recordId]);     
            
            
            List<Cleaning_Config__mdt>  listCleaningConfig = [SELECT Cleaning_Rate__c,Discount_Rate__c,
                                                              No_of_Worker_per_Home__c,No_of_Worker_per_Office__c,  Payment_Mode__c
                                                              FROM Cleaning_Config__mdt
                                                              WHERE Label = 'Cleaning App'];       
            ci.client =accList[0];
            ci.errmsg = 'Success';
            Booking__c wo= new Booking__c();
            if(ci.client.Type=='' || ci.client.Type==null)
                ci.errmsg='Client Type should not be blank';
            wo.Booking_Date__c = system.today()+1;
            if(listCleaningConfig.size()>0){
                if(ci.client.Type=='Office'){
                    ci.numberOfWorker = (Integer)listCleaningConfig[0].No_of_Worker_per_Office__c;
                }
                else
                    ci.numberOfWorker = (Integer)listCleaningConfig[0].No_of_Worker_per_Home__c;
                
                wo.Cleaning_Amount__c = ci.NumberOfWorker * listCleaningConfig[0].Cleaning_Rate__c;
                // wo.Total_Paid_Amount__c =  wo.Cleaning_Amount__c;
                Double dscnt =  wo.Cleaning_Amount__c * listCleaningConfig[0].Discount_Rate__c * .01;
                wo.Discount__c = dscnt;
                wo.Payment_Mode__c = listCleaningConfig[0].Payment_Mode__c;
                ci.discount = listCleaningConfig[0].Discount_Rate__c;
            }
            else{
                ci.errmsg ='Company detail is blank please contact system admin';
            }
            ci.conList =getAvailableEmployee(wo.Booking_Date__c);
            if(ci.conList.size()<ci.numberOfWorker)
                ci.errmsg = 'Number of Cleaner needed for the job is not available, please try for another date.';
            
            ci.booking = wo;
            return ci;
        }
        return null;
    }
    @AuraEnabled
    public static List<Contact> getAvailableEmployee(date bkngdt){
        try {
            List<Contact> AvailableEmployeeList = new List<Contact>();
            for (Contact con : [SELECT id,Name,EMP_ID__c,
                                (SELECT id from Employee_Leaves__r WHERE Leave_Date__c=:bkngdt ),
                                (SELECT id from Job_Deliveries__r WHERE Delivery_Date__c=:bkngdt )  
                                from Contact WHERE Employment_Status__c='Available']){
                                    if(con.Employee_Leaves__r.size()==0 && con.Job_Deliveries__r.size()==0)
                                        AvailableEmployeeList.add(con);
                                }
            return AvailableEmployeeList;
        } catch (Exception e) {
            //   throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static string saveAppointment(String recordId,string data,string jdEmployeeIDs){
        system.debug('>.>'+jdEmployeeIDs);
        string msg; 
        Booking__c wo= new Booking__c();
        try{            
            wo= (Booking__c)JSON.deserialize(data, Booking__c.class);
            wo.Client__c = recordId;
            wo.status__c = 'Booked';
            insert wo;
            List<Job_Delivery__c> jdList = new List<Job_Delivery__c>();
            if(jdEmployeeIDs.contains(',')){
                for(string str: jdEmployeeIDs.split(',')){
                    Job_Delivery__c jd = new Job_Delivery__c();
                    jd.Delivery_Date__c = wo.Booking_date__c;
                    jd.Booking__c = wo.id;
                    jd.Employee__c = str;
                    jdList.add(jd);
                }
            }
            else{
                Job_Delivery__c jd = new Job_Delivery__c();
                jd.Delivery_Date__c = wo.Booking_Date__c;
                jd.Booking__c = wo.id;
                jd.Employee__c = jdEmployeeIDs;
                jdList.add(jd);
            }
            if(jdList.size()>0)
                insert jdList;
            if(wo.Recurring__c){
                update updateClientNextBookingDate(recordId,wo.Booking_Date__c,wo.Recurring_Type__c);
            }
            emailsend(new List<Id>{wo.id});
            
            
        }Catch(Exception e){
            msg=e.getMessage();
        }
        return wo.id==null?msg:wo.id;
    }
    
    public static Account updateClientNextBookingDate(id clientId, Date currDt, string rtype){
        Account acc = new Account();
        acc.id = clientId;
        if(rtype=='Weekly'){
            acc.Next_Cleaning_Date__c=currDt+7;
        }
        else if(rtype=='Bi-Weekly'){
            acc.Next_Cleaning_Date__c=currDt+14;
        }
        else if(rtype=='Monthly'){
            acc.Next_Cleaning_Date__c=currDt.addMonths(1);
        }
        return acc;
    }
    @AuraEnabled
    public static Booking__c retriveMapInfo(string recordId){
        system.debug(recordId);
        try {
            List<Booking__c> bookList = new List<Booking__c>([Select id,Client__r.ShippingStreet,Client__r.ShippingCity,Client__r.ShippingState,
                                                              Client__r.ShippingCountry,Client__r.ShippingPostalCode,Client__r.Name from Booking__c Where id =: recordId]);     
            system.debug(booklist.size());
            if(bookList.size()>0)
                return bookList[0];
            else 
                return null;
            
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    public static void emailsend( List<Id> bidS){
        List < Messaging.SingleEmailMessage > mails = new List < Messaging.SingleEmailMessage > ();
        
        For(Booking__c book : [SELECT client__r.Email__c,client__r.Name,Booking_date__c,Name,
                               (SELECT Name, Employee__r.name, Employee__r.phone from Job_Delivery__r ) from
                               Booking__c Where id IN :bidS]){
                                   if(book.client__r.Email__c!=null){
                                       string sub = 'New Booking Created for cleaning with booking no:'+book.name;
                                       string body = 'Hi '+book.client__r.Name+',<br/> Hope you are doing great.<br/><br/>';
                                       body+='You booking has been created for cleaning on <b>'+book.Booking_date__c.format();
                                       body+='</b>.<br/> Your booking no is:<b>'+book.name;
                                       body+='</b><br/>Please find the cleaner detail below:<br/>';
                                       integer i=0;
                                       for(Job_Delivery__c jd: book.Job_Delivery__r){
                                           i++;
                                           body+=i+'. Name - '+jd.Employee__r.name+' Phone - '+jd.Employee__r.phone+'<br/>';
                                       }
                                       
                                       
                                       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                       mail.setToAddresses(new String[] {book.client__r.Email__c});
                                       
                                       // Specify the name used as the display name.
                                       mail.setSenderDisplayName('Cleaning Team & Agency co');
                                       
                                       // Specify the subject line for your email address.
                                       mail.setSubject(sub);
                                       
                                       // Set to True if you want to BCC yourself on the email.
                                       mail.setBccSender(false);
                                       mail.setHtmlBody(body);
                                       mails.add(mail);
                                   }
                                   
                               }
        if(mails.size()>0)
            Messaging.sendEmail(mails);
        
        
    }
    public class BookingInfo{
        @AuraEnabled public Account client;
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public List<Contact> conList;
        @AuraEnabled public string errmsg;
        @AuraEnabled public Double discount;
        @AuraEnabled public Integer numberOfWorker;
    }
    
    
}