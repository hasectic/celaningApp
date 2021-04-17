global class BookingGenerationBatch implements Database.Batchable<SObject>,Database.Stateful{
    
    global List<Cleaning_Config__mdt> listCleaningConfig;
    
    global BookingGenerationBatch(){
        listCleaningConfig = [SELECT Cleaning_Rate__c,Discount_Rate__c,No_of_Worker_per_Home__c,No_of_Worker_per_Office__c,  
                              Payment_Mode__c FROM Cleaning_Config__mdt WHERE Label = 'Cleaning App'];
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id,Name,Email__c,Next_Cleaning_Date__c,Type, ';
        query += ' (SELECT Id,Recurring_Type__c FROM Bookings__r ORDER BY CreatedDate DESC LIMIT 1) ';
        query += ' FROM Account WHERE Next_Cleaning_Date__c = TOMORROW ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> listClient){
        List<String> listAvailableEmployee = new List<String>();
        List<Job_Delivery__c> listJobDelivery = new List<Job_Delivery__c>();
        List<Booking__c> listBooking = new List<Booking__c>();
        List<Account> listAccountToUpdate = new List<Account>();
        List<Account> listAccountOfFailedBooking = new List<Account>();
        List<Messaging.SingleEmailMessage> listMails = new List <Messaging.SingleEmailMessage> ();
        
        for(Contact con : [SELECT Id,Name,EMP_ID__c,Job_Load__c,(SELECT Id from Employee_Leaves__r WHERE Leave_Date__c = TOMORROW),
                           (SELECT Id from Job_Deliveries__r WHERE Delivery_Date__c = TOMORROW)  
                           FROM Contact WHERE Employment_Status__c='Available' ORDER BY Job_Load__c]){
                               if(con.Employee_Leaves__r.size() == 0 && con.Job_Deliveries__r.size() == 0)
                                   listAvailableEmployee.add(con.Id);
                           }
        Integer i=0;
        system.debug('listAvailableEmployee-->'+listAvailableEmployee.size());
        for(Account acc : listClient){
            system.debug('acc-->'+acc);
            Booking__c booking = new Booking__c();
            booking.Booking_Date__c = acc.Next_Cleaning_Date__c;
            booking.Cleaning_Amount__c = listCleaningConfig[0].Cleaning_Rate__c;
            booking.Client__c = acc.Id;
            booking.Recurring__c = true;
            booking.Discount__c = booking.Cleaning_Amount__c * listCleaningConfig[0].Discount_Rate__c * .01;
            booking.Payment_Mode__c = listCleaningConfig[0].Payment_Mode__c;
            booking.Status__c = 'Booked';
            if(acc.Bookings__r.size() > 0) 
                booking.Recurring_Type__c = acc.Bookings__r[0].Recurring_Type__c;
            
            List<Job_Delivery__c> listTempJobDelivery = new List<Job_Delivery__c>();
            if(String.isNotBlank(acc.Type) && acc.Type == 'Home'){
                for(Integer j= 0;j < listCleaningConfig[0].No_of_Worker_per_Home__c;j++){
                    if(listAvailableEmployee.size() > i){
                        Job_Delivery__c jobdlvery = new Job_Delivery__c();
                        jobdlvery.Delivery_Date__c = booking.Booking_date__c;
                        jobdlvery.Booking__r = booking;
                        jobdlvery.Employee__c = listAvailableEmployee[i];
                        listTempJobDelivery.add(jobdlvery);
                        i++;
                    }
                }
                if(listTempJobDelivery.size() == listCleaningConfig[0].No_of_Worker_per_Home__c){
                    listBooking.add(booking);
                    listJobDelivery.addAll(listTempJobDelivery);
                }else{
                    listAccountOfFailedBooking.add(acc);
                }
            }else{
                for(Integer j= 0; j < listCleaningConfig[0].No_of_Worker_per_Office__c; j++){
                    if(listAvailableEmployee.size() > i){
                        Job_Delivery__c jobdlvery = new Job_Delivery__c();
                        jobdlvery.Delivery_Date__c = booking.Booking_date__c;
                        jobdlvery.Booking__r = booking;
                        jobdlvery.Employee__c = listAvailableEmployee[i];
                        listTempJobDelivery.add(jobdlvery);
                        i++;
                    }
                }
                if(listTempJobDelivery.size() == listCleaningConfig[0].No_of_Worker_per_Office__c){
                    listBooking.add(booking);
                    listJobDelivery.addAll(listTempJobDelivery);
                }else{
                    listAccountOfFailedBooking.add(acc);
                }
            }
        }
        
        if(listBooking.size() > 0){
            insert listBooking;
            for(Booking__c booking :listBooking){
                if(String.isNotBlank(booking.Client__c) && String.isNotBlank(booking.Recurring_Type__c) && booking.Booking_Date__c != NULL)
                    listAccountToUpdate.add(BookingCreateController.updateClientNextBookingDate(booking.Client__c,booking.Booking_Date__c,booking.Recurring_Type__c));
            }
            List<id> bids = new List<id> ();
            if(listJobDelivery.size() > 0){
                for(Job_Delivery__c jobDelvry : listJobDelivery){
                    jobDelvry.Booking__c = jobDelvry.Booking__r.Id;
                    bids.add(jobDelvry.Booking__c);
                }
                insert listJobDelivery;
                BookingCreateController.emailsend(bids);
            }
        }
        
        if(listAccountToUpdate.size() > 0)
            update listAccountToUpdate;
        
        if(listAccountOfFailedBooking.size() > 0){
            for(Account acc: listAccountOfFailedBooking){
                if(acc.Email__c!=null){
                    string subject = 'Cleaning Booking Failed due to Unavailability of Cleaners';
                    string body = 'Hi '+acc.Name+',<br/> Hope you are doing great.<br/><br/>';
                    body += 'Sorry for the inconvinence.You booking for cleaning on <b>'+acc.Next_Cleaning_Date__c.format();
                    body += 'has been postponed.<br/><br/>';
                    body += 'We will try to schedule your booking for tomorrow.';
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] {acc.Email__c});
                    // Specify the name used as the display name.
                    mail.setSenderDisplayName('Cleaning Team & Agency co');
                    // Specify the subject line for your email address.
                    mail.setSubject(subject);
                    // Set to True if you want to BCC yourself on the email.
                    mail.setBccSender(false);
                    mail.setHtmlBody(body);
                    listMails.add(mail);
                }
                acc.Next_Cleaning_Date__c = acc.Next_Cleaning_Date__c.addDays(1);
            }
        }
        
        if(listMails.size()>0)
            Messaging.sendEmail(listMails);
        
        if(listAccountOfFailedBooking.size() > 0)
            update listAccountOfFailedBooking;
        
    }
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
}