global class SchedulePaymentBatch implements Schedulable {
   global void execute(SchedulableContext sc) {
      PaymentCreationBatch b = new PaymentCreationBatch(); 
      database.executebatch(b);
   }
}