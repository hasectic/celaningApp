global class PaymentCreationBatch implements Database.Batchable<AggregateResult>,Database.Stateful{
    
    global List<Cleaning_Config__mdt> listCleaningConfig;
    global Date startDate;
    global Date endDate;
    
    global PaymentCreationBatch(){
        listCleaningConfig = [SELECT Label,Start_Day__c,End_Day__c FROM Cleaning_Config__mdt
                               WHERE Label = 'Cleaning App'];
        //1 //15
        if(Date.today().day()==Integer.valueOf(listCleaningConfig[0].Start_Day__c)){
         	startDate = Date.today().addMonths(-1);
            startDate = date.newInstance(startDate.year(),startDate.month(), Integer.valueOf(listCleaningConfig[0].End_Day__c)); 
        }
        if(Date.today().day()==Integer.valueOf(listCleaningConfig[0].End_Day__c)){
            startDate = date.newInstance(Date.today().year(),Date.today().month(), Integer.valueOf(listCleaningConfig[0].Start_Day__c)); 
        }
        //startDate = Date.today().addDays(Integer.valueOf(listCleaningConfig[0].Start_Day__c - listCleaningConfig[0].End_Day__c));
    }
    
    
    global Iterable<AggregateResult> start(Database.BatchableContext bc) {
        String query = 'SELECT Employee__c,SUM(Payment_Per_Job__c) amount,COUNT(Id) noOfBooking FROM Job_Delivery__c ';
        query += ' WHERE Paid__c = false AND Payment_Per_Job__c != null AND (Delivery_Date__c >=: startDate AND Delivery_Date__c < today) ';
        query += ' GROUP BY Employee__c ';
        return new AggregateResultIterable(query,startDate);
    }
    
    global void execute(Database.BatchableContext bc, List<AggregateResult> listJobDelivery){
        try{
            Set<String> setEmployeeId = new Set<String>();
            List<Payment__c> listPayment = new List<Payment__c>();
            List<Job_Delivery__c> listJobDeliveryToUpdate = new List<Job_Delivery__c>();
            
            for(AggregateResult aggr : listJobDelivery){
                setEmployeeId.add((Id)aggr.get('Employee__c'));
                Payment__c payment = new Payment__c();
                payment.Employee__c = (Id)aggr.get('Employee__c');
                payment.No_Of_Booking__c = (Integer)aggr.get('noOfBooking');
                payment.Amount__c = (Decimal)aggr.get('amount');
                payment.Payment_Date__c = Date.today();
                listPayment.add(payment);
            }
            
            if(setEmployeeId.size() > 0){
                for(Job_Delivery__c jobDlvry : [SELECT ID,Employee__c,Paid__c FROM Job_Delivery__c WHERE Paid__c = false AND 
                                                Payment_Per_Job__c != null AND Employee__c IN :setEmployeeId AND
                                                (Delivery_Date__c >=: startDate AND Delivery_Date__c < today)]){
                                                    jobDlvry.Paid__c = true;
                                                    listJobDeliveryToUpdate.add(jobDlvry);        
                                                }
            }
            if(listPayment.size() > 0)
                insert listPayment;
            
            if(listJobDeliveryToUpdate.size() > 0)
                update listJobDeliveryToUpdate;
            
        }catch(Exception e){
            System.debug('Error-->'+e.getMessage());
            System.debug('Line Number-->'+e.getLineNumber());
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    } 
}