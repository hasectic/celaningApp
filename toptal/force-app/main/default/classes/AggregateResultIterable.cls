global class AggregateResultIterable implements Iterable<AggregateResult> {
  private String query;
  private Date startDate;
  global AggregateResultIterable(String soql,Date startDate){
    query = soql;
    this.startDate = startDate;
  }

  global Iterator<AggregateResult> Iterator(){
    return new AggregateResultIterator(query,startDate);
  }
}